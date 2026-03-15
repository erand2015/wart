import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';
import 'settings_screen.dart';
import 'send_screen.dart';
import 'receive_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      context.read<WalletProvider>().lockApp();
    }
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    
    String shortAddress = "Duke u ngarkuar...";
    if (wallet.address != null && wallet.address!.length > 13) {
      shortAddress = "${wallet.address!.substring(0, 8)}...${wallet.address!.substring(wallet.address!.length - 5)}";
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text("Warthog Wallet", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
                // STATUSI I NYJES (PIKA)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: wallet.isNodeOnline ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (wallet.isNodeOnline ? Colors.green : Colors.red).withOpacity(0.4),
                            blurRadius: 4,
                            spreadRadius: 2,
                          )
                        ]
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      wallet.isNodeOnline ? "NODE ONLINE" : "NODE OFFLINE",
                      style: TextStyle(
                        color: wallet.isNodeOnline ? Colors.green : Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

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
                      const Text("BALANCE", style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.5)),
                      const SizedBox(height: 5),
                      Text(
                        "${wallet.balance.toStringAsFixed(4)} WART", 
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 15),
                      GestureDetector(
                        onTap: () {
                          if (wallet.address != null) {
                            Clipboard.setData(ClipboardData(text: wallet.address!));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Adresa u kopjua!"), duration: Duration(seconds: 1)),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(shortAddress, style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace')),
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
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("TRANSAKSIONET E FUNDIT", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(height: 15),
                wallet.transactions.isEmpty 
                ? const Center(child: Text("\nNuk ka transaksione", style: TextStyle(color: Colors.white24)))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: wallet.transactions.length,
                    itemBuilder: (context, index) {
                      final tx = wallet.transactions[index];
                      bool isOutgoing = tx['from'] == wallet.address;
                      return ListTile(
                        leading: Icon(isOutgoing ? Icons.call_made : Icons.call_received, color: isOutgoing ? Colors.red : Colors.green),
                        title: Text("${(tx['amount'] / 100000000.0).toStringAsFixed(2)} WART"),
                        subtitle: Text(tx['hash'] != null ? tx['hash'].substring(0, 10) : "Në proces..."),
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