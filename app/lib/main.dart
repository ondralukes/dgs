import 'package:app/identity_storage.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solana/solana.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
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
      home: Scaffold(
        body: Center(
          child: IdentityWidget(),
        ),
      )
    );
  }
}

class IdentityWidget extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => IdentityWidgetState();
  
}

class IdentityWidgetState extends State<IdentityWidget>{
  IdentityStorage? _identityStorage;
  Ed25519HDKeyPair? _funder;
  String _status = 'Initializing...';

  final _nameInput = TextEditingController();
  final _idInput = TextEditingController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    var stored = await SharedPreferences.getInstance();
    Ed25519HDKeyPair funder;
    if(stored.containsKey('funder')){
      setState(() {_status = 'Loading funder keypair...';});
      funder = await Ed25519HDKeyPair.fromSeedWithHdPath(
          seed: base64.decode(stored.getString('funder')!),
          hdPath: "m/44'/501'/0'/0'"
      );
    } else {
      setState(() {_status = 'Generating funder keypair...';});
      funder = await Ed25519HDKeyPair.random();
      var bytes = (await funder.extract()).bytes;
      await stored.setString('funder', base64.encode(bytes));
    }
    debugPrint('Funder: ${funder.address}');
    setState(() {
      _funder = funder;
    });

    var rpc = RPCClient('https://api.devnet.solana.com');
    var keyPair;
    IdentityStorage identityStorage;
    if(stored.containsKey('keyPair')){
      setState(() {_status = 'Loading identity keypair...';});
      keyPair = await Ed25519HDKeyPair.fromSeedWithHdPath(
          seed: base64.decode(stored.getString('keyPair')!),
          hdPath: "m/44'/501'/0'/0'"
      );
      identityStorage = IdentityStorage.loadExisting(rpc, 'C9K2LGqKi8neGetJNjBcnKxUzgRrvkNcraE8UZwjsySL', funder, keyPair);
    } else {
      setState(() {_status = 'Creating identity block...';});
      keyPair = await Ed25519HDKeyPair.random();
      var bytes = (await keyPair.extract()).bytes;
      await stored.setString('keyPair', base64.encode(bytes));
      identityStorage = await IdentityStorage.createNew(rpc, 'C9K2LGqKi8neGetJNjBcnKxUzgRrvkNcraE8UZwjsySL', funder, keyPair);
    }
    debugPrint('Identity: ${identityStorage.address}');
    setState(() {
      _identityStorage = identityStorage;
      _status = 'Loaded.';
    });
  }

  void _add() async {
    setState(() {
      _status = 'Adding...';
    });
    var id = await _identityStorage!.add(_nameInput.text);
    setState(() {
      _status = 'Name added with id $id';
    });
  }

  void _sync() async {
    setState(() {
      _status = 'Syncing...';
    });
    await _identityStorage!.sync();
    setState(() {
      _status = 'Synced.';
    });
  }
  
  void _lookup(){
    var name = _identityStorage!.find(int.parse(_idInput.text));
    setState(() {
      _status = name == null?'Not found.':'Found: $name';
    });
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(_funder==null?'No funder.':'Funder: ${_funder!.address}'),
        Text(_identityStorage==null?'No identity.':'Identity: ${_identityStorage!.address}'),
        Text(_status),
        TextField(controller: _nameInput),
        ElevatedButton(onPressed: _add, child: Text('Add')),
        ElevatedButton(onPressed: _sync, child: Text('Sync')),
        TextField(controller: _idInput, keyboardType: TextInputType.number),
        ElevatedButton(onPressed: _lookup, child: Text('Lookup')),
      ],
    );
  }
  
}