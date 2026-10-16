import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:p_a_jewerly/models/customer_model.dart';
import 'package:p_a_jewerly/providers/customer_provider.dart';
import 'package:p_a_jewerly/theme/app_theme.dart';
import 'package:p_a_jewerly/widgets/base_screen.dart';
import 'package:p_a_jewerly/widgets/loading_overlay.dart';
import 'package:p_a_jewerly/widgets/paged_list_view.dart';

class CustomerMainScreen extends StatefulWidget {
  const CustomerMainScreen({super.key});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CustomerProvider>().fetchCustomers();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Create (existing == null) or edit (prefilled) in the same bottom sheet.
  void _openCustomerSheet({CustomerModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _CustomerFormSheet(
        existing: existing,
        onSave: (data) async {
          final provider = Provider.of<CustomerProvider>(context, listen: false);
          final ok = existing == null
              ? await provider.createCustomer(data)
              : await provider.updateCustomer(existing.id, data);
          if (!ok) {
            if (sheetContext.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                errorSnackBar(
                  provider.error ?? (existing == null
                      ? 'Failed to create customer'
                      : 'Failed to update customer'),
                ),
              );
            }
            return false;
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              successSnackBar(existing == null ? 'Customer created' : 'Customer updated'),
            );
          }
          return true;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CustomerProvider>(
      builder: (context, provider, _) {
        final query = _searchQuery.trim().toLowerCase();
        final customers = provider.customers.where((c) {
          if (query.isEmpty) return true;
          return c.name.toLowerCase().contains(query) ||
              c.email.toLowerCase().contains(query) ||
              c.phone.toLowerCase().contains(query);
        }).toList();

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openCustomerSheet(),
            backgroundColor: AppTheme.primaryGold,
            foregroundColor: AppTheme.textColor,
            icon: const Icon(Icons.person_add),
            label: const Text('Add Customer'),
          ),
          body: Column(
            children: [
              // A refresh failure with stale rows on screen keeps the list
              // visible and surfaces the failure as a banner instead.
              if (provider.error != null && provider.customers.isNotEmpty)
                ErrorBanner(
                  message: provider.error!,
                  onRetry: () => provider.fetchCustomers(),
                ),
              const CustomerHeader(),
              // Search by name, email or phone
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search customers…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                              _searchDebounce?.cancel();
                              provider.fetchCustomers(query: '');
                            },
                          ),
                    filled: true,
                    fillColor: AppTheme.surfaceColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  // Server-side search (backend `q` param), debounced so
                  // each keystroke doesn't fire a request.
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                    _searchDebounce?.cancel();
                    _searchDebounce = Timer(
                      const Duration(milliseconds: 400),
                      () => provider.fetchCustomers(query: value),
                    );
                  },
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => provider.fetchCustomers(),
                  child: _buildList(context, provider, customers),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildList(
    BuildContext context,
    CustomerProvider provider,
    List<CustomerModel> customers,
  ) {
    if (provider.isLoading && provider.customers.isEmpty) {
      return const SkeletonList(itemCount: 6);
    }
    if (provider.customers.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline,
        title: 'No customers yet',
        subtitle: 'Tap "Add Customer" to create your first one',
      );
    }
    if (customers.isEmpty) {
      return Center(
        child: Text(
          'No customers matching "$_searchQuery"',
          style: TextStyle(fontSize: 15, color: AppTheme.mutedText),
        ),
      );
    }
    return PagedListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      itemCount: customers.length,
      hasMore: provider.hasMore,
      isLoadingMore: provider.isLoadingMore,
      onLoadMore: () => provider.fetchCustomers(loadMore: true),
      onRefresh: () => provider.fetchCustomers(),
      itemBuilder: (context, index) {
        return _CustomerItem(
          key: ValueKey<int>(customers[index].id),
          customer: customers[index],
          onTap: () => _openCustomerSheet(existing: customers[index]),
          onDelete: () async {
            final ok = await provider.deleteCustomer(customers[index].id);
            if (!ok && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                errorSnackBar(provider.error ?? 'Failed to delete customer'),
              );
            }
          },
        );
      },
    );
  }
}

