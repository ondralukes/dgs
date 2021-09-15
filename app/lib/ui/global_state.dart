import 'package:app/core/class.dart';
import 'package:app/core/identity_storage.dart';
import 'package:app/core/utils.dart';
import 'package:app/ui/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solana/solana.dart';

const programId = 'C9K2LGqKi8neGetJNjBcnKxUzgRrvkNcraE8UZwjsySL';

class GlobalState {
  late RPCClient rpc;
  late Ed25519HDKeyPair funder;
  late SharedPreferences _storage;
  int funderBalance = 0;
  IdentityStorage? identityStorage;
  late List<Class> classes;

  bool loaded = false;

  Future<void> load() async {
    _storage = await SharedPreferences.getInstance();
    await _loadCommon();
    await _loadIdentity();
    await _loadClasses();
    loaded = true;
  }

  Future<void> _loadCommon() async {
    if (_storage.containsKey('funder')) {
      funder = await loadKeyPair(_storage.getString('funder')!);
    } else {
      var k = await generateKeyPair();
      funder = k[0];
      await _storage.setString('funder', k[1]);
    }
    rpc = RPCClient('https://api.devnet.solana.com');
    await _updateFunderBalance();
  }

  Future<void> _loadIdentity() async {
    if (_storage.containsKey('identity')) {
      identityStorage = await IdentityStorage.loadExisting(
          rpc, programId, funder, _storage.getString('identity')!);
    }
  }

  Future<void> _loadClasses() async {
    classes = List<Class>.empty(growable: true);
    var keys = _storage.getStringList('classes');
    if (keys == null) return;
    for (var k in keys) {
      classes.add(await Class.loadExisting(rpc, programId, funder, k));
    }
  }

  Future<void> createClass(String name, ProgressNotifier progress) async {
    classes.add(await Class.createNew(rpc, programId, funder, name, progress));
    await _saveClassList();
  }

  Future<void> _saveClassList() async {
    var _storage = await SharedPreferences.getInstance();
    var keys = List<String>.filled(classes.length, '');
    var i = 0;
    for (var c in classes) {
      keys[i++] = c.seed;
    }
    _storage.setStringList('classes', keys);
  }

  Future<void> _updateFunderBalance() async {
    funderBalance = await rpc.getBalance(funder.address);
  }

  Future<void> airdrop(ProgressNotifier progress) async {
    progress.set('Requesting airdrop...');
    var txid =
        await rpc.requestAirdrop(address: funder.address, lamports: 1000000000);
    progress.set('Waiting for confirmation...');
    await rpc.waitForSignatureStatus(txid, Commitment.finalized);
    progress.set('Refreshing balance...');
    await _updateFunderBalance();
    progress.finish();
  }

  Future<void> createIdentity(ProgressNotifier progress) async {
    progress.set('Creating identity block...');
    identityStorage = await IdentityStorage.createNew(rpc, programId, funder);
    await _storage.setString('identity', identityStorage!.seed);
    progress.set('Refreshing balance...');
    await _updateFunderBalance();
    progress.finish();
  }
}
