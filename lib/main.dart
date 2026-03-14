import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/wallet_provider.dart';
import 'screens/dashboard_screen.dart';
import 'screens/backup_screen.dart';
import 'screens/pin_screen.dart'; // Mos harro kete import

void main() async {
  // Sigurohemi qe Flutter eshte gati para se te nisim Provider-in
  WidgetsFlutterBinding.ensureInitialized();

  final walletProvider = WalletProvider();
  await walletProvider.init(); // Ky inicializon adresen dhe PIN-in

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: walletProvider),
      ],
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      // Perdorim MainGate per te vendosur se ku do shkoje perdoruesi
      home: const MainGate(),
      routes: {
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}

class MainGate extends StatelessWidget {
  const MainGate({super.key});

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();

    // LOGJIKA E NAVIGIMIT (Sipas sigurise):

    // 1. Nese nuk ka portofol te krijuar
    if (wallet.address == null) {
      return const WelcomeScreen();
    }

    // 2. Nese ka portofol por eshte i kycur (Locked) me PIN
    if (wallet.isLocked) {
      return const PinScreen(isSettingPin: false);
    }

    // 3. Nese gjithcka eshte OK dhe e hapur
    return const DashboardScreen();
  }
}

// WelcomeScreen mbetet njesoj sic e ke ti...
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  // ... pjesa tjeter e kodit tend per _showCreateDialog dhe _showImportDialog ...
  // Sigurohu qe t'i mbash ato funksione ketu poshte njesoj sic i ke

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    return Scaffold(
      body: Center(
        child: wallet.isBusy
            ? const CircularProgressIndicator(color: Colors.orange)
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.account_balance_wallet,
                      size: 100, color: Colors.orange),
                  const SizedBox(height: 20),
                  const Text("WARTHOG PRO",
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2)),
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

  // Shto ketu metodat _showCreateDialog dhe _showImportDialog qe kishit me pare
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
            const Text("Krijo Portofol të Ri",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.looks_one, color: Colors.orange),
              title: const Text("12 Fjalë (Standard)"),
              onTap: () async {
                Navigator.pop(ctx);
                await context.read<WalletProvider>().createWallet(12);
                if (context.mounted)
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const BackupScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.looks_two, color: Colors.orange),
              title: const Text("24 Fjalë (Siguri e lartë)"),
              onTap: () async {
                Navigator.pop(ctx);
                await context.read<WalletProvider>().createWallet(24);
                if (context.mounted)
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const BackupScreen()));
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
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Shkruaj fjalët këtu...",
            hintStyle: TextStyle(color: Colors.grey),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.orange)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("Anulo")),
          ElevatedButton(
            onPressed: () async {
              String mnemonic = controller.text.trim();
              if (mnemonic.isNotEmpty) {
                await context.read<WalletProvider>().importWallet(mnemonic);
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
