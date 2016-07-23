// Copyright (c) 2016 P.Y. Laligand

import 'package:bungie_client/bungie_client.dart';
import 'package:shelf/shelf.dart' as shelf;

import 'bungie_database.dart';
import 'context_params.dart' as param;

/// Attaches an actionable BungieClient to incoming requests.
class BungieMiddleWare {
  static shelf.Middleware get(String apiKey, String db) =>
      (shelf.Handler handler) {
        return (shelf.Request request) {
          return handler(request.change(context: {
            param.BUNGIE_CLIENT: new BungieClient(apiKey),
            param.BUNGIE_DATABASE: new BungieDatabase(db)
          }));
        };
      };
}
