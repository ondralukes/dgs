import 'package:app/ui/global_state.dart';
import 'package:app/ui/utils.dart';
import 'package:flutter/material.dart';

class ClassList extends StatefulWidget {
  final GlobalState _gs;
  ClassList(this._gs);
  @override
  State<ClassList> createState() => ClassListState(_gs);
}

class ClassListState extends State<ClassList> {
  GlobalState _gs;
  ClassListState(this._gs);
  TextEditingController _nameInput = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: _gs.classes.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            return Row(
              children: [
                Expanded(
                    child: TextField(
                  controller: _nameInput,
                )),
                ElevatedButton(
                    onPressed: () {
                      _gs
                          .createClass(
                              _nameInput.text, ProgressNotifier(context, false))
                          .then((value) => setState(() {}));
                    },
                    child: Text('New'))
              ],
            );
          }
          var cls = _gs.classes[i - 1];
          return Column(
            children: [
              Text(cls.address),
              cls.data == null
                  ? ElevatedButton(
                      onPressed: () {
                        cls
                            .sync(ProgressNotifier(context, false))
                            .then((_) => setState(() {}));
                      },
                      child: Text('Resolve name'))
                  : Text(cls.data!.name)
            ],
          );
        });
  }
}
