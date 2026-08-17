import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/notification.dart';
import '../theme.dart';

class InboxNoticeLayer extends StatefulWidget {
  final Widget child;

  const InboxNoticeLayer({super.key, required this.child});

  @override
  State<InboxNoticeLayer> createState() => _InboxNoticeLayerState();
}

class _InboxNoticeLayerState extends State<InboxNoticeLayer> {
  StreamSubscription<InboxNotice>? _sub;
  InboxNotice? _notice;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _sub = NotificationService().inboxNotices.listen((notice) {
      _hideTimer?.cancel();
      setState(() => _notice = notice);
      _hideTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _notice = null);
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_notice != null)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: SafeArea(
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: () => setState(() => _notice = null),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.senaryColor.withValues(alpha: 0.45),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.chat_bubble_rounded,
                          color: AppColors.senaryColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _notice!.title,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: AppColors.primaryColor.inverted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _notice!.body,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.tertiaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
