import 'package:app/ui/global_state.dart';
import 'package:app/ui/utils.dart';
import 'package:flutter/material.dart';

class IdentityManager extends StatefulWidget {
  final GlobalState _gs;
  IdentityManager(this._gs);
  @override
  State<StatefulWidget> createState() => IdentityManagerState(_gs);
}

class IdentityManagerState extends State<IdentityManager> {
  GlobalState _gs;
  IdentityManagerState(this._gs);

  final _nameInput = TextEditingController();
  final _idInput = TextEditingController();

  void _add() async {
    var progress = ProgressNotifier(context, true);
    await _gs.identityStorage!.add(_nameInput.text, progress);
  }

  void _sync() async {
    var progress = ProgressNotifier(context, false);
    await _gs.identityStorage!.sync(progress);
  }

  void _lookup() {
    var name = _gs.identityStorage!.find(int.parse(_idInput.text));
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(name == null ? 'Not found.' : 'Found: $name')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _gs.identityStorage == null
          ? [
              ElevatedButton(
                  onPressed: () => {
                        _gs
                            .createIdentity(ProgressNotifier(context, false))
                            .then((value) => setState(() {}))
                      },
                  child: Text('Create identity'))
            ]
          : [
              Text('Identity: ${_gs.identityStorage!.address}'),
              TextField(controller: _nameInput),
              ElevatedButton(onPressed: _add, child: Text('Add')),
              ElevatedButton(onPressed: _sync, child: Text('Sync')),
              TextField(
                  controller: _idInput, keyboardType: TextInputType.number),
              ElevatedButton(onPressed: _lookup, child: Text('Lookup')),
            ],
    );
  }
}
