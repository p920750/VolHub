import 'package:flutter/material.dart';

class AppOpeningPage extends StatefulWidget {
  const AppOpeningPage({super.key});

  @override
  State<AppOpeningPage> createState() => _AppOpeningPageState();
}

class _AppOpeningPageState extends State<AppOpeningPage>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _iconController;

  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<Offset> _logoRubberSlide;

  late Animation<double> _iconFade;
  late Animation<double> _iconScale;
  late Animation<double> _iconRotate;
  late Animation<Offset> _iconArcSlide;

  @override
  void initState() {
    super.initState();

    /// LOGO CONTROLLER (SLOW RUBBER BAND)
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _logoFade = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    );

    _logoScale = Tween<double>(
      begin: 0.65,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOut));

    /// Rubber-band vertical motion
    _logoRubberSlide =
        TweenSequence<Offset>([
          // Come from bottom
          TweenSequenceItem(
            tween: Tween(begin: const Offset(0, 0.35), end: Offset.zero),
            weight: 35,
          ),
          // Stretch upward (rubber pull)
          TweenSequenceItem(
            tween: Tween(begin: Offset.zero, end: const Offset(0, -0.28)),
            weight: 35,
          ),
          // Snap back to original position
          TweenSequenceItem(
            tween: Tween(begin: const Offset(0, -0.28), end: Offset.zero),
            weight: 30,
          ),
        ]).animate(
          CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
        );

    /// ICON CONTROLLER (ROTATION + ARC)
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3800),
    );

    _iconFade = CurvedAnimation(parent: _iconController, curve: Curves.easeIn);

    _iconScale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeOutBack),
    );

    /// Slow full rotation (360°)
    _iconRotate = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeInOut),
      ),
    );

    /// Long arc motion
    _iconArcSlide =
        TweenSequence<Offset>([
          TweenSequenceItem(
            tween: Tween(begin: Offset.zero, end: const Offset(0.45, -0.25)),
            weight: 50,
          ),
          TweenSequenceItem(
            tween: Tween(begin: const Offset(0.45, -0.25), end: Offset.zero),
            weight: 50,
          ),
        ]).animate(
          CurvedAnimation(
            parent: _iconController,
            curve: const Interval(0.45, 1.0, curve: Curves.easeInOut),
          ),
        );

    /// PLAY SEQUENCE
    _logoController.forward();

    Future.delayed(const Duration(milliseconds: 1800), () {
  _iconController.forward();
});


    Future.delayed(const Duration(seconds: 15), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFD91A46), Color(0xFF3C0A6A)],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// ICON (ROTATE → ARC)
            FadeTransition(
              opacity: _iconFade,
              child: SlideTransition(
                position: _iconArcSlide,
                child: RotationTransition(
                  turns: _iconRotate,
                  child: ScaleTransition(
                    scale: _iconScale,
                    child: Image.asset('assets/icons/icon_1.png', width: 150),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 50),

            /// LOGO (RUBBER BAND)
            FadeTransition(
              opacity: _logoFade,
              child: SlideTransition(
                position: _logoRubberSlide,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: Image.asset('assets/images/logo_1.jpeg', width: 300),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
