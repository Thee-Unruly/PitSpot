import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/app_state.dart';
import 'theme/app_theme.dart';
import 'screens/home_service_screen.dart';
import 'screens/sermon_notes_screen.dart';
import 'screens/ask_velora_screen.dart';
import 'screens/devotional_screen.dart';
import 'screens/bible_reader_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const VeloraApp(),
    ),
  );
}

class VeloraApp extends StatelessWidget {
  const VeloraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Velora - Sermon Pitstop Companion',
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
    AskVeloraScreen(),
    DevotionalScreen(),
    BibleReaderScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);

    // Auto switch to Bible Reader if deep-linked reference is set
    if (appState.targetBibleReference != null && appState.targetBibleReference!.isNotEmpty && _currentIndex != 4) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _currentIndex = 4);
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
            icon: Icon(Icons.wb_sunny_outlined),
            activeIcon: Icon(Icons.wb_sunny, color: AppTheme.primaryAmber),
            label: 'Daily',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            activeIcon: Icon(Icons.description, color: AppTheme.primaryAmber),
            label: 'Worship',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble, color: AppTheme.primaryAmber),
            label: 'Ask Velora',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_outlined),
            activeIcon: Icon(Icons.auto_awesome, color: AppTheme.primaryAmber),
            label: 'Devotional',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book, color: AppTheme.primaryAmber),
            label: 'Bible',
          ),
        ],
      ),
    );
  }
}
