import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class AskVeloraScreen extends StatefulWidget {
  final VoidCallback? onClose;
  const AskVeloraScreen({super.key, this.onClose});

  @override
  State<AskVeloraScreen> createState() => _AskVeloraScreenState();
}

class _AskVeloraScreenState extends State<AskVeloraScreen> {
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _chatMessages = [];
  bool _isAsking = false;
  String _selectedRelayFilter = 'All Relays';

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _sendQuestion(AppState appState, {String? customText}) async {
    final query = (customText ?? _chatController.text).trim();
    if (query.isEmpty || _isAsking) return;

    if (customText == null) {
      _chatController.clear();
    }

    setState(() {
      _chatMessages.add({'role': 'user', 'text': query});
      _isAsking = true;
    });

    final answer = await appState.askSermonQuestion(query);

    setState(() {
      _chatMessages.add({'role': 'assistant', 'text': answer});
      _isAsking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0C0E14),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Close (X), Title, History (clock), New Note (pencil) (Screenshot 2)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 22),
                    onPressed: () {
                      if (widget.onClose != null) {
                        widget.onClose!();
                      } else {
                        Navigator.maybePop(context);
                      }
                    },
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.access_time, color: Colors.white70, size: 22),
                        tooltip: 'History',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Viewing conversation history')),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_note_outlined, color: Colors.white70, size: 24),
                        tooltip: 'New note',
                        onPressed: () {
                          setState(() {
                            _chatMessages.clear();
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Chat & Content Body
            Expanded(
              child: _chatMessages.isEmpty
                  ? SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                        child: Column(
                          children: [
                            const SizedBox(height: 12),

                            // Main Title: "Ask anything about what you've been learning"
                            const Text(
                              'Ask anything about\nwhat you\'ve been learning',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                height: 1.3,
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 36),

                            // Centered Velora Sparkle Logo
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF1E2130),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Center(
                                child: Stack(
                                  alignment: Alignment.topRight,
                                  children: [
                                    const Icon(
                                      Icons.chat_bubble_outline,
                                      color: Color(0xFFE2E8F0),
                                      size: 28,
                                    ),
                                    Transform.translate(
                                      offset: const Offset(4, -4),
                                      child: const Icon(
                                        Icons.auto_awesome,
                                        color: AppTheme.primaryAmber,
                                        size: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Welcome to Ask Velora
                            const Text(
                              'Welcome to Ask Velora',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Reflect on the Bible teaching you\'ve heard',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Prompt Action Pills (Screenshot 2: Row 1 & Row 2)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildPillChip('🧘 Meditate', () {
                                  _sendQuestion(appState,
                                      customText:
                                          'Guide me through a biblical meditation and reflection on the sermon preached today.');
                                }),
                                const SizedBox(width: 10),
                                _buildPillChip('🧠 Quiz me', () {
                                  _sendQuestion(appState,
                                      customText:
                                          'Quiz me with 3 questions to test how well I understood today\'s sermon.');
                                }),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _buildPillChip('👥 Make discussion guide', () {
                              _sendQuestion(appState,
                                  customText:
                                      'Create a small group discussion guide with 5 questions based on today\'s sermon.');
                            }),
                            const SizedBox(height: 10),
                            _buildPillChip('👨‍👩‍👧 Family discussion questions', () {
                              _sendQuestion(appState,
                                  customText:
                                      'Generate family dinner discussion questions connecting today\'s sermon to everyday life.');
                            }),

                            const SizedBox(height: 36),

                            // Feature Checklist (Screenshot 2)
                            const Text(
                              'GENERATE SERMON-BASED:',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildCheckItem('Devotionals'),
                                const SizedBox(width: 16),
                                _buildCheckItem('Small group guides'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildCheckItem('Quizzes'),
                                const SizedBox(width: 16),
                                _buildCheckItem('Family discussion questions'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      itemCount: _chatMessages.length,
                      itemBuilder: (context, index) {
                        final msg = _chatMessages[index];
                        final isUser = msg['role'] == 'user';
                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.84,
                            ),
                            decoration: BoxDecoration(
                              color: isUser ? AppTheme.primaryAmber : const Color(0xFF1B1E2E),
                              borderRadius: BorderRadius.circular(18),
                              border: isUser ? null : Border.all(color: AppTheme.darkCardBorder),
                            ),
                            child: Text(
                              msg['text'] ?? '',
                              style: TextStyle(
                                color: isUser ? Colors.black : const Color(0xFFF1F5F9),
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            if (_isAsking)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryAmber),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Velora is reflecting on the sermon...',
                      style: TextStyle(color: AppTheme.primaryAmber, fontSize: 12),
                    ),
                  ],
                ),
              ),

            // Input Field Container (Screenshot 2 Style)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF161926),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.darkCardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _chatController,
                    onSubmitted: (_) => _sendQuestion(appState),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Ask anything. Type @ for mentions.',
                      hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // "All Relays ⌄" Dropdown Chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF222638),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedRelayFilter,
                          underline: const SizedBox.shrink(),
                          icon: const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.white70),
                          dropdownColor: const Color(0xFF1A1D2B),
                          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                          items: ['All Relays', 'Current Sermon', 'Bible Passage'].map((s) {
                            return DropdownMenuItem(value: s, child: Text(s));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedRelayFilter = val);
                            }
                          },
                        ),
                      ),

                      // Send Button in Circle
                      GestureDetector(
                        onTap: () => _sendQuestion(appState),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Color(0xFF33384F),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_upward,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF181B28),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.darkCardBorder),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFFE2E8F0),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCheckItem(String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            color: Color(0xFF22C55E),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, size: 11, color: Colors.black),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
