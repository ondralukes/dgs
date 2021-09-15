import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:app/ui/utils.dart';
import 'package:solana/solana.dart';

import 'utils.dart';

class IdentityStorage {
  final Ed25519HDKeyPair _keyPair;
  final Ed25519HDKeyPair _funder;
  final RPCClient _rpc;
  final String _programId;
  final String _seed;
  final HashMap<int, String> _map = HashMap();

  String get address => _keyPair.address;
  String get seed => _seed;
  static Future<IdentityStorage> loadExisting(RPCClient rpc, String programId,
      Ed25519HDKeyPair funder, String seed) async {
    var kp = await loadKeyPair(seed);
    return IdentityStorage(rpc, programId, kp, funder, seed);
  }

  static Future<IdentityStorage> createNew(
      RPCClient rpc, String programId, Ed25519HDKeyPair funder) async {
    var kpe = await generateKeyPair();
    var keyPair = kpe[0];
    var rent = await rpc.getMinimumBalanceForRentExemption(8192);
    var createIns = Instruction(
        programId: SystemProgram.programId,
        accounts: [
          AccountMeta(
              pubKey: funder.address, isWriteable: true, isSigner: true),
          AccountMeta(
              pubKey: keyPair.address, isWriteable: true, isSigner: true)
        ],
        data: SystemInstruction.createAccount(
          address: keyPair.address,
          owner: programId,
          programId: programId,
          space: 8192,
          rent: rent,
        ).data);
    var txsig = await rpc.signAndSendTransaction(
        Message(instructions: [createIns]), [funder, keyPair],
        commitment: Commitment.finalized);
    await rpc.waitForSignatureStatus(txsig, Commitment.finalized);
    return IdentityStorage(rpc, programId, keyPair, funder, kpe[1]);
  }

  IdentityStorage(
      this._rpc, this._programId, this._keyPair, this._funder, this._seed);

  Future<int> add(String name, ProgressNotifier progress) async {
    var bytes = utf8.encode(name);
    var chain = List<String>.empty();
    var append;
    var idx = -1;
    var uid = 0;
    progress.set('Checking subchains for free space...');
    for (var i = 0; i < 256; i++) {
      var stat = await _findFreeSubchainSpace(i, bytes.length);
      if (stat.status != SubchainFreeStatus.Full) {
        append = stat.status == SubchainFreeStatus.RequiresAppend;
        chain = stat.addresses;
        idx = i;
        uid = i * 256 + stat.id;
        break;
      }
    }
    if (idx == -1) throw 'full';
    progress.set('Building transactions...');
    var accounts = chain
        .map((addr) =>
            AccountMeta(pubKey: addr, isWriteable: true, isSigner: false))
        .toList();
    var signers = [_funder];
    var instructions = List<Instruction>.empty(growable: true);
    if (append) {
      var appendedKp = await Ed25519HDKeyPair.random();
      accounts.add(AccountMeta(
          pubKey: appendedKp.address, isSigner: false, isWriteable: true));
      var rent = await _rpc.getMinimumBalanceForRentExemption(2048);
      instructions.add(Instruction(
          programId: SystemProgram.programId,
          accounts: [
            AccountMeta(
                pubKey: _funder.address, isWriteable: true, isSigner: true),
            AccountMeta(
                pubKey: appendedKp.address, isWriteable: true, isSigner: true)
          ],
          data: SystemInstruction.createAccount(
            address: appendedKp.address,
            owner: _programId,
            programId: _programId,
            space: 2048,
            rent: rent,
          ).data));
      signers.add(appendedKp);
    }
    instructions.add(Instruction(
        programId: _programId,
        accounts: [
              AccountMeta(
                  pubKey: _keyPair.address, isWriteable: true, isSigner: true)
            ] +
            accounts,
        data: [0, idx] + bytes));
    signers.add(_keyPair);
    progress.set('Sending transaction...');
    var txsig = await _rpc.signAndSendTransaction(
        Message(instructions: instructions), signers,
        commitment: Commitment.finalized);
    progress.set('Waiting for confirmation...');
    await _rpc.waitForSignatureStatus(txsig, Commitment.finalized);
    progress.set('Successfully added #$uid');
    progress.finish();
    return uid;
  }

