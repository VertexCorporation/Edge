import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:encrypt/encrypt.dart' as enc;
import 'package:shimmer/shimmer.dart';
import '../../theme.dart';
import '../../services/chat.dart';
import '../../widgets/appbar.dart';
import '../../widgets/fog.dart';
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
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isRecording = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _record.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Optimistic UI Update: Clear immediately
    _messageController.clear();
    
    // Fire and forget
    _chatService.sendMessage(
      text, 
      type: 'text',
      receiverId: widget.receiverId,
      explicitChatId: widget.chatId,
      isGroup: widget.isGroup,
    ).catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gönderilemedi: $e')));
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
    final FilePickerResult? result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null) {
      if (result.files.single.bytes != null) {
        _sendFile(result.files.single.bytes!, 'file');
      } else if (result.files.single.path != null) {
        final bytes = await File(result.files.single.path!).readAsBytes();
        _sendFile(bytes, 'file');
      }
    }
  }

  Future<void> _sendFile(Uint8List bytes, String type) async {
    setState(() => _isSending = true);
    try {
      // Not awaiting the main send operation for UI optimisim, but files do need uploading first.
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
    if (mounted) setState(() => _isSending = false);
  }

  Future<void> _startRecording() async {
    try {
      if (await _record.hasPermission()) {
        final dir = await getApplicationDocumentsDirectory();
        final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
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
    try {
      final path = await _record.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        final bytes = await File(path).readAsBytes();
        _sendFile(bytes, 'audio');
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
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _chatService.getMessages(
                  widget.chatId ?? _chatService.getChatId(_chatService.currentUserId, widget.receiverId!),
                  isGroup: widget.isGroup,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final messages = snapshot.data ?? [];
                  
                  return ScrollFog(
                    scrollController: _scrollController,
                    color: AppColors.background,
                    child: ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg['senderId'] == _chatService.currentUserId;
                        return _buildMessageBubble(msg, isMe, brightness, isDark);
                      },
                    ),
                  );
                },
              ),
            ),
            if (_isSending)
               const Padding(
                 padding: EdgeInsets.all(8.0),
                 child: LinearProgressIndicator(),
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
               _buildInputArea(brightness, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe, Brightness brightness, bool isDark) {
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
      // Decode payload
      try {
        final payload = jsonDecode(text);
        if (type == 'image') {
          final link = (payload['url'] ?? '').toString();
          content = _DecryptedImageWidget(
            url: link,
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
               Text(AppLocalizations.of(context)!.fileWithFileName(payload['fileName'] ?? ''), style: TextStyle(color: isMe ? Colors.white : Colors.black)),
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
          color: isMe 
              ? AppColors.senaryColor 
              : AppColors.secondaryColor,
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

  Widget _buildInputArea(Brightness brightness, bool isDark) {
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
              onPressed: _pickAndSendFile,
            ),
            IconButton(
              icon: Icon(Icons.image_rounded, color: AppColors.tertiaryColor, size: 22),
              onPressed: _pickAndSendImage,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.typeMessage,
                  hintStyle: GoogleFonts.inter(color: AppColors.tertiaryColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
            GestureDetector(
              onLongPress: _startRecording,
              onLongPressUp: _stopRecording,
              child: IconButton(
                icon: Icon(
                  _isRecording ? Icons.mic_rounded : Icons.mic_none_rounded, 
                  color: _isRecording ? Colors.red : AppColors.tertiaryColor, 
                  size: 24
                ),
                onPressed: () {},
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.send_rounded, 
                color: _messageController.text.trim().isEmpty 
                    ? AppColors.tertiaryColor.withValues(alpha: 0.5) 
                    : AppColors.senaryColor, 
                size: 24
              ),
              onPressed: _sendMessage,
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
      return Shimmer.fromColors(
        baseColor: Colors.grey[800]!,
        highlightColor: Colors.grey[600]!,
        child: Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
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
      return SizedBox(
        width: 120,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: widget.textColor),
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