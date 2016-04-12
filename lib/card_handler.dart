// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:math';

import 'package:logging/logging.dart';
import 'package:postgresql/postgresql.dart' as pg;
import 'package:shelf/shelf.dart' as shelf;

import 'slack_command_handler.dart';
import 'slack_format.dart';

/// Display a random grimoire card.
class CardHandler extends SlackCommandHandler {
  final log = new Logger('CardHandler');
  final String _db;

  CardHandler(this._db);

  @override
  Future<shelf.Response> handle(shelf.Request request) async {
    final pg.Connection database = await pg.connect(_db);
    try {
      final countRow =
          await database.query('SELECT COUNT(*) FROM grimoirecards').first;
      final count = countRow.count;
      final index = new Random().nextInt(count);
      final cardRow = await database
          .query('SELECT * from grimoirecards LIMIT 1 OFFSET $index')
          .first;
      final String title = cardRow.title;
      final String text = cardRow.content
          .replaceAll('<br/>', '\n')
          .replaceAll('&quot;', '"')
          .replaceAll('&#39;', '\'');
      final url = 'http://destiny-grimoire.info/#Card-${cardRow.id}';
      log.info('Selecting card $index/$count, id is ${cardRow.id}');
      return createAttachmentResponse(
          {'title': title, 'title_link': url, 'text': text, 'fallback': title});
    } finally {
      database.close();
    }
  }
}
