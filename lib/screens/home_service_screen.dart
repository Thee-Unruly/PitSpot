import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../theme/velora_icons.dart';
import 'processing_screen.dart';
import 'settings_screen.dart';
import 'ask_velora_screen.dart';

class HomeServiceScreen extends StatefulWidget {
  const HomeServiceScreen({super.key});

  @override
  State<HomeServiceScreen> createState() => _HomeServiceScreenState();
}

class _HomeServiceScreenState extends State<HomeServiceScreen> {
  int _selectedDailyVerseIndex = 0;

  final List<Map<String, String>> _dailyVerses = [
    {
      'verse': 'I can do all things through him who strengthens me.',
      'citation': 'PHILIPPIANS 4:13',
      'version': 'ESV',
      'context':
          'After Jason\'s sermons on Christ\'s humility, Paul reminds you: in Christ you have strength for every need.',
    },
    {
      'verse':
          'And we know that in all things God works for the good of those who love him, who have been called according to his purpose.',
      'citation': 'ROMANS 8:28',
      'version': 'ESV',
      'context':
          'God orchestrates every season of difficulty for your ultimate sanctification and His enduring glory.',
    },
    {
      'verse':
          'For I know the plans I have for you, declares the LORD, plans for welfare and not for evil, to give you a future and a hope.',
      'citation': 'JEREMIAH 29:11',
      'version': 'ESV',
      'context':
          'Spoken to exiles in Babylon, God\'s sovereign covenant promises remain unbreakable through every trial.',
    },
  ];

  void _shareDailyVerse(Map<String, String> item) {
    Clipboard.setData(ClipboardData(
        text: '"${item['verse']}" — ${item['citation']} (${item['version']})\n${item['context']}'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verse & reflection copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _cycleNextVerse() {
    setState(() {
      _selectedDailyVerseIndex = (_selectedDailyVerseIndex + 1) % _dailyVerses.length;
    });
  }

  void _openAskVelora() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AskVeloraScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    if (appState.recordingStatus == ServiceRecordingStatus.recording) {
      return const ServiceRecordingView();
    } else if (appState.recordingStatus == ServiceRecordingStatus.processing) {
      return const ProcessingScreen();
    }

    final daily = _dailyVerses[_selectedDailyVerseIndex];

    return Scaffold(
      backgroundColor: const Color(0xFF090B10),
      body: Stack(
        children: [
          // Atmospheric Oil-Painting Background that dissolves into deep black
          Positioned.fill(
            child: Column(
              children: [
                Expanded(
                  flex: 6,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/velora_mountain.jpg',
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF22293A), Color(0xFF0D0F18)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          );
                        },
                      ),
                      // Top gradient for status bar clarity
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 100,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.65),
                                Colors.transparent,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                      // Bottom gradient dissolve into deep obsidian
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 180,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                const Color(0xFF090B10).withValues(alpha: 0.8),
                                const Color(0xFF090B10),
                              ],
                              stops: const [0.0, 0.6, 1.0],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Container(color: const Color(0xFF090B10)),
                ),
              ],
            ),
          ),

