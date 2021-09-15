import 'package:app/ui/global_state.dart';
import 'package:app/ui/utils.dart';
import 'package:flutter/material.dart';

class Settings extends StatefulWidget {
  final GlobalState _gs;
  Settings(this._gs);
  @override
  State<StatefulWidget> createState() => SettingsState(_gs);
}

class SettingsState extends State<Settings> {
  GlobalState _gs;
  SettingsState(this._gs);
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(_gs.funder.address),
      Text('${_gs.funderBalance * 0.000000001} SOL'),
      ElevatedButton(
          onPressed: () {
            _gs
                .airdrop(ProgressNotifier(context, false))
                .then((value) => setState(() {}));
          },
          child: Text('Airdrop'))
    ]);
  }
}
