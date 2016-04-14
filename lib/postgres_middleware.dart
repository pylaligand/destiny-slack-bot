// Copyright (c) 2016 P.Y. Laligand

import 'package:shelf/shelf.dart' as shelf;

import 'postgres_client.dart';

class PostgresMiddleware {
  static shelf.Middleware get(String db) => (shelf.Handler handler) {
        return (shelf.Request request) async {
          return handler(request
              .change(context: {'postgres_client': new PostgresClient(db)}));
        };
      };
}
