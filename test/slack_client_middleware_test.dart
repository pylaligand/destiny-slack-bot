// Copyright (c) 2016 P.Y. Laligand

import 'package:shelf/shelf.dart' as shelf;
import 'package:test/test.dart';

import '../lib/context_params.dart' as param;
import '../lib/slack_client_middleware.dart';

const _AUTH_TOKEN = 'yellow it is me!';
final _RESPONSE = new shelf.Response.ok('all good!');

void main() {
  shelf.Middleware middleware;
  shelf.Request handledRequest;

  shelf.Response testHandler(shelf.Request request) {
    handledRequest = request;
    return _RESPONSE;
  }

  setUp(() {
    middleware = SlackClientMiddleware.get(_AUTH_TOKEN);
  });

  tearDown(() {
    middleware = null;
    handledRequest = null;
  });

  test('adds client', () async {
    final body = _getBody({'token': '12345', 'foo': 'bar'});
    final request = new shelf.Request(
        'POST', Uri.parse('http://something.com/path'),
        body: body,
        headers: {'content-type': 'application/x-www-form-urlencoded'});
    final response = await middleware(testHandler)(request);
    expect(handledRequest, isNot(same(request)));
    expect(handledRequest.context[param.SLACK_CLIENT], isNotNull);
    expect(response, same(_RESPONSE));
  });
}

/// Encodes the content of a request body according to Slack's format.
String _getBody(Map<String, String> params) {
  return Uri
      .encodeFull(params.keys.map((key) => '$key=${params[key]}').join('&'));
}
