// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart' as shelf;

import 'bungie_database.dart';
import 'context_params.dart' as param;
import 'slack_command_handler.dart';
import 'slack_format.dart';

/// Display a random grimoire card.
class CardHandler extends SlackCommandHandler {
  final _log = new Logger('CardHandler');

  @override
  Future<shelf.Response> handle(shelf.Request request) async {
    final params = request.context;
    final BungieDatabase database = params[param.BUNGIE_DATABASE];
    await database.connect();
    final count = await database.getGrimoireCardCount();
    final index = new Random().nextInt(count);
    final card = await database.getGrimoireCard(index);
    final String title = _unescape(card.title);
    final String text = _unescape(card.content);
    final url = 'http://destiny-grimoire.info/#Card-${card.id.hash}';
    _log.info('Selecting card $index/$count, id is ${card.id}');
    return createAttachmentResponse(
        {'title': title, 'title_link': url, 'text': text, 'fallback': title});
  }

  static String _unescape(String string) {
    return string
        .replaceAll('<br/>', '\n')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', '\'');
  }
}
