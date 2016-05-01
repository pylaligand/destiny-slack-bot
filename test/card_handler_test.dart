// Copyright (c) 2016 P.Y. Laligand

import 'dart:convert';

import 'package:mockito/mockito.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:test/test.dart';

import '../lib/bungie_database.dart';
import '../lib/bungie_types.dart';
import '../lib/card_handler.dart';

void main() {
  _MockBungieDatabase database;
  Map<String, dynamic> context;
  CardHandler handler;

  setUp(() {
    database = new _MockBungieDatabase();
    context = {'bungie_database': database};
    handler = new CardHandler();
  });

  tearDown(() {
    database = null;
    context = null;
    handler = null;
  });

  test('escapes fields', () async {
    when(database.getGrimoireCardCount()).thenReturn(10);
    when(database.getGrimoireCard(any)).thenReturn(new GrimoireCard(
        new ItemId(314), '&quot;Foo&quot; Bar', 'Bar<br/>Foo'));
    final json = await _getResponse(handler, context);
    expect(json['response_type'], equals('in_channel'));
    expect(json['attachments'].length, equals(1));
    expect(json['attachments'][0]['title'], equals('"Foo" Bar'));
    expect(json['attachments'][0]['text'], equals('Bar\nFoo'));
  });
}

dynamic _getResponse(CardHandler handler, Map<String, dynamic> context) async {
  final request = new shelf.Request(
      'POST', Uri.parse('http://something.com/path'),
      context: context);
  final response = await handler.handle(request);
  expect(response.statusCode, equals(200));
  return JSON.decode(await response.readAsString());
}

class _MockBungieDatabase extends Mock implements BungieDatabase {}
