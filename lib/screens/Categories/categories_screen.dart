import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:p_a_jewerly/providers/category_provider.dart';
import 'package:p_a_jewerly/models/category_model.dart';
import 'package:p_a_jewerly/widgets/base_screen.dart';
import 'package:p_a_jewerly/widgets/loading_overlay.dart';
import 'package:p_a_jewerly/theme/app_theme.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _categoryNumberController = TextEditingController();
  final _extraInfoController = TextEditingController();
  int? _editingId;
  int _parentCategoryId = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CategoryProvider>().fetchCategories();
    });
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _categoryNumberController.dispose();
    _extraInfoController.dispose();
    super.dispose();
  }

  void _openDialog({CategoryModel? category}) {
    _editingId = category?.id;
    _descriptionController.text = category?.description ?? '';
    _categoryNumberController.text = category?.categoryNumber ?? '';
    _extraInfoController.text = category?.extraInformation ?? '';
    _parentCategoryId = category?.idParentCategory ?? 0;
    showDialog(context: context, builder: (_) => _CategoryDialog(
      formKey: _formKey,
      descriptionController: _descriptionController,
      categoryNumberController: _categoryNumberController,
      extraInfoController: _extraInfoController,
      parentCategoryId: _parentCategoryId,
      editingId: _editingId,
      onSave: _saveCategory,
      allCategories: context.read<CategoryProvider>().categories,
      onParentChanged: (value) => _parentCategoryId = value ?? 0,
    ));
  }

  /// Saves and reports the outcome only — the dialog owns the saving state
  /// and pops itself on success (see _CategoryDialog.onSave).
  Future<bool> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return false;

    final category = CategoryModel(
      id: _editingId ?? 0,
      idParentCategory: _parentCategoryId,
      description: _descriptionController.text.trim(),
      categoryNumber: _categoryNumberController.text.trim(),
      extraInformation: _extraInfoController.text.trim(),
    );

    final provider = context.read<CategoryProvider>();
    final success = _editingId == null
        ? await provider.createCategory(category)
        : await provider.updateCategory(category);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        errorSnackBar(provider.error ?? 'Operation failed'),
      );
    }
    return success;
  }

  void _confirmDelete(int id, String name) async {
    final confirmed = await confirmDelete(context, name, 'Category');
    if (confirmed && mounted) {
      context.read<CategoryProvider>().deleteCategory(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
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
      body: Consumer<CategoryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.categories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: AppTheme.error),
                  const SizedBox(height: 16),
                  Text(provider.error!, textAlign: TextAlign.center),
                  ElevatedButton(
                    onPressed: () => provider.fetchCategories(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          if (provider.categories.isEmpty) {
            return const EmptyState(
              icon: Icons.category_outlined,
              title: 'No categories yet',
              subtitle: 'Tap + to add your first category',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.categories.length,
            itemBuilder: (context, index) {
              final category = provider.categories[index];
              final parentCategory = provider.categories.firstWhere(
                (c) => c.id == category.idParentCategory,
                orElse: () => CategoryModel(id: 0, idParentCategory: 0, description: 'Root'),
              );
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: category.idParentCategory == 0
                        ? const Color(0xFFD4AF37).withOpacity(0.2)
                        : AppTheme.lightPurple.withOpacity(0.2),
                    child: Icon(
                      category.idParentCategory == 0 ? Icons.folder : Icons.subdirectory_arrow_right,
                      color: category.idParentCategory == 0 ? const Color(0xFFD4AF37) : AppTheme.lightPurple,
                    ),
                  ),
                  title: Text(category.description ?? 'Category ${category.id}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (category.categoryNumber != null) Text('Code: ${category.categoryNumber}'),
                      Text('Parent: ${parentCategory.description ?? 'Root'}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit), onPressed: () => _openDialog(category: category)),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _confirmDelete(category.id, category.description ?? ''),
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
        label: const Text('New Category'),
        backgroundColor: const Color(0xFFD4AF37),
      ),
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController descriptionController;
  final TextEditingController categoryNumberController;
  final TextEditingController extraInfoController;
  final int parentCategoryId;
  final int? editingId;

  /// Runs the save and reports the outcome. The dialog stays open (with its
  /// buttons disabled) until the future settles, and pops itself on success —
  /// failed requests return [false] and keep the user's edits on screen.
  final Future<bool> Function() onSave;
  final List<CategoryModel> allCategories;
  // Selection is reported to the owner screen (which outlives rebuilds) —
  // storing it in a build-local previously made dropdown choices vanish.
  final ValueChanged<int?> onParentChanged;

  const _CategoryDialog({
    required this.formKey,
    required this.descriptionController,
    required this.categoryNumberController,
    required this.extraInfoController,
    required this.parentCategoryId,
    required this.editingId,
    required this.onSave,
    required this.allCategories,
    required this.onParentChanged,
  });

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final ok = await widget.onSave();
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        successSnackBar(
            'Category ${widget.editingId == null ? 'created' : 'updated'}'),
      );
      Navigator.pop(context);
    } else {
      // Snackbar for the failure was shown by the save callback.
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final widget = this.widget;
    return AlertDialog(
      title: Text(widget.editingId == null ? 'Add Category' : 'Edit Category'),
      content: SingleChildScrollView(
        child: Form(
          key: widget.formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: widget.descriptionController,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: widget.categoryNumberController,
                decoration: const InputDecoration(labelText: 'Category Number', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: widget.parentCategoryId,
                decoration: const InputDecoration(labelText: 'Parent Category', border: OutlineInputBorder()),
                items: [
                  const DropdownMenuItem(value: 0, child: Text('None (Root)')),
                  ...widget.allCategories.where((c) => c.id != widget.editingId).map((c) {
                    return DropdownMenuItem(value: c.id, child: Text(c.description ?? 'Category ${c.id}'));
                  }),
                ],
                onChanged: (value) => widget.onParentChanged(value ?? 0),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: widget.extraInfoController,
                decoration: const InputDecoration(labelText: 'Extra Information', border: OutlineInputBorder()),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}