          // Main Foreground Content (Screenshot 1 Layout)
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Brand Bar: Stylized Wheat/Fan Logo + V E L O R A
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CustomPaint(
                            size: const Size(20, 20),
                            painter: VeloraLogoPainter(color: const Color(0xFFF3E8D8)),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'VELORA',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 7.0,
                              color: Color(0xFFF3E8D8),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white70, size: 20),
                            tooltip: 'Ask Velora',
                            onPressed: _openAskVelora,
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings_outlined, color: Colors.white70, size: 20),
                            tooltip: 'Settings',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SettingsScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Daily Verse Section (Screenshot 1 Exact Layout)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // "Daily verse" Tag Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2A2016).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFF92673D).withValues(alpha: 0.6),
                            width: 0.8,
                          ),
                        ),
                        child: const Text(
                          'Daily verse',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFDE68A),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Large Serif Verse Quote
                      Text(
                        daily['verse']!,
                        style: const TextStyle(
                          fontSize: 24,
                          height: 1.45,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'serif',
                          color: Colors.white,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Citation, Version, Share & Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                daily['citation']!,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.4,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  daily['version']!,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white60,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.ios_share, color: Colors.white70, size: 18),
                                tooltip: 'Share verse',
                                onPressed: () => _shareDailyVerse(daily),
                                visualDensity: VisualDensity.compact,
                              ),
                              IconButton(
                                icon: const Icon(Icons.more_horiz, color: Colors.white70, size: 20),
                                tooltip: 'Next verse',
                                onPressed: _cycleNextVerse,
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Pastoral Reflection Note
                      Text(
                        daily['context']!,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Bottom Pulpit / Altar Gateway (Screenshot 1 Bottom Illuminated Pulpit Icon)
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      await appState.startServiceMode();
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 52,
                          padding: const EdgeInsets.all(4),
                          child: CustomPaint(
                            size: const Size(48, 44),
                            painter: VeloraPulpitPainter(
                              color: const Color(0xFFD4AF37),
                              glow: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'TAP TO START RELAY',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.0,
                            color: Color(0xFFD4AF37),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Live Service Recording Screen matching Screenshot 5
class ServiceRecordingView extends StatelessWidget {
  const ServiceRecordingView({super.key});

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Color _nodeColor(String type) {
    switch (type) {
      case 'turn_to':
        return const Color(0xFF4ADE80); // Mint Emerald [📖]
      case 'quote':
        return const Color(0xFFFBBF24); // Warm Gold [99]
      case 'suggestion':
        return const Color(0xFFC084FC); // Soft Purple [💡]
      case 'reference':
      default:
        return const Color(0xFF38BDF8); // Cyan [•]
    }
  }

  Widget _buildNodeBadge(String type) {
    switch (type) {
      case 'quote':
        return CustomPaint(
          size: const Size(18, 18),
          painter: VeloraQuoteBadgePainter(color: const Color(0xFFFBBF24)),
        );
      case 'suggestion':
        return const Icon(Icons.lightbulb_outline, size: 18, color: Color(0xFFC084FC));
      case 'turn_to':
        return const Icon(Icons.menu_book, size: 18, color: Color(0xFF4ADE80));
      case 'reference':
      default:
        return const Icon(Icons.bookmark_outline, size: 18, color: Color(0xFF38BDF8));
    }
  }

  String _nodePrefix(String type) {
    switch (type) {
      case 'turn_to':
        return 'Pastor requested you turn to';
      case 'quote':
        return 'Pastor quoted';
      case 'suggestion':
        return 'Velora suggests';
      case 'reference':
      default:
        return 'Scripture referenced:';
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF090A10),
      body: SafeArea(
        child: Column(
          children: [
            // Top Status Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'RELAY ACTIVE',
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.4,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    _formatDuration(appState.recordingSeconds),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Low Glare',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),

            // Vertical Continuous Timeline (Screenshot 5 Style)
            Expanded(
              child: appState.liveDetectedScriptures.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primaryAmber.withValues(alpha: 0.1),
                                border: Border.all(
                                  color: AppTheme.primaryAmber.withValues(alpha: 0.3),
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.sensors,
                                  color: AppTheme.primaryAmber,
                                  size: 36,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Transcribe sermons & capture every reference\nat any church, in real time',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Speak or listen. Live verses and pastoral turn-to cues will populate this timeline.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF94A3B8),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      itemCount: appState.liveDetectedScriptures.length,
                      itemBuilder: (context, index) {
                        final sc = appState.liveDetectedScriptures[index];
                        final color = _nodeColor(sc.type);
                        final prefix = _nodePrefix(sc.type);
                        final isLast = index == appState.liveDetectedScriptures.length - 1;

                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Timeline vertical connector line and badge
                              Column(
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: _buildNodeBadge(sc.type),
                                    ),
                                  ),
                                  if (!isLast)
                                    Expanded(
                                      child: Container(
                                        width: 1.5,
                                        color: Colors.white12,
                                        margin: const EdgeInsets.symmetric(vertical: 4),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 14),

                              // Timeline Event Card
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 18),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF131520),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: color.withValues(alpha: 0.2)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Prefix + Citation + Time
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: RichText(
                                              text: TextSpan(
                                                children: [
                                                  TextSpan(
                                                    text: '$prefix ',
                                                    style: const TextStyle(
                                                      color: Color(0xFF94A3B8),
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                  TextSpan(
                                                    text: sc.citation,
                                                    style: TextStyle(
                                                      color: color,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          if (sc.timestamp != null)
                                            Text(
                                              '• ${sc.timestamp}',
                                              style: const TextStyle(
                                                color: Colors.white38,
                                                fontSize: 11,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // Spoken verse snippet
                                      Text(
                                        sc.verseText,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFFCBD5E1),
                                          fontSize: 12,
                                          height: 1.4,
                                          fontFamily: 'serif',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // Glowing Floating Microphone Pill (Screenshot 5 Style)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF0F1118),
                border: Border(top: BorderSide(color: Colors.white12)),
              ),
              child: Column(
                children: [
                  if (appState.liveTranscript.isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        appState.liveTranscript,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE2E8F0),
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      // "Listening now" Pill with Circular Microphone Glow (Screenshot 5)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B1E2E),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: appState.soundLevel > 0.05
                                ? AppTheme.primaryAmber
                                : Colors.white12,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.08),
                                boxShadow: appState.soundLevel > 0.05
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.primaryAmber.withValues(alpha: 0.35),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                Icons.mic,
                                size: 16,
                                color: appState.soundLevel > 0.05
                                    ? AppTheme.primaryAmber
                                    : Colors.white70,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Listening now',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Finish Button
                      ElevatedButton.icon(
                        onPressed: () async {
                          await appState.stopServiceModeAndProcess();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: const Icon(Icons.stop_circle, size: 18),
                        label: const Text(
                          'Finish',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
}
