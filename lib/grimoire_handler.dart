// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart' as shelf;

import 'bungie_client.dart';
import 'slack_command_handler.dart';
import 'slack_format.dart';

/// Fetches grimoire scores.
class GrimoireHandler extends SlackCommandHandler {
  final log = new Logger('GrimoireHandler');

  @override
  Future<shelf.Response> handle(shelf.Request request) async {
    final params = request.context;
    final BungieClient client = params['bungie_client'];
    final String userName = params['user_name'];
    final String gamertag = params['text'] ?? userName;

    log.info('@$userName looking up "$gamertag"');
    lookUp() async {
      final directId = await client.getDestinyId(gamertag);
      if (directId != null) {
        return directId;
      }
      if (!gamertag.contains('_')) {
        return null;
      }
      final alteredGamertag = gamertag.replaceAll('_', ' ');
      log.info('Trying alternate gamertag "$alteredGamertag"');
      return await client.getDestinyId(alteredGamertag);
    }
    final id = await lookUp();
    if (id == null) {
      log.warning('Could not identify gamertag.');
      return createTextResponse('Unable to identify "$gamertag"',
          private: true);
    }
    log.info('Found id: $id');

    int score = await client.getGrimoireScore(id);
    if (score != null) {
      log.info('Score is $score');
      return createTextResponse('$gamertag has a grimoire score of *$score*');
    } else {
      log.warning('Could not find score...');
      return createTextResponse('Could not find grimoire score for $gamertag',
          private: true);
    }
  }
}
