import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color.fromARGB(255, 17, 1, 195),
          brightness: Brightness.light,  //TO-DO - dark theme-Brightness.dark
        ),
        textTheme: TextTheme(
          displayLarge: const TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
          ),
          
        )
      ),
      home: HomeScreen()
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex=0;

  @override
  Widget build(BuildContext context) {
    final themeElemColor=Theme.of(context);

    return Scaffold(  
        body: Center( 
          child: Column( 
            mainAxisSize: MainAxisSize.min,

            children: <Widget>[
              const Text(
              'Înregistrează o tranzacție',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            IconButton(
              iconSize: 60,
              icon: Icon(
                Icons.add_circle_outline,
                color: themeElemColor.colorScheme.primary,
              ),
              onPressed: () {
                //TO-DO - logica de adaugare a tranzactiilor
                print('Add button pressed.');
              },
            )
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,

          //backgroundColor: Colors.white,
          selectedItemColor: themeElemColor.colorScheme.primary,
          unselectedItemColor: Colors.grey,

          currentIndex: _selectedIndex,

          onTap: (int index) {
            setState(() {
              _selectedIndex=index;
            });
          },

          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Acasa'),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Istoric'),
            BottomNavigationBarItem(icon: Icon(Icons.money), label: 'Buget'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setari'),
          ]
        ),
    );
  }
}

