import 'package:flutter/material.dart';
import '../services/wallet_service.dart';

class WalletProvider with ChangeNotifier {
  final WalletService _walletService = WalletService();
  String? _address;
  String? _tempMnemonic;
  double _balance = 0.0;
  List<dynamic> _transactions = [];
  bool _isLoading = false;
  bool _isLocked = true;
  bool _isNodeOnline = false;

  // Getters
  String? get address => _address;
  double get balance => _balance;
  List<dynamic> get transactions => _transactions;
  bool get isBusy => _isLoading;
  bool get isLocked => _isLocked;
  bool get isNodeOnline => _isNodeOnline;
  String? get tempMnemonic => _tempMnemonic;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    _address = await _walletService.getAddress();
    String? savedPin = await _walletService.secureStorage.read(key: 'user_pin');

    _isLocked = (_address != null && savedPin != null);
    if (_address != null) await refresh(); // Përdorim await këtu

    _isLoading = false;
    notifyListeners();
  }

  // --- REFRESH I PËRMIRËSUAR (Merr Balancën dhe Historikun) ---
  Future<void> refresh() async {
    if (_address == null) return;
    try {
      final data = await _walletService.getLiveState(_address!);
      _balance = data['balance'];

      // Mbledhja e transaksioneve reale nga blockchain
      _transactions = await _walletService.getTransactionHistory(_address!, 0);

      _isNodeOnline = true;
      print(
          "✅ Refresh u krye. Balanca: $_balance, Transaksione: ${_transactions.length}");
    } catch (e) {
      print("❌ Gabim gjatë refresh: $e");
      _isNodeOnline = false;
    }
    notifyListeners();
  }

  // --- Metodat e PIN-it dhe Sigurisë ---
  Future<void> lockApp() async {
    _isLocked = true;
    notifyListeners();
  }

  Future<void> setPin(String pin) async {
    await _walletService.secureStorage.write(key: 'user_pin', value: pin);
    _isLocked = false;
    notifyListeners();
  }

  Future<bool> verifyPin(String inputPin) async {
    String? savedPin = await _walletService.secureStorage.read(key: 'user_pin');
    if (savedPin == inputPin) {
      _isLocked = false;
      notifyListeners();
      return true;
    }
    return false;
  }

  // --- Metodat e Wallet-it ---
  Future<void> createWallet(int words) async {
    _tempMnemonic =
        _walletService.generateNewMnemonic(strength: words == 12 ? 128 : 256);
    notifyListeners();
  }

  Future<void> confirmWallet() async {
    if (_tempMnemonic != null) {
      await importWallet(_tempMnemonic!);
      _tempMnemonic = null;
    }
  }

  Future<void> importWallet(String mnemonic) async {
    final walletData = await _walletService.deriveWallet(mnemonic.trim());
    _address = walletData['address'];
    await _walletService.saveWallet(mnemonic.trim(), _address!);
    await refresh();
  }

  // --- DËRGIMI REAL (Me rregullimin e Nonce + 1) ---
  Future<bool> sendRealMoney(String toAddress, double amount) async {
    _isLoading = true;
    notifyListeners();
    try {
      final mnemonic = await _walletService.getMnemonic();
      if (mnemonic == null) return false;

      final walletData = await _walletService.deriveWallet(mnemonic);
      final state = await _walletService.getLiveState(_address!);

      // NONCE + 1: Ky është çelësi që transaksioni të pranohet nga rrjeti
      int nextNonce = (state['nonce'] as int) + 1;

      bool success = await _walletService.sendTransaction(
        privateKeyHex: walletData['privateKey']!,
        toAddress: toAddress,
        amount: amount,
        nonce: nextNonce,
      );

      if (success) {
        // Presim pak që blockchain ta regjistrojë përpara se të bëjmë refresh
        await Future.delayed(const Duration(seconds: 3));
        await refresh();
      }
      return success;
    } catch (e) {
      print("❌ Gabim te dërgimi: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _walletService.clear();
    _address = null;
    _balance = 0.0;
    _transactions = [];
    notifyListeners();
  }
}
