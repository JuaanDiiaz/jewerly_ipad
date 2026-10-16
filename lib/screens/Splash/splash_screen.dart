import 'dart:async';

import 'package:flutter/material.dart';

import 'package:p_a_jewerly/screens/home_screen.dart';
import 'package:p_a_jewerly/theme/app_theme.dart';

/// Branded launch screen: gold diamond over the purple gradient, subtle
/// pulse on the logo, then a fade into the main app. It is not loading
/// anything by itself (the providers warm up on the first screen's mount) —
/// it just covers the cold-start frame so the app doesn't land on an
/// unstyled window.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void initState() {
    super.initState();
    _pulse.repeat(reverse: true);
    Timer(const Duration(milliseconds: 1600), _enterApp);
  }

  void _enterApp() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(_FadePageRoute(
      builder: (_) => const HomeScreen(),
    ));
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkPurple,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.darkPurple, AppTheme.deepPurple, AppTheme.mediumPurple],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pulse ring + gold diamond logo
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, child) {
                        final t = Curves.easeOut.transform(_pulse.value);
                        return SizedBox(
                          width: 148,
                          height: 148,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Transform.scale(
                                scale: 1.0 + t * 0.35,
                                child: Container(
                                  width: 128,
                                  height: 128,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white
                                        .withOpacity((1 - t) * 0.08),
                                  ),
                                ),
                              ),
                              child!,
                            ],
                          ),
                        );
                      },
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryGold, AppTheme.secondaryGold],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryGold.withOpacity(0.45),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.diamond_outlined,
                          color: Colors.white,
                          size: 52,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'P&A Jewelry',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'PlayfairDisplay',
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Inventory Management',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 14,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  '1.0.0',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.35),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cross-fade route so the splash dissolves into the app instead of cutting.
class _FadePageRoute extends PageRouteBuilder {
  final WidgetBuilder builder;

  _FadePageRoute({required this.builder})
      : super(
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) =>
              builder(context),
        );

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    );
  }
}