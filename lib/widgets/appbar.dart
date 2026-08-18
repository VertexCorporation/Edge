// lib/widgets/appbar.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';
import '../theme.dart';

/// Defines the behavior of the leading (left) button.
enum VertexLeadingMode {
  auto,
  axon,
  back,
  none,
}

// --- 1. THE UNIVERSAL APP BAR ---
class VertexAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onLeadingPressed;
  final Widget? actionButton;
  final List<Widget>? actions;
  final List<Widget>? leadingActions;
  final Widget? title;
  final String? titleText;
  final bool showGradient;
  final bool includeTrailingActionsPadding;
  final bool ignoreActionsForCentering;
  final bool titleAlignToActions;
  final double? trailingEdgePadding;
  final ScrollController? scrollController;
  final VertexLeadingMode leadingMode;
  final double? layoutWidth;

  const VertexAppBar({
    super.key,
    this.onLeadingPressed,
    this.actionButton,
    this.actions,
    this.leadingActions,
    this.title,
    this.titleText,
    this.showGradient = true,
    this.includeTrailingActionsPadding = true,
    this.ignoreActionsForCentering = false,
    this.titleAlignToActions = false,
    this.trailingEdgePadding,
    this.scrollController,
    this.leadingMode = VertexLeadingMode.auto,
    this.layoutWidth,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 10);

  @override
  Widget build(BuildContext context) {
    final double screenWidth =
        layoutWidth ?? MediaQuery.sizeOf(context).width;
    final bool isTablet = screenWidth >= 600;

    final double buttonSize = isTablet ? 46.0 : 40.0;
    final double iconSize = isTablet ? 24.0 : 20.0;
    final double horizontalPadding = math.max(12.0, screenWidth * 0.04);
    final double gapSize = 12.0;

    // --- LEADING LOGIC ---
    final ModalRoute<dynamic>? parentRoute = ModalRoute.of(context);
    final bool canPopThisRoute = parentRoute?.canPop ?? false;

    final bool showBackButton = leadingMode == VertexLeadingMode.back ||
        (leadingMode == VertexLeadingMode.auto && canPopThisRoute);
    final bool hideLeading = leadingMode == VertexLeadingMode.none;

    final List<Widget> leftWidgets = [];
    double calculatedLeadingWidth = 0;

    if (!hideLeading) {
      if (showBackButton) {
        leftWidgets.add(
          _BackButton(
            buttonSize: buttonSize,
            iconSize: iconSize,
            onPressed: onLeadingPressed ?? () => Navigator.of(context).pop(),
          ),
        );
        calculatedLeadingWidth += buttonSize;
      }
      // Note: Vertex-specific Axon mode is disabled for Edge.
    }

    if (leadingActions != null && leadingActions!.isNotEmpty) {
      if (leftWidgets.isNotEmpty) {
        leftWidgets.add(SizedBox(width: gapSize));
        calculatedLeadingWidth += gapSize;
      }
      for (int i = 0; i < leadingActions!.length; i++) {
        leftWidgets.add(leadingActions![i]);
        calculatedLeadingWidth += buttonSize;
        if (i < leadingActions!.length - 1) {
          leftWidgets.add(SizedBox(width: gapSize));
          calculatedLeadingWidth += gapSize;
        }
      }
    }

    if (leftWidgets.isNotEmpty) {
      calculatedLeadingWidth += horizontalPadding;
    }

    // --- RIGHT WIDGETS LOGIC ---
    final List<Widget> rightWidgets = [];
    double calculatedActionsWidth = 0;
    final List<Widget> sourceActions =
        actions ?? (actionButton != null ? [actionButton!] : []);

    for (int i = 0; i < sourceActions.length; i++) {
      final Widget sourceAction = sourceActions[i];
      double estimatedActionWidth = buttonSize;
      if (sourceAction is SizedBox && sourceAction.width != null) {
        estimatedActionWidth =
            sourceAction.width! <= 0 ? 0 : sourceAction.width!;
      }

      rightWidgets.add(
        Container(
          height: buttonSize,
          constraints: BoxConstraints(minWidth: estimatedActionWidth),
          alignment: Alignment.center,
          child: sourceAction,
        ),
      );

      calculatedActionsWidth += estimatedActionWidth;

      if (i < sourceActions.length - 1) {
        rightWidgets.add(SizedBox(width: gapSize));
        calculatedActionsWidth += gapSize;
      }
    }

    if (rightWidgets.isNotEmpty && includeTrailingActionsPadding) {
      final edgePad = trailingEdgePadding ?? horizontalPadding;
      rightWidgets.add(SizedBox(width: edgePad));
      calculatedActionsWidth += edgePad;
    }

    // --- CENTER CALCULATION ---
    final double effectiveActionsWidth =
        ignoreActionsForCentering ? 0 : calculatedActionsWidth;
    final double maxSideWidth =
        math.max(calculatedLeadingWidth, effectiveActionsWidth);
    final double availableCenteredSpace = screenWidth - (maxSideWidth * 2);
    final double targetWidth = screenWidth * 0.70;
    final double finalTitleMaxWidth =
        math.max(0.0, math.min(targetWidth, availableCenteredSpace));

    final Widget? titleWidget = title ??
        (titleText != null
            ? Text(
                titleText!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  color: AppColors.isDarkUi ? Colors.white : const Color(0xFF111827),
                ),
                maxLines: 1,
              )
            : null);

    Widget? builtTitle;
    if (titleWidget != null) {
      final wrappedTitle = _AnimatedTitleWrapper(
        controller: scrollController,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: titleAlignToActions ? Alignment.centerRight : Alignment.center,
          child: titleWidget,
        ),
      );

      if (titleAlignToActions) {
        builtTitle = Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(right: calculatedActionsWidth + 6),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: math.max(0, screenWidth - calculatedLeadingWidth - calculatedActionsWidth - 12),
              ),
              child: wrappedTitle,
            ),
          ),
        );
      } else if (finalTitleMaxWidth > 0) {
        builtTitle = ConstrainedBox(
          constraints: BoxConstraints(maxWidth: finalTitleMaxWidth),
          child: wrappedTitle,
        );
      }
    }

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      centerTitle: !titleAlignToActions,
      toolbarHeight: kToolbarHeight,
      flexibleSpace: showGradient
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withValues(alpha: 1),
                    AppColors.background.withValues(alpha: 0),
                  ],
                  stops: const [0.0, 0.7],
                ),
              ),
            )
          : null,
      leading: leftWidgets.isNotEmpty
          ? OverflowBox(
              alignment: Alignment.centerLeft,
              minWidth: 0,
              maxWidth: double.infinity,
              child: Padding(
                padding: EdgeInsetsDirectional.only(start: horizontalPadding),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: leftWidgets,
                ),
              ),
            )
          : null,
      leadingWidth: leftWidgets.isNotEmpty ? calculatedLeadingWidth : null,
      actions: rightWidgets,
      title: builtTitle ?? const SizedBox.shrink(),
    );
  }
}

