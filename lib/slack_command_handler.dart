// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_route/shelf_route.dart';

/// Base class for command handlers.
///
/// Takes care of SSL check queries.
abstract class SlackCommandHandler extends Routeable {
  final _log = new Logger('SlackCommandHandler');

  @override
  createRoutes(Router router) {
    router.get('/', _handleSslCheck);
    router.post('/', handle);
  }

  shelf.Response _handleSslCheck(shelf.Request request) {
    if (request.url.queryParameters['ssl_check'] == '1') {
      _log.info('SSL check');
      return new shelf.Response.ok('All systems clear!');
    }
    return new shelf.Response.notFound('Not sure what you are looking for...');
  }

  /// Called to process a command.
  Future<shelf.Response> handle(shelf.Request request);
}
