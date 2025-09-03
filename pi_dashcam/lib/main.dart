import 'package:flutter/material.dart';
import 'package:pi_dashcam/live_view/live_view.dart';
import 'package:pi_dashcam/settings/settings_manager.dart';
import 'package:pi_dashcam/settings/settings_page.dart';
import 'package:provider/provider.dart';


void main() {
  runApp(ChangeNotifierProvider(
    create: (_) => SettingsManager(),
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PI-Dashcam',
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const MyHomePage(title: 'PI Dashcam'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selected_page = 0;

  final List<Widget> _tabs = [
    LiveView(),
    Placeholder(),
    SettingsMenu()
  ];

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(

        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: Text(widget.title),
      ),
      body: IndexedStack(
        index: _selected_page,
        children: _tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selected_page,
        onDestinationSelected: (int index){
          setState(() {
            _selected_page = index;
          });
        },
        destinations: [
          NavigationDestination(icon: Icon(Icons.camera), label: 'Live View'),
          NavigationDestination(icon: Icon(Icons.folder), label: 'Stored Footage'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Settings')
        ],
    ),
       // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
