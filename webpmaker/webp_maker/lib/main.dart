import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/conversion_provider.dart';
import 'screens/animation_screen.dart';
import 'screens/image_converter_screen.dart';
import 'screens/webp_decoder_screen.dart';
import 'screens/gif_converter_screen.dart';
import 'screens/animation_tools_screen.dart';
import 'screens/support_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ConversionProvider(),
      child: MaterialApp(
        title: 'WebP Studio',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF6366F1),
            secondary: Color(0xFF8B5CF6),
            surface: Color(0xFF1F2937),
            onSurface: Colors.white,
          ),
          scaffoldBackgroundColor: const Color(0xFF111827),
          cardColor: const Color(0xFF1F2937),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1F2937),
            foregroundColor: Colors.white,
            elevation: 0,
            titleTextStyle: TextStyle(
              fontFamily: 'Segoe UI',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          textTheme: const TextTheme(
            headlineLarge: TextStyle(
              fontFamily: 'Segoe UI',
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            headlineMedium: TextStyle(
              fontFamily: 'Segoe UI',
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            headlineSmall: TextStyle(
              fontFamily: 'Segoe UI',
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            bodyLarge: TextStyle(fontFamily: 'Segoe UI', color: Colors.white),
            bodyMedium: TextStyle(
              fontFamily: 'Segoe UI',
              color: Colors.white70,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              textStyle: const TextStyle(
                fontFamily: 'Segoe UI',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          drawerTheme: const DrawerThemeData(
            backgroundColor: Color(0xFF1F2937),
          ),
        ),
        home: const MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const AnimationScreen(),
    const ImageConverterScreen(),
    const WebPDecoderScreen(),
    const GifConverterScreen(),
    const AnimationToolsScreen(),
    const SupportScreen(),
  ];

  final List<String> _titles = [
    'PNG → Animated WebP',
    'Image → Static WebP',
    'WebP → PNG/JPEG',
    'GIF → WebP Animation',
    'Animation Tools',
    'Buy Me Coffee ☕',
  ];

  final List<IconData> _icons = [
    Icons.movie_creation,
    Icons.image,
    Icons.transform,
    Icons.gif,
    Icons.animation,
    Icons.coffee,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_titles[_selectedIndex]), centerTitle: true),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_library, size: 48, color: Colors.white),
                    SizedBox(height: 8),
                    Text(
                      'WebP Studio',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Segoe UI',
                      ),
                    ),
                    Text(
                      'Professional WebP Tools',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        fontFamily: 'Segoe UI',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _titles.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(
                      _icons[index],
                      color: _selectedIndex == index
                          ? Theme.of(context).colorScheme.primary
                          : Colors.white70,
                    ),
                    title: Text(
                      _titles[index],
                      style: TextStyle(
                        fontFamily: 'Segoe UI',
                        fontWeight: _selectedIndex == index
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _selectedIndex == index
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white,
                      ),
                    ),
                    selected: _selectedIndex == index,
                    selectedTileColor: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const Divider(color: Colors.white24),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Powered by Google libwebp',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                  fontFamily: 'Segoe UI',
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
    );
  }
}
