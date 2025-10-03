import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/user.dart';
import 'models/cart.dart';
import 'models/search_parameters.dart';
import 'services/dummyjson_api.dart';
import 'widgets/search_dialog.dart';

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
  final _userCtrl = TextEditingController(text: 'emilys'); 
  final _passCtrl = TextEditingController(text: 'emilyspass');
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
  late TextEditingController _limitCtrl;
  int _limit = 10;

  int _usersPage = 1;
  int _cartsPage = 1;
  int _totalUsers = 0;
  int _totalCarts = 0;

  bool _loading = false;
  String? _error;
  List<User> _users = const [];
  List<Cart> _carts = const [];
  SearchParameters _currentSearchParams = const SearchParameters();
  bool _isSearchMode = false;

  @override
  void initState() {
    super.initState();
    _limitCtrl = TextEditingController(text: _limit.toString());
    _fetchAll();
  }

  @override
  void dispose() {
    _limitCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSearchPressed() async {
    FocusScope.of(context).unfocus();

    int newLimit = int.tryParse(_limitCtrl.text.trim()) ?? 10;

    if (newLimit <= 0) {
      newLimit = 10;
      _limitCtrl.text = newLimit.toString(); 
    }

    if (newLimit != _limit) {
      setState(() {
        _limit = newLimit;
        _usersPage = 1;
        _cartsPage = 1;
      });
    }

    await _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Future.wait([
        _fetchUsers(),
        _fetchCarts(),
      ]);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if(mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _fetchUsers() async {
    final skip = (_usersPage - 1) * _limit;
    final response = await widget.api.getLatestUsers(limit: _limit, skip: skip);
    if (!mounted) return;

    setState(() {
      _users = (response['users'] as List)
          .map((json) => User.fromJson(json))
          .toList();
      _totalUsers = response['total'];
    });
  }

  Future<void> _fetchCarts() async {
    final skip = (_cartsPage - 1) * _limit;
    final response = await widget.api.getLatestCarts(limit: _limit, skip: skip);
    if (!mounted) return;

    setState(() {
      _carts = (response['carts'] as List)
          .map((json) => Cart.fromJson(json))
          .toList();
      _totalCarts = response['total'];
    });
  }

  void _navigateUsers(int page) {
    setState(() => _usersPage = page);
    _fetchUsers();
  }

  void _navigateCarts(int page) {
    setState(() => _cartsPage = page);
    _fetchCarts();
  }

  Future<void> _performSearch(SearchParameters params) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.api.searchUsers(params),
        widget.api.getLatestCartsList(limit: params.limit),
      ]);
      setState(() {
        _users = results[0] as List<User>;
        _carts = results[1] as List<Cart>;
        _currentSearchParams = params;
        _isSearchMode = true;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _openSearchDialog() async {
    final result = await showDialog<SearchParameters>(
      context: context,
      builder: (context) => SearchDialog(initialParams: _currentSearchParams),
    );
    
    if (result != null) {
      await _performSearch(result);
    }
  }

  Widget _buildPaginationControls({
    required int currentPage,
    required int totalItems,
    required ValueChanged<int> onPageChanged,
  }) {
    final totalPages = (totalItems / _limit).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
        ),
        Text('Página $currentPage de $totalPages'),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
        ),
      ],
    );
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSearchMode ? 'Busca Combinada' : 'Últimos usuários & carrinhos'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _openSearchDialog,
            icon: const Icon(Icons.search),
            tooltip: 'Busca Combinada',
          ),
          if (_isSearchMode)
            IconButton(
              onPressed: _loading ? null : _fetchAll,
              icon: const Icon(Icons.clear),
              tooltip: 'Voltar à lista normal',
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isSearchMode)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.filter_list,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Critérios ativos:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _currentSearchParams.searchDescription,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _limitCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Limite por página',
                      prefixIcon: Icon(Icons.filter_list),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onSubmitted: (_) => _onSearchPressed(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: _loading ? null : _onSearchPressed,
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16)
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _loading ? null : _openSearchDialog,
                  icon: const Icon(Icons.filter_alt),
                  label: const Text('Filtros'),
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
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              children: [
                const Text('Usuários',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (!_isSearchMode)
                  _buildPaginationControls(
                    currentPage: _usersPage,
                    totalItems: _totalUsers,
                    onPageChanged: _navigateUsers,
                  ),
                const SizedBox(height: 8),
                if (_users.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Icon(
                            _isSearchMode ? Icons.search_off : Icons.person_off,
                            size: 48,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _isSearchMode 
                                ? 'Nenhum usuário encontrado com os critérios especificados'
                                : 'Nenhum usuário disponível',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (_isSearchMode) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Tente ajustar os filtros de busca',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                else
                  ..._users.map((u) => Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: u.image != null ? NetworkImage(u.image!) : null,
                          child: u.image == null ? const Icon(Icons.person) : null,
                        ),
                        title: Text(u.fullName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('@${u.username} • ${u.email}'),
                            if (u.gender != null || u.age != null)
                              Text(
                                [
                                  if (u.gender != null) 
                                    u.gender == 'male' ? 'Masculino' : 
                                    u.gender == 'female' ? 'Feminino' : u.gender!,
                                  if (u.age != null) '${u.age} anos',
                                ].join(' • '),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                          ],
                        ),
                        trailing: Text('#${u.id}'),
                      ),
                    )),
                const SizedBox(height: 16),
                const Text('Carrinhos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (!_isSearchMode)
                  _buildPaginationControls(
                    currentPage: _cartsPage,
                    totalItems: _totalCarts,
                    onPageChanged: _navigateCarts,
                  ),
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
