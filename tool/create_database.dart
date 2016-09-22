// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:postgresql/postgresql.dart' as pg;
import 'package:sqlite/sqlite.dart' as lite;

import '../lib/bungie_database.dart';

const _FLAG_LITE_DB = 'sqlite_db_file';
const _FLAG_PG_DB = 'postgres_uri';

/// Creates a table containing all the Grimoire cards.
Future<int> _createGrimoireDatabase(
    lite.Database liteDb, pg.Connection pgDb) async {
  const tableName = BgDb.TABLE_GRIMOIRE;
  print('Populating $tableName...');

  final Stream<GrimoireCard> cardStream = liteDb
      .query('SELECT json FROM DestinyGrimoireCardDefinition')
      .transform(new StreamTransformer<lite.Row, GrimoireCard>.fromHandlers(
          handleData: (lite.Row row, EventSink<GrimoireCard> sink) {
    final json = JSON.decode(row['json']);
    sink.add(new GrimoireCard(
        json['cardId'], json['cardName'], json['cardDescription']));
  }));

  await pgDb.execute('DROP TABLE IF EXISTS $tableName');
  await pgDb.execute('CREATE TABLE $tableName ('
      '${BgDb.GRIMOIRE_ID} BIGINT, '
      '${BgDb.GRIMOIRE_TITLE} TEXT, '
      '${BgDb.GRIMOIRE_CONTENT} TEXT)');
  int count = 0;
  await for (final GrimoireCard card in cardStream) {
    count += await pgDb.execute('INSERT INTO $tableName VALUES ('
        '${card.id}, '
        '\$\$${card.title}\$\$, '
        '\$\$${card.content}\$\$)');
  }
  print('Added $count entries to $tableName.');
  return count;
}

/// Creates a table containing all weapons.
Future<int> _createWeaponsDatabase(
    lite.Database liteDb, pg.Connection pgDb) async {
  final tableName = BgDb.TABLE_WEAPONS;
  print('Populating $tableName...');

  final Stream<Weapon> weaponStream = liteDb
      .query('SELECT json FROM DestinyInventoryItemDefinition')
      .transform(new StreamTransformer<lite.Row, Weapon>.fromHandlers(
          handleData: (lite.Row row, EventSink<Weapon> sink) {
    final json = JSON.decode(row['json']);
    final List<int> categories = json['itemCategoryHashes'];
    if (categories != null && categories.contains(1 /* weapon category */)) {
      final id = json['itemHash'];
      final name = json['itemName'];
      final type = WEAPON_TYPE_MAPPINGS[json['itemSubType']];
      final category = getWeaponCategory(categories);
      final rarity = RARITY_MAPPINGS[json['tierType']];
      sink.add(new Weapon(id, name, type, category, rarity));
    }
  })).where((Weapon weapon) =>
          weapon.name != null &&
          weapon.type != null &&
          weapon.name != 'Reforge Weapon');

  await pgDb.execute('DROP TABLE IF EXISTS $tableName');
  await pgDb.execute('CREATE TABLE $tableName ('
      '${BgDb.WEAPONS_ID} BIGINT, '
      '${BgDb.WEAPONS_NAME} TEXT, '
      '${BgDb.WEAPONS_TYPE} INT, '
      '${BgDb.WEAPONS_CATEGORY} INT, '
      '${BgDb.WEAPONS_RARITY} INT)');
  int count = 0;
  await for (final Weapon weapon in weaponStream) {
    count += await pgDb.execute('INSERT INTO $tableName VALUES ('
        '${weapon.id}, '
        '\$\$${weapon.name}\$\$, '
        '${weapon.type.index}, '
        '${weapon.category.index}, '
        '${weapon.rarity.index})');
  }
  print('Added $count entries to $tableName.');
  return count;
}

/// Creates a table containing all armor pieces.
Future<int> _createArmorDatabase(
    lite.Database liteDb, pg.Connection pgDb) async {
  final tableName = BgDb.TABLE_ARMOR;
  print('Populating $tableName...');

  final Stream<Armor> armorStream = liteDb
      .query('SELECT json FROM DestinyInventoryItemDefinition')
      .transform(new StreamTransformer<lite.Row, Armor>.fromHandlers(
          handleData: (lite.Row row, EventSink<Armor> sink) {
    final json = JSON.decode(row['json']);
    final List<int> categories = json['itemCategoryHashes'];
    if (categories != null && categories.contains(20 /* armor category */)) {
      final id = json['itemHash'];
      final name = json['itemName'];
      final clazz = CLASS_MAPPINGS[json['classType']];
      final type = getArmorTypeFromCategories(categories);
      final rarity = RARITY_MAPPINGS[json['tierType']];
      sink.add(new Armor(id, name, clazz, type, rarity));
    }
  })).where((Armor armor) =>
          armor.name != null && armor.clazz != null && armor.type != null);

  await pgDb.execute('DROP TABLE IF EXISTS $tableName');
  await pgDb.execute('CREATE TABLE $tableName ('
      '${BgDb.ARMOR_ID} BIGINT, '
      '${BgDb.ARMOR_NAME} TEXT, '
      '${BgDb.ARMOR_CLASS} INT, '
      '${BgDb.ARMOR_TYPE} INT, '
      '${BgDb.ARMOR_RARITY} INT)');
  int count = 0;
  await for (final armor in armorStream) {
    count += await pgDb.execute('INSERT INTO $tableName VALUES ('
        '${armor.id}, '
        '\$\$${armor.name}\$\$, '
        '${armor.clazz.index}, '
        '${armor.type.index}, '
        '${armor.rarity.index})');
  }
  print('Added $count entries to $tableName.');
  return count;
}

