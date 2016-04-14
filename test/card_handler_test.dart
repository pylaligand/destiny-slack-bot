// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:convert';
import 'dart:mirrors';

import 'package:mockito/mockito.dart';
import 'package:postgresql/postgresql.dart' as pg;
import 'package:shelf/shelf.dart' as shelf;
import 'package:test/test.dart';

import '../lib/card_handler.dart';
import '../lib/postgres_client.dart';

void main() {
  _MockConnection connection;
  Map<String, dynamic> context;
  CardHandler handler;

  setUp(() {
    connection = new _MockConnection();
    context = {'postgres_client': new _MockPostgresClient(connection)};
    handler = new CardHandler();
  });

  tearDown(() {
    connection = null;
    context = null;
    handler = null;
  });

  test('escapes title', () async {
    when(connection.query(argThat(startsWith('SELECT COUNT(*)'))))
        .thenReturn(new Stream.fromIterable([
      new _Row({'count': 1})
    ]));
    when(connection.query(argThat(startsWith('SELECT * FROM'))))
        .thenReturn(new Stream.fromIterable([
      new _Row(
          {'id': 314, 'title': '&quot;Foo&quot; Bar', 'content': 'Bar<br/>Foo'})
    ]));
    final json = await _getResponse(handler, context);
    expect(json['response_type'], equals('in_channel'));
    expect(json['attachments'].length, equals(1));
    expect(json['attachments'][0]['title'], equals('"Foo" Bar'));
    expect(json['attachments'][0]['text'], contains('Bar\nFoo'));
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

class _MockPostgresClient implements PostgresClient {
  final _MockConnection _connection;

  _MockPostgresClient(this._connection);

  @override
  connect() => _connection;
}

class _MockConnection extends Mock implements pg.Connection {}

@proxy
class _Row implements pg.Row {
  final Map<String, dynamic> _values;

  _Row(this._values);

  @override
  noSuchMethod(Invocation invocation) {
    if (invocation.isGetter) {
      return _values[MirrorSystem.getName(invocation.memberName)];
    }
    return super.noSuchMethod(invocation);
  }
}
