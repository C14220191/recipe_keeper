import 'package:flutter/material.dart';
import 'package:recipe_keeper/auth/auth_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GetStartedPage extends StatefulWidget {
  const GetStartedPage({super.key});

  @override
  State<GetStartedPage> createState() => _GetStartedPageState();
}

class _GetStartedPageState extends State<GetStartedPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 2000,
      ), // ← lebih lama = lebih smooth
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 2.5), // ← lebih jauh dari bawah
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut, // ← transisi lebih lembut
      ),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 4), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isFirstTime', false);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AuthGate()),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "My Recipe",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(height: 24),
                SlideTransition(
                  position: _offsetAnimation,
                  child: Image.network(
                    'https://cdn-icons-png.flaticon.com/512/2738/2738730.png',
                    height: 150,
                  ),
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(color: Colors.deepOrange),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
