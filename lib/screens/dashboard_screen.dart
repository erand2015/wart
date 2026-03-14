import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import 'settings_screen.dart';
import 'send_screen.dart';
import 'receive_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    
    // RREGULLIMI I ADRESËS: Kontrollojmë gjatësinë që të mos bëjë crash
    String shortAddress = "Duke u ngarkuar...";
    if (wallet.address != null && wallet.address!.length > 13) {
      shortAddress = "${wallet.address!.substring(0, 8)}...${wallet.address!.substring(wallet.address!.length - 5)}";
    } else if (wallet.address != null) {
      shortAddress = wallet.address!;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text("Warthog Wallet", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.orange),
            onPressed: () => wallet.refresh(),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.grey),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: Colors.orange,
        onRefresh: () => wallet.refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // CARD BALANCE
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFF9500), Color(0xFFE65100)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text("REAL BALANCE", style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.5)),
                      const SizedBox(height: 5),
                      Text(
                        "${wallet.balance.toStringAsFixed(4)} WART", 
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 15),
                      
                      // SHFAQJA E ADRESËS DHE COPY
                      GestureDetector(
                        onTap: () {
                          if (wallet.address != null) {
                            Clipboard.setData(ClipboardData(text: wallet.address!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Adresa u kopjua në clipboard!"),
                                backgroundColor: Colors.orange,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                shortAddress,
                                style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace'),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.copy, size: 14, color: Colors.white70),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                
                // BUTTONS SEND & RECEIVE
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SendScreen())),
                        icon: const Icon(Icons.arrow_upward, size: 18),
                        label: const Text("SEND", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: Colors.white10,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          if (wallet.address != null) {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => ReceiveScreen(address: wallet.address!)));
                          }
                        },
                        icon: const Icon(Icons.arrow_downward, size: 18),
                        label: const Text("RECEIVE", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 35),
                
                // TRANSACTION LIST HEADER
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "TRANSAKSIONET E FUNDIT",
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
                  ),
                ),
                const SizedBox(height: 15),
                
                // TRANSACTION LIST LOGIC
                wallet.transactions.isEmpty 
                ? const Padding(
                    padding: EdgeInsets.only(top: 50),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.history, color: Colors.white10, size: 50),
                          SizedBox(height: 10),
                          Text("Nuk ka transaksione akoma", style: TextStyle(color: Colors.white24)),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: wallet.transactions.length,
                    itemBuilder: (context, index) {
                      final tx = wallet.transactions[index];
                      bool isOutgoing = tx['sender'] == wallet.address;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isOutgoing ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                            child: Icon(
                              isOutgoing ? Icons.call_made : Icons.call_received,
                              color: isOutgoing ? Colors.redAccent : Colors.greenAccent,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            "${isOutgoing ? '-' : '+'}${(tx['amount'] / 100000000.0).toStringAsFixed(2)} WART",
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            tx['hash'].toString().length > 15 
                                ? "${tx['hash'].toString().substring(0, 15)}..."
                                : tx['hash'].toString(),
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.white10),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}