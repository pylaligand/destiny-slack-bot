// Copyright (c) 2016 P.Y. Laligand

import 'package:shelf/shelf.dart' as shelf;

import 'bungie_client.dart';

/// Attaches an actionable BungieClient to incoming requests.
class BungieMiddleWare {
  static shelf.Middleware get(String apiKey) => (shelf.Handler handler) {
        return (shelf.Request request) {
          return handler(request.change(
              context: {'bungie_client': new BungieClient(apiKey)}));
        };
      };
}
