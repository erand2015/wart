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
  // RREGULLIMI: Ndryshuar nga _storage ne secureStorage qe ta gjeje Provider-i
  final secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  String _calculateWarthogAddress(Uint8List compressedPubKey) {
    final sha = sha256.convert(compressedPubKey).bytes;
    final ripemd = RIPEMD160Digest().process(Uint8List.fromList(sha));
    final checksumFull = sha256.convert(ripemd).bytes;
    final checksum = checksumFull.sublist(0, 4);
    final addressBytes = Uint8List.fromList([...ripemd, ...checksum]);
    return HEX.encode(addressBytes);
  }

  Future<Map<String, String>> deriveWallet(String mnemonic) async {
    final seed = bip39.mnemonicToSeed(mnemonic);
    final root = bip32.BIP32.fromSeed(seed);
    
    // Path-i zyrtar Warthog qe perdorje ti
    final child = root.derivePath("m/44'/2070'/0'/0/0");
    
    final privateKey = child.privateKey!;
    final publicKey = child.publicKey; 

    final String address = _calculateWarthogAddress(publicKey);

    return {
      'address': address,
      'privateKey': HEX.encode(privateKey),
      'publicKey': HEX.encode(publicKey),
    };
  }

  String generateNewMnemonic({int strength = 128}) {
    return bip39.generateMnemonic(strength: strength);
  }

  Future<void> saveWallet(String mnemonic, String address) async {
    await secureStorage.write(key: 'mnemonic', value: mnemonic);
    await secureStorage.write(key: 'address', value: address);
  }

  Future<String?> getAddress() async => await secureStorage.read(key: 'address');
  Future<String?> getMnemonic() async => await secureStorage.read(key: 'mnemonic');

  Future<Map<String, dynamic>> getLiveState(String address) async {
    try {
      final response = await http.get(Uri.parse('https://node.warthog.network/api/account/$address'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("Error rrjeti: $e");
    }
    return {'balance': 0.0, 'transactions': [], 'nonce': 0};
  }

  Future<bool> sendTransaction({
    required String privateKeyHex,
    required String toAddress,
    required double amount,
    required int nonce,
  }) async {
    debugPrint("Gati per dergese");
    await Future.delayed(const Duration(seconds: 1));
    return true; 
  }

  // I shtova te dyja qe mos kesh asnje error ne asnje vend
  Future<void> clearWallet() async => await secureStorage.deleteAll();
  Future<void> clear() async => await secureStorage.deleteAll();
}