import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:p_a_jewerly/providers/category_provider.dart';
import 'package:p_a_jewerly/models/category_model.dart';
import 'package:p_a_jewerly/widgets/base_screen.dart';
import 'package:p_a_jewerly/widgets/loading_overlay.dart';

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
    ));
  }

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;

    final category = CategoryModel(
      id: _editingId ?? 0,
      idParentCategory: _parentCategoryId,
      description: _descriptionController.text.trim(),
      categoryNumber: _categoryNumberController.text.trim(),
      extraInformation: _extraInfoController.text.trim(),
    );

    final provider = context.read<CategoryProvider>();
    bool success;

    if (_editingId == null) {
      success = await provider.createCategory(category);
    } else {
      success = await provider.updateCategory(category);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        success
            ? successSnackBar('Category ${_editingId == null ? 'created' : 'updated'}')
            : errorSnackBar(provider.error ?? 'Operation failed'),
      );
    }
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
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
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
                        : Colors.blue[100],
                    child: Icon(
                      category.idParentCategory == 0 ? Icons.folder : Icons.subdirectory_arrow_right,
                      color: category.idParentCategory == 0 ? const Color(0xFFD4AF37) : Colors.blue,
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
                        color: Colors.red,
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

class _CategoryDialog extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController descriptionController;
  final TextEditingController categoryNumberController;
  final TextEditingController extraInfoController;
  final int parentCategoryId;
  final int? editingId;
  final VoidCallback onSave;
  final List<CategoryModel> allCategories;

  const _CategoryDialog({
    required this.formKey,
    required this.descriptionController,
    required this.categoryNumberController,
    required this.extraInfoController,
    required this.parentCategoryId,
    required this.editingId,
    required this.onSave,
    required this.allCategories,
  });

  @override
  Widget build(BuildContext context) {
    int localParentId = parentCategoryId;
    return AlertDialog(
      title: Text(editingId == null ? 'Add Category' : 'Edit Category'),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: categoryNumberController,
                decoration: const InputDecoration(labelText: 'Category Number', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              StatefulBuilder(
                builder: (context, setState) => DropdownButtonFormField<int>(
                  value: localParentId == 0 && allCategories.isNotEmpty
                      ? allCategories.first.id
                      : localParentId,
                  decoration: const InputDecoration(labelText: 'Parent Category', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(value: 0, child: Text('None (Root)')),
                    ...allCategories.where((c) => c.id != editingId).map((c) {
                      return DropdownMenuItem(value: c.id, child: Text(c.description ?? 'Category ${c.id}'));
                    }),
                  ],
                  onChanged: (value) => localParentId = value ?? 0,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: extraInfoController,
                decoration: const InputDecoration(labelText: 'Extra Information', border: OutlineInputBorder()),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: onSave, child: const Text('Save')),
      ],
    );
  }
}