/// Swipe-delete confirmed + tap-to-edit list row
class _CustomerItem extends StatelessWidget {
  final CustomerModel customer;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CustomerItem({
    super.key,
    required this.customer,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey<int>(customer.id),
      crossAxisEndOffset: 0.2,
      confirmDismiss: (direction) async {
        if (direction != DismissDirection.endToStart) return false;
        return confirmDelete(context, customer.name, 'Customer');
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onDelete();
        }
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.success,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(width: 20),
            Icon(Icons.archive, color: Colors.white),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete, color: Colors.white),
            SizedBox(width: 20),
          ],
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.goldBorderDecoration(),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryGold.withOpacity(0.2),
                radius: 24,
                child: Text(
                  customer.name.isNotEmpty
                      ? customer.name[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textColor,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 14, color: AppTheme.mutedText),
                        const SizedBox(width: 4),
                        Text(
                          customer.phone.isNotEmpty ? customer.phone : 'No phone',
                          style: TextStyle(color: AppTheme.mutedText, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.email_outlined, size: 14, color: AppTheme.mutedText),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            customer.email.isNotEmpty ? customer.email : 'No email',
                            style: TextStyle(color: AppTheme.mutedText, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppTheme.mutedText),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomerHeader extends StatelessWidget {
  const CustomerHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 90,
      decoration: AppTheme.gradientDecoration(radius: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 36, color: AppTheme.primaryGold),
          const SizedBox(width: 12),
          Text(
            'Customers',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppTheme.textColor,
              fontFamily: 'PlayfairDisplay',
            ),
          ),
        ],
      ),
    );
  }
}

/// Create / edit customer form in a modal bottom sheet. The whole list page
/// used to pin this form permanently at the bottom, stealing half the screen;
/// now it only exists when the user asks for it.
class _CustomerFormSheet extends StatefulWidget {
  final CustomerModel? existing;
  /// Return true when the record saved (and the sheet should close).
  final Future<bool> Function(Map<String, dynamic> data) onSave;

  const _CustomerFormSheet({
    required this.existing,
    required this.onSave,
  });

  @override
  State<_CustomerFormSheet> createState() => _CustomerFormSheetState();
}

class _CustomerFormSheetState extends State<_CustomerFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  late final TextEditingController _postalCodeController;
  late final TextEditingController _countryController;
  bool _saving = false;

  static final _emailPattern = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _nameController = TextEditingController(text: c?.name ?? '');
    _emailController = TextEditingController(text: c?.email ?? '');
    _phoneController = TextEditingController(text: c?.phone ?? '');
    _addressController = TextEditingController(text: c?.address ?? '');
    _cityController = TextEditingController(text: c?.city ?? '');
    _postalCodeController = TextEditingController(text: c?.postalCode ?? '');
    _countryController = TextEditingController(text: c?.country ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final ok = await widget.onSave({
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
      'city': _cityController.text.trim(),
      'postalCode': _postalCodeController.text.trim(),
      'country': _countryController.text.trim(),
    });
    if (ok && mounted) Navigator.pop(context);
    // A failed save keeps the sheet open so the user can correct the input;
    // the snackbar came from the save callback.
    if (mounted) setState(() => _saving = false);
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: AppTheme.raisedColor,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Keyboard clearance for the scrollable form
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    widget.existing == null ? 'Add Customer' : 'Edit Customer',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textColor,
                      fontFamily: 'PlayfairDisplay',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: _decoration('Name *', Icons.person_outline),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Name is required';
                    if (value.trim().length < 2) return 'Name must be at least 2 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  autocorrect: false,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _decoration('Email *', Icons.email_outlined),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Email is required';
                    if (!_emailPattern.hasMatch(value.trim())) return 'Please enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _decoration('Phone *', Icons.phone_outlined),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Phone is required';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  decoration: _decoration('Address', Icons.location_on_outlined),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cityController,
                        decoration: _decoration('City', Icons.location_city),
                        textCapitalization: TextCapitalization.words,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _postalCodeController,
                        decoration: _decoration('Postal Code', Icons.local_post_office),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _countryController,
                  decoration: _decoration('Country', Icons.public),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGold,
                        foregroundColor: AppTheme.textColor,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.check),
                      label: Text(widget.existing == null ? 'Create' : 'Save Changes'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}