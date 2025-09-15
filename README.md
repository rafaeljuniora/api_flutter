# dummyjson\_list

App Flutter **didático** que autentica no **DummyJSON** e lista **Usuários** e **Carrinhos**, permitindo escolher **quantos** itens (N) exibir.
Ao tocar em um carrinho, o app mostra os **itens** em um **popup (bottom-sheet)**.

> **Stack**: Flutter 3.22+ • Dart 3 • `http`

---

## Funcionalidades

* **Login** (`/auth/login`) e uso de **Bearer accessToken (JWT)** nas requisições.
* Campo para informar **N** (ex.: `10`) e botão **Buscar** para recarregar dados.
* Lista os **últimos N** **usuários** (`/users`) e **carrinhos** (`/carts`) por **`id` desc** (se a API não ordenar, o app ordena localmente).
* **Popup de itens do carrinho**: toque em um carrinho e veja título, preço, quantidade, total de cada item e totais do carrinho.
* **Refresh automático do token**: ao receber **401/403**, tenta `POST /auth/refresh` e **repete** a requisição **uma vez**; se falhar, volta à **tela de Login** com aviso.

> Projeto para **estudos**. Antes de produção: armazenamento seguro de tokens, tratamento de erros robusto, retry/backoff, logging e testes.

---

## Credenciais de exemplo

Use qualquer usuário de `/users`. Exemplo oficial:

```jsonc
POST https://dummyjson.com/auth/login
{
  "username": "emilys",
  "password": "emilyspass",
  "expiresInMins": 30 // opcional (padrão 60)
}
```

Após o login, a API retorna `accessToken` e `refreshToken`. As rotas autenticadas aceitam `Authorization: Bearer <accessToken>`.

---

## Como o app funciona

### Fluxo de autenticação

1. A **LoginPage** chama `DummyJsonApi.login(...)` (POST `/auth/login`).
2. O serviço guarda **`accessToken`** e **`refreshToken`** em memória.
3. Demais chamadas incluem `Authorization: Bearer <token>`.

### Atualização de token (refresh)

* Se uma requisição retornar **401/403**, o serviço chama `POST /auth/refresh`, atualiza o `accessToken` e **repete a requisição uma vez**.
* Se o refresh falhar, os tokens são limpos; a Home mostra SnackBar “Sessão expirada” e navega para a **tela de Login**.

### “Últimos N”

* **Usuários**: `GET /users?limit=N&sortBy=id&order=desc&select=id,firstName,lastName,username,email,image`
  (se a API não ordenar, o app ordena localmente por `id` desc).
* **Carrinhos**: `GET /carts?limit=N`
  (tenta `sortBy=id&order=desc`; se indisponível, ordena localmente por `id` desc).

### Itens do carrinho

* Toque em um cartão de carrinho para abrir **bottom-sheet** com `products[]` (título, quantidade, preço, total) e os totais `total` / `discountedTotal`.

---

## Estrutura do projeto

```
dummyjson_list/
├─ lib/
│  ├─ main.dart                     # UI (Login + Home) e bottom-sheet dos itens do carrinho
│  ├─ services/
│  │  └─ dummyjson_api.dart         # Serviço HTTP (auth, refresh, users, carts)
│  └─ models/
│     ├─ user.dart                  # Modelo User
│     ├─ cart.dart                  # Modelo Cart
│     └─ cart_item.dart             # Modelo CartItem
├─ pubspec.yaml                     # Dependências (http)
└─ README.md
```

**Principais responsabilidades**

* `dummyjson_api.dart`

  * `login(...)`: `POST /auth/login` → guarda `accessToken` e `refreshToken`.
  * `getLatestUsers(limit)`, `getLatestCarts(limit)`: GET com **\_getWithRetry** (faz refresh se 401/403).
* `main.dart`

  * `LoginPage`: tela de login.
  * `HomePage`: campo **N**, botão **Buscar**, listas (Usuários/Carrinhos) e `_openCart(...)` (bottom-sheet).
  * Em erro 401/403 após tentativa de refresh, **volta ao Login**.

---

## Como rodar

> Requisitos: Flutter 3.22+ e um device (emulador/simulador, navegador ou dispositivo físico).

```bash
# 1) Entre na pasta do projeto
cd dummyjson_list

# 2) Baixe as dependências
flutter pub get

# 3) Rode
flutter run
```

