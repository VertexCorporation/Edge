import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:encrypt/encrypt.dart' as enc;
import '../../theme.dart';
import '../../services/chat.dart';
import '../../widgets/appbar.dart';
import '../../widgets/fog.dart';
import '../../utils/file_bytes.dart';
import 'package:edge/l10n/app_localizations.dart';

class ChatDetailScreen extends StatefulWidget {
  final String title;
  final String? receiverId;
  final String? chatId;
  final bool isGroup;
  final bool isAnnouncementGroup;
  final bool isAdmin;

  const ChatDetailScreen({
    super.key,
    required this.title,
    this.receiverId,
    this.chatId,
    this.isGroup = false,
    this.isAnnouncementGroup = false,
    this.isAdmin = false,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();
  
  final AudioRecorder _record = AudioRecorder();

  bool _isRecording = false;
  final List<Map<String, dynamic>> _pendingMessages = [];
  Timer? _typingIdleTimer;
  bool _amTyping = false;
  late final String _resolvedChatId;

  @override
  void initState() {
    super.initState();
    _resolvedChatId = widget.chatId ??
        _chatService.getChatId(_chatService.currentUserId, widget.receiverId!);
    _messageController.addListener(_onComposeChanged);
  }

  @override
  void dispose() {
    _typingIdleTimer?.cancel();
    _messageController.removeListener(_onComposeChanged);
    _setTyping(false);
    _messageController.dispose();
    _scrollController.dispose();
    _record.dispose();
    super.dispose();
  }

  void _onComposeChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText) {
      if (!_amTyping) _setTyping(true);
      _typingIdleTimer?.cancel();
      _typingIdleTimer = Timer(const Duration(seconds: 2), () {
        _setTyping(false);
      });
    } else {
      _typingIdleTimer?.cancel();
      _setTyping(false);
    }
  }

  void _setTyping(bool isTyping) {
    if (_amTyping == isTyping) return;
    _amTyping = isTyping;
    _chatService.setTypingStatus(_resolvedChatId, isTyping);
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final localId = 'local_${DateTime.now().microsecondsSinceEpoch}';
    final pending = {
      'id': localId,
      'senderId': _chatService.currentUserId,
      'receiverId': widget.receiverId ?? '',
      'text': text,
      'timestamp': Timestamp.now(),
      'type': 'text',
      'pending': true,
    };

    _messageController.clear();
    _typingIdleTimer?.cancel();
    _setTyping(false);
    setState(() => _pendingMessages.insert(0, pending));

    _chatService.sendMessage(
      text,
      type: 'text',
      receiverId: widget.receiverId,
      explicitChatId: widget.chatId,
      isGroup: widget.isGroup,
    ).then((_) {
      if (mounted) {
        setState(() => _pendingMessages.removeWhere((m) => m['id'] == localId));
      }
    }).catchError((e) {
      if (mounted) {
        setState(() {
          _pendingMessages.removeWhere((m) => m['id'] == localId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gönderilemedi: $e')),
        );
      }
    });
  }

  Future<void> _pickAndSendImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      _sendFile(bytes, 'image');
    }
  }

  Future<void> _pickAndSendFile() async {
    final PlatformFile? result = await FilePicker.pickFile();
    if (result != null) {
      final bytes = await result.readAsBytes();
      _sendFile(bytes, 'file');
    }
  }

  Future<void> _sendFile(Uint8List bytes, String type) async {
    try {
      await _chatService.sendFile(
        bytes, 
        type,
        receiverId: widget.receiverId,
        explicitChatId: widget.chatId,
        isGroup: widget.isGroup,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dosya gönderim hatası: $e')));
      }
    }
  }

