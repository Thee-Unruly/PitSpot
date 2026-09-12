import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class DevotionalScreen extends StatefulWidget {
  const DevotionalScreen({super.key});

  @override
  State<DevotionalScreen> createState() => _DevotionalScreenState();
}

class _DevotionalScreenState extends State<DevotionalScreen> {
  int _selectedDayIndex = 0;
  final TextEditingController _prayerController = TextEditingController();

  @override
  void dispose() {
    _prayerController.dispose();
    super.dispose();
  }

  void _updatePrayerControllerText(DevotionalDay day) {
    if (_prayerController.text != (day.userPrayerResponse ?? '')) {
      _prayerController.text = day.userPrayerResponse ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final devotionalDays = appState.currentDevotional;

    if (devotionalDays.isEmpty) {
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
                  child: const Icon(Icons.auto_stories, size: 36, color: AppTheme.primaryAmber),
                ),
                const SizedBox(height: 20),
                const Text(
                  'No active devotional generated',
                  style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Start Service Relay on the Home screen to record a sermon and generate your personalized 5-7 day devotional plan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentDay = devotionalDays[_selectedDayIndex.clamp(0, devotionalDays.length - 1)];
    _updatePrayerControllerText(currentDay);

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Post-Sermon Devotional'),
      ),
      body: Column(
        children: [
          // Day Selector Tabs
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: devotionalDays.length,
              itemBuilder: (context, index) {
                final day = devotionalDays[index];
                final isSelected = index == _selectedDayIndex;
                final hasJournal = day.userPrayerResponse != null && day.userPrayerResponse!.isNotEmpty;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    selected: isSelected,
                    avatar: hasJournal
                        ? Icon(Icons.check, size: 14, color: isSelected ? Colors.black : AppTheme.primaryAmber)
                        : null,
                    label: Text('Day ${day.dayNumber}'),
                    selectedColor: AppTheme.primaryAmber,
                    backgroundColor: const Color(0xFF161926),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? AppTheme.primaryAmber : Colors.white12,
                      ),
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedDayIndex = index);
                      }
                    },
                  ),
                );
              },
            ),
          ),

          // Active Day Content
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(18.0),
              children: [
                // Day Title Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.darkSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryAmber.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryAmber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.primaryAmber),
                            ),
                            child: Text(
                              'DAY ${currentDay.dayNumber}',
                              style: const TextStyle(
                                color: AppTheme.primaryAmber,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              currentDay.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        currentDay.reflectionText,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFFE2E8F0),
                          height: 1.6,
                          fontFamily: 'serif',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Linked Verses Section
                if (currentDay.linkedVerses.isNotEmpty) ...[
                  const Text(
                    'Scriptures for Reflection',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryAmber),
                  ),
                  const SizedBox(height: 10),
                  ...currentDay.linkedVerses.map((verseRef) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF151824),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.bookmark_outline, color: Color(0xFF38BDF8), size: 20),
                        title: Text(
                          verseRef,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38BDF8), fontSize: 14),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 13, color: Colors.white38),
                        onTap: () {
                          appState.setTargetBibleReference(verseRef);
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                ],

                // Prompt Question Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF171A29),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.relaySuggestion.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.psychology, color: AppTheme.relaySuggestion, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Guided Reflection Prompt',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.relaySuggestion),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        currentDay.promptQuestion,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFFCBD5E1),
                          fontStyle: FontStyle.italic,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Prayer Journal Entry Field
                const Text(
                  'Personal Prayer Journal',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryAmber),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _prayerController,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'What is God saying to your heart today? Write a prayer or reflection...',
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await appState.savePrayerNote(currentDay.id, _prayerController.text.trim());
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Prayer journal entry saved to SQLite vault!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryAmber,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.save, size: 18),
                    label: const Text('Save Journal Entry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
