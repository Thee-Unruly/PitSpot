import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class SermonNotesScreen extends StatefulWidget {
  const SermonNotesScreen({super.key});

  @override
  State<SermonNotesScreen> createState() => _SermonNotesScreenState();
}

class _SermonNotesScreenState extends State<SermonNotesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTagFilter = 'All';

  // Chat Q&A State
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _chatMessages = [];
  bool _isAsking = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  Color _getTagColor(String tag) {
    switch (tag.toLowerCase()) {
      case 'key_point':
        return AppTheme.tagKeyPoint;
      case 'joke':
        return AppTheme.tagJoke;
      case 'scripture_reference':
        return AppTheme.tagScripture;
      case 'altar_call':
        return AppTheme.tagAltarCall;
      default:
        return AppTheme.primaryBlue;
    }
  }

  Color _badgeColor(String type) {
    switch (type) {
      case 'turn_to':
        return const Color(0xFF86EFAC); // Soft Green
      case 'quote':
        return const Color(0xFFFCD34D); // Soft Gold
      case 'suggestion':
        return const Color(0xFFD8B4FE); // Soft Lavender
      case 'reference':
      default:
        return const Color(0xFF67E8F9); // Neon Cyan
    }
  }

  void _copyQuote(String quote) {
    Clipboard.setData(ClipboardData(text: '"$quote"'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quote copied to clipboard!'), duration: Duration(seconds: 2)),
    );
  }

  Future<void> _sendQuestion(AppState appState) async {
    final query = _chatController.text.trim();
    if (query.isEmpty || _isAsking) return;

    _chatController.clear();
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
    final sermon = appState.currentSermon;
    final notes = appState.currentNotes;
    final segments = appState.currentSegments;

    if (sermon == null || notes == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sermon Notes')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description_outlined, size: 64, color: Colors.white24),
                SizedBox(height: 16),
                Text(
                  'No active sermon loaded.',
                  style: TextStyle(fontSize: 18, color: Colors.white70, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Start Service Mode on the Home screen to record and generate live sermon notes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(sermon.title),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryAmber,
          labelColor: AppTheme.primaryAmber,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.note_alt), text: 'Notes & Summary'),
            Tab(icon: Icon(Icons.psychology), text: 'Ask Amanda AI'),
            Tab(icon: Icon(Icons.timeline), text: 'Transcript'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Notes & Summary
          ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Preacher & Date Info Card
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Chip(
                    avatar: const Icon(Icons.person, size: 16, color: Colors.black),
                    label: Text(sermon.preacher, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    backgroundColor: AppTheme.primaryAmber,
                  ),
                  Text(sermon.date, style: const TextStyle(color: Colors.white54, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 16),

              // Summary Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: AppTheme.primaryAmber, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Sermon Summary',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        notes.summary,
                        style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Key Points Section
              const Text(
                'Key Takeaways & Points',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryAmber),
              ),
              const SizedBox(height: 12),
              ...notes.mainPoints.map((point) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle, color: AppTheme.tagKeyPoint, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            point,
                            style: const TextStyle(fontSize: 14, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),

              // Quotable Quotes Section (Velora-style Shareables)
              if (notes.quotableLines.isNotEmpty) ...[
                const Text(
                  'Memorable Quotes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryAmber),
                ),
                const SizedBox(height: 12),
                ...notes.quotableLines.map((quote) {
                  return Card(
                    color: const Color(0xFF1E2038),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.amber.withValues(alpha: 0.3)),
                    ),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.format_quote, color: AppTheme.tagJoke, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '"$quote"',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontStyle: FontStyle.italic,
                                    color: Color(0xFFF1F5F9),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: const Icon(Icons.copy, size: 16, color: Colors.amber),
                              tooltip: 'Copy Quote',
                              onPressed: () => _copyQuote(quote),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 20),
              ],

              // Scripture Mentions Section (with classification badges)
              const Text(
                'Scriptures Preached & Referenced',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryAmber),
              ),
              const SizedBox(height: 12),
              ...notes.scriptures.map((sc) {
                final badgeColor = _badgeColor(sc.type);
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: badgeColor.withValues(alpha: 0.3)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  sc.citation,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: badgeColor),
                                  ),
                                  child: Text(
                                    sc.typeLabel.toUpperCase(),
                                    style: TextStyle(
                                      color: badgeColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (sc.timestamp != null)
                              Text(
                                sc.timestamp!,
                                style: const TextStyle(color: Colors.white38, fontSize: 12),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '"${sc.verseText}"',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                            fontFamily: 'serif',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              appState.setTargetBibleReference(sc.citation);
                            },
                            icon: const Icon(Icons.menu_book, size: 16, color: AppTheme.primaryAmber),
                            label: const Text('Read in Bible Reader', style: TextStyle(color: AppTheme.primaryAmber)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),

          // Tab 2: Ask Amanda AI (Interactive Sermon Q&A)
          Column(
            children: [
              // Prompt Suggestion Bar
              Container(
                padding: const EdgeInsets.all(12),
                color: const Color(0xFF141628),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      'How do I apply point 1 this week?',
                      'Explain the context of the main scripture',
                      'Summarize this sermon for small group',
                    ].map((prompt) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ActionChip(
                          avatar: const Icon(Icons.chat_bubble_outline, size: 12, color: Colors.amber),
                          label: Text(prompt),
                          backgroundColor: const Color(0xFF1E2038),
                          labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
                          onPressed: () {
                            _chatController.text = prompt;
                            _sendQuestion(appState);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Chat Message Stream
              Expanded(
                child: _chatMessages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.psychology, size: 48, color: Colors.amber),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Engage Beyond Sunday',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Ask Amanda AI anything about today\'s sermon, pastoral points, or practical life application.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white54, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _chatMessages.length,
                        itemBuilder: (context, index) {
                          final msg = _chatMessages[index];
                          final isUser = msg['role'] == 'user';
                          return Align(
                            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.82),
                              decoration: BoxDecoration(
                                color: isUser ? Colors.amber : const Color(0xFF1E2138),
                                borderRadius: BorderRadius.circular(16),
                                border: isUser ? null : Border.all(color: Colors.white12),
                              ),
                              child: Text(
                                msg['text'] ?? '',
                                style: TextStyle(
                                  color: isUser ? Colors.black : Colors.white,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),

              if (_isAsking)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber)),
                      SizedBox(width: 8),
                      Text('Amanda AI is reflecting on the sermon...', style: TextStyle(color: Colors.amber, fontSize: 12)),
                    ],
                  ),
                ),

              // Input Row
              Container(
                padding: const EdgeInsets.all(12),
                color: const Color(0xFF121422),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatController,
                        onSubmitted: (_) => _sendQuestion(appState),
                        decoration: InputDecoration(
                          hintText: 'Ask a question about this sermon...',
                          hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                          filled: true,
                          fillColor: const Color(0xFF1F223C),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: () => _sendQuestion(appState),
                      style: IconButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                      icon: const Icon(Icons.send, size: 20),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Tab 3: Tagged Transcript
          Column(
            children: [
              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: ['All', 'key_point', 'scripture_reference', 'joke', 'altar_call'].map((tag) {
                    final isSelected = _selectedTagFilter == tag;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(tag == 'All' ? 'All Moments' : tag.replaceAll('_', ' ').toUpperCase()),
                        selectedColor: AppTheme.primaryAmber,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        onSelected: (val) {
                          setState(() => _selectedTagFilter = tag);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Filtered Transcript List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: segments.length,
                  itemBuilder: (context, index) {
                    final seg = segments[index];

                    if (_selectedTagFilter != 'All' && !seg.tags.contains(_selectedTagFilter)) {
                      return const SizedBox.shrink();
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${seg.speaker} • ${seg.start}',
                                  style: const TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.bold),
                                ),
                                Wrap(
                                  spacing: 4,
                                  children: seg.tags.map((t) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getTagColor(t).withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: _getTagColor(t), width: 1),
                                      ),
                                      child: Text(
                                        t.replaceAll('_', ' ').toUpperCase(),
                                        style: TextStyle(
                                          color: _getTagColor(t),
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              seg.text,
                              style: const TextStyle(fontSize: 14, color: Colors.white70, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

