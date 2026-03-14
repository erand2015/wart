import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Importi i duhur
import 'package:flutter/services.dart';

class ReceiveScreen extends StatelessWidget {
  final String address;
  const ReceiveScreen({super.key, required this.address});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        title: const Text("Prano WART"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: QrImageView(  // Sigurohu që emri është i saktë
                data: address,
                version: QrVersions.auto,
                size: 200.0,
                gapless: false,
              ),
            ),
            const SizedBox(height: 30),
            const Text("Adresa Jote:", style: TextStyle(color: Colors.grey)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 20),
              child: Text(
                address,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.orange,
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.copy),
              label: const Text("Kopjo Adresën"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.black,
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: address));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("U kopjua!")),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}