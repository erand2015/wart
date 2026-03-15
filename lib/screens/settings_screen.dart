import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text("Cilësimet", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // INFO KARTA
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.security, color: Colors.orange),
                    title: Text("Siguria", style: TextStyle(color: Colors.white)),
                    subtitle: Text("Portofoli juaj është i mbrojtur me PIN", 
                        style: TextStyle(color: Colors.white54, fontSize: 12)),
                  ),
                  const Divider(color: Colors.white10),
                  ListTile(
                    leading: const Icon(Icons.vibration, color: Colors.orange),
                    title: const Text("Haptic Feedback", style: TextStyle(color: Colors.white)),
                    trailing: Switch(
                      value: true,
                      onChanged: (val) {},
                      activeColor: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),

            // BUTONI LOGOUT (I KUQ)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.1),
                  foregroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: const BorderSide(color: Colors.redAccent, width: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _showLogoutDialog(context),
                icon: const Icon(Icons.logout),
                label: const Text("LOGOUT (FSHI PORTOFOLIN)", 
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            
            const Spacer(),
            const Text("Warthog Pro Wallet v1.0.0", 
                style: TextStyle(color: Colors.white24, fontSize: 12)),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // DIALOGU I KONFIRMIMIT
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("A jeni i sigurt?"),
        content: const Text(
          "Ky veprim do të fshijë portofolin nga ky pajisje. Sigurohuni që keni bërë backup Seed Phrase (12/24 fjalët) para se të vazhdoni!",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("ANULO", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx); // Mbyllet dialogu
              Navigator.pop(context); // Mbyllet Settings
              await context.read<WalletProvider>().logout();
              // MainGate do të detektojë që address == null dhe do të dërgojë te WelcomeScreen
            },
            child: const Text("PO, FSHIJE"),
          ),
        ],
      ),
    );
  }
}