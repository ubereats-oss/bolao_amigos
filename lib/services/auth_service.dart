import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/app_user.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // Usuário autenticado atual
  User? get currentUser => _auth.currentUser;
  // Stream de mudanças de autenticação
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  // Login com e-mail e senha
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  // Registro com e-mail e senha
  Future<UserCredential> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(name);
    await _saveUserToFirestore(
      uid: credential.user!.uid,
      name: name,
      email: email.trim(),
    );
    return credential;
  }

  // Login com Google
  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    // Cria o perfil no Firestore apenas se for o primeiro login
    final doc =
        await _db.collection('users').doc(userCredential.user!.uid).get();
    if (!doc.exists) {
      await _saveUserToFirestore(
        uid: userCredential.user!.uid,
        name: googleUser.displayName ?? 'Usuário',
        email: googleUser.email,
      );
    }
    return userCredential;
  }

  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
        length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<UserCredential> signInWithApple() async {
    final rawNonce = _generateNonce();
    final nonce = _sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
      webAuthenticationOptions: !kIsWeb && Platform.isIOS
          ? null
          : WebAuthenticationOptions(
              clientId: 'com.salles.bolaocopadomundo.signin',
              redirectUri: Uri.parse(
                'https://bolao-copa-do-mundo-salles.firebaseapp.com/__/auth/handler',
              ),
            ),
    );

    final idToken = appleCredential.identityToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception(
        'Apple não retornou um token de identidade. '
        'Verifique suas configurações de conta Apple ID e tente novamente.',
      );
    }

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: idToken,
      rawNonce: rawNonce,
      accessToken: appleCredential.authorizationCode,
    );

    final userCredential = await _auth.signInWithCredential(oauthCredential);

    final isNew = userCredential.additionalUserInfo?.isNewUser ?? false;
    if (isNew) {
      final given = appleCredential.givenName ?? '';
      final family = appleCredential.familyName ?? '';
      final name = [given, family].where((s) => s.isNotEmpty).join(' ').trim();
      await _saveUserToFirestore(
        uid: userCredential.user!.uid,
        name: name.isEmpty ? 'Usuário' : name,
        email: appleCredential.email ?? userCredential.user!.email ?? '',
      );
    }

    return userCredential;
  }

  Future<void> deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    final uid = user.uid;

    // 🔥 deletar dados do Firestore (ajuste conforme sua estrutura)
    final firestore = FirebaseFirestore.instance;

    await firestore.collection('users').doc(uid).delete();

    // ⚠️ deletar outros dados vinculados se existirem
    // ex: apostas, grupos, etc

    // 🔴 deletar usuário do Auth (por último)
    await user.delete();
  }

  // Logout
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Envia e-mail de recuperação de senha
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // Busca o perfil do usuário no Firestore
  Future<AppUser?> fetchAppUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(uid, doc.data()!);
  }

  // Salva usuário novo no Firestore
  Future<void> _saveUserToFirestore({
    required String uid,
    required String name,
    required String email,
  }) async {
    await _db.collection('users').doc(uid).set({
      'name': name,
      'email': email,
      'is_admin': false,
      'total_points': 0,
      'created_at': FieldValue.serverTimestamp(),
    });
  }
}
