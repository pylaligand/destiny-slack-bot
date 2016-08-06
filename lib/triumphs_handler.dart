// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';

import 'package:bungie_client/bungie_client.dart';
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart' as shelf;

import 'context_params.dart' as param;
import 'slack_command_handler.dart';
import 'slack_format.dart';
import 'utils/players.dart' as players;

const _OPTION_HELP = 'help';

/// Displays Moments of Triumph completion.
class TriumphsHandler extends SlackCommandHandler {
  final _log = new Logger('TriumphsHandler');

  @override
  Future<shelf.Response> handle(shelf.Request request) async {
    final params = request.context;
    final BungieClient client = params[param.BUNGIE_CLIENT];
    final String userName = params[param.SLACK_USERNAME];
    final text = params[param.SLACK_TEXT];
    if (text == _OPTION_HELP) {
      _log.info('@$userName needs help');
      return createTextResponse(
          'Looks up a given player\'s completion on Moments of Triumph',
          private: true);
    }

    _log.info('@$userName looking up "$text"');
    final player = await players.lookUp(client, userName, text);
    final gamertag = player.gamertag;
    if (!player.wasFound) {
      _log.warning('Could not identify gamertag "$gamertag".');
      return createTextResponse('Unable to identify "gamertag"', private: true);
    }
    final id = player.id;
    _log.info('Found id $id for $gamertag');

    final progress = await client.getTriumphsProgress(id);
    if (progress != null) {
      _log.info('Progress is $progress%');
      return createTextResponse(
          '$gamertag has completed *$progress%* of <https://www.bungie.net/en/Profile/Triumphs/${id.type}/${id.token}|Moments of Triumph>',
          expandLinks: false);
    } else {
      _log.warning('Could not find progress...');
      return createTextResponse('Could not find progress for $gamertag',
          private: true);
    }
  }
}
