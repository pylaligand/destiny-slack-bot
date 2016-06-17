// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:math' as math;

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart' as shelf;

import 'slack_command_handler.dart';
import 'slack_format.dart';
import 'twitch_scanner.dart';

/// Looks up active Twitch streams.
class TwitchHandler extends SlackCommandHandler {
  final _log = new Logger('TwitchHandler');

  final TwitchScanner _scanner;

  TwitchHandler(List<String> streamers)
      : _scanner = new TwitchScanner(streamers);

  @override
  Future<shelf.Response> handle(shelf.Request request) async {
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
