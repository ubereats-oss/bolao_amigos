import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

const _email = 'sallesconsultant@gmail.com';
const _linkedin = 'https://www.linkedin.com/in/salles-apps/';

Future<void> mostrarSobre(BuildContext context) async {
  final info = await PackageInfo.fromPlatform();
  final versao = info.version;

  if (!context.mounted) return;

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Sobre o app'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Icon(Icons.emoji_events, size: 48, color: Color(0xFF1A6B3C)),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Bolão Entre Amigos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          Center(
            child: Text(
              'Versão $versao',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Desenvolvido por',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const Text('Salles Apps',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              Clipboard.setData(const ClipboardData(text: _email));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('E-mail copiado!')),
              );
            },
            child: const Text(
              _email,
              style: TextStyle(
                color: Color(0xFF1A6B3C),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {
              Clipboard.setData(const ClipboardData(text: _linkedin));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Link copiado!')),
              );
            },
            child: const Text(
              _linkedin,
              style: TextStyle(
                color: Color(0xFF1A6B3C),
                decoration: TextDecoration.underline,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          style:
              FilledButton.styleFrom(backgroundColor: const Color(0xFF1A6B3C)),
          onPressed: () => Navigator.pop(context),
          child: const Text('Fechar'),
        ),
      ],
    ),
  );
}
