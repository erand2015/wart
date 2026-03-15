import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/wallet_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/backup_screen.dart';
import 'screens/pin_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final walletProvider = WalletProvider();
  await walletProvider.init();

  runApp(
    ChangeNotifierProvider.value(
      value: walletProvider,
      child: const WarthogProApp(),
    ),
  );
}

class WarthogProApp extends StatelessWidget {
  const WarthogProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Warthog Wallet',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.black,
          ),
        ),
      ),
      home: const MainGate(),
    );
  }
}

class MainGate extends StatelessWidget {
  const MainGate({super.key});

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();

    // 1. Loading State
    if (wallet.isBusy && wallet.address == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    // 2. Setup (Nëse s'ka wallet)
    if (wallet.address == null) {
      return const WelcomeScreen();
    }

    // 3. Security (Kyçja)
    if (wallet.isLocked) {
      return const PinScreen(isSettingPin: false);
    }

    // 4. Dashboard
    return const DashboardScreen();
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_wallet,
                size: 100, color: Colors.orange),
            const SizedBox(height: 20),
            const Text(
              "WARTHOG PRO",
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
            const SizedBox(height: 50),
            SizedBox(
              width: 250,
              height: 60,
              child: ElevatedButton(
                onPressed: () => _showCreateDialog(context),
                child: const Text("KRIJO PORTOFOL",
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: () => _showImportDialog(context),
              child: const Text("Importo me Seed Phrase",
                  style: TextStyle(color: Colors.grey, fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.looks_one, color: Colors.orange),
              title: const Text("12 Fjalë (Standard)"),
              onTap: () async {
                Navigator.pop(ctx);
                await context.read<WalletProvider>().createWallet(12);
                if (context.mounted) {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const BackupScreen()));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.looks_two, color: Colors.orange),
              title: const Text("24 Fjalë (Siguri e lartë)"),
              onTap: () async {
                Navigator.pop(ctx);
                await context.read<WalletProvider>().createWallet(24);
                if (context.mounted) {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const BackupScreen()));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("Importo Portofolin"),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: "Shkruaj fjalët këtu..."),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Anulo")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await context
                    .read<WalletProvider>()
                    .importWallet(controller.text.trim());
                if (context.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text("Importo"),
          )
        ],
      ),
    );
  }
}
