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
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    selected: isSelected,
                    label: Text('Day ${day.dayNumber}'),
                    selectedColor: AppTheme.primaryAmber,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontWeight: FontWeight.bold,
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
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryAmber,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'DAY ${currentDay.dayNumber}',
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                currentDay.title,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          currentDay.reflectionText,
                          style: const TextStyle(fontSize: 15, color: Colors.white90, height: 1.5),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryAmber),
                  ),
                  const SizedBox(height: 12),
                  ...currentDay.linkedVerses.map((verseRef) {
                    return Card(
                      color: const Color(0xFF1E2038),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: const Icon(Icons.bookmark, color: AppTheme.primaryAmber),
                        title: Text(verseRef, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        trailing: const Icon(Icons.open_in_new, size: 18, color: Colors.white54),
                        onTap: () {
                          appState.setTargetBibleReference(verseRef);
                        },
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 20),
                ],

                // Prompt Question Card
                Card(
                  color: const Color(0xFF22253F),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.psychology, color: AppTheme.primaryAmber, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Reflection Question',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryAmber),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          currentDay.promptQuestion,
                          style: const TextStyle(fontSize: 14, color: Colors.white90, fontStyle: FontStyle.italic, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Prayer Journal Entry Field
                const Text(
                  'Personal Prayer Journal',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryAmber),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _prayerController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: 'What is God saying to you through this sermon today?',
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Color(0xFF191B2E),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await appState.savePrayerNote(currentDay.id, _prayerController.text.trim());
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Prayer journal entry saved to vault!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryAmber,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.save),
                    label: const Text('Save Journal Entry', style: TextStyle(fontWeight: FontWeight.bold)),
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
