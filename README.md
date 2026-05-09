# Bolão com Amigos

Aplicativo Flutter/Firebase para bolão da Copa.

## Comandos

~~~powershell
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
~~~

## Firebase

Antes de publicar novas regras:

~~~powershell
firebase deploy --only firestore:rules,firestore:indexes
~~~

Após a mudança para convites indexados, migrar grupos já existentes:

~~~powershell
node seed/migrar_invite_codes.js
~~~

## Segurança

- Dados da Copa (`cups/**`) só podem ser alterados por usuário com `users/{uid}.is_admin == true`.
- Pontuação não é gravada pelo cliente; ranking e tela inicial calculam os pontos ao ler os dados.
- Palpites só podem ser gravados antes de `cups/{cupId}.starts_at`.
- Convites usam `invite_codes/{codigo}` com leitura direta; listagem é bloqueada.
