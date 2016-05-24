// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart' as shelf;

import 'slack_command_handler.dart';
import 'slack_format.dart';

/// Looks up active Twitch streams.
class TwitchHandler extends SlackCommandHandler {
  final _log = new Logger('TwitchHandler');

  final List<String> _streamers;

  TwitchHandler(this._streamers);

  @override
  Future<shelf.Response> handle(shelf.Request request) async {
    final url =
        'https://api.twitch.tv/kraken/streams?channel=${_streamers.join(",")}';
    final json = JSON.decode(await http.read(url));
    final Iterable<String> users =
        json['streams'].map((stream) => stream['channel']['name']);
    _log.info('${users.length} streaming');
    if (users.isEmpty) {
      final text = 'No active stream';
      return createAttachmentResponse(
          {'color': '#ff0000', 'text': text, 'fallback': text});
    } else {
      const link = 'https://www.twitch.tv';
      _log.info(users.join(", "));
      final names = users.toList();
      names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      final content = names.map((name) => '<$link/$name|$name>').join('\n');
      return createTextResponse('```$content```');
    }
  }
}
