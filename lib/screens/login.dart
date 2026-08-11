import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/colors.dart';
import '../widgets/button.dart';
import '../widgets/input.dart';
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
  bool _isLoadingGoogle = false;
  bool _isLoadingApple = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  late AnimationController _fillController;
  late Animation<double> _fillAnimation;

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

    _fillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fillAnimation = CurvedAnimation(
      parent: _fillController,
      curve: Curves.easeInOut,
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
    _fillController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    _fillController.forward();

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
      _fillController.reverse();
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
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFF101010),
      body: Stack(
        children: [
          // Background Blurs
          AnimatedBuilder(
            animation: _fillAnimation,
            builder: (context, child) {
              final fillValue = _fillAnimation.value;
              final topSize = 300.0 + (screenHeight * fillValue);
              final bottomSize = 400.0 + (screenHeight * fillValue);
              
              return Stack(
                children: [
                  // Top light blue blur
                  Positioned(
                    top: -150 - (fillValue * 100),
                    left: -100 - (fillValue * 100),
                    child: Container(
                      width: topSize,
                      height: topSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withValues(alpha: 0.15 + (fillValue * 0.85)),
                            blurRadius: 100 - (fillValue * 50),
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Bottom dark blue blur
                  Positioned(
                    bottom: -200 - (fillValue * 100),
                    right: -100 - (fillValue * 100),
                    child: Container(
                      width: bottomSize,
                      height: bottomSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.transparent,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2F6BF5).withValues(alpha: 0.15 + (fillValue * 0.85)),
                            blurRadius: 120 - (fillValue * 60),
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          
          // Content
          Center(
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
        ],
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
                    isLoading: _isLoading && !_isLoadingGoogle && !_isLoadingApple,
                    width: double.infinity,
                    icon: _isLogin ? Icons.arrow_forward_rounded : Icons.person_add_rounded,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // OAuth Dividers
                Row(
                  children: [
                    Expanded(child: Divider(color: VertexColors.glassBorder(brightness))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'VEYA',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: VertexColors.textMuted(brightness),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: VertexColors.glassBorder(brightness))),
                  ],
                ),
                
                const SizedBox(height: 24),

                // OAuth Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildOAuthButton(
                        icon: FontAwesomeIcons.google,
                        label: 'Google ile devam et',
                        isLoading: _isLoadingGoogle,
                        onPressed: _handleGoogleSignIn,
                        brightness: brightness,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildOAuthButton(
                        icon: FontAwesomeIcons.apple,
                        label: 'Apple ile devam et',
                        isLoading: _isLoadingApple,
                        onPressed: _handleAppleSignIn,
                        brightness: brightness,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                
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

  Widget _buildOAuthButton({
    required dynamic icon,
    required String label,
    required bool isLoading,
    required VoidCallback onPressed,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;
    return Material(
      color: VertexColors.glassBg(brightness),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: VertexColors.glassBorder(brightness)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: isLoading || _isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(icon, size: 20, color: isDark ? Colors.white : Colors.black),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        label,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoadingGoogle = true;
      _isLoading = true;
      _errorMessage = null;
    });
    _fillController.forward();

    final result = await _authService.signInWithGoogle();

    if (!mounted) return;

    if (!result.isSuccess) {
      _fillController.reverse();
      setState(() {
        _isLoadingGoogle = false;
        _isLoading = false;
        _errorMessage = result.errorMessage;
      });
      _shakeController.forward(from: 0);
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() {
      _isLoadingApple = true;
      _isLoading = true;
      _errorMessage = null;
    });
    _fillController.forward();

    final result = await _authService.signInWithApple();

    if (!mounted) return;

    if (!result.isSuccess) {
      _fillController.reverse();
      setState(() {
        _isLoadingApple = false;
        _isLoading = false;
        _errorMessage = result.errorMessage;
      });
      _shakeController.forward(from: 0);
    }
  }
}

extension BlurExtension on Widget {
  Widget applyBlur({double sigma = 10}) {
    return ImageFilterWidget(sigma: sigma, child: this);
  }
}

class ImageFilterWidget extends StatelessWidget {
  final double sigma;
  final Widget child;

  const ImageFilterWidget({super.key, required this.sigma, required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: child,
      ),
    );
  }
}