### Web

```bash
flutter config --enable-web
flutter run -d chrome
```

### Android

```bash
flutter devices
flutter run -d <id-do-dispositivo>
```

### iOS (simulador)

```bash
open -a Simulator
flutter run -d ios
```

---

## Configurações e personalização

* **Base URL**
  Use outro endpoint (proxy, mock, etc.) passando no construtor — ou compile-time env:

  ```dart
  // Direto
  final api = DummyJsonApi(baseUrl: 'https://seu-proxy.local');

  // Via --dart-define (ex.: flutter run --dart-define=DUMMYJSON_BASE_URL=https://seu-proxy.local)
  const base = String.fromEnvironment('DUMMYJSON_BASE_URL', defaultValue: 'https://dummyjson.com');
  final api = DummyJsonApi(baseUrl: base);
  ```

* **Expiração do token**
  Ajuste o tempo de vida do `accessToken` no login:

  ```dart
  await api.login(username: user, password: pass, expiresInMins: 15); // padrão 60
  ```

* **Seleção de campos (users)**
  Para reduzir payload, edite o `select` da chamada em `DummyJsonApi.getLatestUsers(...)`.
  Exemplos de seleções úteis:

  ```text
  select=id,firstName,lastName,username,email,image             // leve (padrão da demo)
  select=id,firstName,lastName,age,gender,phone,company,title   // mais dados
  ```

  > Dica: se quiser tornar isso **parametrizável**, adicione um parâmetro opcional `select` ao método e construa a URL com ele.

* **Quantidade padrão (N)**
  Altere o valor inicial do campo na `HomePage`:

  ```dart
  final _qtyCtrl = TextEditingController(text: '10'); // mude para '20', '50', ...
  ```

* **Ordenação**
  A demo tenta `sortBy=id&order=desc` no servidor e, se indisponível, **ordena localmente**.
  Para mudar o critério:

  * **No servidor (quando suportado):** troque a query, p.ex. `sortBy=firstName&order=asc`.
  * **Localmente (fallback):** ajuste o `sort(...)` no serviço:

    ```dart
    // usuários
    list.sort((a, b) => (b['id'] as int).compareTo(a['id'] as int)); // desc por id
    // exemplo: asc por firstName
    // list.sort((a, b) => (a['firstName'] as String).compareTo(b['firstName'] as String));
    ```

> Extra: quer deixar tudo **configurável** sem editar código? Centralize essas opções (baseUrl, select, sortBy/order, N) em uma classe `AppConfig` e injete no `DummyJsonApi`/`HomePage`.

---
## Endpoints (resumo prático)

**Headers comuns**

```http
Content-Type: application/json
Authorization: Bearer <accessToken>   # após login/refresh
```

* **Login** — `POST /auth/login`
  **Body**:

  ```json
  { "username": "emilys", "password": "emilyspass", "expiresInMins": 30 }
  ```

  **Retorno**: `accessToken`, `refreshToken`.

* **Refresh** — `POST /auth/refresh`
  **Body**:

  ```json
  { "refreshToken": "<seu_refresh>", "expiresInMins": 30 }
  ```

  **Retorno**: novo `accessToken` (e, às vezes, novo `refreshToken`).

* **Eu (opcional)** — `GET /auth/me`
  **Header**: `Authorization: Bearer <accessToken>`
  **Uso**: valida o token e obtém o perfil autenticado.

* **Users** — `GET /users`
  **Query params úteis**:

  * `limit=N` • `skip=K` (paginação)
  * `sortBy=id|firstName|...` • `order=asc|desc` (ordenação, quando suportado)
  * `select=campos,separados,por,vírgula` (reduz payload)
    **Exemplo**:

  ```
  /users?limit=10&sortBy=id&order=desc&select=id,firstName,lastName,username,email,image
  ```

  **Obs.**: se a API não ordenar, o app **ordena localmente** por `id desc`.

* **Carts** — `GET /carts`
  **Query**: `limit=N` • `skip=K` (paginação)
  **Retorno**:

  ```json
  { "carts": [ { "id": 1, "userId": 5, "products": [ { "id": 59, "title": "...", "price": 10, "quantity": 2, "total": 20, "discountPercentage": 5, "discountedTotal": 19 } ], "total": 20, "discountedTotal": 19, "totalProducts": 1, "totalQuantity": 2 } ], "total": 100, "skip": 0, "limit": 10 }
  ```

  **Notas**: cada `cart` possui `userId` (para junção com usuários) e `products[]`. Se `sortBy/order` não estiver disponível, o app **ordena localmente** por `id desc`.

