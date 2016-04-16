// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:postgresql/postgresql.dart' as pg;
import 'package:shelf/shelf.dart' as shelf;

import 'bungie_client.dart';
import 'postgres_client.dart';
import 'slack_command_handler.dart';
import 'slack_format.dart';

/// Handles requests for Xur inventory.
class XurHandler extends SlackCommandHandler {
  final _log = new Logger('XurHandler');

  @override
  Future<shelf.Response> handle(shelf.Request request) async {
    final params = request.context;
    final BungieClient client = params['bungie_client'];
    final PostgresClient dbClient = request.context['postgres_client'];
    final pg.Connection db = await dbClient.connect();
    final inventory = await client.getXurInventory();
    if (inventory == null || inventory.isEmpty) {
      _log.info('Xur is wandering...');
      return createTextResponse('Xur is not available at the moment...');
    }
    final items = (await Future.wait(inventory.map((id) async {
      List<pg.Row> rows = await db
          .query('SELECT * FROM inventoryItems WHERE id = $id')
          .toList();
      return rows.isEmpty ? null : rows[0];
    })))
        .toList();
    items.removeWhere((item) => item == null);
    _log.info('Items:');
    items.forEach((item) => _log.info(' - ${item.name} (${item.type})'));
    return createTextResponse(_formatItems(items));
  }

  /// Returns the formatted list of items for display in a bot message.
  static _formatItems(List<pg.Row> items) {
    final list = items.map((item) => item.name).join('\n');
    return '```$list```';
  }
}
