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
  bool _isNodeOnline = false; // Ky tregon statusin e nyjes

  String? get address => _address;
  double get balance => _balance;
  List<dynamic> get transactions => _transactions;
  bool get isBusy => _isLoading;
  String? get tempMnemonic => _tempMnemonic;
  bool get isLocked => _isLocked;
  bool get isNodeOnline => _isNodeOnline;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    _address = await _walletService.getAddress();
    String? savedPin = await _walletService.secureStorage.read(key: 'user_pin');
    
    if (_address != null && savedPin != null && savedPin.isNotEmpty) {
      _isLocked = true;
      refresh(); 
    } else {
      _isLocked = false;
    }
    _isLoading = false;
    notifyListeners();
  }

  // --- REFRESH I PËRDITËSUAR ---
  Future<void> refresh() async {
    if (_address == null) return;
    
    // Resetojmë statusin: e bëjmë offline sa fillon kontrolli
    _isNodeOnline = false;
    notifyListeners(); 
    
    try {
      // Nëse kjo vijë dështon, hidhemi direkt te 'catch'
      final data = await _walletService.getLiveState(_address!);
      
      _balance = (data['balance'] ?? 0.0).toDouble();
      _transactions = data['transactions'] ?? [];
      
      // Nëse arritëm këtu, nyja është OK
      _isNodeOnline = true; 
    } catch (e) {
      debugPrint("Nyja dështoi: $e");
      _isNodeOnline = false; // Konfirmojmë dritën e kuqe
    }
    notifyListeners();
  }

  Future<void> lockApp() { _isLocked = true; notifyListeners(); return Future.value(); }
  Future<void> setPin(String pin) async {
    await _walletService.secureStorage.write(key: 'user_pin', value: pin);
    _isLocked = false; notifyListeners();
  }
  Future<bool> verifyPin(String inputPin) async {
    String? savedPin = await _walletService.secureStorage.read(key: 'user_pin');
    if (savedPin == inputPin) { _isLocked = false; notifyListeners(); return true; }
    return false;
  }
  Future<void> createWallet(int words) async {
    _isLoading = true; notifyListeners();
    _tempMnemonic = _walletService.generateNewMnemonic(strength: words == 12 ? 128 : 256);
    _isLoading = false; notifyListeners();
  }
  Future<void> confirmWallet() async {
    if (_tempMnemonic != null) {
      _isLoading = true; notifyListeners();
      await importWallet(_tempMnemonic!);
      _tempMnemonic = null;
      _isLoading = false; notifyListeners();
    }
  }
  Future<void> importWallet(String mnemonic) async {
    try {
      final walletData = await _walletService.deriveWallet(mnemonic.trim());
      _address = walletData['address'];
      await _walletService.saveWallet(mnemonic.trim(), _address!);
      refresh();
    } catch (e) { debugPrint("Import Error: $e"); }
    notifyListeners();
  }
  Future<bool> sendRealMoney(String toAddress, double amount) async {
    _isLoading = true; notifyListeners();
    try {
      final mnemonic = await _walletService.getMnemonic();
      if (mnemonic == null) return false;
      final walletData = await _walletService.deriveWallet(mnemonic);
      final state = await _walletService.getLiveState(_address!);
      bool success = await _walletService.sendTransaction(
        privateKeyHex: walletData['privateKey']!,
        toAddress: toAddress,
        amount: amount,
        nonce: state['nonce'] ?? 0,
      );
      if (success) { await Future.delayed(const Duration(seconds: 2)); refresh(); }
      _isLoading = false; notifyListeners(); return success;
    } catch (e) { _isLoading = false; _isNodeOnline = false; notifyListeners(); return false; }
  }
  Future<void> logout() async {
    await _walletService.clear();
    _address = null; _balance = 0.0; _transactions = []; _isLocked = false; _isNodeOnline = false;
    notifyListeners();
  }
  Future<String?> getMnemonic() async => await _walletService.getMnemonic();
}