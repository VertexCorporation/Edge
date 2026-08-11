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
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/colors.dart';
import '../widgets/background.dart';
import '../services/chat_service.dart';

class ChatDetailScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatDetailScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ImagePicker _picker = ImagePicker();
  
  final AudioRecorder _record = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isRecording = false;
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _record.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    try {
      await _chatService.sendMessage(widget.receiverId, text, type: 'text');
      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
      }
    }
    if (mounted) setState(() => _isSending = false);
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
      await _chatService.sendFile(widget.receiverId, bytes, type);
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
      appBar: AppBar(
        backgroundColor: VertexColors.glassBg(brightness),
        elevation: 0,
        title: Text(
          widget.receiverName,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: GeoBackground(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _chatService.getMessages(widget.receiverId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final messages = snapshot.data ?? [];
                  
                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg['senderId'] == _chatService.currentUserId;
                      return _buildMessageBubble(msg, isMe, brightness, isDark);
                    },
                  );
                },
              ),
            ),
            if (_isSending)
               const Padding(
                 padding: EdgeInsets.all(8.0),
                 child: LinearProgressIndicator(),
               ),
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
          content = Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               const FaIcon(FontAwesomeIcons.image, size: 40, color: Colors.grey),
               const SizedBox(height: 4),
               Text('Şifreli Görsel (Link: ${payload['url'].substring(0, 20)}...)', 
                    style: TextStyle(color: isMe ? Colors.white : Colors.black)),
             ],
          );
        } else if (type == 'audio') {
          content = Row(
             mainAxisSize: MainAxisSize.min,
             children: [
               const FaIcon(FontAwesomeIcons.microphone, color: Colors.grey),
               const SizedBox(width: 8),
               Text('Ses Kaydı', style: TextStyle(color: isMe ? Colors.white : Colors.black)),
             ],
          );
        } else {
           content = Row(
             mainAxisSize: MainAxisSize.min,
             children: [
               const FaIcon(FontAwesomeIcons.file, color: Colors.grey),
               const SizedBox(width: 8),
               Text('Dosya: ${payload['fileName']}', style: TextStyle(color: isMe ? Colors.white : Colors.black)),
             ],
          );
        }
      } catch (e) {
         content = const Text('Desteklenmeyen Medya Tipi');
      }
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMe 
              ? VertexColors.primary(brightness) 
              : VertexColors.glassBg(brightness),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
          border: isMe ? null : Border.all(color: VertexColors.glassBorder(brightness)),
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
          color: VertexColors.glassBg(brightness),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: VertexColors.glassBorder(brightness)),
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
              icon: FaIcon(FontAwesomeIcons.paperclip, color: VertexColors.textMuted(brightness), size: 20),
              onPressed: _pickAndSendFile,
            ),
            IconButton(
              icon: FaIcon(FontAwesomeIcons.image, color: VertexColors.textMuted(brightness), size: 20),
              onPressed: _pickAndSendImage,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: 'Bir mesaj yaz...',
                  hintStyle: GoogleFonts.inter(color: VertexColors.textMuted(brightness)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
            ),
            GestureDetector(
              onLongPress: _startRecording,
              onLongPressUp: _stopRecording,
              child: IconButton(
                icon: FaIcon(
                  _isRecording ? FontAwesomeIcons.microphone : FontAwesomeIcons.microphoneLines, 
                  color: _isRecording ? Colors.red : VertexColors.textMuted(brightness),
                  size: 20,
                ),
                onPressed: () {},
              ),
            ),
            IconButton(
              icon: FaIcon(FontAwesomeIcons.paperPlane, color: VertexColors.primary(brightness), size: 20),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
