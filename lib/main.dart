import 'package:flutter/material.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

//pages import
import 'package:moneyapp/transaction_model.dart';
import 'package:moneyapp/theme_provider.dart';
import 'package:moneyapp/pages/add_transactions_page.dart';
import 'package:moneyapp/pages/history_page.dart';
import 'package:moneyapp/pages/stats_page.dart';
import 'package:moneyapp/pages/settings_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); //widgets initialized before Hive start

  //localisation
  await initializeDateFormatting('en');
  //Hive initialisations
  await Hive.initFlutter(); 
  Hive.registerAdapter(TransactionAdapter()); 
  await Hive.openBox<Transaction>('transactions');

  runApp(ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        MonthYearPickerLocalizations.delegate, 
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('ro', ' '),
      ],
      debugShowCheckedModeBanner: false,
      theme: themeProvider.isDarkMode 
        ? _darkTheme()
        : _lightTheme(),
      home: HomeScreen()
    );
  }

  ThemeData _lightTheme() {
    return ThemeData(
      fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color.fromARGB(255, 17, 1, 195),
          brightness: Brightness.light,
      ),
      textTheme: TextTheme(
          displayLarge: const TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
          ),
        )
    );
  }

  ThemeData _darkTheme() {
    return ThemeData(
      fontFamily: 'Poppins',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color.fromARGB(255, 17, 1, 195),
          brightness: Brightness.dark,
      ),
      textTheme: TextTheme(
          displayLarge: const TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
          ),
        )
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  PageController _pageController=PageController();
  int _selectedIndex=0;

  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex=index;
    });
  }
  void _onItemTapped(int i)
  {
    _pageController.jumpToPage(i);
  }
  
  @override
  Widget build(BuildContext context) {
    final themeElemColor=Theme.of(context);

    return Scaffold(  
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          children: [
            _buildHomePage(context),
            HistoryPage(),
            StatsPage(),
            SettingsPage()
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,

          //backgroundColor: Colors.white,
          selectedItemColor: themeElemColor.colorScheme.primary,
          unselectedItemColor: Colors.grey,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,

          items:  const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
          ]
        ),
    );
  }

  //HomePage
  SafeArea _buildHomePage(BuildContext context) {
    return SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, 
          children: [
            Column(
              children: [
                const SizedBox(height: 200),
                const Text(
                  'Add a transaction',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddTransactionScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20.0),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.red,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ValueListenableBuilder(
                valueListenable: Hive.box<Transaction>('transactions').listenable(),
                builder: (context, Box<Transaction> box, _) {
                  
                  if (box.isEmpty) {
                    return Center(
                      child: Column(
                        children: [
                          Text(
                            "No transactions registered",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 200)
                        ],
                      ),
                    );
                  }

                  final transactions = box.values.toList().reversed.take(3).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        "Latest transactions registered",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      latestTransactions(transactions),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      );
  }

  Container latestTransactions(List<Transaction> transactions) {
    return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
                ),
          child: Column(
          children: transactions.map((tx) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.monetization_on,
                color: Colors.green),
            title: Text(tx.category),
            subtitle: Text(tx.date.toString().split(" ")[0]),
            trailing: Text(
                "${tx.amount.toStringAsFixed(2)} USD",
                style: const TextStyle(
                fontWeight: FontWeight.bold,
                ),
              ),
            );
        }).toList(),
      ),
    );
  }
}

