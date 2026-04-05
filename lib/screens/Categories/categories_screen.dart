import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:p_a_jewerly/providers/category_provider.dart';
import 'package:p_a_jewerly/models/category_model.dart';
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
    showDialog(context: context, builder: (_) => _buildDialog(category));
  }

  Widget _buildDialog(CategoryModel? category) {
    final categories = context.watch<CategoryProvider>().categories;
    return AlertDialog(
      title: Text(category == null ? 'Add Category' : 'Edit Category'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryNumberController,
                decoration: const InputDecoration(
                  labelText: 'Category Number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _parentCategoryId == 0 && categories.isNotEmpty ? categories.first.id : _parentCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Parent Category',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: 0, child: Text('None (Root)')),
                  ...categories.where((c) => c.id != category?.id).map((c) {
                    return DropdownMenuItem(value: c.id, child: Text(c.description ?? 'Category ${c.id}'));
                  }),
                ],
                onChanged: (value) => _parentCategoryId = value ?? 0,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _extraInfoController,
                decoration: const InputDecoration(
                  labelText: 'Extra Information',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveCategory,
          child: const Text('Save'),
        ),
      ],
    );
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

  void _confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Category'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<CategoryProvider>().deleteCategory(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        backgroundColor: Colors.amber[700],
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.categories.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null) {
            return AppErrorWidget(
              message: provider.error!,
              onRetry: () => provider.fetchCategories(),
            );
          }
          if (provider.categories.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No categories yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
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
                    backgroundColor: category.idParentCategory == 0 ? Colors.amber[100] : Colors.blue[100],
                    child: Icon(category.idParentCategory == 0 ? Icons.folder : Icons.subdirectory_arrow_right),
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
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _openDialog(category: category),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _confirmDelete(category.id),
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
        backgroundColor: Colors.amber[700],
      ),
    );
  }
}
