import 'package:flutter/material.dart';
import 'package:trackizer/view/main_tab/main_tab_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _textFade;
  late final Animation<double> _glowFade;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    // Logo fades + scales in: 0% → 55%
    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );

    _logoScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    // Text fades in: 45% → 100%
    _textFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 1.0, curve: Curves.easeIn),
    );

    // Glow pulses in alongside logo
    _glowFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _controller.forward();

    // After 2.5s total → fade out → go home
    Future.delayed(const Duration(milliseconds: 2500), _goHome);
  }

  Future<void> _goHome() async {
    if (!mounted) return;
    await _controller.reverse(from: 1.0);
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: animation,
          child: const MainTabView(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      body: Stack(
        children: [
          // ── Background glow ──────────────────────────────────────────────
          Positioned(
            top: size.height * 0.25,
            left: size.width / 2 - 180,
            child: AnimatedBuilder(
              animation: _glowFade,
              builder: (_, __) => Opacity(
                opacity: _glowFade.value * 0.30,
                child: Container(
                  width: 360,
                  height: 360,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0xFF7B61FF), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Centre content ───────────────────────────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) => FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          "assets/icon/app_icon.png",
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // App name
                FadeTransition(
                  opacity: _textFade,
                  child: const Text(
                    'Expense Tracker',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 6),

                // Subtitle
                FadeTransition(
                  opacity: _textFade,
                  child: Text(
                    'Your money, your rules.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.40),
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom pulse bar ─────────────────────────────────────────────
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _textFade,
              child: Center(
                child: SizedBox(
                  width: 100,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white.withOpacity(0.07),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF7B61FF),
                      ),
                      minHeight: 2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Logo widget ────────────────────────────────────────────────────────────────
class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF9B84FF), Color(0xFF5B3FD6)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7B61FF).withOpacity(0.50),
            blurRadius: 40,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: const Center(
        child: CustomPaint(
          size: Size(46, 46),
          painter: _ChartPainter(),
        ),
      ),
    );
  }
}

// ── Chart icon painter ─────────────────────────────────────────────────────────
class _ChartPainter extends CustomPainter {
  const _ChartPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Trending-up line
    final path = Path()
      ..moveTo(0, size.height * 0.75)
      ..lineTo(size.width * 0.28, size.height * 0.48)
      ..lineTo(size.width * 0.52, size.height * 0.63)
      ..lineTo(size.width * 0.76, size.height * 0.22)
      ..lineTo(size.width, size.height * 0.12);

    canvas.drawPath(path, stroke);

    // Arrow tip (top-right)
    canvas.drawLine(
      Offset(size.width * 0.76, size.height * 0.12),
      Offset(size.width, size.height * 0.12),
      stroke,
    );
    canvas.drawLine(
      Offset(size.width, size.height * 0.12),
      Offset(size.width, size.height * 0.36),
      stroke,
    );

    // Node dots
    final dot = Paint()
      ..color = Colors.white.withOpacity(0.75)
      ..style = PaintingStyle.fill;

    for (final pt in [
      Offset(0, size.height * 0.75),
      Offset(size.width * 0.28, size.height * 0.48),
      Offset(size.width * 0.52, size.height * 0.63),
      Offset(size.width * 0.76, size.height * 0.22),
    ]) {
      canvas.drawCircle(pt, 3.0, dot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}