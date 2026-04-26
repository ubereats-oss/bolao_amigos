import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../core/widgets/sobre_dialog.dart';
import '../../data/models/app_user.dart';
import '../../core/routes/app_routes.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  AppUser? _appUser;
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _carregarUsuario();
  }

  Future<void> _carregarUsuario() async {
    final user = _authService.currentUser;
    if (user == null) {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
      return;
    }
    final appUser = await _authService.fetchAppUser(user.uid);
    if (mounted) {
      setState(() {
        _appUser = appUser;
        _loading = false;
      });
    }
  }

  Future<void> _sair() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bolão Entre Amigos'),
        backgroundColor: const Color(0xFF1A6B3C),
        foregroundColor: Colors.white,
        actions: [
          if (_appUser?.isAdmin == true)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              tooltip: 'Admin',
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.adminDashboard),
            ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Sobre',
            onPressed: () async => mostrarSobre(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: _sair,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Olá, ${_appUser?.name ?? 'Jogador'}!',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pontuação total: ${_appUser?.totalPoints ?? 0} pts',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            _MenuItem(
              icon: Icons.sports_soccer,
              label: 'Meus Palpites',
              descricao: 'Coloque seus palpites nos resultados dos jogos',
              onTap: () => Navigator.pushNamed(context, AppRoutes.matches),
            ),
            const SizedBox(height: 12),
            _MenuItem(
              icon: Icons.star_outline,
              label: 'Palpites Extras',
              descricao: 'Campeão, artilheiro e mais',
              onTap: () => Navigator.pushNamed(context, AppRoutes.extras),
            ),
            const SizedBox(height: 12),
            _MenuItem(
              icon: Icons.leaderboard_outlined,
              label: 'Ranking',
              descricao: 'Veja a classificação geral',
              onTap: () => Navigator.pushNamed(context, AppRoutes.ranking),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String descricao;
  final VoidCallback onTap;
  const _MenuItem({
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
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(descricao),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