  Future<void> _startRecording() async {
    if (kIsWeb) return;
    try {
      if (await _record.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        final path =
            '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _record.start(const RecordConfig(), path: path);
        setState(() {
          _isRecording = true;
        });
      }
    } catch (e) {
      debugPrint('Kayıt hatası: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (kIsWeb) return;
    try {
      final path = await _record.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        final bytes = await readFileBytes(path);
        if (bytes != null) _sendFile(bytes, 'audio');
      }
    } catch (e) {
      debugPrint('Kayıt durdurma hatası: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      appBar: VertexAppBar(
        scrollController: _scrollController,
        titleText: widget.title,
        leadingMode: VertexLeadingMode.back,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _ChatMessagesList(
                chatService: _chatService,
                scrollController: _scrollController,
                chatId: _resolvedChatId,
                isGroup: widget.isGroup,
                pendingMessages: _pendingMessages,
              ),
            ),
            if (!widget.isGroup && widget.receiverId != null)
              _PeerTypingIndicator(
                stream: _chatService.watchPeerTyping(
                  _resolvedChatId,
                  widget.receiverId!,
                ),
                name: widget.title,
              ),
            if (widget.isAnnouncementGroup && !widget.isAdmin)
               Container(
                 padding: const EdgeInsets.all(16),
                 color: isDark ? Colors.white10 : Colors.black12,
                 child: Center(
                   child: Text(
                     AppLocalizations.of(context)!.onlyAdminsCanMessage,
                     style: TextStyle(color: AppColors.tertiaryColor, fontStyle: FontStyle.italic),
                   ),
                 ),
               )
            else
               _MessageInputBar(
                 controller: _messageController,
                 isDark: isDark,
                 isRecording: _isRecording,
                 onSend: _sendMessage,
                 onPickFile: _pickAndSendFile,
                 onPickImage: _pickAndSendImage,
                 onStartRecording: _startRecording,
                 onStopRecording: _stopRecording,
               ),
          ],
        ),
      ),
    );
  }

}

class _PeerTypingIndicator extends StatelessWidget {
  final Stream<bool> stream;
  final String name;

  const _PeerTypingIndicator({
    required this.stream,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.data != true) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '$name typing...',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.tertiaryColor,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ChatMessagesList extends StatelessWidget {
  final ChatService chatService;
  final ScrollController scrollController;
  final String chatId;
  final bool isGroup;
  final List<Map<String, dynamic>> pendingMessages;

  const _ChatMessagesList({
    required this.chatService,
    required this.scrollController,
    required this.chatId,
    required this.isGroup,
    required this.pendingMessages,
  });

  List<Map<String, dynamic>> _mergeMessages(List<Map<String, dynamic>> remote) {
    final remoteIds = remote.map((m) => m['id']).toSet();
    final locals = pendingMessages.where((m) => !remoteIds.contains(m['id'])).toList();
    final merged = [...locals, ...remote];
    merged.sort((a, b) {
      final tA = a['timestamp'];
      final tB = b['timestamp'];
      if (tA == null && tB == null) return 0;
      if (tA == null) return 1;
      if (tB == null) return -1;
      if (tA is Timestamp && tB is Timestamp) return tB.compareTo(tA);
      return 0;
    });
    return merged;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: chatService.getMessages(chatId, isGroup: isGroup),
      builder: (context, snapshot) {
        final messages = _mergeMessages(snapshot.data ?? []);

        return ScrollFog(
          scrollController: scrollController,
          color: AppColors.background,
          child: ListView.builder(
            controller: scrollController,
            reverse: true,
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final msg = messages[index];
              final isMe = msg['senderId'] == chatService.currentUserId;
              return _MessageBubble(
                key: ValueKey(msg['id']),
                msg: msg,
                isMe: isMe,
                isDark: isDark,
              );
            },
          ),
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final Map<String, dynamic> msg;
  final bool isMe;
  final bool isDark;

  const _MessageBubble({
    super.key,
    required this.msg,
    required this.isMe,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final String type = msg['type'] ?? 'text';
    final String text = msg['text'];

    Widget content;
    if (type == 'text') {
      content = Text(
        text,
        style: GoogleFonts.inter(
          color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black),
        ),
      );
    } else {
      try {
        final payload = jsonDecode(text);
        if (type == 'image') {
          content = _DecryptedImageWidget(
            url: (payload['url'] ?? '').toString(),
            keyBase64: payload['key'] ?? '',
            ivBase64: payload['iv'] ?? '',
          );
        } else if (type == 'audio') {
          content = _DecryptedAudioWidget(
            url: (payload['url'] ?? '').toString(),
            keyBase64: payload['key'] ?? '',
            ivBase64: payload['iv'] ?? '',
            textColor: isMe ? Colors.white : (isDark ? Colors.white : Colors.black),
          );
        } else {
          content = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.insert_drive_file, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.fileWithFileName(payload['fileName'] ?? ''),
                style: TextStyle(color: isMe ? Colors.white : Colors.black),
              ),
            ],
          );
        }
      } catch (e) {
        content = Text(AppLocalizations.of(context)!.unsupportedMediaType);
      }
    }

    if (type == 'image') {
      return Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: content,
        ),
      );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe ? AppColors.senaryColor : AppColors.secondaryColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
          border: isMe ? null : Border.all(color: AppColors.border),
        ),
        child: content,
      ),
    );
  }
}