/// Creates a table containing activity definitions.
Future<int> _createActivityDatabase(
    lite.Database liteDb, pg.Connection pgDb) async {
  final tableName = BgDb.TABLE_ACTIVITY;
  print('Populating $tableName...');

  // Get the map of activity types.
  final types = <int, String>{};
  await liteDb
      .query('SELECT json FROM DestinyActivityTypeDefinition')
      .forEach((lite.Row row) {
    final json = JSON.decode(row['json']);
    final hash = json['activityTypeHash'];
    final name = json['activityTypeName'];
    types[hash] = name;
  });

  final Stream<Activity> activityStream = liteDb
      .query('SELECT json FROM DestinyActivityDefinition')
      .transform(new StreamTransformer<lite.Row, Activity>.fromHandlers(
          handleData: (lite.Row row, EventSink<Activity> sink) {
    final json = JSON.decode(row['json']);
    final hash = json['activityHash'];
    final type = types[json['activityTypeHash']];
    final name = json['activityName'];
    sink.add(new Activity(hash, type, name));
  }));

  await pgDb.execute('DROP TABLE IF EXISTS $tableName');
  await pgDb.execute('CREATE TABLE $tableName ('
      '${BgDb.ACTIVITY_ID} BIGINT, '
      '${BgDb.ACTIVITY_TYPE} TEXT, '
      '${BgDb.ACTIVITY_NAME} TEXT)');
  int count = 0;
  await for (final Activity activity in activityStream) {
    count += await pgDb.execute('INSERT INTO $tableName VALUES ('
        '${activity.id}, '
        '\$\$${activity.type}\$\$, '
        '\$\$${activity.name}\$\$)');
  }
  print('Added $count entries to $tableName.');
  return count;
}

/// Creates a table containing activity type definitions.
Future<int> _createActivityTypeDatabase(
    lite.Database liteDb, pg.Connection pgDb) async {
  final tableName = BgDb.TABLE_ACTIVITY_TYPE;
  print('Populating $tableName...');

  final Stream<List> typeStream = liteDb
      .query('SELECT json FROM DestinyActivityTypeDefinition')
      .transform(new StreamTransformer<lite.Row, List>.fromHandlers(
          handleData: (lite.Row row, EventSink<List> sink) {
    final json = JSON.decode(row['json']);
    final hash = json['activityTypeHash'];
    final name = json['activityTypeName'];
    sink.add([hash, name]);
  }));

  await pgDb.execute('DROP TABLE IF EXISTS $tableName');
  await pgDb.execute('CREATE TABLE $tableName ('
      '${BgDb.ACTIVITY_TYPE_ID} BIGINT, '
      '${BgDb.ACTIVITY_TYPE_NAME} TEXT)');
  int count = 0;
  await for (final List type in typeStream) {
    count += await pgDb.execute('INSERT INTO $tableName VALUES ('
        '${type[0]}, '
        '\$\$${type[1]}\$\$)');
  }
  print('Added $count entries to $tableName.');
  return count;
}

/// Utility to list item buckets.
//ignore: unused_element
_inspectBuckets(lite.Database liteDb) async {
  await liteDb
      .query('SELECT json FROM DestinyInventoryBucketDefinition')
      .forEach((row) {
    final json = JSON.decode(row['json']);
    print(
        '${json['bucketHash'].toString().padRight(15)} -- ${json['bucketName']}');
  });
}

//// Utility to list inventory items.
//ignore: unused_element
_inspectItems(lite.Database liteDb) async {
  await liteDb
      .query('SELECT json FROM DestinyInventoryItemDefinition')
      .forEach((row) {
    final json = JSON.decode(row['json']);
    final tier = json['tierType'];
    final name = json['tierTypeName'];
    print('$tier --> $name');
    if (tier == 0) {
      print(json['itemName']);
    }
  });
}

/// Utility to list item categories.
//ignore: unused_element
_inspectCategories(lite.Database liteDb) async {
  await liteDb
      .query('SELECT json FROM DestinyItemCategoryDefinition')
      .forEach((row) {
    final json = JSON.decode(row['json']);
    final tier = json['itemCategoryHash'];
    final name = json['title'];
    print('$tier --> $name');
  });
}

/// Utility to list activities.
//ignore: unused_element
_inspectActivities(lite.Database liteDb) async {
  await liteDb
      .query('SELECT json FROM DestinyActivityDefinition')
      .forEach((row) {
    final json = JSON.decode(row['json']);
    final name = json['activityName'];
    print(name);
  });
}

/// Utility to list activity types.
//ignore: unused_element
_inspectActivityTypes(lite.Database liteDb) async {
  await liteDb
      .query('SELECT json FROM DestinyActivityTypeDefinition')
      .forEach((row) {
    final json = JSON.decode(row['json']);
    final name = json['activityTypeName'];
    print(name);
  });
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
    final entryCount = await _createGrimoireDatabase(liteDb, pgDb) +
        await _createWeaponsDatabase(liteDb, pgDb) +
        await _createArmorDatabase(liteDb, pgDb) +
        await _createActivityDatabase(liteDb, pgDb) +
        await _createActivityTypeDatabase(liteDb, pgDb);
    print('Inserted $entryCount entries.');
  } finally {
    liteDb.close();
    pgDb.close();
  }
}
