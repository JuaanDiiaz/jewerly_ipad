import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:p_a_jewerly/providers/customer_provider.dart';
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
                  CustomerHeader(),
                  SizedBox(
                    height: isPortrait
                        ? screenHeight * 0.55
                        : screenHeight * 0.7,
                    child: customerProvider.isLoading && customerProvider.customers.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : customerProvider.error != null
                            ? AppErrorWidget(
                                message: customerProvider.error!,
                                onRetry: () => customerProvider.fetchCustomers(),
                              )
                            : ListView.builder(
                                itemCount: customerProvider.customers.length,
                                itemBuilder: (_, index) {
                                  return _CustomerItem(
                                    customer: customerProvider.customers[index],
                                    onDelete: () {
                                      customerProvider.deleteCustomer(customerProvider.customers[index].id);
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
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  // Implement undo logic
                },
              ),
            ),
          );
        }
      },
      background: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.green,
          borderRadius: BorderRadius.circular(10),
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
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(width: 20),
            Icon(Icons.delete, color: Colors.white),
          ],
        ),
      ),
      child: Card(
        margin: const EdgeInsets.all(10),
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: Colors.amberAccent,
                radius: 20,
                child: Text(customer.name[0].toUpperCase()),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Text('Phone: ${customer.phone}'),
                    const SizedBox(height: 10),
                    Text('Email: ${customer.email}'),
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
      decoration: BoxDecoration(
        color: Colors.orangeAccent,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 40, color: Colors.white),
          SizedBox(width: 10),
          Text(
            'Customer Header',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
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
        successSnackBar('Customer created successfully'),
      );
      widget.onClear();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        errorSnackBar(customerProvider.error ?? 'Failed to create customer'),
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
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Form(
        key: widget.formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add a new customer',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            if (widget.isPortrait && screenWidth > 600)
              // Landscape-style layout in portrait for wider iPads
              Row(
                children: [
                  Expanded(child: _buildNameField()),
                  const SizedBox(width: 10),
                  Expanded(child: _buildEmailField()),
                ],
              )
            else
              _buildNameField(),
            if (!widget.isPortrait || screenWidth <= 600) ...[
              const SizedBox(height: 15),
              _buildEmailField(),
            ],
            const SizedBox(height: 15),
            _buildPhoneField(),
            const SizedBox(height: 15),
            Consumer<CustomerProvider>(
              builder: (context, provider, _) {
                return SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: provider.isLoading ? null : _saveCustomer,
                    child: provider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
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
      decoration: const InputDecoration(
        labelText: 'Name',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.person),
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
      decoration: const InputDecoration(
        labelText: 'Email',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.email),
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
      decoration: const InputDecoration(
        labelText: 'Phone',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.phone),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Phone is required';
        }
        if (!_validatePhone(value.trim())) {
          return 'Please enter a valid phone number (8-15 digits)';
        }
        return null;
      },
    );
  }
}
