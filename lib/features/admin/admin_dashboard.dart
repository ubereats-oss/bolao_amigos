import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Admin'),
        backgroundColor: const Color(0xFF1A6B3C),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AdminMenuItem(
            icon: Icons.sports_soccer,
            label: 'Gerenciar Jogos',
            descricao: 'Visualize os jogos cadastrados',
            onTap: () => Navigator.pushNamed(context, AppRoutes.adminMatches),
          ),
          const SizedBox(height: 12),
          _AdminMenuItem(
            icon: Icons.quiz_outlined,
            label: 'Perguntas Extras',
            descricao: 'Gerencie as perguntas do bolão',
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.adminExtraQuestions),
          ),
          const SizedBox(height: 12),
          _AdminMenuItem(
            icon: Icons.people_outline,
            label: 'Jogadores',
            descricao: 'Cadastre os jogadores de cada seleção',
            onTap: () => Navigator.pushNamed(context, AppRoutes.adminPlayers),
          ),
        ],
      ),
    );
  }
}

class _AdminMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String descricao;
  final VoidCallback onTap;

  const _AdminMenuItem({
    required this.icon,
    required this.label,
    required this.descricao,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF1A6B3C), size: 32),
        title:
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(descricao),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
