// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart' as shelf;

import '../context_params.dart' as param;
import '../slack_command_handler.dart';
import '../slack_format.dart';

/// Handles Slack message buttons.
class ActionsHandler extends SlackCommandHandler {
  final _log = new Logger('ActionsHandler');

  final String _verificationToken;

  ActionsHandler(this._verificationToken);

  @override
  Future<shelf.Response> handle(shelf.Request request) async {
    final params = request.context;
    final body = await request.readAsString();
    _log.info('Body: $body');
    final String payload = params[param.SLACK_PAYLOAD];
    _log.info('Payload: $payload');
    if (payload != null) {
      final content = Uri.splitQueryString(Uri.decodeFull(payload));
      _log.info('Content: $content');
    }
    return createTextResponse('Oki doki', private: true);
  }
}
