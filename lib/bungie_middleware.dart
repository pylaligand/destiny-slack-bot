// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';

import 'package:shelf/shelf.dart' as shelf;

import 'bungie_client.dart';
import 'bungie_database.dart';
import 'context_params.dart' as param;

/// Attaches an actionable BungieClient to incoming requests.
class BungieMiddleWare {
  static shelf.Middleware get(String apiKey, String db) =>
      (shelf.Handler handler) {
        return (shelf.Request request) {
          final BungieDatabase database = new BungieDatabase(db);
          bool shouldCloseDatabase = true;
          try {
            final result = handler(request.change(context: {
              param.BUNGIE_CLIENT: new BungieClient(apiKey),
              param.BUNGIE_DATABASE: database
            }));
            if (result is Future) {
              shouldCloseDatabase = false;
              result.whenComplete(() => database.close());
            }
            return result;
          } finally {
            if (shouldCloseDatabase) {
              database.close();
            }
          }
        };
      };
}
