// Copyright (c) 2016 P.Y. Laligand

import 'package:shelf/shelf.dart' as shelf;

import 'context_params.dart' as param;
import 'the_hundred_client.dart';

/// Attaches an actionable [TheHundredClient] to incoming requests.
class TheHundredMiddleWare {
  static shelf.Middleware get(String authToken, String groupId) =>
      (shelf.Handler handler) {
        return (shelf.Request request) {
          return handler(request.change(context: {
            param.THE_HUNDRED_CLIENT: new TheHundredClient(authToken, groupId),
          }));
        };
      };
}
