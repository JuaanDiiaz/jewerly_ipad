import 'package:flutter/material.dart';
import 'package:p_a_jewerly/theme/app_theme.dart';

class MenuItem {
  final String title;
  final IconData icon;
  final Widget? screen;
  final List<MenuItem>? subItems;
  final bool isExpandable;

  const MenuItem({
    required this.title,
    required this.icon,
    this.screen,
    this.subItems,
    this.isExpandable = false,
  });
}

class ModernSidebar extends StatefulWidget {
  final List<MenuItem> items;
  final String title;
  final String? subtitle;
  final bool isCollapsed;
  final Function(bool)? onCollapsedChanged;
  final Function(Widget)? onItemSelected;

  const ModernSidebar({
    super.key,
    required this.items,
    this.title = 'P&A Jewelry',
    this.subtitle,
    this.isCollapsed = false,
    this.onCollapsedChanged,
    this.onItemSelected,
  });

  @override
  State<ModernSidebar> createState() => _ModernSidebarState();
}

class _ModernSidebarState extends State<ModernSidebar> with SingleTickerProviderStateMixin {
  final Set<int> _expandedItems = {};
  final Set<int> _hoveredItems = {};
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _isCollapsed = widget.isCollapsed;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _widthAnimation = Tween<double>(begin: 260, end: 72).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    if (_isCollapsed) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleCollapse() {
    setState(() {
      _isCollapsed = !_isCollapsed;
      if (_isCollapsed) {
        _animationController.forward();
        _expandedItems.clear();
      } else {
        _animationController.reverse();
      }
      widget.onCollapsedChanged?.call(_isCollapsed);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _widthAnimation,
      builder: (context, child) {
        return Container(
          width: _widthAnimation.value,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.deepPurple,
                AppTheme.mediumPurple,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.deepPurple.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(4, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: _buildMenuItems(),
                ),
              ),
              _buildFooter(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    final isCollapsed = _widthAnimation.value < 150;
    return Container(
      padding: EdgeInsets.all(isCollapsed ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryGold, AppTheme.secondaryGold],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGold.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.diamond_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'PlayfairDisplay',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.subtitle != null)
                        Text(
                          widget.subtitle!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMenuItems() {
    final widgets = <Widget>[];
    for (int i = 0; i < widget.items.length; i++) {
      widgets.add(_buildMenuItem(widget.items[i], i, 0));
    }
    return widgets;
  }

  Widget _buildMenuItem(MenuItem item, int index, int depth) {
    final isExpanded = _expandedItems.contains(index);
    final isHovered = _hoveredItems.contains(index);
    final isCollapsed = _widthAnimation.value < 150;
    final hasSubItems = item.subItems != null && item.subItems!.isNotEmpty;

    return Column(
      children: [
        MouseRegion(
          onEnter: (_) => setState(() => _hoveredItems.add(index)),
          onExit: (_) => setState(() => _hoveredItems.remove(index)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: EdgeInsets.only(
              left: depth * 8.0 + 8,
              right: 8,
              top: 4,
              bottom: 4,
            ),
            decoration: BoxDecoration(
              color: isHovered
                  ? Colors.white.withOpacity(0.15)
                  : (isExpanded ? Colors.white.withOpacity(0.1) : Colors.transparent),
              borderRadius: BorderRadius.circular(12),
              border: isExpanded
                  ? Border.all(color: AppTheme.primaryGold.withOpacity(0.3), width: 1)
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  if (hasSubItems && !isCollapsed) {
                    setState(() {
                      if (isExpanded) {
                        _expandedItems.remove(index);
                      } else {
                        _expandedItems.add(index);
                      }
                    });
                  } else if (item.screen != null) {
                    _navigateTo(item.screen!);
                  }
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCollapsed ? 12 : 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isExpanded
                              ? AppTheme.primaryGold.withOpacity(0.2)
                              : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          item.icon,
                          color: isExpanded ? AppTheme.primaryGold : Colors.white.withOpacity(0.8),
                          size: 20,
                        ),
                      ),
                      if (!isCollapsed) ...[
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            item.title,
                            style: TextStyle(
                              color: isExpanded ? Colors.white : Colors.white.withOpacity(0.85),
                              fontSize: 14,
                              fontWeight: isExpanded ? FontWeight.w600 : FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasSubItems)
                          AnimatedRotation(
                            turns: isExpanded ? 0.25 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.chevron_right,
                              color: Colors.white.withOpacity(0.5),
                              size: 20,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (isExpanded && !isCollapsed && hasSubItems)
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: Column(
              children: item.subItems!
                  .asMap()
                  .entries
                  .map((entry) => _buildMenuItem(entry.value, index * 1000 + entry.key, depth + 1))
                  .toList(),
            ),
          ),
      ],
    );
  }

  void _navigateTo(Widget screen) {
    widget.onItemSelected?.call(screen);
  }

  Widget _buildFooter() {
    final isCollapsed = _widthAnimation.value < 150;
    return Container(
      padding: EdgeInsets.all(isCollapsed ? 8 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isCollapsed)
            _buildFooterItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              onTap: () {},
            ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _toggleCollapse,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 8 : 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: isCollapsed ? MainAxisSize.min : MainAxisSize.max,
                children: [
                  Icon(
                    _isCollapsed ? Icons.chevron_right : Icons.chevron_left,
                    color: Colors.white.withOpacity(0.6),
                    size: 20,
                  ),
                  if (!isCollapsed) ...[
                    const SizedBox(width: 8),
                    Text(
                      'Collapse',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.6), size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}