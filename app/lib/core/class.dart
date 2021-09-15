import 'dart:convert';

import 'package:app/core/utils.dart';
import 'package:app/ui/utils.dart';
import 'package:flutter/material.dart';
import 'package:solana/solana.dart';

class Class {
  final RPCClient _rpc;
  final Ed25519HDKeyPair _keyPair;
  final Ed25519HDKeyPair _funder;
  final String _seed;
  ClassData? data;

  String get address => _keyPair.address;
  String get seed => _seed;
  static Future<Class> createNew(RPCClient rpc, String programId,
      Ed25519HDKeyPair funder, String name, ProgressNotifier progress) async {
    progress.set('Generating keypair...');
    var kpe = await generateKeyPair();
    var keyPair = kpe[0];
    progress.set('Building instruction...');
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
                rent: await rpc.getMinimumBalanceForRentExemption(2048),
                space: 2048,
                programId: programId)
            .data);
    var initIns = Instruction(
        programId: programId,
        accounts: [
          AccountMeta(
              pubKey: keyPair.address, isWriteable: true, isSigner: true)
        ],
        data: [1] + utf8.encode(name));
    progress.set('Sending transaction...');
    var txsig = await rpc.signAndSendTransaction(
        Message(instructions: [createIns, initIns]), [funder, keyPair],
        commitment: Commitment.finalized);
    debugPrint(txsig.toString());
    progress.set('Waiting for confirmation...');
    await rpc.waitForSignatureStatus(txsig, Commitment.finalized);
    progress.set('Successfully added.');
    progress.finish();
    return Class(rpc, funder, keyPair, kpe[1]);
  }

  static Future<Class> loadExisting(RPCClient rpc, String programId,
      Ed25519HDKeyPair funder, String seed) async {
    var kp = await loadKeyPair(seed);
    return Class(rpc, funder, kp, seed);
  }

  Class(this._rpc, this._funder, this._keyPair, this._seed);
  Future<void> sync(ProgressNotifier progress) async {
    progress.set('Downloading class block...');
    var accountData = await getAccountDataFromString(_rpc, _keyPair.address);
    data = ClassData(
        utf8.decode(accountData.getRange(0, accountData.indexOf(0)).toList()));
    progress.set('Successfully downloaded.');
    progress.finish();
  }
}

class ClassData {
  String name;
  ClassData(this.name);
}
