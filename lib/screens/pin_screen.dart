import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wallet_provider.dart';

class PinScreen extends StatefulWidget {
  final bool isSettingPin; // true nese po e krijon, false nese po e hap app-in
  const PinScreen({super.key, this.isSettingPin = false});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _input = "";

  void _onNumberPress(String num) {
    if (_input.length < 6) {
      setState(() => _input += num);
    }
    if (_input.length == 6) {
      _processPin();
    }
  }

  void _processPin() async {
    final wallet = context.read<WalletProvider>();
    if (widget.isSettingPin) {
      await wallet.setPin(_input);
      if (mounted) Navigator.pop(context);
    } else {
      bool success = await wallet.verifyPin(_input);
      if (success) {
        if (mounted) Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        setState(() => _input = "");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("PIN i gabuar!"), backgroundColor: Colors.redAccent)
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, color: Colors.orange, size: 50),
          const SizedBox(height: 20),
          Text(
            widget.isSettingPin ? "Krijo PIN-in (6 shifra)" : "Shkruaj PIN-in",
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 30),
          // Treguesit e shifrave (rrathet)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (index) => Container(
              margin: const EdgeInsets.all(8),
              width: 15, height: 15,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index < _input.length ? Colors.orange : Colors.white10,
              ),
            )),
          ),
          const SizedBox(height: 50),
          // Tastiera numerike
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, childAspectRatio: 1.2),
              itemCount: 12,
              itemBuilder: (context, index) {
                if (index == 9) return const SizedBox();
                if (index == 10) return _buildNumButton("0");
                if (index == 11) return IconButton(
                  icon: const Icon(Icons.backspace, color: Colors.grey),
                  onPressed: () => setState(() { if(_input.isNotEmpty) _input = _input.substring(0, _input.length-1); }),
                );
                return _buildNumButton("${index + 1}");
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumButton(String text) {
    return TextButton(
      onPressed: () => _onNumberPress(text),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
    );
  }
}