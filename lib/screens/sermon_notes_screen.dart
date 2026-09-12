import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class SermonNotesScreen extends StatefulWidget {
  const SermonNotesScreen({super.key});

  @override
  State<SermonNotesScreen> createState() => _SermonNotesScreenState();
}

class _SermonNotesScreenState extends State<SermonNotesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isFormattedView = true; // Toggle between 'Formatted' and 'List'

  // Chat Q&A State (Screenshot 2: Ask Velora)
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _chatMessages = [];
  bool _isAsking = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  void _copyText(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
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

  void _showShareModal(BuildContext context, Sermon sermon) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF131624),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Export & Share Relay',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Share formatted transcripts, summaries, and references.',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 18),

              // Sharing Link Box (Screenshot 4 Style)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1E30),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.darkCardBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'https://velora.bible/relay/${sermon.id.replaceAll("-", "").substring(0, 16)}',
                        style: const TextStyle(
                          color: Color(0xFF67E8F9),
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: AppTheme.primaryAmber, size: 18),
                      tooltip: 'Copy link',
                      onPressed: () {
                        _copyText(
                          'https://velora.bible/relay/${sermon.id.replaceAll("-", "").substring(0, 16)}',
                          'Relay link copied to clipboard!',
                        );
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Share Targets Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _shareTargetItem(Icons.chat, 'Messages', Colors.blue, () {
                    Navigator.pop(ctx);
                    _copyText(
                      'Sermon: ${sermon.title}\nPreacher: ${sermon.preacher}\nhttps://velora.bible/relay/${sermon.id}',
                      'Shared to Messages!',
                    );
                  }),
                  _shareTargetItem(Icons.send, 'Telegram', Colors.cyan, () {
                    Navigator.pop(ctx);
                    _copyText(
                      'Sermon: ${sermon.title}\nhttps://velora.bible/relay/${sermon.id}',
                      'Shared to Telegram!',
                    );
                  }),
                  _shareTargetItem(Icons.cloud_upload, 'Drive', Colors.green, () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Transcripts uploaded to Cloud Drive!')),
                    );
                  }),
                  _shareTargetItem(Icons.picture_as_pdf, 'PDF Export', AppTheme.primaryAmber, () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Worship-grade PDF formatted & generated!')),
                    );
                  }),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _shareTargetItem(IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final sermon = appState.currentSermon;
    final notes = appState.currentNotes;
    final segments = appState.currentSegments;

    if (sermon == null || notes == null) {
      return Scaffold(
        backgroundColor: AppTheme.darkBackground,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryAmber.withValues(alpha: 0.12),
                    border: Border.all(color: AppTheme.primaryAmber.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.menu_book, size: 36, color: AppTheme.primaryAmber),
                ),
                const SizedBox(height: 20),
                const Text(
                  'No active sermon loaded',
                  style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Start Service Relay on the Home screen or load a sermon from the Vault to view worship-grade transcripts and AI reflection.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: Text(sermon.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share, color: Colors.white70),
            tooltip: 'Share & Export',
            onPressed: () => _showShareModal(context, sermon),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryAmber,
          labelColor: AppTheme.primaryAmber,
          unselectedLabelColor: Colors.white54,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Transcript'),
            Tab(text: 'References'),
            Tab(text: 'Summary'),
            Tab(text: 'Ask Velora AI'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: WORSHIP-GRADE FORMATTED TRANSCRIPT (Screenshots 3 & 4)
          _buildWorshipTranscriptView(appState, sermon, notes, segments),

          // TAB 2: REFERENCES & SCRIPTURE MENTIONS
          _buildReferencesView(appState, notes),

          // TAB 3: SUMMARY & KEY TAKEAWAYS
          _buildSummaryView(notes),

          // TAB 4: ASK VELORA AI (Screenshot 2)
          _buildAskVeloraView(appState),
        ],
      ),
    );
  }

  /// Worship-grade formatted transcript viewer (Screenshot 3 & 4)
  Widget _buildWorshipTranscriptView(
    AppState appState,
    Sermon sermon,
    SermonNotes notes,
    List<TranscriptSegment> segments,
  ) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      children: [
        // Sermon Info Banner & View Toggle (Screenshot 4)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              sermon.date,
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
            // Formatted | List Switcher
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF181B28),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.darkCardBorder),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _isFormattedView = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: !_isFormattedView ? AppTheme.primaryAmber : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'List',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: !_isFormattedView ? Colors.black : Colors.white60,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _isFormattedView = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isFormattedView ? AppTheme.primaryAmber : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Formatted',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _isFormattedView ? Colors.black : Colors.white60,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Large Sermon Title
        Text(
          sermon.title,
          style: AppTheme.sermonTitleStyle,
        ),
        const SizedBox(height: 10),

        // Preacher Badge & Duration
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2132),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.darkCardBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 9,
                    backgroundColor: AppTheme.primaryAmber,
                    child: Text(
                      sermon.preacher.isNotEmpty ? sermon.preacher.substring(0, 1) : 'P',
                      style: const TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    sermon.preacher,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${segments.length * 2}:14',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 24),

        if (!_isFormattedView)
          // Simple Segmented List Mode
          ...segments.map((seg) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.darkSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.darkCardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${seg.speaker} • ${seg.start}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.primaryAmber, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    seg.text,
                    style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 14, height: 1.45),
                  ),
                ],
              ),
            );
          })
        else
          // Rich Formatted Worship Transcript (Screenshot 3 Style)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Diamond Thesis Callout
              Center(
                child: Column(
                  children: [
                    const Icon(Icons.diamond_outlined, color: Color(0xFFCBD5E1), size: 18),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        notes.summary.isNotEmpty
                            ? notes.summary
                            : 'God fulfills his promises to his covenant people in specific ways throughout redemptive history.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          fontFamily: 'serif',
                          color: Color(0xFFCBD5E1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Section 1: Introduction / Glorifying God's Name
              const Text(
                'Glorifying God\'s Great Name',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 12),

              // Main Sermon Body with Inline Scripture Badge (Screenshot 3)
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.7,
                    color: Color(0xFFE2E8F0),
                    fontFamily: 'serif',
                  ),
                  children: [
                    TextSpan(
                      text: segments.isNotEmpty
                          ? segments.first.text
                          : 'To know his name is to understand His nature and to recognize that he alone is worthy of worship and adoration. His sacred covenant name signifies his self-existence and faithfulness to His promises. It shows his unwavering commitment to his own glory and his covenant. ',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Inline Scripture Tag Pill (e.g. • Isaiah 42:8 +3)
              if (notes.scriptures.isNotEmpty)
                Wrap(
                  spacing: 8,
                  children: notes.scriptures.take(2).map((sc) {
                    return InkWell(
                      onTap: () => appState.setTargetBibleReference(sc.citation),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E2638),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF38BDF8),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              sc.citation,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 20),

              // Interactive Context Card (Screenshot 3: Purple Ambient Box)
              if (notes.scriptures.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1528),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.relaySuggestion.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.relaySuggestion.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lightbulb_outline,
                          color: AppTheme.relaySuggestion,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              notes.scriptures.first.citation,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'The sermon references the sacred covenant truth in ${notes.scriptures.first.citation}.',
                              style: const TextStyle(
                                color: Color(0xFFCBD5E1),
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
                        onPressed: () => appState.setTargetBibleReference(notes.scriptures.first.citation),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Scripture Reading Inset Card (Screenshot 4)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141724),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.darkCardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.menu_book, color: AppTheme.primaryAmber, size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          'SCRIPTURE READING',
                          style: TextStyle(
                            color: AppTheme.primaryAmber,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      notes.scriptures.isNotEmpty
                          ? notes.scriptures.first.verseText
                          : 'Blessed is the man who walks not in the counsel of the wicked, nor stands in the way of sinners, nor sits in the seat of scoffers.',
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Color(0xFFF1F5F9),
                        height: 1.55,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Prayer Callout Box (Screenshot 3)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF151822),
                  borderRadius: BorderRadius.circular(16),
                  border: const Border(
                    left: BorderSide(color: AppTheme.primaryAmber, width: 3.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.church_outlined, color: AppTheme.primaryAmber, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'PASTORAL PRAYER',
                          style: TextStyle(
                            color: AppTheme.primaryAmber,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Our gracious God and heavenly Father, we thank you for revealing yourself to us through your Word. Help us to live lives that testify to the glory, majesty, and power of your great name. We ask it in Jesus\' name, amen.',
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        fontFamily: 'serif',
                        height: 1.6,
                        color: Color(0xFFF1F5F9),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Congregational Singing Cue (Screenshot 3)
              Row(
                children: [
                  const Icon(Icons.music_note, color: Color(0xFFF472B6), size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Congregational singing... Let\'s stand and sing "To God Be the Glory!"',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
      ],
    );
  }

  /// Tab 2: References & Bible Mentions View
  Widget _buildReferencesView(AppState appState, SermonNotes notes) {
    if (notes.scriptures.isEmpty) {
      return const Center(
        child: Text('No scripture references recorded for this sermon.', style: TextStyle(color: Colors.white54)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notes.scriptures.length,
      itemBuilder: (context, index) {
        final sc = notes.scriptures[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      sc.citation,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryAmber,
                      ),
                    ),
                    Text(
                      sc.typeLabel.toUpperCase(),
                      style: const TextStyle(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  sc.verseText,
                  style: const TextStyle(
                    fontFamily: 'serif',
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFFE2E8F0),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => appState.setTargetBibleReference(sc.citation),
                    icon: const Icon(Icons.menu_book, size: 15, color: AppTheme.primaryAmber),
                    label: const Text('Read in Bible', style: TextStyle(color: AppTheme.primaryAmber, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Tab 3: Sermon Summary & Main Takeaways
  Widget _buildSummaryView(SermonNotes notes) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppTheme.primaryAmber, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Executive Summary',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  notes.summary,
                  style: const TextStyle(fontSize: 14, color: Color(0xFFCBD5E1), height: 1.5),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Key Points
        const Text(
          'Key Takeaways',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 10),
        ...notes.mainPoints.map((point) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.darkSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.darkCardBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle, color: AppTheme.tagKeyPoint, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    point,
                    style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  /// Tab 4: Ask Velora AI Screen (Screenshot 2 Style)
  Widget _buildAskVeloraView(AppState appState) {
    return Column(
      children: [
        // Prompt Chips Section (Screenshot 2)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPromptChip('🧘 Meditate', 'Give me a guided biblical meditation on this sermon'),
                _buildPromptChip('🧠 Quiz me', 'Quiz me with 3 questions to test my understanding of this sermon'),
                _buildPromptChip('👥 Make discussion guide', 'Generate a small group discussion guide for this sermon'),
                _buildPromptChip('👨‍👩‍👧 Family questions', 'Generate family dinner discussion questions based on this sermon'),
              ],
            ),
          ),
        ),

        // Chat Stream
        Expanded(
          child: _chatMessages.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Velora Sparkle Logo (Screenshot 2)
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.relaySuggestion.withValues(alpha: 0.15),
                            border: Border.all(color: AppTheme.relaySuggestion.withValues(alpha: 0.4)),
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline,
                            color: AppTheme.relaySuggestion,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Welcome to Ask Velora',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Reflect on the Bible teaching you\'ve heard.\nGenerate sermon-based devotionals, discussion guides, quizzes & family reflections.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.4),
                        ),
                        const SizedBox(height: 20),

                        // Checklist Highlights (Screenshot 2)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF151824),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.darkCardBorder),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'GENERATE SERMON-BASED:',
                                style: TextStyle(
                                  color: AppTheme.primaryAmber,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF4ADE80)),
                                  SizedBox(width: 6),
                                  Text('Devotionals', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  SizedBox(width: 14),
                                  Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF4ADE80)),
                                  SizedBox(width: 6),
                                  Text('Small group guides', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                              SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF4ADE80)),
                                  SizedBox(width: 6),
                                  Text('Quizzes', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  SizedBox(width: 14),
                                  Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF4ADE80)),
                                  SizedBox(width: 6),
                                  Text('Family questions', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
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
                          color: isUser ? AppTheme.primaryAmber : const Color(0xFF1E2132),
                          borderRadius: BorderRadius.circular(16),
                          border: isUser ? null : Border.all(color: AppTheme.darkCardBorder),
                        ),
                        child: Text(
                          msg['text'] ?? '',
                          style: TextStyle(
                            color: isUser ? Colors.black : Colors.white,
                            fontSize: 13,
                            height: 1.45,
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
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryAmber)),
                SizedBox(width: 10),
                Text('Velora is reflecting on the sermon...', style: TextStyle(color: AppTheme.primaryAmber, fontSize: 12)),
              ],
            ),
          ),

        // Chat Input Box (Screenshot 2 Style)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
            color: Color(0xFF10121C),
            border: Border(top: BorderSide(color: Colors.white12)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatController,
                  onSubmitted: (_) => _sendQuestion(appState),
                  decoration: InputDecoration(
                    hintText: 'Ask anything. Type @ for mentions...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF1B1E2E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: const BoxDecoration(
                  color: AppTheme.primaryAmber,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_upward, color: Colors.black, size: 20),
                  onPressed: () => _sendQuestion(appState),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPromptChip(String label, String prompt) {
    final appState = Provider.of<AppState>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        label: Text(label),
        backgroundColor: const Color(0xFF1A1D2B),
        side: const BorderSide(color: Colors.white12),
        labelStyle: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600),
        onPressed: () => _sendQuestion(appState, customText: prompt),
      ),
    );
  }
}
