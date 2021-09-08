import 'dart:io';

import 'package:solana/solana.dart' as sol;

import 'identity_storage.dart';

const identityProgramId = 'C9K2LGqKi8neGetJNjBcnKxUzgRrvkNcraE8UZwjsySL';

Future<void> main(List<String> arguments) async {
  var funder = await sol.Ed25519HDKeyPair.fromMnemonic('unable cargo know thing give lunar husband inmate steak material hello ball');
  var rpc = sol.RPCClient('https://api.devnet.solana.com');
  print('User account ${funder.address}, balance ${await rpc.getBalance(funder.address)}');
  print('<ENTER> to create new identity block.');
  stdin.readLineSync();
  var identityStorage = await IdentityStorage.createNew(rpc, identityProgramId, funder);
  print('Identity block created at ${identityStorage.address}');
  while(true){
    print('a <name> - add');
    print('l - list');
    String? cmd;
    while(cmd == null) {
      cmd = stdin.readLineSync();
    }
    if(cmd.isEmpty) continue;
    if(cmd.startsWith('a')){
      await identityStorage.add(cmd.substring(1).trim());
    } else if(cmd.startsWith('l')){
      await identityStorage.list();
    }
  }
}