// --- 2. DUAL ACTION PILL ---
class DualActionPill extends StatelessWidget {
  final bool isDual;
  final Widget mainIcon; // Right side
  final Widget? secondaryIcon; // Left side
  final VoidCallback onMainTap;
  final VoidCallback? onSecondaryTap;
  final double size;

  const DualActionPill({
    super.key,
    required this.isDual,
    required this.mainIcon,
    this.secondaryIcon,
    required this.onMainTap,
    this.onSecondaryTap,
    this.size = 42.0,
  });

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final invertedColor = AppColors.primaryColor.inverted;
    final Color backgroundColor = AppColors.background;
    final Color borderColor = invertedColor.withValues(alpha: 0.12);
    final Color splashColor = invertedColor.withValues(alpha: 0.1);

    const double radius = 16.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutBack,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              alignment: Alignment.centerRight,
              child: isDual
                  ? Row(
                      children: [
                        SizedBox(
                          width: size,
                          height: size,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              onSecondaryTap?.call();
                            },
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(radius),
                              bottomLeft: Radius.circular(radius),
                            ),
                            splashColor: splashColor,
                            highlightColor: splashColor.withValues(alpha: 0.05),
                            child: Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 200),
                                child: secondaryIcon ?? const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: size * 0.6,
                          color: borderColor,
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            SizedBox(
              width: size,
              height: size,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onMainTap();
                },
                borderRadius: isDual
                    ? const BorderRadius.only(
                        topRight: Radius.circular(radius),
                        bottomRight: Radius.circular(radius),
                      )
                    : BorderRadius.circular(radius),
                splashColor: splashColor,
                highlightColor: splashColor.withValues(alpha: 0.05),
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: FadeTransition(
                          opacity: animation,
                          child: child,
                        ),
                      );
                    },
                    child: mainIcon,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- 3. BACK BUTTON ---
