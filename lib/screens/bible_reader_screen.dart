import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../services/bible_service.dart';
import '../theme/app_theme.dart';

class BibleReaderScreen extends StatefulWidget {
  const BibleReaderScreen({super.key});

  @override
  State<BibleReaderScreen> createState() => _BibleReaderScreenState();
}

class _BibleReaderScreenState extends State<BibleReaderScreen> {
  final BibleService _bibleService = BibleService();
  final TextEditingController _searchController = TextEditingController();

  String _selectedTranslation = 'NIV';
  List<BibleVerse> _results = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadInitialVerses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialVerses() async {
    setState(() => _isSearching = true);
    final verses = await _bibleService.searchVerses('Romans', translation: _selectedTranslation);
    setState(() {
      _results = verses;
      _isSearching = false;
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      _loadInitialVerses();
      return;
    }

    setState(() => _isSearching = true);
    final verses = await _bibleService.searchVerses(query.trim(), translation: _selectedTranslation);
    setState(() {
      _results = verses;
      _isSearching = false;
    });
  }

  Future<void> _handleDeepLinkReference(String reference) async {
    setState(() => _isSearching = true);
    final verse = await _bibleService.fetchVerseText(reference);
    setState(() {
      _results = [verse];
      _searchController.text = reference;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // Deep link check
    if (appState.targetBibleReference != null) {
      final ref = appState.targetBibleReference!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appState.setTargetBibleReference(''); // clear reference
        _handleDeepLinkReference(ref);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bible Reader'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButton<String>(
              value: _selectedTranslation,
              dropdownColor: AppTheme.darkSurface,
              underline: const SizedBox.shrink(),
              icon: const Icon(Icons.translate, color: AppTheme.primaryAmber),
              items: ['NIV', 'KJV', 'SUV'].map((t) {
                return DropdownMenuItem(
                  value: t,
                  child: Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedTranslation = val);
                  _performSearch(_searchController.text);
                }
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Box
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onSubmitted: _performSearch,
              decoration: InputDecoration(
                hintText: 'Search verse or citation (e.g. Romans 8:28, Philippians)...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppTheme.primaryAmber),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward, color: AppTheme.primaryAmber),
                  onPressed: () => _performSearch(_searchController.text),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                filled: true,
                fillColor: AppTheme.darkSurface,
              ),
            ),
          ),

          // Quick Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['Romans 8:28', 'Philippians 4:13', 'Jeremiah 29:11', 'John 3:16', 'Yohana 3:16'].map((citation) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    avatar: const Icon(Icons.bookmark_outline, size: 14, color: Colors.amber),
                    label: Text(citation),
                    backgroundColor: AppTheme.darkCard,
                    labelStyle: const TextStyle(color: Colors.white70, fontSize: 12),
                    onPressed: () {
                      _searchController.text = citation;
                      _performSearch(citation);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Results List
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryAmber))
                : _results.isEmpty
                    ? const Center(
                        child: Text(
                          'No matching Bible verses found.\nTry searching "Romans" or "Philippians".',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white38),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final verse = _results[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        verse.reference,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryAmber,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryBlue.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          verse.translation,
                                          style: const TextStyle(
                                            color: AppTheme.primaryBlue,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    verse.text,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Colors.white70,
                                      height: 1.5,
                                    ),
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
    );
  }
}
