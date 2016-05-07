// Copyright (c) 2016 P.Y. Laligand

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

import '../lib/bungie_types.dart';
import '../lib/card_handler.dart';
import '../lib/context_params.dart' as param;

import 'utils.dart';

void main() {
  MockBungieDatabase database;
  Map<String, dynamic> context;
  CardHandler handler;

  setUp(() {
    database = new MockBungieDatabase();
    context = {param.BUNGIE_DATABASE: database};
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
    final json = await getResponse(handler, context);
    expect(json['response_type'], equals('in_channel'));
    expect(json['attachments'].length, equals(1));
    expect(json['attachments'][0]['title'], equals('"Foo" Bar'));
    expect(json['attachments'][0]['text'], equals('Bar\nFoo'));
  });
}
