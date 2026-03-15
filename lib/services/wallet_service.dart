import 'dart:typed_data';
import 'dart:convert';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;
import 'package:crypto/crypto.dart';
import 'package:hex/hex.dart';
import 'package:pointycastle/digests/ripemd160.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class WalletService {
  // Nyjet ku aplikacioni do të kërkojë të dhënat
  final List<String> _nodes = [
    "https://162.19.164.24", // IP direkte e api.warthog.network
    "https://warthognode.duckdns.org",
    "http://217.182.64.43:3001",
    "https://api.warthog.network"
  ];

  final secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Ky funksion provon të gjitha nyjet me radhë
  Future<http.Response> _multiNodeRequest(String path, {bool isPost = false, Map<String, dynamic>? body}) async {
    for (String node in _nodes) {
      try {
        final uri = Uri.parse('$node$path');
        final headers = {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "User-Agent": "WarthogWallet/1.0"
        };

        final response = isPost 
          ? await http.post(uri, headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 8))
          : await http.get(uri, headers: headers).timeout(const Duration(seconds: 8));
        
        if (response.statusCode == 200) return response;
      } catch (e) {
        debugPrint("Nyja $node nuk punon: $e");
        continue; // Provojmë nyjen tjetër
      }
    }
    // Nëse asnjë nyje nuk kthen status 200, hedhim gabim
    throw Exception("Asnjë nyje nuk është funksionale");
  }

  // --- REFRESH I NYJES ---
  Future<Map<String, dynamic>> getLiveState(String address) async {
    // Hoqëm try-catch që të bëjmë dritën e kuqe te Provider-i
    final response = await _multiNodeRequest('/account/$address');
    return jsonDecode(response.body);
  }

  Future<String> _getChainPin() async {
    try {
      final response = await _multiNodeRequest('/chain/head');
      return jsonDecode(response.body)['pin'] ?? "";
    } catch (e) { return ""; }
  }

  String generateNewMnemonic({int strength = 128}) => bip39.generateMnemonic(strength: strength);

  String _calculateWarthogAddress(Uint8List compressedPubKey) {
    final sha = sha256.convert(compressedPubKey).bytes;
    final ripemd = RIPEMD160Digest().process(Uint8List.fromList(sha));
    final checksum = sha256.convert(ripemd).bytes.sublist(0, 4);
    return HEX.encode(Uint8List.fromList([...ripemd, ...checksum]));
  }

  Future<Map<String, String>> deriveWallet(String mnemonic) async {
    final seed = bip39.mnemonicToSeed(mnemonic);
    final root = bip32.BIP32.fromSeed(seed);
    final child = root.derivePath("m/44'/2070'/0'/0/0");
    return {
      'address': _calculateWarthogAddress(child.publicKey),
      'privateKey': HEX.encode(child.privateKey!),
      'publicKey': HEX.encode(child.publicKey),
    };
  }

  Future<void> saveWallet(String mnemonic, String address) async {
    await secureStorage.write(key: 'mnemonic', value: mnemonic);
    await secureStorage.write(key: 'address', value: address);
  }

  Future<String?> getAddress() async => await secureStorage.read(key: 'address');
  Future<String?> getMnemonic() async => await secureStorage.read(key: 'mnemonic');
  Future<void> clear() async => await secureStorage.deleteAll();

  Future<bool> sendTransaction({
    required String privateKeyHex,
    required String toAddress,
    required double amount,
    required int nonce,
  }) async {
    try {
      final int atomicAmount = (amount * 100000000).toInt();
      final String pin = await _getChainPin();
      if (pin.isEmpty) return false;

      final BytesBuilder builder = BytesBuilder();
      builder.add(HEX.decode(pin));
      builder.add(HEX.decode(toAddress).sublist(0, 20)); 
      final ByteData numbers = ByteData(24);
      numbers.setUint64(0, atomicAmount, Endian.big);
      numbers.setUint64(8, 1000, Endian.big); 
      numbers.setUint64(16, nonce, Endian.big);
      builder.add(numbers.buffer.asUint8List());

      final wallet = bip32.BIP32.fromPrivateKey(Uint8List.fromList(HEX.decode(privateKeyHex)), Uint8List(32));
      final signature = wallet.sign(Uint8List.fromList(sha256.convert(builder.toBytes()).bytes));

      final response = await _multiNodeRequest('/transaction/add', isPost: true, body: {
        "pin": pin, "to": toAddress, "amount": atomicAmount, "fee": 1000,
        "nonce": nonce, "signature": HEX.encode(signature), "pubKey": HEX.encode(wallet.publicKey),
      });
      return jsonDecode(response.body)['success'] == true;
    } catch (e) { return false; }
  }
}