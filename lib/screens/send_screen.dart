import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Për FilteringTextInputFormatter
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  // Fee fiks për Warthog (E8 format: 0.01 WART)
  final double _transactionFee = 0.01;

  // Për të kontrolluar nëse adresa është e vlefshme (Warthog addresses janë 48 chars hex)
  bool _isValidAddress(String addr) => addr.length == 48;

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    double amount = double.tryParse(_amountController.text) ?? 0.0;
    double total = amount > 0 ? amount + _transactionFee : 0.0;
    bool canSend = _isValidAddress(_addressController.text) &&
        amount > 0 &&
        wallet.balance >= total &&
        !wallet.isBusy;

    return GestureDetector(
      onTap: () =>
          FocusScope.of(context).unfocus(), // Mbyll tastierën kur klikon jashtë
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0D0D),
        appBar: AppBar(
          title: const Text("Dërgo WART",
              style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text("Adresa e marrësit",
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 10),
              TextField(
                controller: _addressController,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: "Adresa Hex (48 karaktere)",
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  prefixIcon: const Icon(Icons.account_balance_wallet,
                      color: Colors.orange, size: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide:
                        const BorderSide(color: Colors.orange, width: 1),
                  ),
                ),
              ),
              const SizedBox(height: 25),
              const Text("Shuma për dërgim",
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 10),
              TextField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(
                      r'^\d+\.?\d{0,8}')), // Vetem numra dhe deri ne 8 decimale
                ],
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold),
                onChanged: (val) => setState(() {}),
                decoration: InputDecoration(
                  suffixText: "WART",
                  suffixStyle: const TextStyle(
                      color: Colors.orange, fontWeight: FontWeight.bold),
                  filled: true,
                  fillColor: const Color(0xFF1A1A1A),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 30),

              // PANEL I PËRMBLEDHJES
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow("Bilanci aktual:",
                        "${wallet.balance.toStringAsFixed(4)} WART"),
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                        "Tarifa e rrjetit:", "$_transactionFee WART"),
                    const Divider(color: Colors.white10, height: 30),
                    _buildSummaryRow(
                        "Gjithsej:", "${total.toStringAsFixed(4)} WART",
                        isTotal: true),
                  ],
                ),
              ),

              const Spacer(),

              // BUTONI KONFIRMO
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.white10,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  onPressed: canSend ? _handleSend : null,
                  child: wallet.isBusy
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                              color: Colors.black, strokeWidth: 2))
                      : const Text("KONFIRMO DËRGIMIN",
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // Helper për rreshtat e përmbledhjes
  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: isTotal ? Colors.white : Colors.grey,
                fontSize: isTotal ? 16 : 14)),
        Text(value,
            style: TextStyle(
                color: isTotal ? Colors.orange : Colors.white,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: isTotal ? 18 : 14)),
      ],
    );
  }

  // Logjika e dërgimit
  void _handleSend() async {
    final wallet = context.read<WalletProvider>();
    bool ok = await wallet.sendRealMoney(
        _addressController.text.trim(), double.parse(_amountController.text));

    if (mounted) {
      if (ok) {
        _showStatusSnack("Transaksioni u dërgua me sukses!", isError: false);
        Navigator.pop(context);
      } else {
        _showStatusSnack("Gabim! Kontrollo rrjetin ose balancën.",
            isError: true);
      }
    }
  }

  void _showStatusSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
