import 'dart:convert';
import 'dart:math';

import 'package:solana/solana.dart';

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

Future<List> generateKeyPair() async {
  var rnd = Random.secure();
  var seed = List<int>.generate(32, (index) => rnd.nextInt(256));
  return [
    await Ed25519HDKeyPair.fromSeedWithHdPath(
        seed: seed, hdPath: "m/44'/501'/0'/0'"),
    base64.encode(seed)
  ];
}

Future<Ed25519HDKeyPair> loadKeyPair(String s) async {
  return await Ed25519HDKeyPair.fromSeedWithHdPath(
      seed: base64.decode(s), hdPath: "m/44'/501'/0'/0'");
}

Future<List<int>> getAccountDataFromBytes(
    RPCClient rpc, Iterable<int> addr) async {
  if (addr.every((x) => x == 0)) {
    return List.empty();
  }
  return getAccountDataFromString(rpc, encodeAddress(addr));
}

Future<List<int>> getAccountDataFromString(RPCClient rpc, String addr) async {
  var data = (await rpc.getAccountInfo(addr, commitment: Commitment.processed))
      ?.data
      ?.whenOrNull(fromBytes: (List<int> b) => b);
  if (data == null) return List.empty();
  return data;
}
