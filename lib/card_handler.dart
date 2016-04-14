// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:postgresql/postgresql.dart' as pg;
import 'package:shelf/shelf.dart' as shelf;

import 'postgres_client.dart';
import 'slack_command_handler.dart';
import 'slack_format.dart';

/// Display a random grimoire card.
class CardHandler extends SlackCommandHandler {
  final log = new Logger('CardHandler');

  @override
  Future<shelf.Response> handle(shelf.Request request) async {
    final PostgresClient client = request.context['postgres_client'];
    final pg.Connection database = await client.connect();
    try {
      final countRow =
          await database.query('SELECT COUNT(*) FROM grimoirecards').first;
      final count = countRow.count;
      final index = new Random().nextInt(count);
      final cardRow = await database
          .query('SELECT * FROM grimoirecards LIMIT 1 OFFSET $index')
          .first;
      final String title = _unescape(cardRow.title);
      final String text = _unescape(cardRow.content);
      final url = 'http://destiny-grimoire.info/#Card-${cardRow.id}';
      log.info('Selecting card $index/$count, id is ${cardRow.id}');
      return createAttachmentResponse(
          {'title': title, 'title_link': url, 'text': text, 'fallback': title});
    } finally {
      database.close();
    }
  }

  static String _unescape(String string) {
    return string
        .replaceAll('<br/>', '\n')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', '\'');
  }
}
