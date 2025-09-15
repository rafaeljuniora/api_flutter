import 'package:flutter/material.dart';
import 'models/user.dart';
import 'models/cart.dart';
import 'services/dummyjson_api.dart';

void main() {
  runApp(const DummyJsonApp());
}

class DummyJsonApp extends StatelessWidget {
  const DummyJsonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DummyJSON Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

/// --- TELA DE LOGIN ---------------------------------------------------------
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _api = DummyJsonApi();
  final _form = GlobalKey<FormState>();
  final _userCtrl = TextEditingController(text: 'emilys'); // exemplo
  final _passCtrl = TextEditingController(text: 'emilyspass'); // exemplo
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _api.login(
        username: _userCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomePage(api: _api),
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login • DummyJSON')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Use um usuário do /users (ex.: emilys / emilyspass)',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _userCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Informe o user' : null,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: Icon(Icons.lock),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Informe a senha' : null,
                    ),
                    const SizedBox(height: 12),
                    if (_error != null)
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Entrar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// --- HOME: campo de texto para "N" e listas de Users/Carts ------------------
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.api});
  final DummyJsonApi api;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _qtyCtrl = TextEditingController(text: '10');
  bool _loading = false;
  String? _error;
  List<User> _users = const [];
  List<Cart> _carts = const [];

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final n = int.tryParse(_qtyCtrl.text.trim()) ?? 10;
      final results = await Future.wait([
        widget.api.getLatestUsers(limit: n),
        widget.api.getLatestCarts(limit: n),
      ]);
      setState(() {
        _users = results[0] as List<User>;
        _carts = results[1] as List<Cart>;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }


  void _openCart(Cart c) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 420,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Carrinho #${c.id} • User ${c.userId}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: c.products.isEmpty
                        ? const Center(child: Text('Sem itens neste carrinho.'))
                        : ListView.separated(
                            itemCount: c.products.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final p = c.products[i];
                              return ListTile(
                                dense: true,
                                title: Text(p.title),
                                subtitle: Text('${p.quantity} × ${p.price} = ${p.total}'),
                                trailing: Text('#${p.id}'),
                              );
                            },
                          ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total bruto:'),
                      Text(c.total.toString()),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total com desconto:'),
                      Text(c.discountedTotal.toString()),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Últimos usuários & carrinhos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Quantidade (N)',
                      hintText: 'Ex.: 10',
                      prefixIcon: Icon(Icons.filter_1),
                    ),
                    onSubmitted: (_) => _fetch(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _loading ? null : _fetch,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Buscar'),
                ),
              ],
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                const Text('Usuários', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._users.map((u) => Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: u.image != null ? NetworkImage(u.image!) : null,
                          child: u.image == null ? const Icon(Icons.person) : null,
                        ),
                        title: Text(u.fullName),
                        subtitle: Text('@${u.username} • ${u.email}'),
                        trailing: Text('#${u.id}'),
                      ),
                    )),
                const SizedBox(height: 16),
                const Text('Carrinhos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._carts.map((c) => Card(
                      child: ListTile(
                        onTap: () => _openCart(c),
                        title: Text('Cart #${c.id} • User ${c.userId}'),
                        subtitle: Text(
                            '${c.totalProducts} prod. / ${c.totalQuantity} itens • total: ${c.total.toString()} (desc: ${c.discountedTotal.toString()})'),
                        trailing: const Icon(Icons.shopping_cart_outlined),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
