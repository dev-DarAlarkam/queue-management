import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/edit_rooms_screen.dart';
import 'screens/view_rooms_screen.dart';
import 'firebase_options.dart'; // You must generate this with `flutterfire configure`.

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const QueueManagerApp());
}

class QueueManagerApp extends StatelessWidget {
  const QueueManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'إدارة الطابور',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color.fromRGBO(249, 235, 217, 1)),
        primaryColor: Color.fromRGBO(17, 114, 58, 1),
        textTheme: GoogleFonts.almaraiTextTheme(
          TextTheme(
          titleLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color.fromRGBO(17, 114, 58, 1),
          ),

          titleMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color.fromRGBO(118, 78, 39, 1),
          ),

        ),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ViewRoomsScreenWrapper()),);
              }, 
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(Icons.tv, size: 100,),
              )
            ),
            SizedBox(width: 40,),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => EditRoomsScreen()),);
              }, 
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(Icons.edit, size: 100),
              )
            )
          ],
        ),
      )
    );
  }
}
