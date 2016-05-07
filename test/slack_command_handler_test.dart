// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';

import 'package:quiver/testing/async.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_route/shelf_route.dart';
import 'package:test/test.dart';

import '../lib/context_params.dart' as param;
import '../lib/slack_command_handler.dart';

const _MESSAGE = 'Yipee!';

main() {
  TestHandler handler;
  Router testRouter;

  setUp(() {
    handler = new TestHandler();
    testRouter = router()..addAll(handler, path: '/test');
  });

  tearDown(() {
    handler = null;
    testRouter = null;
  });

  test('SSL check', () async {
    final request = new shelf.Request(
        'GET', Uri.parse('http://something.com/test?ssl_check=1'));
    final responseFuture = testRouter.handler(request);
    expect(responseFuture, new isInstanceOf<Future<shelf.Response>>());
    final shelf.Response response = await responseFuture;
    expect(response.statusCode, equals(200));
  });

  test('random GET', () async {
    final request =
        new shelf.Request('GET', Uri.parse('http://something.com/test'));
    final responseFuture = testRouter.handler(request);
    expect(responseFuture, new isInstanceOf<Future<shelf.Response>>());
    final shelf.Response response = await responseFuture;
    expect(response.statusCode, equals(404));
  });

  test('POST', () async {
    final request = new shelf.Request(
        'POST', Uri.parse('http://something.com/test'),
        context: {param.USE_DELAYED_RESPONSES: false});
    final responseFuture = testRouter.handler(request);
    expect(responseFuture, new isInstanceOf<Future<shelf.Response>>());
    final shelf.Response response = await responseFuture;
    expect(await response.readAsString(), equals(_MESSAGE));
  });

  test('delayed response', () {
    new FakeAsync().run((control) {
      handler = new TestHandler.delayed(10);
      testRouter = router()..addAll(handler, path: '/test');
      final request = new shelf.Request(
          'POST', Uri.parse('http://something.com/test'),
          context: {param.USE_DELAYED_RESPONSES: true});
      shelf.Response receivedResponse;
      final future = testRouter.handler(request);
      future.then((response) {
        receivedResponse = response;
      });
      expect(receivedResponse, isNull);
      control.elapse(const Duration(seconds: 2));
      expect(receivedResponse, isNull);
      control.elapse(const Duration(seconds: 5));
      expect(receivedResponse, isNotNull);
      receivedResponse.readAsString().then((content) {
        expect(content, isNot(equals(_MESSAGE)));
      });
      control.flushMicrotasks();
    });
  });
}

class TestHandler extends SlackCommandHandler {
  final int _delaySeconds;

  factory TestHandler() {
    return new TestHandler.delayed(0);
  }

  TestHandler.delayed(this._delaySeconds);

  @override
  Future<shelf.Response> handle(shelf.Request request) {
    final response = new shelf.Response.ok(_MESSAGE);
    if (_delaySeconds > 0) {
      return new Future.delayed(
          new Duration(seconds: _delaySeconds), () => response);
    }
    return new Future.value(response);
  }
}