### Exemplos (cURL)

```bash
# Login
curl -X POST https://dummyjson.com/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"emilys","password":"emilyspass","expiresInMins":30}'

# Eu autenticado
curl -X GET https://dummyjson.com/auth/me \
  -H "Authorization: Bearer <SEU_ACCESS_TOKEN>"

# Últimos 10 usuários (id desc)
curl "https://dummyjson.com/users?limit=10&sortBy=id&order=desc&select=id,firstName,lastName,username,email,image"

# 10 carrinhos
curl "https://dummyjson.com/carts?limit=10"
```
---

## Visão geral das camadas

* **UI (Flutter widgets)**

  * `LoginPage` / `_LoginPageState`
  * `HomePage` / `_HomePageState`
* **Serviço HTTP**

  * `DummyJsonApi`
* **Modelos (dados imutáveis)**

  * `User`
  * `Cart`
  * `CartItem`

### Relações entre classes (diagrama textual)

```
LoginPage ──(usa)──> DummyJsonApi.login()
                       │
HomePage ──(usa)──> DummyJsonApi.getLatestUsers() ──> List<User>
            │
            └─(usa)──> DummyJsonApi.getLatestCarts() ──> List<Cart>
                                                           │
                                                           └─ Cart.products : List<CartItem>

Cart.userId --- (junção lógica) ---> User.id
```

> Observação: **não há herança entre os modelos**; a herança existe apenas nas telas (widgets) por serem `StatefulWidget`/`State` do Flutter.

---

## Modelos (dados)

### `User`

**Arquivo:** `lib/models/user.dart`

**Propósito:** Representa um usuário retornado por `/users`.

**Campos principais:**

* `int id`
* `String firstName`, `String lastName`
* `String username`, `String email`
* `String? image`
* `String get fullName` (getter calculado: `"$firstName $lastName"`)

**Como foi feita:**

* Classe **imutável** (todos `final`).
* **Factory** `fromJson(Map<String,dynamic>)` defensiva (campos opcionais com default vazio).
* **Sem herança**: classe simples de dados.

**Relações:**

* É **referenciado** por `Cart` via `Cart.userId` ⇢ `User.id` (junção lógica, não automática).

---

### `CartItem`

**Arquivo:** `lib/models/cart_item.dart`

**Propósito:** Representa um **item** dentro de um carrinho (`Cart.products[]`).

**Campos principais:**

* `int id`
* `String title`
* `num price`
* `int quantity`
* `num total`
* `num discountPercentage`
* `num discountedPrice` (aceita também `discountedTotal` quando presente no payload)

**Como foi feita:**

* Imutável com `final`.
* **Factory** `fromJson` com **fallbacks**:

  * Se vier `discountedPrice`, usa; senão tenta `discountedTotal`; senão `total`.

**Relações:**

* Pertence a um `Cart` (lista `products`).

---

### `Cart`

**Arquivo:** `lib/models/cart.dart`

**Propósito:** Representa um carrinho retornado por `/carts`.

**Campos principais:**

* `int id`
* `int userId` (para relacionar com `User.id`)
* `List<CartItem> products`
* `num total`, `num discountedTotal`
* `int totalProducts`, `int totalQuantity` (calculados se não vierem)

**Como foi feita:**

* Imutável com `final`.
* **Factory** `fromJson`:

  * Monta `products` convertendo cada item para `CartItem`.
  * Garante `totalProducts` / `totalQuantity` com **fallback**: se ausentes, usa `items.length` e soma de `quantity`.

**Relações:**

* **Contém** uma lista de `CartItem`.
* **Aponta** para um `User` por `userId` (junção lógica ao exibir).

---

## Serviço HTTP

### `DummyJsonApi`

**Arquivo:** `lib/services/dummyjson_api.dart`

**Propósito:** Fornece um **ponto único** para autenticação e consumo de `/users` e `/carts`.

**Principais membros:**

* **Config**:

  * `String baseUrl` (default: `https://dummyjson.com`)
  * `http.Client _client`
* **Auth (estado em memória)**:

  * `String? _accessToken`, `String? _refreshToken`
  * `Map<String,String> get _baseHeaders` (injeta `Authorization: Bearer` quando logado)

