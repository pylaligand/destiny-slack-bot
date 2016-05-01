// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';

import 'package:shelf/shelf.dart' as shelf;

import 'bungie_client.dart';
import 'bungie_database.dart';

/// Attaches an actionable BungieClient to incoming requests.
class BungieMiddleWare {
  static shelf.Middleware get(String apiKey, String db) =>
      (shelf.Handler handler) {
        return (shelf.Request request) {
          final BungieDatabase database = new BungieDatabase(db);
          bool shouldCloseDatabase = true;
          try {
            final result = handler(request.change(context: {
              'bungie_client': new BungieClient(apiKey),
              'bungie_database': database
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
