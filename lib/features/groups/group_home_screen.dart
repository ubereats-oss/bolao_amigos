import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/widgets/sobre_dialog.dart';
import '../../data/models/bolao_group.dart';
import '../../data/models/app_user.dart';
import '../../data/repositories/group_repository.dart';
import '../../services/auth_service.dart';
import '../matches/matches_screen.dart';
import '../extras/extra_predictions_screen.dart';
import '../ranking/ranking_screen.dart';
import '../rules/rules_screen.dart';
import '../admin/manage_results_screen.dart';

class GroupHomeScreen extends StatefulWidget {
  final BolaoGroup group;

  const GroupHomeScreen({super.key, required this.group});

  @override
  State<GroupHomeScreen> createState() => _GroupHomeScreenState();
}

class _GroupHomeScreenState extends State<GroupHomeScreen> {
  final _authService = AuthService();
  final _groupRepo = GroupRepository();

  AppUser? _appUser;
  BolaoMember? _member;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final user = _authService.currentUser;
    if (user == null) return;

    final results = await Future.wait([
      _authService.fetchAppUser(user.uid),
      _groupRepo.fetchMember(widget.group.id, user.uid),
    ]);

    if (mounted) {
      setState(() {
        _appUser = results[0] as AppUser?;
        _member = results[1] as BolaoMember?;
        _loading = false;
      });
    }
  }

  void _copiarCodigo() {
    Clipboard.setData(ClipboardData(text: widget.group.inviteCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código copiado!'),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF1A6B3C),
      ),
    );
  }

  void _abrirMatches() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MatchesScreen(groupId: widget.group.id),
      ),
    );
  }

  void _abrirExtras() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExtraPredictionsScreen(groupId: widget.group.id),
      ),
    );
  }

  void _abrirRanking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RankingScreen(groupId: widget.group.id),
      ),
    );
  }

  void _abrirRegras() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RulesScreen()),
    );
  }

  void _abrirResultados() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManageResultsScreen(groupId: widget.group.id),
      ),
    );
  }

  void _abrirAdmin() {
    Navigator.pushNamed(context, '/admin');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isAdmin = _member?.isAdmin ?? false;
    final pts = _member?.points ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        backgroundColor: const Color(0xFF1A6B3C),
        foregroundColor: Colors.white,
        actions: [
          if (_appUser?.isAdmin == true)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              tooltip: 'Admin',
              onPressed: _abrirAdmin,
            ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Sobre',
            onPressed: () => mostrarSobre(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Olá, ${_appUser?.name ?? 'Jogador'}!',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Pontuação no bolão: $pts pts',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          InkWell(
            onTap: _copiarCodigo,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A6B3C).withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF1A6B3C).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tag, color: Color(0xFF1A6B3C), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Código de convite',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          widget.group.inviteCode,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            color: Color(0xFF1A6B3C),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.copy_outlined,
                      color: Color(0xFF1A6B3C), size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          _MenuItem(
            icon: Icons.sports_soccer,
            label: 'Meus Palpites',
            descricao: 'Coloque seus palpites nos resultados dos jogos',
            onTap: _abrirMatches,
          ),
          const SizedBox(height: 12),
          _MenuItem(
            icon: Icons.star_outline,
            label: 'Palpites Extras',
            descricao: 'Campeão, artilheiro e mais',
            onTap: _abrirExtras,
          ),
          const SizedBox(height: 12),
          _MenuItem(
            icon: Icons.leaderboard_outlined,
            label: 'Ranking do Bolão',
            descricao: 'Classificação dos participantes',
            onTap: _abrirRanking,
          ),
          const SizedBox(height: 12),
          _MenuItem(
            icon: Icons.menu_book_outlined,
            label: 'Regras do Bolão',
            descricao: 'Pontuação, critérios e desempates',
            onTap: _abrirRegras,
          ),
          if (isAdmin) ...[
            const SizedBox(height: 12),
            _MenuItem(
              icon: Icons.scoreboard_outlined,
              label: 'Inserir Resultados',
              descricao: 'Registre o placar oficial dos jogos',
              onTap: _abrirResultados,
            ),
          ],
        ],
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
