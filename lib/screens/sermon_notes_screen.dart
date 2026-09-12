import 'package:flutter/material.dart';
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
  String _selectedTagFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
            Tab(icon: Icon(Icons.timeline), text: 'Tagged Transcript'),
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
                    crossAxisAlignment: CrossAlignment.start,
                    children: [
                      Row(
                        children: const [
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
                        style: const TextStyle(fontSize: 14, color: Colors.white90, height: 1.5),
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
                      crossAxisAlignment: CrossAlignment.start,
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
              }).toList(),
              const SizedBox(height: 20),

              // Quotable Quotes Section
              if (notes.quotableLines.isNotEmpty) ...[
                const Text(
                  'Memorable Quotes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryAmber),
                ),
                const SizedBox(height: 12),
                ...notes.quotableLines.map((quote) {
                  return Card(
                    color: const Color(0xFF1E2038),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Row(
                        children: [
                          const Icon(Icons.format_quote, color: AppTheme.tagJoke, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '"$quote"',
                              style: const TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.white90,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 20),
              ],

              // Scripture Mentions Section
              const Text(
                'Scriptures Preached & Referenced',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryAmber),
              ),
              const SizedBox(height: 12),
              ...notes.scriptures.map((sc) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Column(
                      crossAxisAlignment: CrossAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              sc.citation,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryBlue,
                              ),
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
                          style: const TextStyle(fontSize: 13, color: Colors.white80, fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              appState.setTargetBibleReference(sc.citation);
                            },
                            icon: const Icon(Icons.menu_book, size: 16, color: AppTheme.primaryAmber),
                            label: const Text('Read Passage in Bible Reader', style: TextStyle(color: AppTheme.primaryAmber)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),

          // Tab 2: Tagged Transcript
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
                        label: Text(tag == 'All' ? 'All Segment Moments' : tag.replaceAll('_', ' ').toUpperCase()),
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
                          crossAxisAlignment: CrossAlignment.start,
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
                                        color: _getTagColor(t).withOpacity(0.2),
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
                              style: const TextStyle(fontSize: 14, color: Colors.white90, height: 1.4),
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
