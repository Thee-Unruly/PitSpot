import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/home_service_screen.dart';
import 'screens/sermon_notes_screen.dart';
import 'screens/devotional_screen.dart';
import 'screens/bible_reader_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const AmandaApp(),
    ),
  );
}

class AmandaApp extends StatelessWidget {
  const AmandaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amanda - Sermon Pitstop Companion',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeServiceScreen(),
    SermonNotesScreen(),
    DevotionalScreen(),
    BibleReaderScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // Auto switch to Bible Reader if deep-linked reference is set
    if (appState.targetBibleReference != null && _currentIndex != 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _currentIndex = 3);
      });
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.radio_button_checked),
            label: 'Service Mode',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description),
            label: 'Notes & Tags',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_stories),
            label: 'Devotional',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Bible Reader',
          ),
        ],
      ),
    );
  }
}