**Métodos:**

* `Future<void> login({username, password, expiresInMins})`
  Autentica via `POST /auth/login` e **guarda** `accessToken`/`refreshToken`.

* `Future<bool> _tryRefresh({expiresInMins})` (privado)
  Tenta `POST /auth/refresh`; **atualiza** `accessToken` (e possivelmente `refreshToken`).

* `Future<http.Response> _getWithRetry(Uri)` (privado)
  Faz `GET`. Se vier **401/403**, chama `_tryRefresh()` e **repete** a requisição **uma vez**.

* `Future<List<User>> getLatestUsers({int limit = 10})`
  Chama `/users?limit=...&sortBy=id&order=desc&select=...`.
  **Fallback**: se a API não ordenar, ordena **localmente** por `id desc`.

* `Future<List<Cart>> getLatestCarts({int limit = 10})`
  Chama `/carts?limit=...` (tenta `sortBy=id&order=desc`).
  **Fallback**: ordena localmente por `id desc`.

* `void logout()`
  **Limpa tokens** em memória (encerra sessão local).

**Como foi feito:**

* Separação clara de **responsabilidades** (auth, refresh, consumo).
* **Retry na borda** (\_getWithRetry) para **não poluir a UI** com lógica de refresh.
* **Sem herança**; composição de `http.Client`.
* **Tratamento de erro**: repassa `statusCode` e mensagens da API quando não-200.

**Relações:**

* Usado por `LoginPage` (login) e por `HomePage` (listagens).
* Não conhece widgets; é **agnóstico de UI**.

---

## UI (telas)

### `LoginPage` / `_LoginPageState`

**Arquivo:** `lib/main.dart`

**Propósito:** Tela de **autenticação**.

**Como foi feita:**

* `StatefulWidget` com `Form` e `TextFormField` para `username`/`password`.
* Botão **Entrar** dispara `_submit()`:

  * Chama `api.login(...)`.
  * Em sucesso: navega para `HomePage(api: _api)`.
  * Em erro: exibe mensagem em vermelho.

**Relações:**

* **Depende** de `DummyJsonApi` para autenticar.
* **Navega** para `HomePage` após sucesso.

---

### `HomePage` / `_HomePageState`

**Arquivo:** `lib/main.dart`

**Propósito:** Tela principal com:

* Campo **N** (quantidade), botão **Buscar**.
* Listas de **Usuários** e **Carrinhos**.
* **Bottom-sheet** ao tocar em um carrinho (mostra `CartItem`s).
* **Menu (Drawer)** com ações rápidas.

**Como foi feita:**

* `StatefulWidget` que **mantém estado**:

  * `_qtyCtrl` (`TextEditingController`) com valor inicial `"10"`.
  * `_loading`, `_error`, `_users`, `_carts`.
* Método `_fetch()`:

  * Lê `N`, chama **em paralelo**: `getLatestUsers(N)` e `getLatestCarts(N)` (`Future.wait`).
  * Atualiza estado; erros vão para `_error`.
  * Se erro tiver **401/403** após tentativa de refresh, a tela **volta ao Login** (SnackBar “Sessão expirada”).
* Método `_openCart(Cart c)`:

  * `showModalBottomSheet` listando `c.products` (título, quantidade, preço, total) + `total`/`discountedTotal`.
* Método `_buildMenu(...)` (Drawer):

  * **Início** (fecha menu), **Atualizar listas** (chama `_fetch()`),
    **Definir N** (diálogo para alterar `_qtyCtrl`), **Sair** (chama `api.logout()` e volta ao Login), **Sobre**.

**Relações:**

* **Usa** `DummyJsonApi` para buscar dados.
* **Renderiza** `User` e `Cart` (com `CartItem`) em listas e popup.

**Herança:**

* `HomePage` e `LoginPage` **herdam** de `StatefulWidget` (Flutter).
* Seus estados herdam de `State<T>` — herança **própria do framework**.

---

## Estratégias importantes implementadas

* **Ordenação**: tenta `sortBy=id&order=desc` na API; **fallback local** por `id desc`.
* **Refresh automático**: abstraído no serviço; a UI só reage a erro pós-refresh (volta ao Login).
* **Imutabilidade nos modelos**: evita efeitos colaterais.
* **UI simples com `setState`**: direta e fácil de ler para fins didáticos.

