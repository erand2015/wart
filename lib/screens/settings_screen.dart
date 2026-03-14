import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showBackupModal(BuildContext context, String mnemonic) {
    final List<String> words = mnemonic.split(' ');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, 
      backgroundColor: const Color(0xFF0D0D0D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        // I japim 85% te lartesise se ekranit qe te kete hapesire
        height: MediaQuery.of(context).size.height * 0.85, 
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            const Icon(Icons.security, color: Colors.orange, size: 50),
            const SizedBox(height: 10),
            const Text("Your Recovery Phrase", 
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            // PJESA QE BEN SCROLL (Fjalet dhe Butoni)
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 2.1,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: words.length,
                        itemBuilder: (context, index) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.black38, 
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("${index + 1}", 
                                  style: TextStyle(color: Colors.orange.withOpacity(0.5), fontSize: 10)),
                                const SizedBox(width: 6),
                                Text(words[index], 
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 25),

                    // BUTONI COPY
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white10,
                        foregroundColor: Colors.orange,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), 
                          side: const BorderSide(color: Colors.orange, width: 0.5)
                        ),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: mnemonic));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Seed phrase u kopjua!"))
                        );
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text("COPY TO CLIPBOARD", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            
            // Butoni MBYLL rri gjithmone ne fund
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("MBYLL", style: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text("Settings"), 
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text("SECURITY", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 15),
          
          ListTile(
            onTap: () async {
              final mnemonic = await context.read<WalletProvider>().getMnemonic();
              if (context.mounted && mnemonic != null) {
                _showBackupModal(context, mnemonic);
              }
            },
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.lock_reset_rounded, color: Colors.orange),
            ),
            title: const Text("Backup Seed Phrase", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: const Text("Rishiko dhe kopjo fjalët e sigurisë", style: TextStyle(color: Colors.grey, fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
            tileColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          
          const SizedBox(height: 30),
          const Text("DANGER ZONE", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 15),
          
          ListTile(
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1A1A1A),
                  title: const Text("Fshi Portofolin?", style: TextStyle(color: Colors.white)),
                  content: const Text("Sigurohuni që keni bërë backup fjalët. Ky veprim nuk mund të kthehet pas.", style: TextStyle(color: Colors.white70)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("ANULO")),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      onPressed: () async {
                        await context.read<WalletProvider>().logout();
                        if (context.mounted) Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                      },
                      child: const Text("FSHI"),
                    ),
                  ],
                ),
              );
            },
            leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
            title: const Text("Delete Wallet", style: TextStyle(color: Colors.redAccent)),
            tileColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ],
      ),
    );
  }
}