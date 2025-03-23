import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Box settingsBox = Hive.box('settings');
    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('App title'),
        ),
        body: Center(
            child: ValueListenableBuilder<Box>(
                valueListenable: settingsBox.listenable(),
                builder: (context, box, widget) {
                  return Center(
                    child: Switch(
                      value: box.get('darkmode', defaultValue: false),
                      onChanged: (val) {
                        settingsBox.put('darkmode', val);
                      },
                    ),
                  );
                })));
  }
}
