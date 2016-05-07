// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../lib/bungie_client.dart';
import '../lib/bungie_types.dart';
import '../lib/context_params.dart' as param;
import '../lib/guardian_gg_client.dart';
import '../lib/trials_handler.dart';

import 'utils.dart';

const _GAMERTAG = 'd4 pl4yer';
const _DESTINY_ID = const DestinyId(true, 'abcdefghijkl');
final _GUARDIAN = new Guardian(_DESTINY_ID.token, 'Superb4d', 3144, 3.14);
final _CHARACTER = new Character('character_one', 'Hunter', new DateTime.now());
final _SUBCLASS = 'Gunslinger';

void main() {
  MockBungieDatabase database;
  MockBungieClient bungieClient;
  _MockGuardianGgClient guardianGgClient;
  Map<String, dynamic> context;
  TrialsHandler handler;

  setUp(() {
    database = new MockBungieDatabase();
    bungieClient = new MockBungieClient();
    guardianGgClient = new _MockGuardianGgClient();
    context = {
      param.BUNGIE_CLIENT: bungieClient,
      param.BUNGIE_DATABASE: database,
      param.SLACK_TEXT: _GAMERTAG
    };
    handler = new TrialsHandler.withClient(guardianGgClient);
  });

  tearDown(() {
    database = null;
    bungieClient = null;
    guardianGgClient = null;
    context = null;
    handler = null;
  });

  test('unknown player', () async {
    when(bungieClient.getDestinyId(argThat(anything))).thenReturn(null);
    context[param.SLACK_TEXT] = 'b0gus pla4yer';
    final json = await getResponse(handler, context);
    expect(json['response_type'], isNot(equals('in_channel')));
    expect(json['text'], isNotNull);
    verifyNoMoreInteractions(guardianGgClient);
  });

  test('no Trials data', () async {
    when(bungieClient.getDestinyId(argThat(equals(_GAMERTAG))))
        .thenReturn(_DESTINY_ID);
    when(guardianGgClient.getTrialsStats(argThat(anything)))
        .thenReturn(const <Guardian>[]);
    final json = await getResponse(handler, context);
    expect(json['response_type'], isNot(equals('in_channel')));
    expect(json['text'], isNotNull);
    verify(guardianGgClient.getTrialsStats(argThat(equals(_DESTINY_ID.token))));
  });

  test('unknown subclass', () async {
    when(bungieClient.getDestinyId(argThat(equals(_GAMERTAG))))
        .thenReturn(_DESTINY_ID);
    when(bungieClient.getLastPlayedCharacter(argThat(equals(_DESTINY_ID))))
        .thenReturn(null);
    when(guardianGgClient.getTrialsStats(argThat(equals(_DESTINY_ID.token))))
        .thenReturn([_GUARDIAN]);
    final json = await getResponse(handler, context);
    expect(json['response_type'], equals('in_channel'));
    expect(json['text'], isNotNull);
    expect(json['text'], contains('Unknown'));
  });

  test('found team', () async {
    when(bungieClient.getDestinyId(argThat(equals(_GAMERTAG))))
        .thenReturn(_DESTINY_ID);
    when(bungieClient.getLastPlayedCharacter(argThat(equals(_DESTINY_ID))))
        .thenReturn(_CHARACTER);
    final inventory = new _MockInventory();
    when(inventory.subclass).thenReturn(_SUBCLASS);
    when(inventory.armorIds).thenReturn(const []);
    when(inventory.weaponIds).thenReturn(const []);
    when(bungieClient.getInventory(
            argThat(equals(_DESTINY_ID)), argThat(equals(_CHARACTER.id))))
        .thenReturn(inventory);
    when(guardianGgClient.getTrialsStats(argThat(equals(_DESTINY_ID.token))))
        .thenReturn([_GUARDIAN]);
    when(database.getArmorPieces(any)).thenReturn(new Stream.fromIterable([]));
    when(database.getWeapons(any)).thenReturn(new Stream.fromIterable([]));
    final json = await getResponse(handler, context);
    expect(json['response_type'], equals('in_channel'));
    expect(json['text'], isNotNull);
    expect(json['text'], contains(_SUBCLASS));
  });
}

class _MockGuardianGgClient extends Mock implements GuardianGgClient {}

class _MockInventory extends Mock implements Inventory {}
