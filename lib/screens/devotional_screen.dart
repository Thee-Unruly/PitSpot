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
        appBar: AppBar(title: const Text('Post-Sermon Devotional')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_stories, size: 64, color: Colors.white24),
                SizedBox(height: 16),
                Text(
                  'No active devotional generated yet.',
                  style: TextStyle(fontSize: 18, color: Colors.white70, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Start Service Mode on the Home screen to record a sermon and generate your 7-day personalized devotional.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38),
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
      appBar: AppBar(
        title: const Text('7-Day Sermon Devotional'),
      ),
      body: Column(
        children: [
          // Day Selector Bar
          Container(
            height: 64,
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
                    backgroundColor: const Color(0xFF1B1E34),
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
              padding: const EdgeInsets.all(16.0),
              children: [
                // Day Title Card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(color: AppTheme.primaryAmber.withValues(alpha: 0.25)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
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
                ),
                const SizedBox(height: 20),

                // Linked Verses Section
                if (currentDay.linkedVerses.isNotEmpty) ...[
                  const Text(
                    'Scriptures for Reflection',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.primaryAmber),
                  ),
                  const SizedBox(height: 10),
                  ...currentDay.linkedVerses.map((verseRef) {
                    return Card(
                      color: const Color(0xFF141728),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0x3367E8F9)),
                      ),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(Icons.bookmark_outline, color: Color(0xFF67E8F9)),
                        title: Text(
                          verseRef,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF67E8F9), fontSize: 14),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
                        onTap: () {
                          appState.setTargetBibleReference(verseRef);
                        },
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                ],

                // Prompt Question Card
                Card(
                  color: const Color(0xFF161930),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.amber.withValues(alpha: 0.3)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.psychology, color: AppTheme.primaryAmber, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Guided Reflection Prompt',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryAmber),
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
                ),
                const SizedBox(height: 20),

                // Prayer Journal Entry Field
                const Text(
                  'Personal Prayer Journal',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.primaryAmber),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.save, size: 18),
                    label: const Text('Save Journal Entry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
