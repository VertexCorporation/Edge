import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../widgets/background.dart';
import '../widgets/button.dart';
import '../widgets/input.dart';
import '../widgets/text.dart';
import '../services/auth.dart';

/// Login screen with Vertex branding
/// Features: geo background, glassmorphic card, gradient text, animated logo
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 24).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = _isLogin
        ? await _authService.signIn(
            _emailController.text,
            _passwordController.text,
          )
        : await _authService.createUser(
            _emailController.text,
            _passwordController.text,
            _nameController.text.isEmpty ? 'Kullanıcı' : _nameController.text,
          );

    if (!mounted) return;

    if (result.isSuccess) {
      // Navigation will be handled by auth state listener in app.dart
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = result.errorMessage;
      });
      _shakeController.forward(from: 0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text(result.errorMessage ?? 'Giriş hatası')),
            ],
          ),
          backgroundColor: VertexColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    return Scaffold(
      body: GeoBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // ─── Login Card ───
                        AnimatedBuilder(
                          animation: _shakeAnimation,
                          builder: (context, child) {
                            final _ =
                                (ui.PlatformDispatcher.instance.views.first.physicalSize.width > 0) ? 
                                  // Just a simple sine wave for shaking
                                  (1 - (_shakeController.value)) * 
                                  (1 - (_shakeController.value)) // decay
                                : 0.0;
                            // Actually, let's use a simpler sine wave based on value
                            final offset = _shakeController.value > 0 
                                ? (12 * (1 - _shakeController.value) * 
                                   math.sin(3.14159 * 6 * _shakeController.value))
                                : 0.0;
                            return Transform.translate(
                              offset: Offset(offset, 0),
                              child: child,
                            );
                          },
                          child: _buildLoginCard(brightness, isDark),
                        ),

                        const SizedBox(height: 24),

                        // ─── Footer ───
                        Text(
                          '© 2026 Vertex Corporation',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: VertexColors.textMuted(brightness)
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildLoginCard(Brightness brightness, bool isDark) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: VertexColors.glassBg(brightness),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: VertexColors.glassBorder(brightness),
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isLogin ? 'Giriş Yap' : 'Kayıt Ol',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? VertexColors.textMainDark
                        : VertexColors.textMainLight,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isLogin ? 'Vertex hesabınız ile devam edin' : 'Yeni bir hesap oluşturun',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: VertexColors.textMuted(brightness),
                  ),
                ),
                const SizedBox(height: 28),

                // Name input (only for Sign Up) with smooth animation
                AnimatedSize(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.fastOutSlowIn,
                  child: !_isLogin
                      ? Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: VertexInput(
                            label: 'Ad Soyad',
                            hint: 'Örn: Ahmet Yılmaz',
                            controller: _nameController,
                            prefixIcon: Icon(
                              Icons.person_outline_rounded,
                              size: 18,
                              color: VertexColors.textMuted(brightness),
                            ),
                            validator: (value) {
                              if (!_isLogin && (value == null || value.isEmpty)) {
                                return 'Ad Soyad gerekli';
                              }
                              return null;
                            },
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                // Email input
                VertexInput(
                  label: 'E-posta',
                  hint: 'isim@vertex.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icon(
                    Icons.mail_outline_rounded,
                    size: 18,
                    color: VertexColors.textMuted(brightness),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'E-posta adresi gerekli';
                    }
                    if (!value.contains('@')) {
                      return 'Geçerli bir e-posta adresi girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password input
                VertexInput(
                  label: 'Şifre',
                  hint: '••••••••',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  prefixIcon: Icon(
                    Icons.lock_outline_rounded,
                    size: 18,
                    color: VertexColors.textMuted(brightness),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                      color: VertexColors.textMuted(brightness),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Şifre gerekli';
                    }
                    return null;
                  },
                ),

                // Error message
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: VertexColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: VertexColors.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 16,
                          color: VertexColors.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: VertexColors.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // Login/Register button
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.0, 0.2),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: VertexButton(
                    key: ValueKey<bool>(_isLogin),
                    label: _isLogin ? 'Giriş Yap' : 'Kayıt Ol',
                    onPressed: _handleAuth,
                    isLoading: _isLoading,
                    width: double.infinity,
                    icon: _isLogin ? Icons.arrow_forward_rounded : Icons.person_add_rounded,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Toggle mode button
                Center(
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _isLogin = !_isLogin;
                        _errorMessage = null;
                      });
                    },
                    child: Text(
                      _isLogin 
                          ? 'Hesabınız yok mu? Kayıt Olun' 
                          : 'Zaten hesabınız var mı? Giriş Yapın',
                      style: GoogleFonts.inter(
                        color: VertexColors.primary(brightness),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
