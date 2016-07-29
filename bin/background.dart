// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:timezone/standalone.dart';

import '../lib/the_hundred_client.dart';
import '../lib/twitch_scanner.dart';

/// An entity sending messages to Slack.
typedef Future<bool> MessageSender(Map content, Logger logger);

/// Returns the value for [name] in the server configuration.
String _getConfigValue(String name) {
  final value = io.Platform.environment[name];
  if (value == null) {
    throw 'Missing configuration value for $name';
  }
  return value;
}

main(List<String> args) async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.loggerName}: ${rec.message}');
  });
  await initializeTimeZone();

  final slackBotToken = _getConfigValue('SLACK_BOT_TOKEN');
  final slackBotChannel = _getConfigValue('SLACK_BOT_CHANNEL');
  final theHundredAuthToken = _getConfigValue('THE_HUNDRED_AUTH_TOKEN');
  final theHundredGroupdId = _getConfigValue('THE_HUNDRED_GROUP_ID');

  final sender = (Map content, Logger logger) async {
    content['token'] = slackBotToken;
    content['channel'] = slackBotChannel;
    content['as_user'] = 'true';
    final postUrl = new Uri.https('slack.com', 'api/chat.postMessage', content);
    return http.post(postUrl).then((response) {
      final json = JSON.decode(response.body);
      if (!json['ok']) {
        logger.warning('Message not published: ${json['error']}');
        return false;
      }
      return true;
    }).catchError((error) {
      logger.warning('Message request failed: $error');
      return false;
    });
  };

  _monitorTwitch(sender);
  _monitorTheHundred(theHundredAuthToken, theHundredGroupdId, sender);
}

/// Monitors the status of Twitch streamers and sends notifications to Slack.
_monitorTwitch(MessageSender sender) async {
  final logger = new Logger('Twitch');
  final scanner =
      new TwitchScanner(_getConfigValue('TWITCH_STREAMERS').split(','));
  await scanner.update();
  List<Streamer> oldStreamers = scanner.liveStreamers;
  new Timer.periodic(const Duration(minutes: 5), (_) async {
    logger.info('Checking...');
    await scanner.update();
    final newStreamers = scanner.liveStreamers;
    newStreamers
        .where((streamer) => !oldStreamers.contains(streamer))
        .forEach((streamer) {
      logger.info('$streamer is now online!');
      sender({
        'text':
            ':twitch:  Now streaming: <https://www.twitch.tv/${streamer.id}|${streamer.name}> - ${streamer.status}  :twitch:',
        'unfurl_media': 'false',
        'unfurl_links': 'false'
      }, logger);
    });
    oldStreamers
        .where((streamer) => !newStreamers.contains(streamer))
        .forEach((streamer) => logger.info('$streamer is now offline!'));
    oldStreamers = newStreamers;
  });
}

/// Monitors activity on the100.io and reports to Slack.
_monitorTheHundred(
    String authToken, String groupId, MessageSender sender) async {
  final logger = new Logger('TheHundred');
  final client = new TheHundredClient(authToken, groupId);
  List<Game> oldGames = await client.getAllGames();
  const period = const Duration(minutes: 15);
  new Timer.periodic(period, (_) async {
    logger.info('Checking...');
    final newGames = await client.getAllGames();
    newGames.where((game) => !oldGames.contains(game)).forEach((game) {
      logger.info('New game: $game');
      sender({
        'text':
            ':vanguard:  <${game.url}|New game> by ${game.creator} on ${game.platformLabel}: ${game.title}  :vanguard:',
        'unfurl_media': 'false',
        'unfurl_links': 'false'
      }, logger);
    });
    final now = new TZDateTime.now(client.location);
    newGames.forEach((game) {
      final timeToGo = game.startDate.difference(now);
      if (Duration.ZERO <= timeToGo && timeToGo <= period) {
        sender({
          'text':
              ':vanguard:  <${game.url}|${game.title}> by ${game.creator} on ${game.platformLabel} is about to start  :vanguard:',
          'unfurl_media': 'false',
          'unfurl_links': 'false'
        }, logger);
      }
    });
    oldGames = newGames;
  });
}