---

## Pontos de extensão sugeridos — **como implementar**

### 1) Sincronizar `Cart.userId` ↔ `User` na UI (mostrar nome do usuário do carrinho)

**Ideia:** após buscar usuários e carrinhos, crie um índice `Map<int, User>` para resolver o nome rapidamente.

```dart
// Depois de carregar as listas:
final Map<int, User> userById = { for (final u in _users) u.id : u };

// Ao renderizar cada cart:
title: Text('Cart #${c.id} • ${userById[c.userId]?.fullName ?? "User ${c.userId}"}'),
subtitle: Text('Itens: ${c.totalQuantity} • Total: ${c.total}'),
```

**Opcional (lazy):** se você não tiver todos os usuários carregados, adicione um cache no serviço:

```dart
final _userCache = <int, User>{};
Future<User?> getUser(int id) async {
  if (_userCache.containsKey(id)) return _userCache[id];
  final res = await _getWithRetry(Uri.parse('$baseUrl/users/$id'));
  if (res.statusCode != 200) return null;
  final user = User.fromJson(jsonDecode(res.body));
  return _userCache[id] = user;
}
```

…e, na UI, carregue sob demanda (ex.: `FutureBuilder`) quando faltar o nome.

---

### 2) Página de **Detalhes do Usuário**

**Ideia:** abrir uma tela ao tocar em um usuário, com avatar grande, nome, @username e ações (copiar e-mail, enviar e-mail).

```dart
// Navegação ao tocar na ListTile do usuário:
onTap: () => Navigator.push(context,
  MaterialPageRoute(builder: (_) => UserDetailsPage(user: u)),
);

// Exemplo de tela:
class UserDetailsPage extends StatelessWidget {
  const UserDetailsPage({super.key, required this.user});
  final User user;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(user.fullName)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(radius: 40, backgroundImage: user.image != null ? NetworkImage(user.image!) : null),
            const SizedBox(height: 12),
            Text('@${user.username} • ${user.email}'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {/* abrir mailto:${user.email} */},
              icon: const Icon(Icons.mail),
              label: const Text('Enviar e-mail'),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Extra:** buscar `/users/{id}` aqui para detalhes adicionais, se a lista inicial usa `select` reduzido.

---

### 3) Camada de **estado** e **repositório**

**Objetivo:** separar UI ↔ dados; facilitar testes, caching e reuso.

#### 3.1 Riverpod (recomendado pela simplicidade)

**pubspec.yaml**

```yaml
dependencies:
  flutter_riverpod: ^2.5.1
```

**Setup básico**

```dart
void main() => runApp(const ProviderScope(child: DummyJsonApp()));

final apiProvider = Provider((_) => DummyJsonApi());
final nProvider = StateProvider<int>((_) => 10);

final usersProvider = FutureProvider<List<User>>((ref) {
  final n = ref.watch(nProvider);
  return ref.read(apiProvider).getLatestUsers(limit: n);
});

final cartsProvider = FutureProvider<List<Cart>>((ref) {
  final n = ref.watch(nProvider);
  return ref.read(apiProvider).getLatestCarts(limit: n);
});
```

**Na UI (Home)**

```dart
final users = ref.watch(usersProvider);
final carts  = ref.watch(cartsProvider);
// users.when(data: ..., loading: ..., error: ...)
// ao mudar N: ref.read(nProvider.notifier).state = novoN;
```

#### 3.2 Repositório

```dart
abstract class DummyRepo {
  Future<void> login(String u, String p);
  Future<List<User>> latestUsers(int n);
  Future<List<Cart>> latestCarts(int n);
}

class DummyRepoImpl implements DummyRepo {
  DummyRepoImpl(this.api);
  final DummyJsonApi api;
  final _userIndex = <int, User>{}; // cache leve

  @override Future<void> login(String u, String p) => api.login(username: u, password: p);
  @override Future<List<User>> latestUsers(int n) async {
    final list = await api.getLatestUsers(limit: n);
    for (final u in list) _userIndex[u.id] = u;
    return list;
  }
  @override Future<List<Cart>> latestCarts(int n) => api.getLatestCarts(limit: n);

