import 'package:flutter/material.dart';
import '../../../data/models/team.dart';
import '../../../data/models/player.dart';

class PlayerSelectionSheet extends StatefulWidget {
  final String title;
  final List<Team> teams;
  final List<Player> players;
  final String? selectedPlayerId;
  final String? lockedTeamId;

  const PlayerSelectionSheet({
    super.key,
    required this.title,
    required this.teams,
    required this.players,
    required this.selectedPlayerId,
    this.lockedTeamId,
  });

  @override
  State<PlayerSelectionSheet> createState() => _PlayerSelectionSheetState();
}

class _PlayerSelectionSheetState extends State<PlayerSelectionSheet> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  String? _teamFiltro;
  String _busca = '';

  static const double _itemHeight = 56.0;

  @override
  void initState() {
    super.initState();
    if (widget.lockedTeamId != null) {
      _teamFiltro = widget.lockedTeamId;
    } else if (widget.selectedPlayerId != null) {
      final player = widget.players.firstWhere(
        (p) => p.id == widget.selectedPlayerId,
        orElse: () => const Player(id: '', name: '', teamId: '', position: ''),
      );
      if (player.teamId.isNotEmpty) _teamFiltro = player.teamId;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<Team> get _teamsOrdenados {
    final lista = List<Team>.from(widget.teams);
    lista.sort((a, b) => a.name.compareTo(b.name));
    return lista;
  }

  List<String> get _letras {
    final set = <String>{};
    for (final t in _teamsOrdenados) {
      if (t.name.isNotEmpty) set.add(t.name[0].toUpperCase());
    }
    return set.toList()..sort();
  }

  void _pularParaLetra(String letra) {
    final teams = _teamsOrdenados;
    final index = teams.indexWhere(
      (t) => t.name.toUpperCase().startsWith(letra),
    );
    if (index == -1) return;
    final offset = index * _itemHeight;
    _scrollController.animateTo(
      offset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  List<Player> get _filtrados => widget.players.where((p) {
        final matchTeam = _teamFiltro == null || p.teamId == _teamFiltro;
        final matchBusca = p.name.toLowerCase().contains(_busca.toLowerCase());
        return matchTeam && matchBusca && !p.reserva;
      }).toList();

  @override
  Widget build(BuildContext context) {
    final altura = MediaQuery.of(context).size.height * 0.85;
    final teamSelecionado = _teamFiltro == null
        ? null
        : widget.teams.firstWhere(
            (t) => t.id == _teamFiltro,
            orElse: () => const Team(id: '', name: '', flagAsset: ''),
          );

    return SizedBox(
      height: altura,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(widget.title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
          ),
          const SizedBox(height: 12),
          if (widget.lockedTeamId != null && teamSelecionado != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (teamSelecionado.flagAsset.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.asset(teamSelecionado.flagAsset,
                            width: 36,
                            height: 24,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox()),
                      ),
                    ),
                  Text(
                    teamSelecionado.name,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (teamSelecionado != null &&
                      teamSelecionado.flagAsset.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.asset(teamSelecionado.flagAsset,
                            width: 36,
                            height: 24,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox()),
                      ),
                    ),
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      initialValue: _teamFiltro,
                      decoration: const InputDecoration(
                        labelText: 'Selecione a seleção',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('Todas as seleções')),
                        ..._teamsOrdenados.map((t) => DropdownMenuItem(
                              value: t.id,
                              child: Text(t.name),
                            )),
                      ],
                      onChanged: (v) => setState(() {
                        _teamFiltro = v;
                        _busca = '';
                        _searchController.clear();
                      }),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar jogador...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              ),
              onChanged: (v) => setState(() => _busca = v),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _teamFiltro != null
                ? _filtrados.isEmpty
                    ? const Center(child: Text('Nenhum jogador encontrado.'))
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: _filtrados.length,
                        itemExtent: _itemHeight,
                        itemBuilder: (context, index) {
                          final player = _filtrados[index];
                          final team = widget.teams.firstWhere(
                            (t) => t.id == player.teamId,
                            orElse: () =>
                                const Team(id: '', name: '', flagAsset: ''),
                          );
                          final selected = widget.selectedPlayerId == player.id;
                          return ListTile(
                            leading: team.flagAsset.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.asset(team.flagAsset,
                                        width: 40,
                                        height: 27,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.person_outline)),
                                  )
                                : const Icon(Icons.person_outline),
                            title: Text(player.name),
                            subtitle: Text(
                                '${team.name} · ${player.position} · Nº ${player.number}'),
                            trailing: selected
                                ? const Icon(Icons.check_circle,
                                    color: Color(0xFF1A6B3C))
                                : null,
                            onTap: () => Navigator.pop(context, player.id),
                          );
                        },
                      )
                : Row(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: _teamsOrdenados.length,
                          itemExtent: _itemHeight,
                          itemBuilder: (context, index) {
                            final team = _teamsOrdenados[index];
                            final selected = team.id == _teamFiltro;
                            return ListTile(
                              leading: team.flagAsset.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.asset(team.flagAsset,
                                          width: 40,
                                          height: 27,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(Icons.flag_outlined)),
                                    )
                                  : const Icon(Icons.flag_outlined),
                              title: Text(team.name),
                              trailing: selected
                                  ? const Icon(Icons.check_circle,
                                      color: Color(0xFF1A6B3C))
                                  : null,
                              onTap: () => setState(() {
                                _teamFiltro = team.id;
                                _busca = '';
                                _searchController.clear();
                              }),
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        width: 24,
                        child: ListView(
                          children: _letras
                              .map((letra) => GestureDetector(
                                    onTap: () => _pularParaLetra(letra),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 2),
                                      child: Text(
                                        letra,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1A6B3C),
                                        ),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
