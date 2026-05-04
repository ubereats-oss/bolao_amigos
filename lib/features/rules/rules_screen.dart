import 'package:flutter/material.dart';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Regras do Bolão'),
        backgroundColor: const Color(0xFF1A6B3C),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _Secao(titulo: 'Jogos — Fase de Grupos'),
          _LinhaRegra(
            descricao: 'Placar exato (gols do time da casa E visitante corretos)',
            pontos: '13',
          ),
          _LinhaRegra(
            descricao: 'Resultado certo sem placar exato (vencedor ou empate)',
            pontos: '6',
          ),
          _LinhaRegra(
            descricao: 'Gols de apenas UM time corretos *',
            pontos: '2',
          ),
          _Nota(texto: '* Somente se não pontuou pelos critérios anteriores.'),
          SizedBox(height: 8),
          _Secao(titulo: 'Mata-mata'),
          _TextoInfo(
            texto:
                'Os placares do mata-mata não valem pontos — servem apenas para indicar o time classificado.',
          ),
          SizedBox(height: 8),
          _Secao(titulo: 'Palpites Extras'),
          _LinhaRegra(descricao: '1º gol do Brasil – Jogo 1', pontos: '7'),
          _LinhaRegra(descricao: '1º gol do Brasil – Jogo 2', pontos: '7'),
          _LinhaRegra(descricao: '1º gol do Brasil – Jogo 3', pontos: '7'),
          _LinhaRegra(
            descricao: 'Colocação de cada equipe em seu grupo (por time acertado)',
            pontos: '10',
          ),
          _LinhaRegra(
            descricao: 'Equipes classificadas para as Quartas (por time acertado)',
            pontos: '15',
          ),
          _LinhaRegra(
            descricao: 'Equipes classificadas para as Semifinais (por time acertado)',
            pontos: '20',
          ),
          _LinhaRegra(descricao: '4ª colocada', pontos: '20'),
          _LinhaRegra(descricao: '3ª colocada', pontos: '25'),
          _LinhaRegra(descricao: 'Vice-campeã', pontos: '30'),
          _LinhaRegra(descricao: 'Campeã', pontos: '40'),
          _LinhaRegra(descricao: '1º gol da final', pontos: '30'),
          _LinhaRegra(descricao: 'Melhor campanha na fase de grupos', pontos: '20'),
          _LinhaRegra(descricao: 'Pior campanha na fase de grupos', pontos: '20'),
          _LinhaRegra(descricao: 'Melhor ataque na fase de grupos', pontos: '20'),
          _LinhaRegra(descricao: 'Pior ataque na fase de grupos', pontos: '20'),
          _LinhaRegra(descricao: 'Artilheiro da Copa', pontos: '25'),
          SizedBox(height: 8),
          _Secao(titulo: 'Desempates'),
          _TextoInfo(
            texto:
                'Em caso de empate na pontuação, o critério de desempate é a maior pontuação nos palpites extras. Persistindo o empate, a posição no ranking é compartilhada.',
          ),
          SizedBox(height: 8),
          _Secao(titulo: 'Observações importantes'),
          _TextoInfo(
            texto:
                '• Os palpites podem ser feitos e alterados até o início de cada jogo.\n'
                '• Resultados são oficializados pelo administrador do grupo.\n'
                '• A pontuação é atualizada automaticamente após cada resultado.',
          ),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Secao extends StatelessWidget {
  final String titulo;

  const _Secao({required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Text(
        titulo,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A6B3C),
        ),
      ),
    );
  }
}

class _LinhaRegra extends StatelessWidget {
  final String descricao;
  final String pontos;

  const _LinhaRegra({required this.descricao, required this.pontos});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(descricao, style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(width: 8),
          _PontosChip(pontos: pontos),
        ],
      ),
    );
  }
}

class _PontosChip extends StatelessWidget {
  final String pontos;

  const _PontosChip({required this.pontos});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A6B3C).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$pontos pts',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Color(0xFF1A6B3C),
          fontSize: 13,
        ),
      ),
    );
  }
}

class _Nota extends StatelessWidget {
  final String texto;

  const _Nota({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 4, left: 4),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _TextoInfo extends StatelessWidget {
  final String texto;

  const _TextoInfo({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        texto,
        style: const TextStyle(fontSize: 14, height: 1.5),
      ),
    );
  }
}
