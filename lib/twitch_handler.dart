// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:math' as math;

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart' as shelf;

import 'context_params.dart' as param;
import 'slack_command_handler.dart';
import 'slack_format.dart';
import 'twitch_scanner.dart';

const _OPTION_HELP = 'help';

/// Looks up active Twitch streams.
class TwitchHandler extends SlackCommandHandler {
  final _log = new Logger('TwitchHandler');

  final TwitchScanner _scanner;

  TwitchHandler(String clientId, List<String> streamers)
      : _scanner = new TwitchScanner(clientId, streamers);

  @override
  Future<shelf.Response> handle(shelf.Request request) async {
    final params = request.context;
    if (params[param.SLACK_TEXT] == _OPTION_HELP) {
      _log.info('@${params[param.SLACK_USERNAME]} needs help');
      return createTextResponse(
          'List which clan superstars are currently streaming'
          ' (the list is hardcoded)',
          private: true);
    }
    await _scanner.update();
    final users = _scanner.liveStreamers;
    _log.info('${users.length} streaming');
    if (users.isEmpty) {
      final text = 'No active stream';
      return createAttachmentResponse(
          {'color': '#ff0000', 'text': text, 'fallback': text});
    } else {
      const link = 'https://www.twitch.tv';
      _log.info(users.map((user) => user.id).join(', '));
      users
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      final maxNameWidth =
          users.map((user) => user.name.length).reduce(math.max);
      final content = users.map((user) {
        final nameBlanks = maxNameWidth - user.name.length;
        return '<$link/${user.id}|${user.name}>${''.padRight(nameBlanks)}'
            '   ${user.status}';
      }).join('\n');
      return createTextResponse('```$content```');
    }
  }
}
