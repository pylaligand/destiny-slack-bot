// Copyright (c) 2016 P.Y. Laligand

import 'dart:convert';

import 'package:mockito/mockito.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:test/test.dart';

import '../lib/bungie_client.dart';
import '../lib/context_params.dart' as param;
import '../lib/online_handler.dart';

const _CLAN_ID = '123456789';
const _ON_XBOX = true;
const _MEMBER_ONE =
    const ClanMember('foo', const BungieId('abcdef'), 'member_one', _ON_XBOX);
const _MEMBER_TWO =
    const ClanMember('bar', const BungieId('ghijkl'), 'member_two', _ON_XBOX);
final _NOW = new DateTime.now();
final _CHARACTER_ONE = new Character(
    'character_one', 'Hunter', _NOW.subtract(const Duration(minutes: 5)));
final _CHARACTER_ONE_OLD = new Character(
    'character_one', 'Hunter', _NOW.subtract(const Duration(hours: 6)));
final _CHARACTER_TWO_OLD = new Character(
    'character_two', 'Warlock', _NOW.subtract(const Duration(days: 5)));

void main() {
  _MockBungieClient client;
  Map<String, dynamic> context;
  OnlineHandler handler;

  setUp(() {
    client = new _MockBungieClient();
    context = {param.BUNGIE_CLIENT: client, param.SLACK_TEXT: 'xbl'};
    handler = new OnlineHandler(_CLAN_ID);
  });

  tearDown(() {
    client = null;
    context = null;
    handler = null;
  });

  test('no member in clan', () async {
    when(client.getClanRoster(_CLAN_ID, _ON_XBOX)).thenReturn(<ClanMember>[]);
    final json = await _getResponse(handler, context);
    expect(json['response_type'], equals('in_channel'));
    expect(json['attachments'], isNotNull);
  });

  test('invalid platform', () async {
    context[param.SLACK_TEXT] = 'bogus!';
    final json = await _getResponse(handler, context);
    expect(json['response_type'], isNot(equals('in_channel')));
    expect(json['text'], isNotNull);
    verifyZeroInteractions(client);
  });

  test('with online members', () async {
    when(client.getClanRoster(_CLAN_ID, _ON_XBOX))
        .thenReturn(<ClanMember>[_MEMBER_ONE, _MEMBER_TWO]);
    when(client.getLastPlayedCharacter(_MEMBER_ONE.id))
        .thenReturn(_CHARACTER_ONE);
    when(client.getLastPlayedCharacter(_MEMBER_TWO.id))
        .thenReturn(_CHARACTER_TWO_OLD);
    final json = await _getResponse(handler, context);
    expect(json['response_type'], equals('in_channel'));
    expect(json['text'], isNotNull);
    expect(json['text'], contains(_MEMBER_ONE.gamertag));
    expect(json['text'], isNot(contains(_MEMBER_TWO.gamertag)));
  });

  test('no online member', () async {
    when(client.getClanRoster(_CLAN_ID, _ON_XBOX))
        .thenReturn(<ClanMember>[_MEMBER_ONE, _MEMBER_TWO]);
    when(client.getLastPlayedCharacter(_MEMBER_ONE.id))
        .thenReturn(_CHARACTER_ONE_OLD);
    when(client.getLastPlayedCharacter(_MEMBER_TWO.id))
        .thenReturn(_CHARACTER_TWO_OLD);
    final json = await _getResponse(handler, context);
    expect(json['response_type'], equals('in_channel'));
    expect(json['attachments'], isNotNull);
  });

  test('no character data', () async {
    when(client.getClanRoster(_CLAN_ID, _ON_XBOX))
        .thenReturn(<ClanMember>[_MEMBER_ONE, _MEMBER_TWO]);
    final json = await _getResponse(handler, context);
    expect(json['response_type'], equals('in_channel'));
    expect(json['attachments'], isNotNull);
  });
}

dynamic _getResponse(
    OnlineHandler handler, Map<String, dynamic> context) async {
  final request = new shelf.Request(
      'POST', Uri.parse('http://something.com/path'),
      context: context);
  final response = await handler.handle(request);
  expect(response.statusCode, equals(200));
  return JSON.decode(await response.readAsString());
}

class _MockBungieClient extends Mock implements BungieClient {}
