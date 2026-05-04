import 'package:flutter/material.dart';
import '../../features/auth/register_screen.dart';
import '../../features/admin/admin_dashboard.dart';
import '../../features/admin/manage_matches_screen.dart';
import '../../features/admin/manage_extra_questions_screen.dart';
import '../../features/admin/manage_players_screen.dart';
import '../../features/groups/groups_screen.dart';
import '../../features/rules/rules_screen.dart';

// Rotas nomeadas — apenas telas sem contexto de grupo.
// matches, extras, ranking e manage_results são abertas via Navigator.push
// a partir de GroupHomeScreen, recebendo groupId como parâmetro.
class AppRoutes {
  static const String register = '/register';
  static const String groups = '/groups';
  static const String adminDashboard = '/admin';
  static const String adminMatches = '/admin/matches';
  static const String adminExtraQuestions = '/admin/extra-questions';
  static const String adminPlayers = '/admin/players';
  static const String matches = '/matches';
  static const String extras = '/extras';
  static const String ranking = '/ranking';
  static const String rules = '/rules';

  static Map<String, WidgetBuilder> get routes => {
        register: (_) => const RegisterScreen(),
        adminDashboard: (_) => const AdminDashboard(),
        adminMatches: (_) => const ManageMatchesScreen(),
        adminExtraQuestions: (_) => const ManageExtraQuestionsScreen(),
        adminPlayers: (_) => const ManagePlayersScreen(),
        groups: (_) => const GroupsScreen(),
        rules: (_) => const RulesScreen(),
      };
}
