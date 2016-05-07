// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart' as shelf;

import 'bungie_client.dart';
import 'bungie_database.dart';
import 'context_params.dart' as param;
import 'slack_command_handler.dart';
import 'slack_format.dart';

/// Handles requests for Xur inventory.
class XurHandler extends SlackCommandHandler {
  final _log = new Logger('XurHandler');

  @override
  Future<shelf.Response> handle(shelf.Request request) async {
    final params = request.context;
    final BungieClient client = params[param.BUNGIE_CLIENT];
    final BungieDatabase database = params[param.BUNGIE_DATABASE];
    await database.connect();
    final inventory = await client.getXurInventory();
    if (inventory == null || inventory.isEmpty) {
      _log.info('Xur is wandering...');
      return createTextResponse('Xur is not available at the moment...');
    }
    final items = (await Future.wait(inventory.map((XurExoticItem item) async =>
            item.isArmor
                ? (await database.getArmorPiece(item.id))?.name
                : (await database.getWeapon(item.id))?.name)))
        .where((item) => item != null)
        .toList();
    _log.info('Items:');
    items.forEach((item) => _log.info(' - $item'));
    return createTextResponse(_formatItems(items));
  }

  /// Returns the formatted list of items for display in a bot message.
  static _formatItems(List<String> items) {
    final list = items.join('\n');
    return '```$list```';
  }
}
