import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme.dart';
import '../widgets/button.dart';
import '../widgets/input.dart';
import '../services/auth.dart';
import '../utils/ios.dart';
import 'package:edge/l10n/app_localizations.dart';

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
            _nameController.text.isEmpty ? AppLocalizations.of(context)!.user : _nameController.text,
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
              Expanded(child: Text(result.errorMessage ?? AppLocalizations.of(context)!.loginError)),
            ],
          ),
          backgroundColor: AppColors.septenaryColor,
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
                          AppLocalizations.of(context)!.copyRightText,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.tertiaryColor
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
            color: AppColors.secondaryColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isLogin ? AppLocalizations.of(context)!.login : AppLocalizations.of(context)!.signUp,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.primaryColor.inverted
                        : AppColors.primaryColor.inverted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isLogin ? AppLocalizations.of(context)!.continueWithVertex : AppLocalizations.of(context)!.createNewAccount,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.tertiaryColor,
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
                          child: Column(
                            children: [
                              VertexInput(
                                label: AppLocalizations.of(context)!.fullName,
                                hint: AppLocalizations.of(context)!.exampleName,
                                controller: _nameController,
                                prefixIcon: Icon(
                                  Icons.person_outline_rounded,
                                  size: 18,
                                  color: AppColors.tertiaryColor,
                                ),
                                validator: (value) {
                                  if (!_isLogin && (value == null || value.isEmpty)) {
                                    return AppLocalizations.of(context)!.fullNameRequired;
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                // Email input
                VertexInput(
                  label: AppLocalizations.of(context)!.email,
                  hint: AppLocalizations.of(context)!.exampleEmail,
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icon(
                    Icons.mail_outline_rounded,
                    size: 18,
                    color: AppColors.tertiaryColor,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.emailRequired;
                    }
                    if (!value.contains('@')) {
                      return AppLocalizations.of(context)!.enterValidEmail;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password input
                VertexInput(
                  label: AppLocalizations.of(context)!.password,
                  hint: '12345678',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  maskSecretInDom: true,
                  prefixIcon: Icon(
                    Icons.lock_outline_rounded,
                    size: 18,
                    color: AppColors.tertiaryColor,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                      color: AppColors.tertiaryColor,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)!.passwordRequired;
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
                      color: AppColors.septenaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.septenaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 16,
                          color: AppColors.septenaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.septenaryColor,
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
                    label: _isLogin ? AppLocalizations.of(context)!.login : AppLocalizations.of(context)!.signUp,
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
                    Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        AppLocalizations.of(context)!.or,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.tertiaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.border)),
                  ],
                ),
                
                const SizedBox(height: 24),

                // OAuth Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildOAuthButton(
                        icon: FontAwesomeIcons.google,
                        label: AppLocalizations.of(context)!.continueWithGoogle,
                        isLoading: _isLoadingGoogle,
                        onPressed: _handleGoogleSignIn,
                        brightness: brightness,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildOAuthButton(
                        icon: FontAwesomeIcons.apple,
                        label: AppLocalizations.of(context)!.continueWithApple,
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
                          ? AppLocalizations.of(context)!.dontHaveAccount 
                          : AppLocalizations.of(context)!.alreadyHaveAccount,
                      style: GoogleFonts.inter(
                        color: AppColors.senaryColor,
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
      color: AppColors.secondaryColor,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.border),
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
    if (!isIosDevice()) {
      setState(() => _errorMessage = 'CIHAZ IOS DEĞIL');
      _shakeController.forward(from: 0);
      return;
    }

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
