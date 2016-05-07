// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_route/shelf_route.dart';

import 'context_params.dart' as param;
import 'slack_format.dart';

const _STALLING_MESSAGES = const [
  'The Cryptarchs are on it...',
  'Contacting Destiny servers...',
  'Hold on a second, yesssssss?',
];

const _RESPONSE_TIMEOUT = const Duration(seconds: 3);

/// Base class for command handlers.
///
/// Takes care of SSL check queries.
abstract class SlackCommandHandler extends Routeable {
  final _log = new Logger('SlackCommandHandler');

  @override
  createRoutes(Router router) {
    router.get('/', _handleSslCheck);
    router.post('/', _handleRequest);
  }

  shelf.Response _handleSslCheck(shelf.Request request) {
    if (request.url.queryParameters['ssl_check'] == '1') {
      _log.info('SSL check');
      return new shelf.Response.ok('All systems clear!');
    }
    return new shelf.Response.notFound('Not sure what you are looking for...');
  }

  Future<shelf.Response> _handleRequest(shelf.Request request) async {
    final params = request.context;
    if (!params[param.USE_DELAYED_RESPONSES]) {
      return handle(request);
    }
    final completer = new Completer();
    handle(request).then((response) {
      if (!completer.isCompleted) {
        completer.complete(response);
      } else {
        // A reply to the request was already sent, so dial back using the
        // response URL instead.
        _forwardToUrl(params[param.SLACK_RESPONSE_URL], response);
      }
    });
    new Future.delayed(_RESPONSE_TIMEOUT, () {
      if (!completer.isCompleted) {
        // No result was returned, send a canned reply to prevent a timeout.
        completer.complete(_createStallingResponse());
      }
    });
    return completer.future;
  }

  shelf.Response _createStallingResponse() {
    _log.info('Stalling');
    return createTextResponse(
        _STALLING_MESSAGES[new Random().nextInt(_STALLING_MESSAGES.length)]);
  }

  _forwardToUrl(String url, shelf.Response response) async {
    _log.info('Forwarding answer');
    http.post(url,
        body: await response.readAsString(),
        headers: {'content-type': 'application/json'});
  }

  /// Called to process a command.
  Future<shelf.Response> handle(shelf.Request request);
}
