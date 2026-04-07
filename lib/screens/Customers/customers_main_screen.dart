import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:p_a_jewerly/providers/customer_provider.dart';
import 'package:p_a_jewerly/theme/app_theme.dart';
import 'package:p_a_jewerly/widgets/loading_overlay.dart';

class CustomerMainScreen extends StatefulWidget {
  const CustomerMainScreen({super.key});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().fetchCustomers();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _phoneController.clear();
    _formKey.currentState?.reset();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    return Consumer<CustomerProvider>(
      builder: (context, customerProvider, _) {
        return Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  const CustomerHeader(),
                  SizedBox(
                    height: isPortrait
                        ? screenHeight * 0.55
                        : screenHeight * 0.7,
                    child: customerProvider.isLoading && customerProvider.customers.isEmpty
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryGold,
                            ),
                          )
                        : customerProvider.error != null
                            ? AppErrorWidget(
                                message: customerProvider.error!,
                                onRetry: () => customerProvider.fetchCustomers(),
                              )
                            : customerProvider.customers.isEmpty
                                ? Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.people_outline,
                                          size: 64,
                                          color: AppTheme.primaryGold.withOpacity(0.5),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No customers yet',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: AppTheme.subtleText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(16),
                                    itemCount: customerProvider.customers.length,
                                    itemBuilder: (_, index) {
                                      return _CustomerItem(
                                        customer: customerProvider.customers[index],
                                        onDelete: () {
                                          customerProvider.deleteCustomer(
                                              customerProvider.customers[index].id);
                                        },
                                      );
                                    },
                                  ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: CreateUser(
                formKey: _formKey,
                nameController: _nameController,
                emailController: _emailController,
                phoneController: _phoneController,
                onClear: _clearForm,
                isPortrait: isPortrait,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CustomerItem extends StatelessWidget {
  final dynamic customer;
  final VoidCallback onDelete;

  const _CustomerItem({
    required this.customer,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      crossAxisEndOffset: 0.2,
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onDelete();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Customer deleted'),
              backgroundColor: AppTheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
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
            Icon(Icons.edit, color: Colors.white),
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
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: AppTheme.goldBorderDecoration(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryGold.withOpacity(0.2),
                radius: 24,
                child: Text(
                  customer.name[0].toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.deepPurple,
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
                      customer.name ?? 'Unknown',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppTheme.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone, size: 14, color: AppTheme.subtleText),
                        const SizedBox(width: 4),
                        Text(
                          customer.phone ?? 'No phone',
                          style: TextStyle(color: AppTheme.subtleText, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.email_outlined, size: 14, color: AppTheme.subtleText),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            customer.email ?? 'No email',
                            style: TextStyle(color: AppTheme.subtleText, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
      height: 100,
      decoration: AppTheme.gradientDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 36, color: AppTheme.primaryGold),
          const SizedBox(width: 12),
          const Text(
            'Customers',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontFamily: 'PlayfairDisplay',
            ),
          ),
        ],
      ),
    );
  }
}

class CreateUser extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final VoidCallback onClear;
  final bool isPortrait;

  const CreateUser({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.onClear,
    required this.isPortrait,
  });

  @override
  State<CreateUser> createState() => _CreateUserState();
}

class _CreateUserState extends State<CreateUser> {
  bool _validateEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool _validatePhone(String phone) {
    return RegExp(r'^\d{8,15}$').hasMatch(phone);
  }

  Future<void> _saveCustomer() async {
    if (!widget.formKey.currentState!.validate()) {
      return;
    }

    final customerProvider = context.read<CustomerProvider>();

    final success = await customerProvider.createCustomer({
      'name': widget.nameController.text.trim(),
      'email': widget.emailController.text.trim(),
      'phone': widget.phoneController.text.trim(),
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Customer created successfully'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      widget.onClear();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(customerProvider.error ?? 'Failed to create customer'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth > 800 ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.deepPurple.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Form(
        key: widget.formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add New Customer',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkText,
                fontFamily: 'PlayfairDisplay',
              ),
            ),
            const SizedBox(height: 16),
            if (widget.isPortrait && screenWidth > 600)
              Row(
                children: [
                  Expanded(child: _buildNameField()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildEmailField()),
                ],
              )
            else
              _buildNameField(),
            if (!widget.isPortrait || screenWidth <= 600) ...[
              const SizedBox(height: 12),
              _buildEmailField(),
            ],
            const SizedBox(height: 12),
            _buildPhoneField(),
            const SizedBox(height: 16),
            Consumer<CustomerProvider>(
              builder: (context, provider, _) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: provider.isLoading ? null : _saveCustomer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGold,
                      foregroundColor: AppTheme.darkText,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: provider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.darkText,
                            ),
                          )
                        : const Text(
                            'Save Customer',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: widget.nameController,
      autocorrect: false,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        labelText: 'Name',
        prefixIcon: const Icon(Icons.person_outline),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Name is required';
        }
        if (value.trim().length < 2) {
          return 'Name must be at least 2 characters';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: widget.emailController,
      autocorrect: false,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'Email',
        prefixIcon: const Icon(Icons.email_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Email is required';
        }
        if (!_validateEmail(value.trim())) {
          return 'Please enter a valid email';
        }
        return null;
      },
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: widget.phoneController,
      autocorrect: false,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        labelText: 'Phone',
        prefixIcon: const Icon(Icons.phone_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Phone is required';
        }
        if (!_validatePhone(value.trim())) {
          return 'Please enter a valid phone (8-15 digits)';
        }
        return null;
      },
    );
  }
}