  Future<void> sync(ProgressNotifier progress) async {
    progress.set('Downloading identity block...');
    var main = await getAccountDataFromString(_rpc, _keyPair.address);
    if (main.isEmpty) {
      throw 'Indentity block not found.';
    }
    for (var i = 0; i < 256; i++) {
      progress.set('Reading subchain #$i');
      var addr = main.getRange(32 * i, 32 * i + 32);
      if (addr.every((x) => x == 0)) {
        continue;
      }

      print('#$i (${encodeAddress(addr)})');
      var curAddr = addr;
      var cur = await getAccountDataFromBytes(_rpc, curAddr);
      var j = 0;
      while (true) {
        var id = cur[j];
        j++;
        var nameStart = j;
        while (cur[j] != 0) {
          j++;
        }
        var name = utf8.decode(cur.getRange(nameStart, j).toList());
        var uid = i * 256 + id;
        print('#$uid ($i/$id): $name');
        _map[uid] = name;
        j++;
        while (cur[j] == 0 && j < 2016) {
          j++;
        }
        if (j == 2016 || cur[j] == 0) {
          print(
              '(${encodeAddress(curAddr)} => ${encodeAddress(cur.getRange(2016, 2048))})');
          cur = await getAccountDataFromBytes(_rpc, cur.getRange(2016, 2048));
          if (cur.isEmpty) break;
          j = 0;
        }
      }
    }
    progress.set('Synced successfully.');
    progress.finish();
  }

  String? find(int uid) {
    return _map[uid];
  }

  Future<SubchainFreeSpace> _findFreeSubchainSpace(int idx, int nameLen) async {
    var main = await getAccountDataFromString(_rpc, _keyPair.address);
    if (main.isEmpty) {
      throw 'Indentity block not found.';
    }
    var used = List.filled(256, false);
    var addresses = List<String>.empty(growable: true);
    var maxFree = 0;
    var cur = await getAccountDataFromBytes(
        _rpc, main.getRange(idx * 32, idx * 32 + 32));
    if (cur.isEmpty) {
      return SubchainFreeSpace(addresses, SubchainFreeStatus.RequiresAppend, 0);
    }
    addresses.add(encodeAddress(main.getRange(idx * 32, idx * 32 + 32)));
    var i = 0;
    while (true) {
      var id = cur[i];
      used[id] = true;
      i++;
      while (cur[i] != 0) {
        i++;
      }
      i++;
      var freeLen = 0;
      while (cur[i] == 0 && i < 2016) {
        freeLen++;
        i++;
      }
      if (freeLen > maxFree) maxFree = freeLen;
      if (i == 2016 || cur[i] == 0) {
        addresses.add(encodeAddress(cur.getRange(2016, 2048)));
        cur = await getAccountDataFromBytes(_rpc, cur.getRange(2016, 2048));
        if (cur.isEmpty) {
          addresses.removeLast();
          break;
        }
        i = 0;
      }
    }
    var id = -1;
    for (var i = 0; i < 256; i++) {
      if (!used[i]) {
        id = i;
        break;
      }
    }
    if (id == -1)
      return SubchainFreeSpace(addresses, SubchainFreeStatus.Full, id);
    if (maxFree > nameLen + 2)
      return SubchainFreeSpace(addresses, SubchainFreeStatus.Free, id);
    return SubchainFreeSpace(addresses, SubchainFreeStatus.RequiresAppend, id);
  }
}

enum SubchainFreeStatus { Full, RequiresAppend, Free }

class SubchainFreeSpace {
  List<String> addresses;
  SubchainFreeStatus status;
  int id;
  SubchainFreeSpace(this.addresses, this.status, this.id);
}
