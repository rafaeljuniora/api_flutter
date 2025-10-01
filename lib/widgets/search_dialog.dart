import 'package:flutter/material.dart';
import '../models/search_parameters.dart';

/// Diálogo para configuração de busca combinada
class SearchDialog extends StatefulWidget {
  final SearchParameters initialParams;

  const SearchDialog({
    super.key,
    required this.initialParams,
  });

  @override
  State<SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<SearchDialog> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _minAgeController;
  late TextEditingController _maxAgeController;
  late TextEditingController _limitController;
  
  String? _selectedGender;
  bool _caseInsensitive = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialParams.nameQuery ?? '');
    _emailController = TextEditingController(text: widget.initialParams.emailQuery ?? '');
    _minAgeController = TextEditingController(text: widget.initialParams.minAge?.toString() ?? '');
    _maxAgeController = TextEditingController(text: widget.initialParams.maxAge?.toString() ?? '');
    _limitController = TextEditingController(text: widget.initialParams.limit.toString());
    _selectedGender = widget.initialParams.gender;
    _caseInsensitive = widget.initialParams.caseInsensitive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _minAgeController.dispose();
    _maxAgeController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  SearchParameters _buildSearchParameters() {
    return SearchParameters(
      nameQuery: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
      emailQuery: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
      gender: _selectedGender,
      minAge: int.tryParse(_minAgeController.text.trim()),
      maxAge: int.tryParse(_maxAgeController.text.trim()),
      limit: int.tryParse(_limitController.text.trim()) ?? 10,
      caseInsensitive: _caseInsensitive,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Busca Combinada'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Campo de busca por nome
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome (contém)',
                hintText: 'Ex: ana',
                prefixIcon: Icon(Icons.person_search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Campo de busca por email
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email (contém)',
                hintText: 'Ex: gmail',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Seletor de gênero
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: const InputDecoration(
                labelText: 'Gênero',
                prefixIcon: Icon(Icons.wc),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Todos')),
                DropdownMenuItem(value: 'male', child: Text('Masculino')),
                DropdownMenuItem(value: 'female', child: Text('Feminino')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedGender = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Campos de idade
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minAgeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Idade mín.',
                      hintText: '18',
                      prefixIcon: Icon(Icons.trending_up),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _maxAgeController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Idade máx.',
                      hintText: '65',
                      prefixIcon: Icon(Icons.trending_down),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Campo de limite
            TextField(
              controller: _limitController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Limite de resultados',
                hintText: '10',
                prefixIcon: Icon(Icons.numbers),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Checkbox para busca case-insensitive
            CheckboxListTile(
              title: const Text('Busca insensível a maiúsculas/minúsculas'),
              subtitle: const Text('"Ana" encontrará "ana", "ANA", etc.'),
              value: _caseInsensitive,
              onChanged: (value) {
                setState(() {
                  _caseInsensitive = value ?? true;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Limpar todos os campos
            setState(() {
              _nameController.clear();
              _emailController.clear();
              _minAgeController.clear();
              _maxAgeController.clear();
              _limitController.text = '10';
              _selectedGender = null;
              _caseInsensitive = true;
            });
          },
          child: const Text('Limpar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final params = _buildSearchParameters();
            Navigator.of(context).pop(params);
          },
          child: const Text('Buscar'),
        ),
      ],
    );
  }
}
