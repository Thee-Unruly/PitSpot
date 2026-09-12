import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import 'processing_screen.dart';
import 'settings_screen.dart';

class HomeServiceScreen extends StatelessWidget {
  const HomeServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    if (appState.recordingStatus == ServiceRecordingStatus.recording) {
      return const ServiceRecordingView();
    } else if (appState.recordingStatus == ServiceRecordingStatus.processing) {
      return const ProcessingScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Amanda • Pitstop'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.amber),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Header Banner
          Card(
            color: const Color(0xFF22253F),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_gas_station, color: Colors.amber, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sermon Pitstop Mode',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Serve your duty without missing spiritual nourishment.',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Big Start Service Button
          GestureDetector(
            onTap: () async {
              await appState.startServiceMode();
            },
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB703), Color(0xFFFB8500)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mic, size: 56, color: Colors.black),
                  SizedBox(height: 12),
                  Text(
                    'START SERVICE MODE',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: 1.2,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Locks into low-glare background capture',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Vault Sermons List
          const Text(
            'Recent Sermon Vault',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber),
          ),
          const SizedBox(height: 12),
          if (appState.vaultSermons.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text(
                  'No recorded sermons yet. Tap "START SERVICE MODE" above during your next church service.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54),
                ),
              ),
            )
          else
            ...appState.vaultSermons.map((sermon) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFF3A86EF),
                    child: Icon(Icons.church, color: Colors.white),
                  ),
                  title: Text(sermon.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${sermon.preacher} • ${sermon.date}'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white54),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    await appState.loadSermonFromVault(sermon.id);
                    messenger.showSnackBar(
                      SnackBar(content: Text('Loaded ${sermon.title}')),
                    );
                  },
                ),
              );
            }),
        ],
      ),
    );
  }
}

class ServiceRecordingView extends StatelessWidget {
  const ServiceRecordingView({super.key});

  String _formatDuration(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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

  IconData _badgeIcon(String type) {
    switch (type) {
      case 'turn_to':
        return Icons.auto_stories;
      case 'quote':
        return Icons.format_quote;
      case 'suggestion':
        return Icons.lightbulb_outline;
      case 'reference':
      default:
        return Icons.bookmark_outline;
    }
  }

  void _showVersePreview(BuildContext context, ScriptureMention sc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141628),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _badgeColor(sc.type).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _badgeColor(sc.type)),
                      ),
                      child: Row(
                        children: [
                          Icon(_badgeIcon(sc.type), size: 14, color: _badgeColor(sc.type)),
                          const SizedBox(width: 4),
                          Text(
                            sc.typeLabel.toUpperCase(),
                            style: TextStyle(
                              color: _badgeColor(sc.type),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (sc.timestamp != null)
                      Text(
                        sc.timestamp!,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  sc.citation,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F223C),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    sc.verseText,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Color(0xFFE2E8F0),
                      fontFamily: 'serif',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Recorded during live service relay',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF090A10),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
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
                          letterSpacing: 1.5,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Low Glare',
                      style: TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Timer Dial & Visualizer
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.red.withValues(alpha: 0.12),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.8), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.redAccent.withValues(alpha: 0.25),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.graphic_eq, color: Colors.redAccent, size: 24),
                      const SizedBox(height: 4),
                      Text(
                        _formatDuration(appState.recordingSeconds),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Listening for sermons & scripture mentions...',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 16),

              // Live Detections Stream
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121422),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.auto_awesome, color: Colors.amber, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Live Scripture Feed',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${appState.liveDetectedScriptures.length} detected',
                              style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (appState.liveDetectedScriptures.isEmpty)
                        const Expanded(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.hearing, color: Colors.white24, size: 40),
                                SizedBox(height: 8),
                                Text(
                                  'Listening for Bible citations...',
                                  style: TextStyle(color: Colors.white38, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.separated(
                            itemCount: appState.liveDetectedScriptures.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final sc = appState.liveDetectedScriptures[index];
                              final badgeColor = _badgeColor(sc.type);
                              return InkWell(
                                onTap: () => _showVersePreview(context, sc),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1B1E32),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: badgeColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(_badgeIcon(sc.type), size: 14, color: badgeColor),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              sc.citation,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              sc.verseText,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white60,
                                                fontSize: 11,
                                                fontFamily: 'serif',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        sc.timestamp ?? '',
                                        style: const TextStyle(color: Colors.white38, fontSize: 11),
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
                ),
              ),
              const SizedBox(height: 16),

              // Stop Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await appState.stopServiceModeAndProcess();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.stop_circle),
                  label: const Text(
                    'FINISH SERVICE & GENERATE NOTES',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