  User? cachedUser(int id) => _userIndex[id];
}
```

> Você pode expor `DummyRepo` via Riverpod e trocar implementações (ex.: mock em testes).

**Alternativa:** Bloc/Cubit (mesma ideia; providers viram blocs, `emit` estados).

---

### 4) **Mutex** no refresh (evitar múltiplos refresh em paralelo)

**Problema:** várias requisições 401 podem disparar `/_auth/refresh` ao mesmo tempo.
**Solução:** guarde a *mesma* `Future<bool>` enquanto o refresh está “em voo”.

```dart
class DummyJsonApi {
  Future<bool>? _refreshInFlight;

  Future<bool> _tryRefreshDedup() async {
    // já existe um refresh rodando? aguarde o mesmo
    if (_refreshInFlight != null) return await _refreshInFlight!;
    final completer = Completer<bool>();
    _refreshInFlight = completer.future;
    try {
      final ok = await _tryRefresh();   // seu método existente
      completer.complete(ok);
      return ok;
    } catch (e, st) {
      completer.completeError(e, st);
      rethrow;
    } finally {
      _refreshInFlight = null;
    }
  }

  Future<http.Response> _getWithRetry(Uri uri) async {
    var res = await _client.get(uri, headers: _baseHeaders);
    if (res.statusCode == 401 || res.statusCode == 403) {
      final ok = await _tryRefreshDedup();
      if (ok) res = await _client.get(uri, headers: _baseHeaders);
    }
    return res;
  }
}
```

> Assim, todas as chamadas aguardam **um** refresh compartilhado, evitando tempestade de requisições.

---

### 5) Persistência **segura** de tokens (`flutter_secure_storage`)

**Quando usar:** se quiser manter sessão entre aberturas do app.

**pubspec.yaml**

```yaml
dependencies:
  flutter_secure_storage: ^9.0.0
```

**No serviço**

```dart
final _storage = const FlutterSecureStorage();

Future<void> _saveTokens() async {
  if (_accessToken != null) await _storage.write(key: 'access', value: _accessToken);
  if (_refreshToken != null) await _storage.write(key: 'refresh', value: _refreshToken);
}

Future<void> loadTokens() async {
  _accessToken  = await _storage.read(key: 'access');
  _refreshToken = await _storage.read(key: 'refresh');
}

void logout() {
  _accessToken = _refreshToken = null;
  _storage.delete(key: 'access');
  _storage.delete(key: 'refresh');
}
```

**No `login(...)` após sucesso**

```dart
_accessToken = body['accessToken'];
_refreshToken = body['refreshToken'];
await _saveTokens();
```

**No app start (Splash)**

```dart
await api.loadTokens();
final logged = api.accessToken != null;
runApp(MyApp(initialRoute: logged ? '/home' : '/login'));
```

> Em **Web**, evite persistir tokens em `localStorage`; prefira **cookies HttpOnly** para refresh e mantenha o access token em memória.

---

## Troubleshooting

* **CORS (Web)**

  * Teste em **aba anônima**, limpe **cache/cookies**, desative **extensões**.
  * Em dev apenas (inseguro):
    `flutter run -d chrome --web-browser-flag="--disable-web-security" --web-browser-flag="--user-data-dir=/tmp/chrome-dev"`
  * Preferível: usar um **proxy de desenvolvimento** que injete CORS:

    ```js
    // proxy-dev.js (Node)
    import express from 'express';
    import { createProxyMiddleware } from 'http-proxy-middleware';
    const app = express();
    app.use('/api', createProxyMiddleware({
      target: 'https://dummyjson.com',
      changeOrigin: true,
      pathRewrite: {'^/api': ''},
    }));
    app.listen(3000);
    // chame http://localhost:3000/api/...
    ```

* **Rede / Timeout**

  * Adicione timeout e trate exceções:

    ```dart
    import 'dart:async';
    final res = await client.get(uri, headers: h).timeout(const Duration(seconds: 10));
    ```
  * **Retry com backoff** simples:

    ```dart
    Future<T> retry<T>(Future<T> Function() run, {int retries=3}) async {
      var delay = const Duration(milliseconds: 400);
      for (var i=0; i<retries; i++) {
        try { return await run(); } catch (e) {
          if (i==retries-1) rethrow;
          await Future.delayed(delay);
          delay *= 2;
        }
      }
      throw StateError('retry falhou');
    }
    ```

* **Build quebrado**

  * `flutter clean && flutter pub get`
  * Verifique versões: `flutter --version` e `flutter doctor -v`
  * Se necessário, repare cache: `dart pub cache repair`
  * iOS: limpe DerivedData/Pods (se usar CocoaPods):
    `rm -rf ios/Pods ios/Podfile.lock && cd ios && pod install && cd ..`

* **Erros HTTP comuns**

  * **401/403**: o app tenta **/auth/refresh** automaticamente; se falhar, volta ao **Login**. Verifique **diferença de horário** do dispositivo.
  * **429 (rate limit)**: reduza frequência e aplique **backoff** (ver snippet acima).
  * **5xx**: geralmente no servidor; tente novamente depois e registre detalhes do erro.

* **SSL / Certificados (dev com proxy)**

  * Android: configurar `network_security_config.xml` para confiar no certificado dev.
  * iOS: ajustar **ATS** no `Info.plist` para domínios de teste.

* **Ambiente corporativo / Proxy**

  * Defina `HTTP_PROXY`, `HTTPS_PROXY`, `NO_PROXY` no sistema/terminal.
  * Emulador Android acessando host: use `http://10.0.2.2:<porta>`.

