import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/bolao_group.dart';
import '../../data/repositories/group_repository.dart';
import '../../services/auth_service.dart';
//import '../../core/routes/app_routes.dart';
import '../../core/widgets/sobre_dialog.dart';
import '../auth/login_screen.dart';
import 'widgets/group_card_bolao.dart';
import 'create_group_screen.dart';
import 'join_group_sheet.dart';
import 'group_home_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final _repo = GroupRepository();
  final _authService = AuthService();

  List<BolaoGroup> _groups = [];
  bool _loading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final groups = await _repo.fetchUserGroups(uid);
      if (mounted) setState(() => _groups = groups);
    } catch (_) {
      if (mounted) setState(() => _erro = 'Erro ao carregar grupos.');
    } finally {
      if (mounted) setState(() => _loading = false);
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

  Future<void> _abrirConfigConta() async {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? user?.email ?? 'Usuário';
    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(displayName),
              subtitle: user?.email != null && user!.email != displayName
                  ? Text(user.email!)
                  : null,
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Excluir conta',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(ctx);
                _confirmarExcluirConta();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarExcluirConta() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir conta?'),
        content: const Text(
          'Todos os seus dados serão removidos permanentemente. Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await _authService.deleteAccount();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        final msg = e.toString().contains('requires-recent-login')
            ? 'Por segurança, saia e entre novamente antes de excluir a conta.'
            : 'Erro ao excluir conta. Tente novamente.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _abrirCriarGrupo() async {
    final criado = await Navigator.push<BolaoGroup>(
      context,
      MaterialPageRoute(builder: (_) => const CreateGroupScreen()),
    );
    if (criado != null) {
      setState(() => _groups.insert(0, criado));
    }
  }

  void _abrirEntrarGrupo() async {
    final entrou = await showModalBottomSheet<BolaoGroup>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const JoinGroupSheet(),
    );
    if (entrou != null) {
      setState(() => _groups.add(entrou));
    }
  }

  void _abrirGrupo(BolaoGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupHomeScreen(group: group),
      ),
    );
  }

  Future<void> _confirmarSair(BolaoGroup group) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isAdmin = group.adminUid == uid;
    final msg = isAdmin
        ? 'Você é o admin. Ao sair, o grupo será apagado permanentemente.'
        : 'Deseja sair do grupo "${group.name}"?';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isAdmin ? 'Apagar grupo?' : 'Sair do grupo?'),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(isAdmin ? 'Apagar' : 'Sair'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      if (isAdmin) {
        await _repo.deleteGroup(group.id);
      } else {
        await _repo.leaveGroup(group.id, uid);
      }
      setState(() => _groups.removeWhere((g) => g.id == group.id));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao sair do grupo.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bolão Entre Amigos'),
        backgroundColor: const Color(0xFF1A6B3C),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: 'Minha conta',
            onPressed: _abrirConfigConta,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Sobre',
            onPressed: () => mostrarSobre(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: _sair,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_erro!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _carregar,
                        child: const Text('Tentar novamente'),
                      ),
                    ],
                  ),
                )
              : _groups.isEmpty
                  ? _EmptyState(
                      onCriar: _abrirCriarGrupo,
                      onEntrar: _abrirEntrarGrupo,
                    )
                  : RefreshIndicator(
                      onRefresh: _carregar,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        children: [
                          const Text(
                            'SEUS BOLÕES',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._groups.map(
                            (g) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GroupCardBolao(
                                group: g,
                                onTap: () => _abrirGrupo(g),
                                onLongPress: () => _confirmarSair(g),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
      floatingActionButton: _groups.isEmpty
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'entrar',
                  backgroundColor: Colors.grey.shade200,
                  foregroundColor: Colors.black87,
                  tooltip: 'Entrar com código',
                  onPressed: _abrirEntrarGrupo,
                  child: const Icon(Icons.group_add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton(
                  heroTag: 'criar',
                  backgroundColor: const Color(0xFF1A6B3C),
                  foregroundColor: Colors.white,
                  tooltip: 'Criar bolão',
                  onPressed: _abrirCriarGrupo,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onCriar;
  final VoidCallback onEntrar;

  const _EmptyState({required this.onCriar, required this.onEntrar});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_outlined,
                size: 72, color: Color(0xFF1A6B3C)),
            const SizedBox(height: 16),
            const Text(
              'Nenhum bolão ainda',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Crie seu bolão ou entre com um código de convite.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1A6B3C)),
              onPressed: onCriar,
              icon: const Icon(Icons.add),
              label: const Text('Criar bolão'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onEntrar,
              icon: const Icon(Icons.group_add),
              label: const Text('Entrar com código'),
            ),
          ],
        ),
      ),
    );
  }
}
