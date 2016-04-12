// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:postgresql/postgresql.dart' as pg;
import 'package:sqlite/sqlite.dart' as lite;

const _FLAG_LITE_DB = 'sqlite_db_file';
const _FLAG_PG_DB = 'postgres_uri';

main(List<String> args) async {
  final parser = new ArgParser()
    ..addOption(_FLAG_LITE_DB, help: 'Source SQLite database file')
    ..addOption(_FLAG_PG_DB, help: 'Destination PostgreSQL database');
  final params = parser.parse(args);
  if (!params.options.contains(_FLAG_LITE_DB) ||
      !params.options.contains(_FLAG_PG_DB)) {
    print(parser.usage);
    exit(1);
  }

  final liteDb = new lite.Database(params[_FLAG_LITE_DB]);
  final pg.Connection pgDb = await pg.connect(params[_FLAG_PG_DB]);

  try {
    await pgDb.execute('drop table grimoirecards');
    await pgDb.execute(
        'create table grimoirecards (id int, title text, content text)');

    final entries = [];
    liteDb.execute('SELECT * from DestinyGrimoireCardDefinition',
        callback: (lite.Row row) {
      final json = JSON.decode(row['json']);
      entries.add({
        'id': row['id'],
        'title': json['cardName'],
        'content': json['cardDescription']
      });
      return false;
    });

    int count = 0;
    await Future.forEach(entries, (entry) async {
      count += await pgDb.execute(
          'insert into grimoirecards values (@id, @title, @content)', entry);
    });
    print('Added $count entries.');
  } finally {
    liteDb.close();
    pgDb.close();
  }
}
