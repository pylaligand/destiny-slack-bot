// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';

import 'package:postgresql/postgresql.dart' as pg;

/// Vends connections to the Postgres database.
class PostgresClient {
  final String _db;

  PostgresClient(this._db);

  Future<pg.Connection> connect() async {
    return pg.connect(_db);
  }
}
