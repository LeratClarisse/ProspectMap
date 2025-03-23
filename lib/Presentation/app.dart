import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'home.dart';

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box>(
        valueListenable: Hive.box('settings').listenable(),
        builder: (context, box, widget) {
          bool darkMode = box.get('darkmode', defaultValue: false);
          return MaterialApp(
              themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
              darkTheme: ThemeData.dark(),
              home: const Home());
        });
  }
}
