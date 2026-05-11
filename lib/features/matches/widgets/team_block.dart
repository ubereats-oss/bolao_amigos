import 'package:flutter/material.dart';
import '../../../data/models/team.dart';

class TeamBlock extends StatelessWidget {
  final Team? team;
  final bool alignRight;
  final String? fallbackLabel;
  final String? subtitle;

  const TeamBlock({
    super.key,
    required this.team,
    this.alignRight = false,
    this.fallbackLabel,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: (team?.flagAsset.isNotEmpty ?? false)
              ? Image.asset(
                  team!.flagAsset,
                  width: 48,
                  height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.flag_outlined, size: 32),
                )
              : const Icon(Icons.flag_outlined, size: 32),
        ),
        const SizedBox(height: 4),
        Text(
          team?.name ?? fallbackLabel ?? '?',
          textAlign: alignRight ? TextAlign.right : TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
