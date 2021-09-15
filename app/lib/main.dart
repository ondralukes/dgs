import 'package:app/ui/class_list.dart';
import 'package:app/ui/global_state.dart';
import 'package:app/ui/identity_manager.dart';
import 'package:app/ui/settings.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(RootWidget());
}

class RootWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => RootWidgetState();
}

class RootWidgetState extends State<RootWidget> {
  final _gs = GlobalState();
  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    await _gs.load();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see the
          // application has a blue toolbar. Then, without quitting the app, try
          // changing the primarySwatch below to Colors.green and then invoke
          // "hot reload" (press "r" in the console where you ran "flutter run",
          // or simply save your changes to "hot reload" in a Flutter IDE).
          // Notice that the counter didn't reset back to zero; the application
          // is not restarted.
          primarySwatch: Colors.blue,
        ),
        home: !_gs.loaded
            ? Center(child: CircularProgressIndicator())
            : DefaultTabController(
                length: 3,
                child: Scaffold(
                  appBar: AppBar(
                    actions: [
                      ElevatedButton(
                          onPressed: () {
                            SharedPreferences.getInstance().then((value) {
                              value.clear();
                              setState(() {});
                            });
                          },
                          child: Text('Reset'))
                    ],
                    bottom: TabBar(tabs: [
                      Icon(Icons.people),
                      Icon(Icons.school),
                      Icon(Icons.settings)
                    ]),
                  ),
                  body: TabBarView(children: [
                    IdentityManager(_gs),
                    ClassList(_gs),
                    Settings(_gs)
                  ]),
                ),
              ));
  }
}
