// Copyright (c) 2016 P.Y. Laligand

import 'dart:io' show Platform;
import 'dart:async' show runZoned;

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_route/shelf_route.dart';

import '../lib/bungie_middleware.dart';
import '../lib/grimoire_handler.dart';
import '../lib/online_handler.dart';
import '../lib/slack_middleware.dart';
import '../lib/trials_handler.dart';

/// Returns the value for [name] in the server configuration.
String _getConfigValue(String name) {
  final value = Platform.environment[name];
  if (value == null) {
    throw 'Missing configuration value for $name';
  }
  return value;
}

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.loggerName}: ${rec.message}');
  });

  final log = new Logger('DestinySlackBot');
  final portEnv = Platform.environment['PORT'];
  final port = portEnv == null ? 9999 : int.parse(portEnv);

  final slackTokens = _getConfigValue('SLACK_VALIDATION_TOKENS').split(',');
  final bungieApiKey = _getConfigValue('BUNGIE_API_KEY');
  final bungieClanId = _getConfigValue('BUNGIE_CLAN_ID');

  final commandRouter = router()
    ..get('/', (_) => new shelf.Response.ok('This is the Destiny bot!'))
    ..addAll(new TrialsHandler(), path: '/trials')
    ..addAll(new OnlineHandler(bungieClanId), path: '/online')
    ..addAll(new GrimoireHandler(), path: '/grimoire');

  final handler = const shelf.Pipeline()
      .addMiddleware(
          shelf.logRequests(logger: (String message, _) => log.info(message)))
      .addMiddleware(BungieMiddleWare.get(bungieApiKey))
      .addMiddleware(SlackMiddleware.get(slackTokens))
      .addHandler(commandRouter.handler);

  runZoned(() {
    log.info('Serving on port $port');
    printRoutes(commandRouter, printer: log.info);
    io.serve(handler, '0.0.0.0', port);
  }, onError: (e, stackTrace) => log.severe('Oh noes! $e $stackTrace'));
}
