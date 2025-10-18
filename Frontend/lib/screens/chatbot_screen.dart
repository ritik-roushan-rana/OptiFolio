import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';
import '../widgets/gradient_background.dart';
import 'dart:ui';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();

  // Placeholder for chat messages (user and bot)
  final List<Map<String, String>> _messages = [];

  Future<String> getAuthToken() async {
    return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY4ZDQxMGEyZWExMWE0MTQxNjk5NWIyZiIsImlhdCI6MTc2MDc2NzQyMSwiZXhwIjoxNzYwNzcxMDIxfQ.8Qffa2E3NtX-lrE0pdwhE3FbHfKooYR1m8MrgWluybw';
  }

  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      final userMessage = _messageController.text.trim();
      setState(() {
        _messages.insert(0, {'role': 'user', 'text': userMessage});
        _messages.insert(0, {'role': 'bot', 'text': 'Analyzing data...'}); // Show intermediate feedback as plain text
        _messageController.clear();
      });

      try {
        final response = await http.post(
          Uri.parse('http://15.206.217.186:3000/api/chatbot'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${await getAuthToken()}',
          },
          body: json.encode({'message': userMessage}),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          setState(() {
            _messages.removeAt(0); // Remove "Analyzing data..."
            _messages.insert(0, {'role': 'bot', 'text': data['reply']});
          });
        } else {
          setState(() {
            _messages.removeAt(0); // Remove "Analyzing data..."
            _messages.insert(0, {
              'role': 'bot',
              'text': 'Error: Unable to get a response from the server.',
            });
          });
        }
      } catch (e) {
        setState(() {
          _messages.removeAt(0); // Remove "Analyzing data..."
          _messages.insert(0, {
            'role': 'bot',
            'text': 'Error: $e',
          });
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isUser = msg['role'] == 'user';
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: 6,
                            bottom: 6,
                            left: isUser ? 40 : 0,
                            right: isUser ? 0 : 40,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? AppColors.primary.withOpacity(0.85)
                                      : Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 8,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(14),
                                child: Text(
                                  msg['text'] ?? '',
                                  style: GoogleFonts.inter(
                                    color: isUser
                                        ? Colors.white
                                        : Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                _buildMessageInput(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.smart_toy, color: AppColors.primary, size: 28),
                const SizedBox(width: 8),
                Text(
                  'AI Assistant',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      decoration: const BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _messageController,
                style: GoogleFonts.inter(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: GoogleFonts.inter(color: AppColors.mutedText),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(10),
              child: const Icon(Icons.send, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}