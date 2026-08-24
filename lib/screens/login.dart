import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../widgets/button.dart';
import '../widgets/input.dart';
import '../services/auth.dart';
import '../utils/ios.dart';
import '../version.dart';
import 'package:edge/l10n/app_localizations.dart';

/// Login screen with Vertex branding.
/// Features: geo background, glassmorphic card, gradient text, animated logo.
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
    context.watch<ThemeProvider>();
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final wide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _fillAnimation,
            builder: (context, child) {
              final fillValue = _fillAnimation.value;
              final topSize = 300.0 + (screenHeight * fillValue);
              final bottomSize = 400.0 + (screenHeight * fillValue);
              final glow = AppColors.senaryColor;

              return Stack(
                children: [
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
                            color: glow.withValues(
                              alpha: 0.12 + (fillValue * 0.55),
                            ),
                            blurRadius: 100 - (fillValue * 50),
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
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
                            color: glow.withValues(
                              alpha: 0.10 + (fillValue * 0.45),
                            ),
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
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SafeArea(
                child: wide
                    ? Row(
                        children: [
                          Expanded(flex: 5, child: _buildBranding(isDark)),
                          Expanded(
                            flex: 4,
                            child: Center(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(24, 32, 40, 32),
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 460),
                                  child: _buildAuthColumn(brightness, isDark),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 460),
                            child: _buildAuthColumn(brightness, isDark),
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

  Widget _buildAuthColumn(Brightness brightness, bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            final offset = _shakeController.value > 0
                ? (12 *
                    (1 - _shakeController.value) *
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
        Text(
          'v$kAppVersion',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppColors.tertiaryColor.withValues(alpha: 0.45),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.copyRightText,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.tertiaryColor.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildBranding(bool isDark) {
    final muted = AppColors.tertiaryColor;
    final titleColor = isDark ? Colors.white : AppColors.primaryColor.inverted;

    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 40, 32, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.secondaryColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                AppColors.senaryColor,
                BlendMode.srcIn,
              ),
              child: Image.asset(
                'assets/icons/edge/transparent.png',
                width: 28,
                height: 28,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Edge.',
            style: GoogleFonts.outfit(
              fontSize: 52,
              fontWeight: FontWeight.w800,
              color: titleColor,
              height: 1,
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Text(
              'Ekibin için uçtan uca şifreli mesajlaşma, arama ve iş takibi. Anahtarlar cihazında kalır.',
              style: GoogleFonts.inter(
                fontSize: 16,
                height: 1.5,
                color: muted,
              ),
            ),
          ),
          const SizedBox(height: 36),
          _featureRow(
            Icons.lock_outline_rounded,
            'Uçtan uca şifreleme',
            'Mesajlar, fotoğraflar ve arama sinyali cihazında şifrelenir.',
          ),
          _featureRow(
            Icons.videocam_outlined,
            'Ses, görüntü, ekran paylaşımı',
            'Cihazlar arasında doğrudan yayın, 4K kaliteye kadar.',
          ),
          _featureRow(
            Icons.groups_outlined,
            'Şirketler, gruplar ve davet linkleri',
            'Tek tek eklemek yok — linki paylaş, ekip katılsın.',
          ),
          _featureRow(
            Icons.checklist_rounded,
            'Görevler ve toplantılar',
            'İşi bir kişiye veya gruba ata, toplantı planla.',
          ),
        ],
      ),
    );
  }

  Widget _featureRow(IconData icon, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.senaryColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.isDarkUi
                        ? Colors.white
                        : AppColors.primaryColor.inverted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.tertiaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(child: _modeTab('Giriş', true)),
          Expanded(child: _modeTab('Kayıt', false)),
        ],
      ),
    );
  }

  Widget _modeTab(String label, bool loginTab) {
    final selected = _isLogin == loginTab;
    return Material(
      color: selected ? AppColors.secondaryColor : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () {
          if (_isLogin == loginTab) return;
          setState(() {
            _isLogin = loginTab;
            _errorMessage = null;
          });
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? (AppColors.isDarkUi
                      ? Colors.white
                      : AppColors.primaryColor.inverted)
                  : AppColors.tertiaryColor,
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildLoginCard(Brightness brightness, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              children: [
                SizedBox(
                  width: double.infinity,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      key: ValueKey<bool>(_isLogin),
                      _isLogin ? 'Tekrar hoş geldin' : 'Hesap oluştur',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.primaryColor.inverted
                            : AppColors.primaryColor.inverted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      key: ValueKey<bool>(_isLogin),
                      _isLogin
                          ? 'Vertex e-posta veya Cortex kullanıcı adınla giriş yap. Ayrı kayıt gerekmez.'
                          : 'Yeni hesap için ad, e-posta ve şifre. Vertex hesabın varsa Giriş sekmesini kullan.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.tertiaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildModeTabs(),
                const SizedBox(height: 24),

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
                  label: _isLogin
                      ? 'E-posta veya kullanıcı adı'
                      : AppLocalizations.of(context)!.email,
                  hint: _isLogin
                      ? 'e-posta veya Cortex kullanıcı adı'
                      : AppLocalizations.of(context)!.exampleEmail,
                  controller: _emailController,
                  keyboardType: _isLogin
                      ? TextInputType.text
                      : TextInputType.emailAddress,
                  prefixIcon: Icon(
                    _isLogin
                        ? Icons.person_outline_rounded
                        : Icons.mail_outline_rounded,
                    size: 18,
                    color: AppColors.tertiaryColor,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return _isLogin
                          ? 'E-posta veya kullanıcı adı gerekli'
                          : AppLocalizations.of(context)!.emailRequired;
                    }
                    if (!_isLogin && !value.contains('@')) {
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
                  child: SizedBox(
                    width: double.infinity,
                    child: _buildOAuthButton(
                      key: ValueKey<bool>(_isLogin),
                      icon: null, // No icon for the main login button, like in the image
                      label: _isLogin ? AppLocalizations.of(context)!.login : AppLocalizations.of(context)!.signUp,
                      onPressed: _handleAuth,
                      isLoading: _isLoading && !_isLoadingGoogle && !_isLoadingApple,
                      brightness: brightness,
                    ),
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
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: _buildOAuthButton(
                        icon: FontAwesomeIcons.apple,
                        iconSize: 24, // Matched visual weight with Google
                        label: AppLocalizations.of(context)!.continueWithApple,
                        isLoading: _isLoadingApple,
                        onPressed: _handleAppleSignIn,
                        brightness: brightness,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: _buildOAuthButton(
                        icon: FontAwesomeIcons.google,
                        label: AppLocalizations.of(context)!.continueWithGoogle,
                        isLoading: _isLoadingGoogle,
                        onPressed: _handleGoogleSignIn,
                        brightness: brightness,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Text(
                  'Sunucu yalnızca şifreli veri tutar. Şifreni kaybedersen eski mesajlar geri gelmez.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    height: 1.4,
                    color: AppColors.tertiaryColor.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildOAuthButton({
    Key? key,
    required dynamic icon,
    required String label,
    required bool isLoading,
    required VoidCallback onPressed,
    required Brightness brightness,
    double iconSize = 20,
  }) {
    final isDark = brightness == Brightness.dark;
    return Material(
      key: key,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.border, width: 1.0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: isLoading || _isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      FaIcon(icon, size: iconSize, color: isDark ? Colors.white : Colors.black),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
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
    if (result.isRedirecting) return;

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
    if (result.isRedirecting) return;

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

class AnimatedNeonBorder extends StatefulWidget {
  final Widget child;

  const AnimatedNeonBorder({super.key, required this.child});

  @override
  State<AnimatedNeonBorder> createState() => _AnimatedNeonBorderState();
}

class _AnimatedNeonBorderState extends State<AnimatedNeonBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8), // Adjusted to 8 seconds for perfect constant speed
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppColors.background,
          ),
          child: widget.child,
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: NeonBorderPainter(_controller.value),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class NeonBorderPainter extends CustomPainter {
  final double progress;

  NeonBorderPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final RRect rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(16),
    );

    final Path path = Path()..addRRect(rrect);
    final ui.PathMetrics pathMetrics = path.computeMetrics();
    
    // Convert to list to safely check and get the first element
    final metricsList = pathMetrics.toList();
    if (metricsList.isEmpty) return;
    
    final ui.PathMetric metric = metricsList.first;
    
    final double length = metric.length;
    final double trailLength = length * 0.4; // Light length is 40% of perimeter
    
    final double headPoint = length * progress;
    final double tailPoint = headPoint - trailLength;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final Paint glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

    // Draw fading segments to create the comet tail effect
    final int segments = 40;
    for (int i = 0; i < segments; i++) {
      double pStart = tailPoint + (i * trailLength / segments);
      double pEnd = pStart + (trailLength / segments);
      
      Path segment = Path();
      
      void addSeg(double s, double e) {
        if (s < 0 && e < 0) {
           segment.addPath(metric.extractPath(s + length, e + length), Offset.zero);
        } else if (s < 0 && e >= 0) {
           segment.addPath(metric.extractPath(s + length, length), Offset.zero);
           segment.addPath(metric.extractPath(0, e), Offset.zero);
        } else if (s > length && e > length) {
           segment.addPath(metric.extractPath(s - length, e - length), Offset.zero);
        } else if (s <= length && e > length) {
           segment.addPath(metric.extractPath(s, length), Offset.zero);
           segment.addPath(metric.extractPath(0, e - length), Offset.zero);
        } else {
           segment.addPath(metric.extractPath(s, e), Offset.zero);
        }
      }
      
      addSeg(pStart, pEnd);

      double opacity = (i / segments); // 0.0 to 1.0
      opacity = opacity * opacity; // Non-linear fade for realistic tail
      
      Color baseColor = Color.lerp(const Color(0xFF0072FF), const Color(0xFF00C6FF), opacity)!;
      
      paint.color = baseColor.withValues(alpha: opacity);
      glowPaint.color = baseColor.withValues(alpha: opacity * 0.6);
      
      canvas.drawPath(segment, glowPaint);
      canvas.drawPath(segment, paint);
    }
  }

  @override
  bool shouldRepaint(NeonBorderPainter oldDelegate) => oldDelegate.progress != progress;
}
