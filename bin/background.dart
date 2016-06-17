// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:io' show Platform;

import 'package:logging/logging.dart';

import '../lib/twitch_scanner.dart';

/// Returns the value for [name] in the server configuration.
String _getConfigValue(String name) {
  final value = Platform.environment[name];
  if (value == null) {
    throw 'Missing configuration value for $name';
  }
  return value;
}

main(List<String> args) {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.loggerName}: ${rec.message}');
  });
  _monitorTwitch();
}

/// Monitors the status of Twitch streamers and sends notifications to Slack.
_monitorTwitch() {
  final logger = new Logger('Twitch');
  final scanner =
      new TwitchScanner(_getConfigValue('TWITCH_STREAMERS').split(','));
  List<Streamer> oldStreamers = [];
  new Timer.periodic(const Duration(seconds: 10), (_) async {
    logger.info('Checking...');
    await scanner.update();
    final newStreamers = scanner.liveStreamers;
    newStreamers
        .where((streamer) => !oldStreamers.contains(streamer))
        .forEach((streamer) => logger.info('$streamer is now online!'));
    oldStreamers
        .where((streamer) => !newStreamers.contains(streamer))
        .forEach((streamer) => logger.info('$streamer is now offline!'));
    oldStreamers = newStreamers;
  });
}
