import 'package:flutter/material.dart';
import 'package:p_a_jewerly/theme/app_theme.dart';

/// Reusable screen scaffold that handles loading, error, and empty states
class BaseScreen extends StatelessWidget {
  final String title;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final List<Widget>? actions;
  final Widget floatingActionButton;
  final Widget body;

  const BaseScreen({
    super.key,
    required this.title,
    required this.isLoading,
    this.error,
    this.onRetry,
    this.actions,
    this.floatingActionButton = const SizedBox.shrink(),
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        flexibleSpace: Container(
          decoration: AppTheme.gradientDecoration(),
        ),
        actions: actions,
      ),
      floatingActionButton: floatingActionButton,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const SkeletonList();
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppTheme.error),
              const SizedBox(height: 16),
              Text(
                'Oops! Something went wrong',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.error),
              ),
              const SizedBox(height: 8),
              Text(error!, style: TextStyle(color: AppTheme.mutedText), textAlign: TextAlign.center),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
              ],
            ],
          ),
        ),
      );
    }

    return body;
  }
}

/// Skeleton list with a pulsing opacity shimmer (no external package) that
/// hints at the card layout actually about to appear.
class SkeletonList extends StatefulWidget {
  final int itemCount;
  final double itemHeight;

  const SkeletonList({
    super.key,
    this.itemCount = 8,
    this.itemHeight = 84,
  });

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.35, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.itemCount,
      itemBuilder: (context, index) {
        return FadeTransition(
          opacity: _opacity,
          child: Container(
            height: widget.itemHeight,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.raisedColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.hairline,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 14,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.hairline,
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      const SizedBox(height: 10),
                      FractionallySizedBox(
                        widthFactor: 0.5,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppTheme.hairline,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Empty state placeholder widget
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppTheme.primaryGold.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 18, color: AppTheme.mutedText)),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(subtitle!, style: TextStyle(fontSize: 14, color: AppTheme.mutedText)),
          ],
          if (action != null) ...[
            const SizedBox(height: 16),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Reusable card container for list items
class ItemCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ItemCard({
    super.key,
    required this.child,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.goldBorderDecoration(),
      child: ListTile(
        onTap: onTap,
        leading: onEdit != null || onDelete != null
            ? null
            : Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.folder_outlined, color: AppTheme.primaryGold),
              ),
        title: child,
        trailing: (onEdit != null || onDelete != null)
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: onEdit,
                      color: AppTheme.mediumPurple,
                    ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: onDelete,
                      color: AppTheme.error,
                    ),
                ],
              )
            : null,
      ),
    );
  }
}

/// Reusable form dialog for CRUD operations
class FormDialog extends StatefulWidget {
  final String title;
  final String labelText;
  final String? initialValue;
  final String? hintText;
  final String saveLabel;
  final Function(String) onSave;

  const FormDialog({
    super.key,
    required this.title,
    required this.labelText,
    this.initialValue,
    this.hintText,
    this.saveLabel = 'Save',
    required this.onSave,
  });

  @override
  State<FormDialog> createState() => _FormDialogState();
}

class _FormDialogState extends State<FormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.gradientDecoration(radius: 12),
              child: Row(
                children: [
                  Icon(Icons.edit_outlined, color: AppTheme.primaryGold, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    widget.title,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: widget.labelText,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: widget.hintText,
                ),
                autofocus: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '${widget.labelText} is required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pop(context);
                      widget.onSave(_controller.text.trim());
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGold,
                    foregroundColor: AppTheme.textColor,
                  ),
                  child: Text(widget.saveLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Confirm delete dialog
Future<bool> confirmDelete(BuildContext context, String itemName, String itemType) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Delete $itemType'),
      content: Text('Are you sure you want to delete "$itemName"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return result ?? false;
}
