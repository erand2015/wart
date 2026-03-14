import 'package:flutter/material.dart';
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
  
  // Fee fiks për Warthog (ose mund ta marrësh nga noda nëse dëshiron)
  final double _transactionFee = 0.01; 

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    double amount = double.tryParse(_amountController.text) ?? 0.0;
    double total = amount > 0 ? amount + _transactionFee : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text("Dërgo WART"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Adresa e marrësit", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            TextField(
              controller: _addressController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "wart1...",
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Shuma", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 10),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              onChanged: (val) => setState(() {}), // Përditëson fee-në live
              decoration: InputDecoration(
                suffixText: "WART",
                suffixStyle: const TextStyle(color: Colors.orange),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 30),
            
            // BOX I FEE-SË DHE TOTALIT
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Network Fee:", style: TextStyle(color: Colors.grey)),
                      Text("$_transactionFee WART", style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total (me Fee):", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                      Text("${total.toStringAsFixed(4)} WART", 
                        style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                ],
              ),
            ),
            
            const Spacer(),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  disabledBackgroundColor: Colors.grey.withOpacity(0.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                // Butoni çaktivizohet nëse balanca nuk mjafton
                onPressed: (wallet.balance < total || amount <= 0 || wallet.isBusy) 
                  ? null 
                  : () async {
                      bool ok = await wallet.sendRealMoney(_addressController.text, amount);
                      if (ok) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Transaksioni u dërgua me sukses!")));
                          Navigator.pop(context);
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Gabim gjatë dërgimit!")));
                        }
                      }
                    },
                child: wallet.isBusy 
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text("KONFIRMO DËRGIMIN", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}