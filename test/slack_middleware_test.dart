// Copyright (c) 2016 P.Y. Laligand

import 'package:shelf/shelf.dart' as shelf;
import 'package:test/test.dart';

import '../lib/slack_middleware.dart';

const _TOKEN_ONE = 'abcdef';
const _TOKEN_TWO = '123456';
const _NOT_TOKEN = 'ghi789';
const _TOKENS = const [_TOKEN_ONE, _TOKEN_TWO];
final _RESPONSE = new shelf.Response.ok('all good!');

void main() {
  shelf.Middleware middleware;
  shelf.Request handledRequest;

  shelf.Response testHandler(shelf.Request request) {
    handledRequest = request;
    return _RESPONSE;
  }

  setUp(() {
    middleware = SlackMiddleware.get(_TOKENS, false);
  });

  tearDown(() {
    middleware = null;
    handledRequest = null;
  });

  test('leave GET alone', () async {
    final request =
        new shelf.Request('GET', Uri.parse('http://something.com/path'));
    final response = await middleware(testHandler)(request);
    expect(handledRequest, same(request));
    expect(response, same(_RESPONSE));
  });

  test('wrong content type', () async {
    final body = _getBody({'token': _TOKEN_ONE});
    final request = new shelf.Request(
        'POST', Uri.parse('http://something.com/path'),
        body: body);
    final response = await middleware(testHandler)(request);
    expect(handledRequest, isNot(same(request)));
    expect(response, isNot(same(_RESPONSE)));
  });

  test('invalid token', () async {
    final body = _getBody({'token': _NOT_TOKEN});
    final request = new shelf.Request(
        'POST', Uri.parse('http://something.com/path'),
        body: body,
        headers: {'content-type': 'application/x-www-form-urlencoded'});
    final response = await middleware(testHandler)(request);
    expect(handledRequest, isNot(same(request)));
    expect(response, isNot(same(_RESPONSE)));
  });

  test('valid token', () async {
    final body = _getBody({'token': _TOKEN_TWO});
    final request = new shelf.Request(
        'POST', Uri.parse('http://something.com/path'),
        body: body,
        headers: {'content-type': 'application/x-www-form-urlencoded'});
    final response = await middleware(testHandler)(request);
    expect(handledRequest, isNot(same(request)));
    expect(response, same(_RESPONSE));
  });

  test('parameter parsing', () async {
    final body = _getBody({'token': _TOKEN_TWO, 'foo': 'bar'});
    final request = new shelf.Request(
        'POST', Uri.parse('http://something.com/path'),
        body: body,
        headers: {'content-type': 'application/x-www-form-urlencoded'});
    final response = await middleware(testHandler)(request);
    expect(handledRequest, isNot(same(request)));
    expect(handledRequest.context, containsPair('slack_foo', 'bar'));
    expect(response, same(_RESPONSE));
  });
}

/// Encodes the content of a request body according to Slack's format.
String _getBody(Map<String, String> params) {
  return Uri
      .encodeFull(params.keys.map((key) => '$key=${params[key]}').join('&'));
}
