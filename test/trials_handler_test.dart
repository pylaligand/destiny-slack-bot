// Copyright (c) 2016 P.Y. Laligand

import 'dart:convert';

import 'package:mockito/mockito.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:test/test.dart';

import '../lib/bungie_client.dart';
import '../lib/guardian_gg_client.dart';
import '../lib/trials_handler.dart';

const _GAMERTAG = 'd4 pl4yer';
const _DESTINY_ID = const DestinyId(true, 'abcdefghijkl');
final _GUARDIAN = new Guardian(_DESTINY_ID.token, 'Superb4d', 3144, 3.14);
final _CHARACTER = new Character('character_one', 'Hunter', new DateTime.now());
final _SUBCLASS = 'Gunslinger';

void main() {
  _MockBungieClient bungie_client;
  _MockGuardianGgClient guardian_gg_client;
  TrialsHandler handler;

  setUp(() {
    bungie_client = new _MockBungieClient();
    guardian_gg_client = new _MockGuardianGgClient();
    handler = new TrialsHandler.withClient(guardian_gg_client);
  });

  tearDown(() {
    bungie_client = null;
    guardian_gg_client = null;
  });

  test('unknown player', () async {
    when(bungie_client.getDestinyId(argThat(anything))).thenReturn(null);
    final context = {'bungie_client': bungie_client, 'text': 'b0gus pla4yer'};
    final json = await _getResponse(handler, context);
    expect(json['response_type'], isNot(equals('in_channel')));
    expect(json['text'], isNotNull);
    verifyNoMoreInteractions(guardian_gg_client);
  });

  test('no Trials data', () async {
    when(bungie_client.getDestinyId(argThat(equals(_GAMERTAG))))
        .thenReturn(_DESTINY_ID);
    when(guardian_gg_client.getTrialsStats(argThat(anything)))
        .thenReturn(const <Guardian>[]);
    final context = {'bungie_client': bungie_client, 'text': _GAMERTAG};
    final json = await _getResponse(handler, context);
    expect(json['response_type'], isNot(equals('in_channel')));
    expect(json['text'], isNotNull);
    verify(
        guardian_gg_client.getTrialsStats(argThat(equals(_DESTINY_ID.token))));
  });

  test('unknown subclass', () async {
    when(bungie_client.getDestinyId(argThat(equals(_GAMERTAG))))
        .thenReturn(_DESTINY_ID);
    when(bungie_client.getLastPlayedCharacter(argThat(equals(_DESTINY_ID))))
        .thenReturn(null);
    when(guardian_gg_client.getTrialsStats(argThat(equals(_DESTINY_ID.token))))
        .thenReturn([_GUARDIAN]);
    final context = {'bungie_client': bungie_client, 'text': _GAMERTAG};
    final json = await _getResponse(handler, context);
    expect(json['response_type'], equals('in_channel'));
    expect(json['text'], isNotNull);
    expect(json['text'], contains('Unknown'));
  });

  test('found team', () async {
    when(bungie_client.getDestinyId(argThat(equals(_GAMERTAG))))
        .thenReturn(_DESTINY_ID);
    when(bungie_client.getLastPlayedCharacter(argThat(equals(_DESTINY_ID))))
        .thenReturn(_CHARACTER);
    final inventory = new _MockInventory();
    when(inventory.subclass).thenReturn(_SUBCLASS);
    when(bungie_client.getInventory(
            argThat(equals(_DESTINY_ID)), argThat(equals(_CHARACTER.id))))
        .thenReturn(inventory);
    when(guardian_gg_client.getTrialsStats(argThat(equals(_DESTINY_ID.token))))
        .thenReturn([_GUARDIAN]);
    final context = {'bungie_client': bungie_client, 'text': _GAMERTAG};
    final json = await _getResponse(handler, context);
    expect(json['response_type'], equals('in_channel'));
    expect(json['text'], isNotNull);
    expect(json['text'], contains(_SUBCLASS));
  });
}

dynamic _getResponse(
    TrialsHandler handler, Map<String, dynamic> context) async {
  final request = new shelf.Request(
      'POST', Uri.parse('http://something.com/path'),
      context: context);
  final response = await handler.handle(request);
  expect(response.statusCode, equals(200));
  return JSON.decode(await response.readAsString());
}

class _MockBungieClient extends Mock implements BungieClient {}

class _MockGuardianGgClient extends Mock implements GuardianGgClient {}

class _MockInventory extends Mock implements Inventory {}
