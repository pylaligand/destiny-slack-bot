// Copyright (c) 2016 P.Y. Laligand

import 'package:shelf/shelf.dart' as shelf;

import 'clients/slack_client.dart';
import 'context_params.dart' as param;

/// Makes an interface to Slack available to handlers.
class SlackClientMiddleware {
  static shelf.Middleware get(String authToken) => (shelf.Handler handler) {
        return (shelf.Request request) async {
          return handler(request.change(
              context: {param.SLACK_CLIENT: new SlackClient(authToken)}));
        };
      };
}
