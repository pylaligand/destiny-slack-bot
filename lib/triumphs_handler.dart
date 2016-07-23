// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart' as shelf;

import 'bungie_client.dart';
import 'context_params.dart' as param;
import 'slack_command_handler.dart';
import 'slack_format.dart';

const _OPTION_HELP = 'help';

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
    final String gamertag = _getGamertag(userName, text);
    _log.info('@$userName looking up "$gamertag"');
    lookUp() async {
      final directId = await client.getDestinyId(gamertag);
      if (directId != null) {
        return directId;
      }
      if (!gamertag.contains('_')) {
        return null;
      }
      final alteredGamertag = gamertag.replaceAll('_', ' ');
      _log.info('Trying alternate gamertag "$alteredGamertag"');
      return await client.getDestinyId(alteredGamertag);
    }
    final id = await lookUp();
    if (id == null) {
      _log.warning('Could not identify gamertag.');
      return createTextResponse('Unable to identify "$gamertag"',
          private: true);
    }
    _log.info('Found id: $id');
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

  /// Returns the gamertag to look for based on the request parameters.
  static String _getGamertag(String userName, String text) {
    if (text == null || text.isEmpty) {
      return userName;
    }
    if (text[0] == '@') {
      return text.substring(1);
    }
    return text;
  }
}
