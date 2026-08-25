import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

/// Glassmorphic input field matching Vertex website's input style
class VertexInput extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool autofocus;

  /// When true, the editable DOM value is a numeric mask (1234…) instead of the
  /// real secret — inspect / DevTools won't show the actual password.
  final bool maskSecretInDom;

  const VertexInput({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.prefixIcon,
    this.errorText,
    this.onChanged,
    this.validator,
    this.autofocus = false,
    this.maskSecretInDom = false,
  });

  @override
  Widget build(BuildContext context) {
    if (maskSecretInDom) {
      return _DomSafeSecretInput(
        label: label,
        hint: hint,
        controller: controller,
        reveal: !obscureText,
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
        errorText: errorText,
        onChanged: onChanged,
        validator: validator,
        autofocus: autofocus,
      );
    }

    return _LabeledField(
      label: label,
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        obscuringCharacter: '•',
        keyboardType: keyboardType,
        onChanged: onChanged,
        validator: validator,
        autofocus: autofocus,
        enableSuggestions: !obscureText,
        autocorrect: !obscureText,
        style: _fieldStyle,
        cursorColor: AppColors.senaryColor,
        decoration: _decoration(
          context,
          hint: hint,
          errorText: errorText,
          suffixIcon: suffixIcon,
          prefixIcon: prefixIcon,
        ),
      ),
    );
  }

  static TextStyle get _fieldStyle => GoogleFonts.inter(
        fontSize: 14,
        color: AppColors.primaryColor.inverted,
      );

  static InputDecoration _decoration(
    BuildContext context, {
    String? hint,
    String? errorText,
    Widget? suffixIcon,
    Widget? prefixIcon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      hintText: hint,
      errorText: errorText,
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: isDark
          ? AppColors.background.withValues(alpha: 0.6)
          : AppColors.secondaryColor,
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final Widget child;

  const _LabeledField({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.tertiaryColor,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _DomSafeSecretInput extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool reveal;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool autofocus;

  const _DomSafeSecretInput({
    required this.label,
    this.hint,
    this.controller,
    required this.reveal,
    this.suffixIcon,
    this.prefixIcon,
    this.errorText,
    this.onChanged,
    this.validator,
    this.autofocus = false,
  });

  @override
  State<_DomSafeSecretInput> createState() => _DomSafeSecretInputState();
}

class _DomSafeSecretInputState extends State<_DomSafeSecretInput> {
  late final TextEditingController _displayController;
  late final _NumericSecretFormatter _formatter;
  String _secret = '';
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _secret = widget.controller?.text ?? '';
    _formatter = _NumericSecretFormatter(
      getSecret: () => _secret,
      setSecret: _setSecret,
      reveal: widget.reveal,
    );
    _displayController = TextEditingController(text: _visibleText(_secret));
    widget.controller?.addListener(_onExternalController);
  }

  @override
  void didUpdateWidget(covariant _DomSafeSecretInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    _formatter.reveal = widget.reveal;
    if (oldWidget.reveal != widget.reveal) {
      _syncing = true;
      _displayController.value = TextEditingValue(
        text: _visibleText(_secret),
        selection: TextSelection.collapsed(offset: _secret.length),
      );
      _syncing = false;
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onExternalController);
    _displayController.dispose();
    super.dispose();
  }

  void _onExternalController() {
    if (_syncing) return;
    final next = widget.controller?.text ?? '';
    if (next == _secret) return;
    _secret = next;
    _syncing = true;
    _displayController.value = TextEditingValue(
      text: _visibleText(_secret),
      selection: TextSelection.collapsed(offset: _secret.length),
    );
    _syncing = false;
  }

  void _setSecret(String value) {
    _secret = value;
    final c = widget.controller;
    if (c != null && c.text != value) {
      _syncing = true;
      c.value = TextEditingValue(
        text: value,
        selection: TextSelection.collapsed(offset: value.length),
      );
      _syncing = false;
    }
    widget.onChanged?.call(value);
  }

  String _visibleText(String secret) =>
      widget.reveal ? secret : _NumericSecretFormatter.mask(secret.length);

  @override
  Widget build(BuildContext context) {
    return _LabeledField(
      label: widget.label,
      child: TextFormField(
        controller: _displayController,
        autofocus: widget.autofocus,
        enableSuggestions: false,
        autocorrect: false,
        obscureText: false,
        keyboardType: TextInputType.visiblePassword,
        inputFormatters: [_formatter],
        validator: (_) => widget.validator?.call(_secret),
        style: VertexInput._fieldStyle,
        cursorColor: AppColors.senaryColor,
        decoration: VertexInput._decoration(
          context,
          hint: widget.hint,
          errorText: widget.errorText,
          suffixIcon: widget.suffixIcon,
          prefixIcon: widget.prefixIcon,
        ),
      ),
    );
  }
}

/// Keeps real password in memory; field text is 123456789… while hidden.
class _NumericSecretFormatter extends TextInputFormatter {
  final String Function() getSecret;
  final ValueChanged<String> setSecret;
  bool reveal;

  _NumericSecretFormatter({
    required this.getSecret,
    required this.setSecret,
    required this.reveal,
  });

  static String mask(int length) {
    if (length <= 0) return '';
    final buffer = StringBuffer();
    for (var i = 0; i < length; i++) {
      buffer.write(((i % 9) + 1).toString());
    }
    return buffer.toString();
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldSecret = getSecret();

    if (reveal) {
      setSecret(newValue.text);
      return newValue;
    }

    final nextSecret = _deriveSecret(oldSecret, oldValue, newValue);
    setSecret(nextSecret);

    final masked = mask(nextSecret.length);
    return TextEditingValue(
      text: masked,
      selection: TextSelection.collapsed(offset: masked.length),
    );
  }

  static String _deriveSecret(
    String oldSecret,
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final oldText = oldValue.text;
    final newText = newValue.text;

    if (newText.length == oldText.length) {
      return oldSecret;
    }

    if (newText.length < oldText.length) {
      final removed = oldText.length - newText.length;
      if (!oldValue.selection.isCollapsed) {
        final start = oldValue.selection.start.clamp(0, oldSecret.length);
        final end = oldValue.selection.end.clamp(0, oldSecret.length);
        return oldSecret.replaceRange(start, end, '');
      }
      final cursor = oldValue.selection.baseOffset.clamp(0, oldSecret.length);
      final from = (cursor - removed).clamp(0, oldSecret.length);
      final to = cursor.clamp(0, oldSecret.length);
      return oldSecret.replaceRange(from, to, '');
    }

    final added = newText.length - oldText.length;
    if (!oldValue.selection.isCollapsed) {
      final start = oldValue.selection.start.clamp(0, oldSecret.length);
      final end = oldValue.selection.end.clamp(0, oldSecret.length);
      final insertAt =
          (newValue.selection.baseOffset - added).clamp(0, newText.length);
      final chunk = newText.substring(
        insertAt,
        (insertAt + added).clamp(0, newText.length),
      );
      return oldSecret.replaceRange(start, end, chunk);
    }

    final insertAt =
        (newValue.selection.baseOffset - added).clamp(0, newText.length);
    final chunk = newText.substring(insertAt, insertAt + added);
    final at = insertAt.clamp(0, oldSecret.length);
    return oldSecret.substring(0, at) + chunk + oldSecret.substring(at);
  }
}
