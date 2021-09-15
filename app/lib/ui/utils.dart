import 'package:flutter/material.dart';

class ProgressNotifier {
  ProgressNotifier(BuildContext context, bool wait) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
            title: const Text('Commiting...'),
            content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setter) {
                _setter = setter;
                if (_finished && !wait) {
                  Navigator.of(context, rootNavigator: true).pop();
                  return Text('');
                }
                return Column(
                  children: _finished
                      ? [
                          Text(_status),
                          ElevatedButton(
                              onPressed: () {
                                Navigator.of(context, rootNavigator: true)
                                    .pop();
                              },
                              child: Text('Hide'))
                        ]
                      : [CircularProgressIndicator(), Text(_status)],
                  mainAxisSize: MainAxisSize.min,
                );
              },
            )));
  }
  StateSetter? _setter;
  String _status = '';
  bool _finished = false;
  void setSetter(StateSetter s) {
    _setter = s;
  }

  void set(String s) {
    _status = s;
    if (_setter == null) return;
    _setter!(() {});
  }

  void finish() {
    _finished = true;
    if (_setter == null) return;
    _setter!(() {});
  }
}
