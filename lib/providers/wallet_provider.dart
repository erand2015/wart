import 'package:flutter/material.dart';
import '../services/wallet_service.dart';

class WalletProvider with ChangeNotifier {
  final WalletService _walletService = WalletService();
  String? _address;
  String? _tempMnemonic;
  double _balance = 0.0;
  List<dynamic> _transactions = [];
  bool _isLoading = false;
  
  // PIN LOGIC - E nisim si TRUE që të bëhet kontrolli në MainGate
  bool _isLocked = true; 

  String? get address => _address;
  double get balance => _balance;
  List<dynamic> get transactions => _transactions;
  bool get isBusy => _isLoading;
  String? get tempMnemonic => _tempMnemonic;
  bool get isLocked => _isLocked;

  // 1. Inicializimi i detyruar
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    
    _address = await _walletService.getAddress();
    
    // Kontrollojmë memorien e sigurt për PIN
    String? savedPin = await _walletService.secureStorage.read(key: 'user_pin');
    
    if (savedPin != null && savedPin.isNotEmpty) {
      _isLocked = true; // Ka PIN, app qëndron i mbyllur
    } else {
      _isLocked = false; // S'ka PIN, app hapet (për setup-in e parë)
    }

    if (_address != null) {
      await refresh();
    }
    
    _isLoading = false;
    notifyListeners();
  }

  // 2. Menaxhimi i PIN
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

  Future<String?> getSavedPin() async {
    return await _walletService.secureStorage.read(key: 'user_pin');
  }

  Future<void> removePin() async {
    await _walletService.secureStorage.delete(key: 'user_pin');
    _isLocked = false;
    notifyListeners();
  }

  void lockApp() {
    _isLocked = true;
    notifyListeners();
  }

  // 3. Funksionet e Wallet
  Future<void> createWallet(int words) async {
    _isLoading = true;
    notifyListeners();
    int strength = (words == 12) ? 128 : 256;
    _tempMnemonic = _walletService.generateNewMnemonic(strength: strength);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> confirmWallet() async {
    if (_tempMnemonic != null) {
      _isLoading = true;
      notifyListeners();
      await importWallet(_tempMnemonic!);
      _tempMnemonic = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> importWallet(String mnemonic) async {
    try {
      final walletData = await _walletService.deriveWallet(mnemonic.trim());
      _address = walletData['address'];
      await _walletService.saveWallet(mnemonic.trim(), _address!);
      await refresh();
    } catch (e) {
      debugPrint("Import Error: $e");
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_address == null) return;
    try {
      final data = await _walletService.getLiveState(_address!);
      _balance = (data['balance'] ?? 0.0).toDouble();
      _transactions = data['transactions'] ?? [];
    } catch (e) {
      debugPrint("Refresh Error: $e");
    }
    notifyListeners();
  }

  Future<bool> sendRealMoney(String toAddress, double amount) async {
    _isLoading = true;
    notifyListeners();
    try {
      final mnemonic = await _walletService.getMnemonic();
      if (mnemonic == null) return false;
      final walletData = await _walletService.deriveWallet(mnemonic);
      final state = await _walletService.getLiveState(_address!);
      
      bool success = await _walletService.sendTransaction(
        privateKeyHex: walletData['privateKey']!,
        toAddress: toAddress,
        amount: amount,
        nonce: state['nonce'],
      );

      if (success) {
        await Future.delayed(const Duration(seconds: 2));
        await refresh();
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _walletService.clear();
    _address = null;
    _balance = 0.0;
    _transactions = [];
    _isLocked = false;
    notifyListeners();
  }

  Future<String?> getMnemonic() async => await _walletService.getMnemonic();
}