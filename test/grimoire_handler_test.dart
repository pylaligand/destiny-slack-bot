// Copyright (c) 2016 P.Y. Laligand

import 'dart:convert';

import 'package:mockito/mockito.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:test/test.dart';

import '../lib/bungie_client.dart';
import '../lib/grimoire_handler.dart';

const _SCORE = 4860;
const _USER_ONE = 'mother4nn';
const _USER_TWO = 'yy_recent_person_yy';
const _GAMERTAG = 'yy recent person yy';
const _DESTINY_ID = const DestinyId(true, 'abcdefghijkl');

void main() {
  _MockBungieClient client;
  Map<String, dynamic> context;
  GrimoireHandler handler;

  setUp(() {
    client = new _MockBungieClient();
    context = {'bungie_client': client};
    handler = new GrimoireHandler();
  });

  tearDown(() {
    client = null;
    handler = null;
  });

  test('unknown gamertag', () async {
    when(client.getDestinyId(any)).thenReturn(null);
    context['user_name'] = _USER_ONE;
    context['text'] = _GAMERTAG;
    final json = await _getResponse(handler, context);
    expect(json['response_type'], isNot(equals('in_channel')));
  });

  test('cannot find score', () async {
    when(client.getDestinyId(_GAMERTAG)).thenReturn(_DESTINY_ID);
    when(client.getGrimoireScore(any)).thenReturn(null);
    context['user_name'] = _USER_ONE;
    context['text'] = _GAMERTAG;
    final json = await _getResponse(handler, context);
    expect(json['response_type'], isNot(equals('in_channel')));
  });

  test('get score', () async {
    when(client.getDestinyId(_GAMERTAG)).thenReturn(_DESTINY_ID);
    when(client.getGrimoireScore(_DESTINY_ID)).thenReturn(_SCORE);
    context['user_name'] = _USER_ONE;
    context['text'] = _GAMERTAG;
    final json = await _getResponse(handler, context);
    expect(json['response_type'], equals('in_channel'));
    expect(json['text'], contains(_SCORE.toString()));
  });

  test('fall back to username', () async {
    when(client.getDestinyId(_USER_ONE)).thenReturn(_DESTINY_ID);
    when(client.getGrimoireScore(_DESTINY_ID)).thenReturn(_SCORE);
    context['user_name'] = _USER_ONE;
    final json = await _getResponse(handler, context);
    expect(json['response_type'], equals('in_channel'));
    expect(json['text'], contains(_SCORE.toString()));
  });

  test('replace underscores', () async {
    when(client.getDestinyId(_GAMERTAG)).thenReturn(_DESTINY_ID);
    when(client.getGrimoireScore(_DESTINY_ID)).thenReturn(_SCORE);
    context['user_name'] = _USER_TWO;
    final json = await _getResponse(handler, context);
    expect(json['response_type'], equals('in_channel'));
    expect(json['text'], contains(_SCORE.toString()));
  });
}

dynamic _getResponse(
    GrimoireHandler handler, Map<String, dynamic> context) async {
  final request = new shelf.Request(
      'POST', Uri.parse('http://something.com/path'),
      context: context);
  final response = await handler.handle(request);
  expect(response.statusCode, equals(200));
  return JSON.decode(await response.readAsString());
}

class _MockBungieClient extends Mock implements BungieClient {}
