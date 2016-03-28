// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_route/shelf_route.dart';
import 'package:test/test.dart';

import '../lib/slack_command_handler.dart';

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
    final request =
        new shelf.Request('POST', Uri.parse('http://something.com/test'));
    final responseFuture = testRouter.handler(request);
    expect(responseFuture, new isInstanceOf<Future<shelf.Response>>());
    final shelf.Response response = await responseFuture;
    expect(await response.readAsString(), equals('Yipee!'));
  });
}

class TestHandler extends SlackCommandHandler {
  @override
  Future<shelf.Response> handle(shelf.Request request) {
    return new Future.value(new shelf.Response.ok('Yipee!'));
  }
}
