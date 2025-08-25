import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
          return Directionality(
              textDirection: TextDirection.ltr,
              child: Banner(
                  location: BannerLocation.topEnd,
                  message: 'BETA',
                  color: Colors.lightBlue,
                  textStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12.0, letterSpacing: 1.0),
                  child: MaterialApp(
                      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
                      darkTheme: ThemeData.dark(),
                      localizationsDelegates: const [
                        GlobalMaterialLocalizations.delegate,
                      ],
                      supportedLocales: const [
                        Locale('fr', 'FR'),
                      ],
                      home: const Home())));
        });
  }
}
