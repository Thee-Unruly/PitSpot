import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  String _selectedTranslation = 'English (KJV)';
  List<BibleVerse> _results = [];
  bool _isSearching = false;

  // Velora-Inspired Multi-Passage Tabs
  final List<String> _passageTabs = ['Philippians 4:13', 'Romans 8:28', 'Jeremiah 29:11'];
  int _activeTabIndex = 0;

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
    if (_passageTabs.isNotEmpty) {
      await _openTab(_activeTabIndex);
    } else {
      setState(() => _isSearching = true);
      final verses = await _bibleService.searchVerses('Romans', translation: _selectedTranslation);
      setState(() {
        _results = verses;
        _isSearching = false;
      });
    }
  }

  Future<void> _openTab(int index) async {
    if (index < 0 || index >= _passageTabs.length) return;
    setState(() {
      _activeTabIndex = index;
      _isSearching = true;
    });

    final citation = _passageTabs[index];
    final verse = await _bibleService.fetchVerseText(citation, translation: _selectedTranslation);
    setState(() {
      _results = [verse];
      _searchController.text = citation;
      _isSearching = false;
    });
  }

  void _addNewTab(String citation) {
    if (!_passageTabs.contains(citation)) {
      setState(() {
        _passageTabs.add(citation);
        _activeTabIndex = _passageTabs.length - 1;
      });
    } else {
      setState(() {
        _activeTabIndex = _passageTabs.indexOf(citation);
      });
    }
    _openTab(_activeTabIndex);
  }

  void _closeTab(int index) {
    if (_passageTabs.length <= 1) return;
    setState(() {
      _passageTabs.removeAt(index);
      if (_activeTabIndex >= _passageTabs.length) {
        _activeTabIndex = _passageTabs.length - 1;
      }
    });
    _openTab(_activeTabIndex);
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

    if (RegExp(r'\d').hasMatch(query)) {
      if (!_passageTabs.contains(query.trim())) {
        setState(() {
          _passageTabs.add(query.trim());
          _activeTabIndex = _passageTabs.length - 1;
        });
      }
    }
  }

  Future<void> _handleDeepLinkReference(String reference) async {
    _addNewTab(reference);
  }

  void _copyVerse(BibleVerse verse) {
    Clipboard.setData(ClipboardData(text: '${verse.reference} (${verse.translation}): "${verse.text}"'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied ${verse.reference} to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // Deep link check
    if (appState.targetBibleReference != null && appState.targetBibleReference!.isNotEmpty) {
      final ref = appState.targetBibleReference!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        appState.setTargetBibleReference(''); // clear reference
        _handleDeepLinkReference(ref);
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text('Smart Bible'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButton<String>(
              value: _selectedTranslation,
              dropdownColor: AppTheme.darkSurface,
              underline: const SizedBox.shrink(),
              icon: const Icon(Icons.translate, color: AppTheme.primaryAmber),
              items: BibleService.availableTranslations.keys.map((t) {
                return DropdownMenuItem(
                  value: t,
                  child: Text(t, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
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
          // Velora-Inspired Passage Tabs Bar
          Container(
            color: const Color(0xFF121420),
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              itemCount: _passageTabs.length,
              itemBuilder: (context, index) {
                final tabCitation = _passageTabs[index];
                final isActive = index == _activeTabIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InkWell(
                    onTap: () => _openTab(index),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive ? AppTheme.primaryAmber.withValues(alpha: 0.18) : const Color(0xFF1B1E2E),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isActive ? AppTheme.primaryAmber : Colors.white12,
                          width: isActive ? 1.4 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_stories,
                            size: 13,
                            color: isActive ? AppTheme.primaryAmber : Colors.white54,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            tabCitation,
                            style: TextStyle(
                              color: isActive ? AppTheme.primaryAmber : Colors.white70,
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                          if (_passageTabs.length > 1) ...[
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => _closeTab(index),
                              child: Icon(
                                Icons.close,
                                size: 14,
                                color: isActive ? AppTheme.primaryAmber.withValues(alpha: 0.8) : Colors.white38,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Search & Filter Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: TextField(
              controller: _searchController,
              onSubmitted: _performSearch,
              decoration: InputDecoration(
                hintText: 'Search verse or citation (e.g. Philippians 4:13, Romans 8:28)...',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppTheme.primaryAmber),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward, color: AppTheme.primaryAmber),
                  onPressed: () => _performSearch(_searchController.text),
                ),
                filled: true,
                fillColor: AppTheme.darkSurface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Quick Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (appState.currentNotes != null)
                  ...appState.currentNotes!.scriptures.map((sc) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        avatar: const Icon(Icons.auto_awesome, size: 14, color: Color(0xFF38BDF8)),
                        label: Text(sc.citation),
                        backgroundColor: const Color(0xFF161A2B),
                        side: const BorderSide(color: Color(0xFF38BDF8), width: 0.8),
                        labelStyle: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold),
                        onPressed: () => _addNewTab(sc.citation),
                      ),
                    );
                  }),
                ...['Philippians 4:13', 'Romans 8:28', 'Jeremiah 29:11', 'John 3:16', 'Psalm 23:1', 'Isaiah 40:31'].map((citation) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      avatar: const Icon(Icons.bookmark_outline, size: 14, color: AppTheme.primaryAmber),
                      label: Text(citation),
                      backgroundColor: AppTheme.darkSurface,
                      labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
                      onPressed: () => _addNewTab(citation),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Results List
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryAmber))
                : _results.isEmpty
                    ? const Center(
                        child: Text(
                          'No matching Bible verses found.\nTry searching "Philippians" or "Romans".',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white38),
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _results.length,
                        itemBuilder: (context, index) {
                          final verse = _results[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(18.0),
                            decoration: BoxDecoration(
                              color: AppTheme.darkSurface,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppTheme.darkCardBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          verse.reference,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryAmber,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            verse.translation,
                                            style: const TextStyle(
                                              color: Color(0xFF38BDF8),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.copy, size: 18, color: Colors.white54),
                                      tooltip: 'Copy verse',
                                      onPressed: () => _copyVerse(verse),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  verse.text,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFFF1F5F9),
                                    fontFamily: 'serif',
                                    height: 1.65,
                                  ),
                                ),
                              ],
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
