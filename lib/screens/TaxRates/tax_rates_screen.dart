import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:p_a_jewerly/providers/category_provider.dart';
import 'package:p_a_jewerly/providers/tax_rate_provider.dart';
import 'package:p_a_jewerly/models/category_model.dart';
import 'package:p_a_jewerly/models/tax_rate_model.dart';
import 'package:p_a_jewerly/widgets/base_screen.dart';
import 'package:p_a_jewerly/widgets/loading_overlay.dart';
import 'package:p_a_jewerly/theme/app_theme.dart';

/// Admin / Tax Rates — manages the per-category IVA rates applied at
/// checkout (IVA-exclusive pricing). Saving an active rate deactivates the
/// previous active rate of the same scope (default vs category), done
/// server-side. The backend's seed provides the default "IVA 16%" row.
class TaxRatesScreen extends StatefulWidget {
  const TaxRatesScreen({super.key});

  @override
  State<TaxRatesScreen> createState() => _TaxRatesScreenState();
}

class _TaxRatesScreenState extends State<TaxRatesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _percentController = TextEditingController();
  int? _editingId;
  // 0 is the sentinel for the fallback rate (TaxRate.categoryId == null).
  int _categoryId = 0;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TaxRateProvider>().fetchTaxRates();
      context.read<CategoryProvider>().fetchCategories();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _percentController.dispose();
    super.dispose();
  }

  void _openDialog({TaxRateModel? rate}) {
    _editingId = rate?.id;
    _nameController.text = rate?.name ?? '';
    // The API stores a fraction (0.16); the form speaks percent.
    _percentController.text =
        rate?.rate == null ? '' : ((rate!.rate! * 100).toStringAsFixed(2));
    _categoryId = rate?.categoryId ?? 0;
    _isActive = rate?.isActive ?? true;
    showDialog(context: context, builder: (_) => _buildDialog());
  }

  Future<bool> _saveRate() async {
    if (!_formKey.currentState!.validate()) return false;

    final provider = context.read<TaxRateProvider>();
    final percent = double.tryParse(_percentController.text.trim()) ?? -1;
    final rate = TaxRateModel(
      id: _editingId ?? 0,
      categoryId: _categoryId == 0 ? null : _categoryId,
      name: _nameController.text.trim(),
      rate: percent / 100,
      isActive: _isActive,
    );

    final success = _editingId == null
        ? await provider.createTaxRate(rate)
        : await provider.updateTaxRate(rate);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        errorSnackBar(provider.error ?? 'Operation failed'),
      );
    }
    return success; // the dialog (_buildDialog) owns popping on success
  }

  void _confirmDelete(int id, String name) async {
    final confirmed = await confirmDelete(context, name, 'Tax Rate');
    if (confirmed && mounted) {
      context.read<TaxRateProvider>().deleteTaxRate(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tax Rates'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2D1B4E), Color(0xFF4A3266)],
            ),
          ),
        ),
      ),
      body: Consumer<TaxRateProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.taxRates.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null && provider.taxRates.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppTheme.error),
                  const SizedBox(height: 16),
                  Text(provider.error!, textAlign: TextAlign.center),
                  ElevatedButton(
                    onPressed: () => provider.fetchTaxRates(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (provider.taxRates.isEmpty) {
            return const EmptyState(
              icon: Icons.percent_outlined,
              title: 'No tax rates yet',
              subtitle: 'Tap + to add your first rate',
            );
          }

          final categories = context.watch<CategoryProvider>().categories;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.taxRates.length,
            itemBuilder: (context, index) {
              final rate = provider.taxRates[index];
              final categoryLabel = rate.categoryId == null
                  ? 'Default (uncategorized products)'
                  : 'Category: ${categories
                      .firstWhere((c) => c.id == rate.categoryId,
                          orElse: () => CategoryModel(
                              id: rate.categoryId ?? 0,
                              idParentCategory: 0,
                              description: 'ID ${rate.categoryId}'))
                      .description}';
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: rate.isActive
                        ? AppTheme.primaryGold.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    child: Icon(
                      rate.isActive ? Icons.check_circle : Icons.block,
                      color: rate.isActive ? AppTheme.primaryGold : Colors.grey,
                    ),
                  ),
                  title: Text('${rate.name ?? 'Rate ${rate.id}'} — '
                      '${((rate.rate ?? 0) * 100).toStringAsFixed(2)}%'),
                  subtitle: Text(categoryLabel),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _openDialog(rate: rate)),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () =>
                            _confirmDelete(rate.id, rate.name ?? ''),
                        color: AppTheme.error,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openDialog(),
        icon: const Icon(Icons.add),
        label: const Text('New Tax Rate'),
        backgroundColor: AppTheme.primaryGold,
      ),
    );
  }

  Widget _buildDialog() {
    final categories = context.read<CategoryProvider>().categories;
    bool saving = false;
    return StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(_editingId == null ? 'New Tax Rate' : 'Edit Tax Rate'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                      labelText: 'Name (e.g. IVA 16%)',
                      border: OutlineInputBorder()),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _percentController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                      labelText: 'Rate (%)', border: OutlineInputBorder()),
                  validator: (value) {
                    final percent = double.tryParse(value?.trim() ?? '');
                    if (percent == null) return 'Enter a number';
                    if (percent <= 0 || percent > 100) {
                      return 'Between 0 and 100';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _categoryId,
                  decoration: const InputDecoration(
                      labelText: 'Applies to', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(
                        value: 0, child: Text('Default (uncategorized)')),
                    ...categories.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text(c.description ?? 'Category ${c.id}'),
                        )),
                  ],
                  onChanged: (value) => setState(() => _categoryId = value ?? 0),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Active'),
                  value: _isActive,
                  onChanged: (value) =>
                      setState(() => _isActive = value ?? true),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: saving ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: saving
                ? null
                : () async {
                    if (!_formKey.currentState!.validate()) return;
                    setState(() => saving = true);
                    final ok = await _saveRate();
                    if (!mounted) return;
                    if (ok) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        successSnackBar(_editingId == null
                            ? 'Tax rate created'
                            : 'Tax rate updated'),
                      );
                      Navigator.pop(context);
                    } else {
                      setState(() => saving = false);
                    }
                  },
            child: saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}