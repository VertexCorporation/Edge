import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../theme.dart';

enum CortexLeadingMode { auto, back, none }

class CortexAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onLeadingPressed;
  final Widget? actionButton;
  final List<Widget>? actions;
  final List<Widget>? leadingActions;
  final Widget? title;
  final String? titleText;
  final bool showGradient;
  final bool includeTrailingActionsPadding;
  final bool ignoreActionsForCentering;
  final ScrollController? scrollController;
  final CortexLeadingMode leadingMode;

  const CortexAppBar({
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
    this.scrollController,
    this.leadingMode = CortexLeadingMode.auto,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 10);

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final bool isTablet = screenWidth >= 600;
    final double buttonSize = isTablet ? 46.0 : 40.0;
    final double iconSize = isTablet ? 24.0 : 20.0;
    final double horizontalPadding = screenWidth * 0.04;
    final double gapSize = 10.0;

    final ModalRoute<dynamic>? parentRoute = ModalRoute.of(context);
    final bool canPopThisRoute = parentRoute?.canPop ?? false;
    final bool showBackButton = leadingMode == CortexLeadingMode.back ||
        (leadingMode == CortexLeadingMode.auto && canPopThisRoute);
    final bool hideLeading = leadingMode == CortexLeadingMode.none;

    final List<Widget> leftWidgets = [];
    double calculatedLeadingWidth = 0;

    if (!hideLeading && showBackButton) {
      leftWidgets.add(
        _BackButton(
          buttonSize: buttonSize,
          iconSize: iconSize,
          onPressed: onLeadingPressed ?? () => Navigator.of(context).pop(),
        ),
      );
      calculatedLeadingWidth += buttonSize;
    }

    if (leadingActions != null && leadingActions!.isNotEmpty) {
      if (leftWidgets.isNotEmpty) {
        leftWidgets.add(SizedBox(width: gapSize));
        calculatedLeadingWidth += gapSize;
      }
      for (int i = 0; i < leadingActions!.length; i++) {
        leftWidgets.add(leadingActions![i]);
        calculatedLeadingWidth += buttonSize * 4.5;
        if (i < leadingActions!.length - 1) {
          leftWidgets.add(SizedBox(width: gapSize));
          calculatedLeadingWidth += gapSize;
        }
      }
    }
    if (leftWidgets.isNotEmpty) calculatedLeadingWidth += horizontalPadding;

    final List<Widget> rightWidgets = [];
    double calculatedActionsWidth = 0;
    final List<Widget> sourceActions =
        actions ?? (actionButton != null ? [actionButton!] : []);

    for (int i = 0; i < sourceActions.length; i++) {
      final Widget sourceAction = sourceActions[i];
      double estimatedActionWidth = buttonSize;
      if (sourceAction is SizedBox && sourceAction.width != null) {
        estimatedActionWidth = sourceAction.width! <= 0
            ? 0
            : math.max(buttonSize, sourceAction.width!);
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
      rightWidgets.add(SizedBox(width: horizontalPadding));
      calculatedActionsWidth += horizontalPadding;
    }

    final double effectiveActionsWidth =
        ignoreActionsForCentering ? 0 : calculatedActionsWidth;
    final double maxSideWidth =
        math.max(calculatedLeadingWidth, effectiveActionsWidth);
    final double availableCenteredSpace = screenWidth - (maxSideWidth * 2);
    final double targetWidth = screenWidth * 0.70;
    final double finalTitleMaxWidth =
        math.max(0.0, math.min(targetWidth, availableCenteredSpace));

    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      centerTitle: true,
      toolbarHeight: kToolbarHeight,
      flexibleSpace: showGradient
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withOpacity(1),
                    AppColors.background.withOpacity(0),
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
      title: finalTitleMaxWidth > 0
          ? ConstrainedBox(
              constraints: BoxConstraints(maxWidth: finalTitleMaxWidth),
              child: _AnimatedTitleWrapper(
                controller: scrollController,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: title ??
                      (titleText != null
                          ? Text(
                              titleText!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                                color: AppColors.primaryColor.inverted,
                              ),
                              maxLines: 1,
                            )
                          : const SizedBox.shrink()),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

class _BackButton extends StatelessWidget {
  final double buttonSize;
  final double iconSize;
  final VoidCallback onPressed;
  const _BackButton({required this.buttonSize, required this.iconSize, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return AppBarButton(
      size: buttonSize,
      onTap: onPressed,
      child: SvgPicture.asset(
        'assets/icons/outlined/left.svg',
        width: iconSize,
        height: iconSize,
        colorFilter: ColorFilter.mode(AppColors.primaryColor.inverted, BlendMode.srcIn),
      ),
    );
  }
}

class _AnimatedTitleWrapper extends StatefulWidget {
  final Widget child;
  final ScrollController? controller;
  const _AnimatedTitleWrapper({required this.child, this.controller});
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
  void dispose() {
    widget.controller?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() => _checkVisibility();

  void _checkVisibility() {
    if (widget.controller == null || !widget.controller!.hasClients) return;
    if (!mounted) return;
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final bool shouldBeVisible = widget.controller!.offset <= screenHeight * 0.025;
    if (_isVisible != shouldBeVisible) {
      setState(() => _isVisible = shouldBeVisible);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.controller == null) return widget.child;
    return AnimatedOpacity(
      opacity: _isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: widget.child,
    );
  }
}

class AppBarButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  final double size;
  final bool isTitle;
  final bool enableHaptic;
  const AppBarButton({super.key, required this.child, required this.onTap, this.size = 42.0, this.isTitle = false, this.enableHaptic = true});

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final invertedColor = AppColors.primaryColor.inverted;
    final Color splashColor = invertedColor.withOpacity(0.1);
    const double radius = 16.0;

    return Container(
      width: isTitle ? null : size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.secondaryColor,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border, width: 0.8),
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
          highlightColor: splashColor.withOpacity(0.05),
          child: Container(
            alignment: Alignment.center,
            padding: isTitle ? const EdgeInsets.symmetric(horizontal: 20) : EdgeInsets.zero,
            child: child,
          ),
        ),
      ),
    );
  }
}
