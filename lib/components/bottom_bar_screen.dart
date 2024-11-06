import 'package:bottom_bar_with_sheet/bottom_bar_with_sheet.dart';
import 'package:flutter/material.dart';

class BottomBarScreen extends StatefulWidget {
  const BottomBarScreen({super.key, required this.body, required this.actionWidget});
  final Widget body;
  final Widget actionWidget;

  @override
  State<BottomBarScreen> createState() => _BottomBarScreenState();
}

class _BottomBarScreenState extends State<BottomBarScreen> {
  final _bottomBarController = BottomBarWithSheetController(initialIndex: 0);
  
    @override
  void initState() {
    _bottomBarController.stream.listen((opened) {
      debugPrint('Bottom bar ${opened ? 'opened' : 'closed'}');
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.body,
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: BottomBarWithSheet(
                    controller: _bottomBarController,
                    bottomBarTheme: const BottomBarTheme(
                      decoration: BoxDecoration(color: Colors.white),
                      itemIconColor: Colors.grey,
                    ),
                    items: const [
                      BottomBarWithSheetItem(icon: Icons.people),
                      BottomBarWithSheetItem(icon: Icons.favorite),
                    ],
                    sheetChild: widget.actionWidget,
                  ),
        )
      ],
    );
  }
}