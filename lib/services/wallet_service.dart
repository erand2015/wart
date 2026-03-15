import 'dart:typed_data';
import 'dart:convert';
import 'package:bip39/bip39.dart' as bip39;
import 'package:bip32/bip32.dart' as bip32;
import 'package:crypto/crypto.dart';
import 'package:hex/hex.dart';
import 'package:pointycastle/digests/ripemd160.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class WalletService {

  final List<String> _nodes = [
    "http://217.182.64.43:3001"
  ];

  final secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // -------------------------------
  // Kontrollo nëse node është online
  // -------------------------------
  Future<bool> _isNodeAlive(String node) async {
    try {

      final res = await http
          .get(Uri.parse("$node/chain/head"))
          .timeout(const Duration(seconds: 5));

      return res.statusCode == 200;

    } catch (e) {

      print("Node error: $e");
      return false;

    }
  }

  // -------------------------------
  // Merr balance reale
  // -------------------------------
  Future<Map<String, dynamic>> getLiveState(String address) async {

    for (String node in _nodes) {

      bool alive = await _isNodeAlive(node);

      if (!alive) continue;

      try {

        final response = await http
            .get(Uri.parse("$node/account/$address/balance"))
            .timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {

          final data = jsonDecode(response.body);

          double balance =
              ((data["balance"] ?? 0) as num).toDouble() / 100000000;

          int nonce = data["nonce"] ?? 0;

          return {
            "balance": balance,
            "nonce": nonce
          };
        }

      } catch (e) {

        print("Blockchain error: $e");

      }
    }

    throw Exception("Node nuk po përgjigjet");
  }

  // -------------------------------
  // Merr historikun e transaksioneve
  // -------------------------------
  Future<List<dynamic>> getTransactionHistory(
      String address,
      int beforeIndex) async {

    for (String node in _nodes) {

      try {

        final response = await http
            .get(Uri.parse(
                "$node/account/$address/history/$beforeIndex"))
            .timeout(const Duration(seconds: 8));

        if (response.statusCode == 200) {

          return jsonDecode(response.body);

        }

      } catch (e) {

        print("History error: $e");

      }
    }

    return [];
  }

  // -------------------------------
  // Dërgim transaksioni
  // -------------------------------
  Future<bool> sendTransaction({
    required String privateKeyHex,
    required String toAddress,
    required double amount,
    required int nonce,
  }) async {

    final int atomicAmount = (amount * 100000000).toInt();

    for (String node in _nodes) {

      try {

        final url = Uri.parse("$node/transaction/add");

        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "to": toAddress,
            "amount": atomicAmount,
            "nonce": nonce
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          return true;
        }

      } catch (e) {

        print("Transaction error: $e");

      }
    }

    return false;
  }

  // -------------------------------
  // Gjenero mnemonic
  // -------------------------------
  String generateNewMnemonic({int strength = 128}) {
    return bip39.generateMnemonic(strength: strength);
  }

  // -------------------------------
  // Gjenero adresë Warthog
  // -------------------------------
  String _calculateWarthogAddress(Uint8List compressedPubKey) {

    final sha = sha256.convert(compressedPubKey).bytes;

    final ripemd =
        RIPEMD160Digest().process(Uint8List.fromList(sha));

    final checksum =
        sha256.convert(ripemd).bytes.sublist(0, 4);

    return HEX.encode(
        Uint8List.fromList([...ripemd, ...checksum]));
  }

  // -------------------------------
  // Derivo wallet nga mnemonic
  // -------------------------------
  Future<Map<String, String>> deriveWallet(
      String mnemonic) async {

    final seed = bip39.mnemonicToSeed(mnemonic);

    final root = bip32.BIP32.fromSeed(seed);

    final child = root.derivePath("m/44'/2070'/0'/0/0");

    return {
      "address": _calculateWarthogAddress(child.publicKey),
      "privateKey": HEX.encode(child.privateKey!),
      "publicKey": HEX.encode(child.publicKey),
    };
  }

  // -------------------------------
  // Storage
  // -------------------------------
  Future<void> saveWallet(
      String mnemonic,
      String address) async {

    await secureStorage.write(
        key: "mnemonic", value: mnemonic);

    await secureStorage.write(
        key: "address", value: address);
  }

  Future<String?> getAddress() async {
    return await secureStorage.read(key: "address");
  }

  Future<String?> getMnemonic() async {
    return await secureStorage.read(key: "mnemonic");
  }

  Future<void> clear() async {
    await secureStorage.deleteAll();
  }
}