class _BackButton extends StatelessWidget {
  final double buttonSize;
  final double iconSize;
  final VoidCallback onPressed;

  const _BackButton({
    required this.buttonSize,
    required this.iconSize,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool isRtl = Directionality.of(context) == TextDirection.rtl;
    final double rotationAngle = isRtl ? -math.pi / 2 : math.pi / 2;

    return AppBarButton(
      size: buttonSize,
      onTap: onPressed,
      child: Transform.rotate(
        angle: rotationAngle,
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: iconSize,
          color: AppColors.primaryColor.inverted,
        ),
      ),
    );
  }
}

// --- 4. ANIMATED TITLE WIDGET ---
class _AnimatedTitleWrapper extends StatefulWidget {
  final Widget child;
  final ScrollController? controller;

  const _AnimatedTitleWrapper({
    required this.child,
    this.controller,
  });

  @override
  State<_AnimatedTitleWrapper> createState() => _AnimatedTitleWrapperState();
}

class _AnimatedTitleWrapperState extends State<_AnimatedTitleWrapper> {
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  @override
  void didUpdateWidget(_AnimatedTitleWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onScroll);
      widget.controller?.addListener(_onScroll);
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    _checkVisibility();
  }

  void _checkVisibility() {
    if (widget.controller == null || !widget.controller!.hasClients) return;
    if (!mounted) return;

    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double dynamicThreshold = screenHeight * 0.025;
    final double offset = widget.controller!.offset;
    final bool shouldBeVisible = offset <= dynamicThreshold;

    if (_isVisible != shouldBeVisible) {
      setState(() {
        _isVisible = shouldBeVisible;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller == null) {
      return widget.child;
    }
    return AnimatedOpacity(
      opacity: _isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: widget.child,
    );
  }
}

// --- 5. STANDARD PILL BUTTON ---
class AppBarButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final double size;
  final bool isTitle;
  final bool enableHaptic;

  const AppBarButton({
    super.key,
    required this.child,
    required this.onTap,
    this.size = 42.0,
    this.isTitle = false,
    this.enableHaptic = true,
  });

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final invertedColor = AppColors.primaryColor.inverted;
    final Color backgroundColor = AppColors.background;
    final Color borderColor = invertedColor.withValues(alpha: 0.12);
    final Color splashColor = invertedColor.withValues(alpha: 0.1);

    const double radius = 16.0;

    return Container(
      width: isTitle ? null : size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(radius),
        child: InkWell(
          onTap: () {
            if (enableHaptic) HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(radius),
          splashColor: splashColor,
          highlightColor: splashColor.withValues(alpha: 0.05),
          child: Container(
            alignment: Alignment.center,
            padding: isTitle
                ? const EdgeInsets.symmetric(horizontal: 20)
                : EdgeInsets.zero,
            child: child,
          ),
        ),
      ),
    );
  }
}