* **JSON / Parsing**

  * Em campos numéricos, prefira `num` ao invés de `int/double` fixos no modelo.
  * Em caso de erro, **log** do corpo ajuda:

    ```dart
    print('status=${res.statusCode} body=${res.body}');
    ```

---
## Segurança

* **Armazenamento de tokens**

  * Nesta demo, os tokens ficam **apenas em memória**.
  * Se **precisar persistir** (ex.: `refreshToken`), use **armazenamento seguro**:

    * Android: **Keystore** (ex.: `flutter_secure_storage`)
    * iOS: **Keychain** (ex.: `flutter_secure_storage`)
  * Limpe tokens em **logout**, falha de **refresh** ou quando o app volta do **background** (se fizer sentido).

* **Estratégia de tokens**

  * Prefira **access tokens de curta duração** (5–15 min) e **refresh rotativo** (renova e invalida o anterior).
  * Não logue tokens nem os envie para ferramentas de crash/analytics.
  * Opcional: **pré-refresh** antes do `exp` (checando a *claim* `exp` do JWT para evitar 401 em tela).
    *Obs.: a validação real é do backend; no cliente é só conveniência.*

* **Rede e HTTP**

  * Use **HTTPS sempre**; nunca aceite certificados inválidos em produção.
  * Aplique **timeouts** e **retry com backoff** em erros transitórios (429/5xx).
  * Envie `Authorization: Bearer <token>` **somente** quando necessário (evite em domínios de terceiro).
  * (Avançado) **Certificate pinning**/trust anchor customizado se o cenário pedir.

* **Web (Flutter Web)**

  * Evite guardar tokens em `localStorage/sessionStorage` (risco de XSS).
  * Prefira **cookies HttpOnly** (+ `SameSite=Strict`/`Lax`, `Secure`) para **refresh** e mantenha o **access token em memória**.
  * Habilite **CSP** e minimize exposição de headers sensíveis em logs do navegador.

* **UI & dispositivo**

  * Evite **prints** de telas sensíveis (Android: `FLAG_SECURE` via plugin; iOS: aplicar blur ao ir para background).
  * Oculte dados sensíveis em **screenshots previews**/multitarefa onde possível.

* **Build & código**

  * **Ofusque** o código em releases:

    ```bash
    flutter build apk  --release --obfuscate --split-debug-info=build/symbols
    flutter build ios  --release --obfuscate --split-debug-info=build/symbols
    ```
  * Injete configurações por `--dart-define` (não comite chaves/URLs privadas) e use `.gitignore`.
  * Faça *scans* de segredos no repositório (ex.: gitleaks) e mantenha dependências atualizadas (`dart pub outdated`).

* **Políticas no servidor**

  * Escopos e **princípio do menor privilégio**.
  * Revogação de refresh tokens, **rate limiting**, detecção de anomalias e **auditoria**.
  * Headers de segurança (CORS, CSP, etc.) e respostas de erro sem vazar detalhes.

> Dica: crie uma camada `AuthClient`/`ApiClient` única para **injetar** o header `Authorization`, fazer **refresh** automático e aplicar **timeouts/retry**—isso centraliza e reduz risco de vazamentos.

---

## Licença

Uso livre para fins educacionais. © Jefferson Rodrigo Speck.
