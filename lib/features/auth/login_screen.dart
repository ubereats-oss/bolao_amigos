import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../services/auth_service.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/sobre_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;
  bool _senhaVisivel = false;
  String? _erro;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginEmail() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      await _authService.signInWithEmail(
        _emailController.text,
        _passwordController.text,
      );
      if (mounted) Navigator.pushReplacementNamed(context, '/groups');
    } on Exception catch (e) {
      setState(() {
        _erro = _traduzirErro(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _loginGoogle() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final result = await _authService.signInWithGoogle();
      if (result != null && mounted) {
        Navigator.pushReplacementNamed(context, '/groups');
      }
    } on Exception catch (e) {
      setState(() {
        _erro = _traduzirErro(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _loginApple() async {
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      await _authService.signInWithApple();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/groups');
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final msg = switch (e.code) {
        AuthorizationErrorCode.failed =>
          'Falha na autenticação com Apple. Verifique as configurações da sua conta.',
        AuthorizationErrorCode.invalidResponse =>
          'Resposta inválida da Apple. Tente novamente.',
        AuthorizationErrorCode.notHandled =>
          'Autenticação Apple não pôde ser concluída. Tente novamente.',
        AuthorizationErrorCode.unknown =>
          'Erro desconhecido na autenticação Apple. Tente novamente.',
        _ => 'Erro ao entrar com Apple: ${e.message}',
      };
      if (mounted) setState(() => _erro = msg);
    } on Exception catch (e) {
      if (mounted) setState(() => _erro = _traduzirErro(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _traduzirErro(String erro) {
    const map = {
      'user-not-found': 'Usuário não encontrado.',
      'wrong-password': 'Senha incorreta.',
      'invalid-email': 'E-mail inválido.',
      'invalid-credential': 'E-mail ou senha incorretos.',
      'too-many-requests': 'Muitas tentativas. Tente mais tarde.',
    };
    for (final entry in map.entries) {
      if (erro.contains(entry.key)) {
        return entry.value;
      }
    }
    return 'Erro ao entrar. Tente novamente.';
  }

  Future<void> _recuperarSenha() async {
    final emailCtrl = TextEditingController(text: _emailController.text.trim());
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recuperar senha'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Informe seu e-mail para receber o link de redefinição.'),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-mail',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final email = emailCtrl.text.trim();
              if (email.isEmpty) return;
              try {
                await _authService.sendPasswordReset(email);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('E-mail de recuperação enviado!'),
                      backgroundColor: Color(0xFF1A6B3C),
                    ),
                  );
                }
              } on Exception {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Não foi possível enviar o e-mail. Verifique o endereço.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    emailCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.emoji_events,
                          size: 80, color: Color(0xFF1A6B3C)),
                      const SizedBox(height: 16),
                      const Text(
                        'Bolão Entre Amigos',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 40),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Informe o e-mail' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_senhaVisivel,
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _senhaVisivel
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _senhaVisivel = !_senhaVisivel),
                          ),
                        ),
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Informe a senha' : null,
                      ),
                      if (_erro != null) ...[
                        const SizedBox(height: 12),
                        Text(_erro!, style: const TextStyle(color: Colors.red)),
                      ],
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _loading ? null : _loginEmail,
                          child: _loading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Entrar'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _loading ? null : _loginGoogle,
                          icon: const Icon(Icons.login),
                          label: const Text('Entrar com Google'),
                        ),
                      ),
                      if (defaultTargetPlatform == TargetPlatform.iOS) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: SignInWithAppleButton(
                            onPressed: _loading ? () {} : _loginApple,
                            style: SignInWithAppleButtonStyle.black,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(8),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.register),
                        child: const Text('Não tem conta? Cadastre-se'),
                      ),
                      TextButton(
                        onPressed: _recuperarSenha,
                        child: const Text('Esqueci minha senha'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.info_outline, color: Color(0xFF1A6B3C)),
                tooltip: 'Sobre',
                onPressed: () async => mostrarSobre(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
