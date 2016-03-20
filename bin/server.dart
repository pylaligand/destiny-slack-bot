// Copyright (c) 2016 P.Y. Laligand

import 'dart:io' show Platform;
import 'dart:async' show runZoned;

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_route/shelf_route.dart';

import '../lib/slack_middleware.dart';
import '../lib/trials_handler.dart';

void main() {
  final portEnv = Platform.environment['PORT'];
  final port = portEnv == null ? 9999 : int.parse(portEnv);

  final slackToken = Platform.environment['SLACK_TEAM_TOKEN'];
  if (slackToken == null) {
    throw 'Slack token not specified!';
  }

  final commandRouter = router()
    ..get('/', (_) => new shelf.Response.ok('This is the Destiny bot!'))
    ..addAll(new TrialsHandler());

  final handler = const shelf.Pipeline()
      .addMiddleware(shelf.logRequests())
      .addMiddleware(SlackMiddleware.get(slackToken))
      .addHandler(commandRouter.handler);

  runZoned(() {
    print('Serving on $port');
    io.serve(handler, '0.0.0.0', port);
  }, onError: (e, stackTrace) => print('Oh noes! $e $stackTrace'));
}
