import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    } catch (_) {
      setState(() => _error = 'Usuário ou senha incorretos. Tente novamente.');
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
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Informe o user'
                          : null,
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

  List<User> _allUsers = [];
  List<Cart> _allCarts = [];
  List<User> _filteredUsers = [];

  String _sortOption = 'ID Crescente';
  String _cartSortOption = 'ID Crescente';

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _minAgeCtrl = TextEditingController();
  final TextEditingController _maxAgeCtrl = TextEditingController();
  final TextEditingController _limitSearchCtrl = TextEditingController(text: '10');
  String _selectedGender = 'Todos';
  bool _caseInsensitive = true;

  @override
  void initState() {
    super.initState();
    _limitCtrl = TextEditingController(text: _limit.toString());
    _fetchAll();
  }

  @override
  void dispose() {
    _limitCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _minAgeCtrl.dispose();
    _maxAgeCtrl.dispose();
    _limitSearchCtrl.dispose();
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

    bool userError = false;
    bool cartError = false;

    try {
      await _fetchUsers().catchError((_) => userError = true);
    } catch (_) {
      userError = true;
    }

    try {
      await _fetchCarts().catchError((_) => cartError = true);
    } catch (_) {
      cartError = true;
    }

    if (!mounted) return;

    setState(() {
      if (userError && cartError) {
        _error = 'Erro ao encontrar registro.';
      } else if (userError) {
        _error = 'Erro ao encontrar usuário.';
      } else if (cartError) {
        _error = 'Erro ao encontrar carrinho.';
      } else {
        _error = null;
      }
      _loading = false;
    });
  }

  Future<void> _fetchUsers() async {
    final response = await widget.api.getLatestUsers(limit: 0, skip: 0);
    if (!mounted) return;

    setState(() {
      _allUsers = (response['users'] as List)
          .map((json) => User.fromJson(json))
          .toList();
      _filteredUsers = List.from(_allUsers);
      _totalUsers = _allUsers.length;
    });
  }

  Future<void> _fetchCarts() async {
    final response = await widget.api.getLatestCarts(limit: 0, skip: 0);
    if (!mounted) return;

    setState(() {
      _allCarts = (response['carts'] as List)
          .map((json) => Cart.fromJson(json))
          .toList();
      _totalCarts = _allCarts.length;
    });
  }

  List<User> get _users {
    final sorted = [..._filteredUsers];
    switch (_sortOption) {
      case 'ID Crescente':
        sorted.sort((a, b) => a.id.compareTo(b.id));
        break;
      case 'ID Decrescente':
        sorted.sort((a, b) => b.id.compareTo(a.id));
        break;
      case 'Nome Crescente':
        sorted.sort((a, b) => a.fullName.compareTo(b.fullName));
        break;
      case 'Nome Decrescente':
        sorted.sort((a, b) => b.fullName.compareTo(a.fullName));
        break;
    }
    final start = (_usersPage - 1) * _limit;
    final end = start + _limit;
    return sorted.sublist(start, end > sorted.length ? sorted.length : end);
  }

  List<Cart> get _carts {
    final sorted = [..._allCarts];
    switch (_cartSortOption) {
      case 'ID Crescente':
        sorted.sort((a, b) => a.id.compareTo(b.id));
        break;
      case 'ID Decrescente':
        sorted.sort((a, b) => b.id.compareTo(a.id));
        break;
    }
    final start = (_cartsPage - 1) * _limit;
    final end = start + _limit;
    return sorted.sublist(start, end > sorted.length ? sorted.length : end);
  }

  void _navigateUsers(int page) {
    setState(() => _usersPage = page);
  }

  void _navigateCarts(int page) {
    setState(() => _cartsPage = page);
  }

  void _applyFilters() {
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        bool matches = true;

        if (_nameCtrl.text.isNotEmpty) {
          final name = _caseInsensitive 
              ? user.fullName.toLowerCase() 
              : user.fullName;
          final searchName = _caseInsensitive 
              ? _nameCtrl.text.toLowerCase() 
              : _nameCtrl.text;
          matches = matches && name.contains(searchName);
        }

        if (_emailCtrl.text.isNotEmpty) {
          final email = _caseInsensitive 
              ? user.email.toLowerCase() 
              : user.email;
          final searchEmail = _caseInsensitive 
              ? _emailCtrl.text.toLowerCase() 
              : _emailCtrl.text;
          matches = matches && email.contains(searchEmail);
        }

        if (_selectedGender != 'Todos') {
          final gender = _caseInsensitive 
              ? user.gender.toLowerCase() 
              : user.gender;
          final searchGender = _caseInsensitive 
              ? _selectedGender.toLowerCase() 
              : _selectedGender;
          matches = matches && gender == searchGender;
        }

        if (_minAgeCtrl.text.isNotEmpty) {
          final minAge = int.tryParse(_minAgeCtrl.text) ?? 0;
          matches = matches && user.age >= minAge;
        }

        if (_maxAgeCtrl.text.isNotEmpty) {
          final maxAge = int.tryParse(_maxAgeCtrl.text) ?? 999;
          matches = matches && user.age <= maxAge;
        }

        return matches;
      }).toList();
      
      final searchLimit = int.tryParse(_limitSearchCtrl.text) ?? 10;
      if (searchLimit > 0) {
        _limit = searchLimit;
        _limitCtrl.text = searchLimit.toString();
      }
      
      _totalUsers = _filteredUsers.length;
      _usersPage = 1;
    });
  }

  void _clearFilters() {
    setState(() {
      _nameCtrl.clear();
      _emailCtrl.clear();
      _minAgeCtrl.clear();
      _maxAgeCtrl.clear();
      _limitSearchCtrl.text = '10';
      _selectedGender = 'Todos';
      _caseInsensitive = true;
      _filteredUsers = List.from(_allUsers);
      _totalUsers = _allUsers.length;
      _usersPage = 1;
      _limit = 10;
      _limitCtrl.text = '10';
    });
  }

  void _showSearchModal() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Busca Combinada'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nome (contém)',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Email (contém)',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: const InputDecoration(
                      labelText: 'Gênero',
                      prefixIcon: Icon(Icons.people),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Todos', child: Text('Todos')),
                      DropdownMenuItem(value: 'male', child: Text('Masculino')),
                      DropdownMenuItem(value: 'female', child: Text('Feminino')),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        _selectedGender = value ?? 'Todos';
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minAgeCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Idade mín.',
                            prefixIcon: Icon(Icons.trending_up),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _maxAgeCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Idade máx.',
                            prefixIcon: Icon(Icons.trending_down),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _limitSearchCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Limite de resultados',
                      prefixIcon: Icon(Icons.filter_list),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    title: const Text('Busca insensível a maiúsculas/minúsculas'),
                    subtitle: const Text('"Ana" encontrará "ana", "ANA", etc.'),
                    value: _caseInsensitive,
                    onChanged: (value) {
                      setModalState(() {
                        _caseInsensitive = value ?? true;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _clearFilters();
                Navigator.of(context).pop();
              },
              child: const Text('Limpar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                if (_nameCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nome é obrigatório')),
                  );
                  return;
                }
                _applyFilters();
                Navigator.of(context).pop();
              },
              child: const Text('Buscar'),
            ),
          ],
        ),
      ),
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
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: c.products.isEmpty
                        ? const Center(child: Text('Sem itens neste carrinho.'))
                        : ListView.separated(
                            itemCount: c.products.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final p = c.products[i];
                              return ListTile(
                                dense: true,
                                title: Text(p.title),
                                subtitle: Text(
                                    '${p.quantity} × ${p.price} = ${p.total}'),
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
          onPressed:
              currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
        ),
        Text('Página $currentPage de $totalPages'),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: currentPage < totalPages
              ? () => onPageChanged(currentPage + 1)
              : null,
        ),
      ],
    );
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
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 16)),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _loading ? null : _showSearchModal,
                  icon: const Icon(Icons.filter_alt),
                  label: const Text('Busca Combinada'),
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 16)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                const Text("Ordenar usuários por: "),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _sortOption,
                  items: const [
                    DropdownMenuItem(
                        value: 'ID Crescente', child: Text('ID Crescente')),
                    DropdownMenuItem(
                        value: 'ID Decrescente', child: Text('ID Decrescente')),
                    DropdownMenuItem(
                        value: 'Nome Crescente', child: Text('Nome Crescente')),
                    DropdownMenuItem(
                        value: 'Nome Decrescente',
                        child: Text('Nome Decrescente')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _sortOption = v);
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                const Text("Ordenar carrinhos por: "),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _cartSortOption,
                  items: const [
                    DropdownMenuItem(
                        value: 'ID Crescente', child: Text('ID Crescente')),
                    DropdownMenuItem(
                        value: 'ID Decrescente', child: Text('ID Decrescente')),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _cartSortOption = v);
                  },
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
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                _buildPaginationControls(
                  currentPage: _usersPage,
                  totalItems: _totalUsers,
                  onPageChanged: _navigateUsers,
                ),
                const SizedBox(height: 8),
                if (_users.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Nenhum usuário encontrado.'),
                    ),
                  )
                else
                  ..._users.map((u) => Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                u.image != null ? NetworkImage(u.image!) : null,
                            child: u.image == null
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(u.fullName),
                          subtitle: Text('@${u.username} • ${u.email}'),
                          trailing: Text('#${u.id}'),
                        ),
                      )),
                const SizedBox(height: 16),
                const Text('Carrinhos',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                _buildPaginationControls(
                  currentPage: _cartsPage,
                  totalItems: _totalCarts,
                  onPageChanged: _navigateCarts,
                ),
                const SizedBox(height: 8),
                if (_carts.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('Nenhum carrinho encontrado.'),
                    ),
                  )
                else
                  ..._carts.map((c) => Card(
                        child: ListTile(
                          onTap: () => _openCart(c),
                          title: Text('Cart #${c.id} • User ${c.userId}'),
                          subtitle: Text(
                              '${c.totalProducts} prod. / ${c.totalQuantity} itens • total: ${c.total} (desc: ${c.discountedTotal})'),
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
