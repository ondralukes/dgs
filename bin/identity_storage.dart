import 'dart:async';
import 'dart:convert';

import 'package:solana/solana.dart' as sol;

const String _base58Alphabet =
    '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

String encodeAddress(Iterable<int> bytes) {
  var encoded = '';
  if (bytes.isEmpty) return encoded;
  final zeroes = bytes.takeWhile((v) => v == 0).length;
  var length = 0;
  // Compute final size
  final size = (bytes.length - zeroes) * 138 ~/ 100 + 1;
  // Create temporary storage
  final b58bytes = List<int>.filled(size, 0);
  for (final byteValue in bytes.skip(zeroes)) {
    var carry = byteValue;
    var i = 0;
    for (var j = 0; j < size; j++, i++) {
      if (!((carry != 0) || (i < length))) break;
      carry += 256 * b58bytes[j];
      b58bytes[j] = carry % 58;
      carry ~/= 58;
    }
    length = i;
  }
  final finalBytes = b58bytes.sublist(0, length);
  for (final byte in finalBytes) {
    encoded = _base58Alphabet[byte] + encoded;
  }
  return '1' * zeroes + encoded;
}

class IdentityStorage{
  final sol.Ed25519HDKeyPair _keyPair;
  final sol.Ed25519HDKeyPair _funder;
  final sol.RPCClient _rpc;
  final String _programId;

  String get address => _keyPair.address;
  static Future<IdentityStorage> createNew(sol.RPCClient rpc, String programId, sol.Ed25519HDKeyPair funder) async {
    var keyPair = await sol.Ed25519HDKeyPair.random();
    var rent = await rpc.getMinimumBalanceForRentExemption(8192);
    var createIns = sol.Instruction(
        programId: sol.SystemProgram.programId,
        accounts: [
          sol.AccountMeta(pubKey: funder.address, isWriteable: true, isSigner: true),
          sol.AccountMeta(pubKey: keyPair.address, isWriteable: true, isSigner: true)
        ],
        data: sol.SystemInstruction.createAccount(
          address: keyPair.address,
          owner: programId,
          programId: programId,
          space: 8192,
          rent: rent,
        ).data
    );
    var txsig = await rpc.signAndSendTransaction(sol.Message(instructions: [createIns]), [funder, keyPair], commitment: sol.Commitment.finalized);
    await rpc.waitForSignatureStatus(txsig, sol.Commitment.finalized);
    return IdentityStorage(rpc, programId, keyPair, funder);
  }
  IdentityStorage(this._rpc, this._programId, this._keyPair, this._funder);

  Future<List<int>> _getAccountDataFromBytes(Iterable<int> addr) async{
    if(addr.every((x) => x == 0)){
      return List.empty();
    }
    return _getAccountDataFromString(encodeAddress(addr));
  }

  Future<List<int>> _getAccountDataFromString(String addr) async {
    var data = (await _rpc.getAccountInfo(addr, commitment: sol.Commitment.processed))?.data?.whenOrNull(fromBytes: (List<int> b) => b);
    if(data == null) return List.empty();
    return data;
  }

  Future<void> add(String name) async {
    var bytes = utf8.encode(name);
    var chain = List<String>.empty();
    var append;
    var idx = -1;
    for(var i = 0;i<256;i++){
      var stat = await _findFreeSubchainSpace(i, bytes.length);
      if(stat.status != SubchainFreeStatus.Full){
        append = stat.status == SubchainFreeStatus.RequiresAppend;
        chain = stat.addresses;
        idx = i;
        break;
      }
    }
    if(idx == -1) throw 'full';
    var accounts = chain.map((addr) => sol.AccountMeta(pubKey: addr, isWriteable: true, isSigner: false)).toList();
    var signers = [_funder];
    var instructions = List<sol.Instruction>.empty(growable: true);
    if(append){
      var appendedKp = await sol.Ed25519HDKeyPair.random();
      accounts.add(sol.AccountMeta(pubKey: appendedKp.address, isSigner: false, isWriteable: true));
      var rent = await _rpc.getMinimumBalanceForRentExemption(2048);
      instructions.add(sol.Instruction(
          programId: sol.SystemProgram.programId,
          accounts: [
            sol.AccountMeta(pubKey: _funder.address, isWriteable: true, isSigner: true),
            sol.AccountMeta(pubKey: appendedKp.address, isWriteable: true, isSigner: true)
          ],
          data: sol.SystemInstruction.createAccount(
            address: appendedKp.address,
            owner: _programId,
            programId: _programId,
            space: 2048,
            rent: rent,
          ).data
      ));
      signers.add(appendedKp);
    }
    instructions.add(sol.Instruction(
      programId: _programId,
      accounts: [sol.AccountMeta(pubKey: _keyPair.address, isWriteable: true, isSigner: true)] + accounts,
      data: [0, idx] + bytes
    ));
    signers.add(_keyPair);
    
    var txsig = await _rpc.signAndSendTransaction(sol.Message(
      instructions: instructions
    ), signers, commitment: sol.Commitment.finalized);
    await _rpc.waitForSignatureStatus(txsig, sol.Commitment.finalized);
  }