class _MessageInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  final bool isRecording;
  final VoidCallback onSend;
  final VoidCallback onPickFile;
  final VoidCallback onPickImage;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;

  const _MessageInputBar({
    required this.controller,
    required this.isDark,
    required this.isRecording,
    required this.onSend,
    required this.onPickFile,
    required this.onPickImage,
    required this.onStartRecording,
    required this.onStopRecording,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.secondaryColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.attach_file_rounded, color: AppColors.tertiaryColor, size: 22),
              onPressed: onPickFile,
            ),
            IconButton(
              icon: Icon(Icons.image_rounded, color: AppColors.tertiaryColor, size: 22),
              onPressed: onPickImage,
            ),
            Expanded(
              child: Focus(
                onKeyEvent: (node, event) {
                  if (event is! KeyDownEvent) return KeyEventResult.ignored;
                  if (event.logicalKey != LogicalKeyboardKey.enter) {
                    return KeyEventResult.ignored;
                  }
                  if (HardwareKeyboard.instance.isShiftPressed) {
                    return KeyEventResult.ignored;
                  }
                  if (controller.text.trim().isNotEmpty) {
                    onSend();
                  }
                  return KeyEventResult.handled;
                },
                child: TextField(
                  controller: controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) {
                    if (controller.text.trim().isNotEmpty) onSend();
                  },
                  minLines: 1,
                  maxLines: 5,
                  style: GoogleFonts.inter(
                      color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.typeMessage,
                    hintStyle:
                        GoogleFonts.inter(color: AppColors.tertiaryColor),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onLongPress: onStartRecording,
              onLongPressUp: onStopRecording,
              child: IconButton(
                icon: Icon(
                  isRecording ? Icons.mic_rounded : Icons.mic_none_rounded,
                  color: isRecording ? Colors.red : AppColors.tertiaryColor,
                  size: 24,
                ),
                onPressed: () {},
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                final hasText = value.text.trim().isNotEmpty;
                return IconButton(
                  icon: Icon(
                    Icons.send_rounded,
                    color: hasText
                        ? AppColors.senaryColor
                        : AppColors.tertiaryColor.withValues(alpha: 0.5),
                    size: 24,
                  ),
                  onPressed: onSend,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DecryptedImageWidget extends StatefulWidget {
  final String url;
  final String keyBase64;
  final String ivBase64;

  const _DecryptedImageWidget({
    required this.url,
    required this.keyBase64,
    required this.ivBase64,
  });

  @override
  State<_DecryptedImageWidget> createState() => _DecryptedImageWidgetState();
}

class _DecryptedImageWidgetState extends State<_DecryptedImageWidget> {
  Uint8List? _decryptedBytes;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    if (_globalImageCache.containsKey(widget.url)) {
      _decryptedBytes = _globalImageCache[widget.url];
      _isLoading = false;
    } else {
      _fetchAndDecrypt();
    }
  }

  Future<void> _fetchAndDecrypt() async {
    try {
      if (widget.url.isEmpty || widget.keyBase64.isEmpty || widget.ivBase64.isEmpty) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        return;
      }

      final response = await http.get(Uri.parse(widget.url));
      if (response.statusCode == 200) {
        final aesKey = enc.Key.fromBase64(widget.keyBase64);
        final iv = enc.IV.fromBase64(widget.ivBase64);

        final encrypter = enc.Encrypter(enc.AES(aesKey, mode: enc.AESMode.cbc));
        final decryptedBytes = encrypter.decryptBytes(enc.Encrypted(response.bodyBytes), iv: iv);

        if (mounted) {
          setState(() {
            _decryptedBytes = Uint8List.fromList(decryptedBytes);
            _globalImageCache[widget.url] = _decryptedBytes!;
            _isLoading = false;
          });
        }
      } else {
        throw Exception("HTTP Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Görsel çözme hatası: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(width: 250, height: 250);
    }
    if (_hasError || _decryptedBytes == null) {
      return Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.broken_image, color: Colors.grey, size: 40),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context)!.imageLoadFailed, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.memory(
        _decryptedBytes!,
        fit: BoxFit.cover,
        width: 250,
        height: 250,
      ),
    );
  }
}

final Map<String, Uint8List> _globalImageCache = {};

class _DecryptedAudioWidget extends StatefulWidget {
  final String url;
  final String keyBase64;
  final String ivBase64;
  final Color textColor;

  const _DecryptedAudioWidget({
    required this.url,
    required this.keyBase64,
    required this.ivBase64,
    required this.textColor,
  });

  @override
  State<_DecryptedAudioWidget> createState() => _DecryptedAudioWidgetState();
}

class _DecryptedAudioWidgetState extends State<_DecryptedAudioWidget> {
  final AudioPlayer _player = AudioPlayer();
  bool _isLoading = true;
  bool _hasError = false;
  bool _isPlaying = false;
  Uint8List? _audioBytes;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
    _fetchAndDecrypt();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _fetchAndDecrypt() async {
    try {
      if (widget.url.isEmpty || widget.keyBase64.isEmpty || widget.ivBase64.isEmpty) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
        return;
      }

      final response = await http.get(Uri.parse(widget.url));
      if (response.statusCode != 200) {
        throw Exception('HTTP Error: ${response.statusCode}');
      }

      final aesKey = enc.Key.fromBase64(widget.keyBase64);
      final iv = enc.IV.fromBase64(widget.ivBase64);
      final encrypter = enc.Encrypter(enc.AES(aesKey, mode: enc.AESMode.cbc));
      final decryptedBytes = encrypter.decryptBytes(enc.Encrypted(response.bodyBytes), iv: iv);

      if (mounted) {
        setState(() {
          _audioBytes = Uint8List.fromList(decryptedBytes);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Ses çözme hatası: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  Future<void> _togglePlayback() async {
    if (_audioBytes == null) return;

    if (_isPlaying) {
      await _player.stop();
      if (mounted) setState(() => _isPlaying = false);
      return;
    }

    await _player.play(BytesSource(_audioBytes!));
    if (mounted) setState(() => _isPlaying = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Text(
        AppLocalizations.of(context)!.audioRecord,
        style: TextStyle(color: widget.textColor.withValues(alpha: 0.6)),
      );
    }

    if (_hasError || _audioBytes == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: widget.textColor.withValues(alpha: 0.7), size: 18),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context)!.unsupportedMediaType,
            style: TextStyle(color: widget.textColor),
          ),
        ],
      );
    }

    return InkWell(
      onTap: _togglePlayback,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isPlaying ? Icons.stop_circle_outlined : Icons.play_circle_outline,
            color: widget.textColor,
          ),
          const SizedBox(width: 8),
          Text(
            AppLocalizations.of(context)!.audioRecord,
            style: TextStyle(color: widget.textColor),
          ),
        ],
      ),
    );
  }
}