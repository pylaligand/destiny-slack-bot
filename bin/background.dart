// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
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
  final botToken = _getConfigValue('SLACK_BOT_TOKEN');
  _monitorTwitch(botToken);
}

/// Monitors the status of Twitch streamers and sends notifications to Slack.
_monitorTwitch(String botToken) {
  final logger = new Logger('Twitch');
  final channel = _getConfigValue('SLACK_BOT_CHANNEL');
  final scanner =
      new TwitchScanner(_getConfigValue('TWITCH_STREAMERS').split(','));
  List<Streamer> oldStreamers = [];
  new Timer.periodic(const Duration(minutes: 5), (_) async {
    logger.info('Checking...');
    await scanner.update();
    final newStreamers = scanner.liveStreamers;
    newStreamers
        .where((streamer) => !oldStreamers.contains(streamer))
        .forEach((streamer) {
      logger.info('$streamer is now online!');
      final postUrl = new Uri.https('slack.com', 'api/chat.postMessage', {
        'token': botToken,
        'channel': channel,
        'text':
            ':twitch:  Now streaming: <https://www.twitch.tv/${streamer.id}|${streamer.name}> - ${streamer.status}  :twitch:',
        'unfurl_media': 'false',
        'as_user': 'true'
      });
      http.post(postUrl).then((response) {
        final json = JSON.decode(response.body);
        if (!json['ok']) {
          logger.info('Failed notification: ${json['error']}');
        }
      });
    });
    oldStreamers
        .where((streamer) => !newStreamers.contains(streamer))
        .forEach((streamer) => logger.info('$streamer is now offline!'));
    oldStreamers = newStreamers;
  });
}
