// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:postgresql/postgresql.dart' as pg;
import 'package:sqlite/sqlite.dart' as lite;

const _FLAG_LITE_DB = 'sqlite_db_file';
const _FLAG_PG_DB = 'postgres_uri';

/// Creates a table containing all the Grimoire cards.
_createGrimoireCardDatabase(lite.Database liteDb, pg.Connection pgDb) async {
  const tableName = 'grimoireCards';
  print('Populating $tableName');

  await pgDb.execute('DROP TABLE IF EXISTS $tableName');
  await pgDb
      .execute('CREATE TABLE $tableName (id INT, title TEXT, content TEXT)');

  final entries = [];
  liteDb.execute('SELECT json FROM DestinyGrimoireCardDefinition',
      callback: (lite.Row row) {
    final json = JSON.decode(row['json']);
    entries.add({
      'id': row['cardId'],
      'title': json['cardName'],
      'content': json['cardDescription']
    });
    return false;
  });

  int count = 0;
  await Future.forEach(entries, (entry) async {
    count += await pgDb.execute(
        'INSERT INTO $tableName VALUES (@id, @title, @content)', entry);
  });
  print('Added $count entries to $tableName.');
}

/// Creates a table containing a subset of all the inventory items.
_createItemsDatabase(lite.Database liteDb, pg.Connection pgDb) async {
  const tableName = 'inventoryItems';
  print('Populating $tableName');

  const targetCategories = const [
    1, // Weapon
    20, // Armor
  ];

  await pgDb.execute('DROP TABLE IF EXISTS $tableName');
  await pgDb
      .execute('CREATE TABLE $tableName (id BIGINT, name TEXT, type TEXT)');

  final entries = [];
  liteDb.execute('SELECT json FROM DestinyInventoryItemDefinition',
      callback: (lite.Row row) {
    final json = JSON.decode(row['json']);
    final List<int> categories = json['itemCategoryHashes'];
    if (categories.any((category) => targetCategories.contains(category))) {
      entries.add({
        'id': json['itemHash'],
        'name': json['itemName'],
        'type': json['itemTypeName']
      });
    }
  });
  int count = 0;
  await Future.forEach(entries, (entry) async {
    count += await pgDb.execute(
        'INSERT INTO $tableName VALUES (@id, @name, @type)', entry);
  });
  print('Added $count entries to $tableName.');
}

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
    await _createGrimoireCardDatabase(liteDb, pgDb);
    await _createItemsDatabase(liteDb, pgDb);
  } finally {
    liteDb.close();
    pgDb.close();
  }
}