  Future<void> list() async {
    var main = await _getAccountDataFromString(_keyPair.address);
    if(main.isEmpty){
      throw 'Indentity block not found.';
    }
    for(var i = 0;i<256;i++){
      var addr = main.getRange(32*i, 32*i+32);
      if(addr.every((x) => x == 0)){
        continue;
      }

      print('#$i (${encodeAddress(addr)})');
      var curAddr = addr;
      var cur = await _getAccountDataFromBytes(curAddr);
      var j = 0;
      while(true){
        var id = cur[j];
        j++;
        var nameStart = j;
        while(cur[j] != 0) {
          j++;
        }
        var name = utf8.decode(cur.getRange(nameStart, j).toList());
        print('#$i/$id: $name');
        j++;
        while(cur[j] == 0 && j < 2016){
          j++;
        }
        if(j == 2016 || cur[j] == 0){
          print('(${encodeAddress(curAddr)} => ${encodeAddress(cur.getRange(2016, 2048))})');
          cur = await _getAccountDataFromBytes(cur.getRange(2016, 2048));
          if(cur.isEmpty) break;
          j = 0;
        }
      }
    }
  }

  Future<SubchainFreeSpace> _findFreeSubchainSpace(int idx, int nameLen) async {
    var main = await _getAccountDataFromString(_keyPair.address);
    if(main.isEmpty){
      throw 'Indentity block not found.';
    }
    var used = List.filled(256, false);
    var addresses = List<String>.empty(growable: true);
    var maxFree = 0;
    var cur = await _getAccountDataFromBytes(main.getRange(idx*32, idx*32+32));
    if(cur.isEmpty) {
      return SubchainFreeSpace(addresses, SubchainFreeStatus.RequiresAppend);
    }
    addresses.add(encodeAddress(main.getRange(idx*32, idx*32+32)));
    var i = 0;
    while(true){
      var id = cur[i];
      used[id] = true;
      i++;
      while(cur[i] != 0) {
        i++;
      }
      i++;
      var freeLen = 0;
      while(cur[i] == 0 && i < 2016){
        freeLen++;
        i++;
      }
      if(freeLen > maxFree) maxFree = freeLen;
      if(i == 2016 || cur[i] == 0){
        addresses.add(encodeAddress(cur.getRange(2016, 2048)));
        cur = await _getAccountDataFromBytes(cur.getRange(2016, 2048));
        if(cur.isEmpty) {
          addresses.removeLast();
          break;
        }
        i = 0;
      }
    }
    var id = -1;
    for(var i = 0;i<256;i++){
      if(!used[i]){
        id = i;
        break;
      }
    }
    if(id == -1) return SubchainFreeSpace(addresses, SubchainFreeStatus.Full);
    if(maxFree > nameLen+2) return SubchainFreeSpace(addresses, SubchainFreeStatus.Free);
    return SubchainFreeSpace(addresses, SubchainFreeStatus.RequiresAppend);
  }
}

enum SubchainFreeStatus{
  Full, RequiresAppend, Free
}
class SubchainFreeSpace{
  List<String> addresses;
  SubchainFreeStatus status;
  SubchainFreeSpace(this.addresses, this.status);
}