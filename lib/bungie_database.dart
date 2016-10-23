// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';

import 'package:bungie_client/bungie_types.dart';
import 'package:logging/logging.dart';
import 'package:postgresql/postgresql.dart' as pg;

export 'package:bungie_client/bungie_types.dart';

/// Schemas of the various tables in the database.
class BgDb {
  static const TABLE_GRIMOIRE = 'grimoire';
  static const GRIMOIRE_ID = 'id';
  static const GRIMOIRE_TITLE = 'title';
  static const GRIMOIRE_CONTENT = 'content';

  static const TABLE_WEAPONS = 'weapons';
  static const WEAPONS_ID = 'id';
  static const WEAPONS_NAME = 'name';
  static const WEAPONS_TYPE = 'type';
  static const WEAPONS_CATEGORY = 'category';
  static const WEAPONS_RARITY = 'rarity';

  static const TABLE_ARMOR = 'armor';
  static const ARMOR_ID = 'id';
  static const ARMOR_NAME = 'name';
  static const ARMOR_CLASS = 'class';
  static const ARMOR_TYPE = 'type';
  static const ARMOR_RARITY = 'rarity';

  static const TABLE_ACTIVITY = 'activity';
  static const ACTIVITY_ID = 'id';
  static const ACTIVITY_TYPE = 'type';
  static const ACTIVITY_NAME = 'name';

  static const TABLE_ACTIVITY_TYPE = 'activity_type';
  static const ACTIVITY_TYPE_ID = 'id';
  static const ACTIVITY_TYPE_NAME = 'name';
}

/// Queries a database of Destiny data.
class BungieDatabase {
  final _log = new Logger('BungieDatabase');

  /// URL of the supporting Postgres database.
  final String _db;

  /// The active connection to the database.
  pg.Connection _connection;

  BungieDatabase(this._db);

  /// Initializes the database connection.
  connect() async {
    _checkConnectionStatus(false);
    _connection = await pg.connect(_db);
    _log.info('Database connection open');
  }

  /// Closes the database connection.
  close() {
    if (_connection != null) {
      _connection.close();
      _connection = null;
      _log.info('Database connection closed');
    }
  }

  _checkConnectionStatus(bool connected) {
    if ((_connection != null) != connected) {
      throw 'Wrong connection state, expected connected: $connected';
    }
  }

  /// Returns the number of grimoire cards in the database.
  Future<int> getGrimoireCardCount() async {
    _checkConnectionStatus(true);
    return (await _connection
            .query('SELECT COUNT(*) FROM ${BgDb.TABLE_GRIMOIRE}')
            .first)
        .count;
  }

  /// Returns the grimoire card at the given [index].
  Future<GrimoireCard> getGrimoireCard(int index) async {
    _checkConnectionStatus(true);
    final row = await _connection
        .query('SELECT * FROM ${BgDb.TABLE_GRIMOIRE} LIMIT 1 OFFSET $index')
        .first;
    final columns = row.toMap();
    return new GrimoireCard(new ItemId(columns[BgDb.GRIMOIRE_ID]),
        columns[BgDb.GRIMOIRE_TITLE], columns[BgDb.GRIMOIRE_CONTENT]);
  }

  /// Fetches the weapons with the given [ids].
  Stream<Weapon> getWeapons(List<ItemId> ids) {
    _checkConnectionStatus(true);
    final whereClause =
        ids.map((id) => '${BgDb.WEAPONS_ID} = ${id.hash}').join(' OR ');
    return _connection
        .query('SELECT * FROM ${BgDb.TABLE_WEAPONS} WHERE $whereClause')
        .map((pg.Row row) {
      final columns = row.toMap();
      return new Weapon(
          new ItemId(columns[BgDb.WEAPONS_ID]),
          columns[BgDb.WEAPONS_NAME],
          WeaponType.values[columns[BgDb.WEAPONS_TYPE]],
          WeaponCategory.values[columns[BgDb.WEAPONS_CATEGORY]],
          Rarity.values[columns[BgDb.WEAPONS_RARITY]]);
    });
  }

  /// Fetches the weapon with the given [id];
  Future<Weapon> getWeapon(ItemId id) {
    return getWeapons([id]).first;
  }

  /// Fetches the armor pieces with the given [ids].
  Stream<Armor> getArmorPieces(List<ItemId> ids) {
    _checkConnectionStatus(true);
    final whereClause =
        ids.map((id) => '${BgDb.ARMOR_ID} = ${id.hash}').join(' OR ');
    return _connection
        .query('SELECT * FROM ${BgDb.TABLE_ARMOR} WHERE $whereClause')
        .map((pg.Row row) {
      final columns = row.toMap();
      return new Armor(
          new ItemId(columns[BgDb.ARMOR_ID]),
          columns[BgDb.ARMOR_NAME],
          Class.values[columns[BgDb.ARMOR_CLASS]],
          ArmorType.values[columns[BgDb.ARMOR_TYPE]],
          Rarity.values[columns[BgDb.ARMOR_RARITY]]);
    });
  }

  /// Fetches the armor piece with the given [id].
  Future<Armor> getArmorPiece(ItemId id) async {
    return getArmorPieces([id]).first;
  }

  /// Fetches an activity from the given [reference].
  Future<Activity> getActivity(ActivityReference reference) async {
    _checkConnectionStatus(true);
    final baseActivity = (await _connection
            .query(
                'SELECT * FROM ${BgDb.TABLE_ACTIVITY} WHERE ${BgDb.ACTIVITY_ID} = ${reference.id}')
            .first)
        .toMap();

    getOverride() async {
      if (reference.typeId == 0) {
        return null;
      }
      final columns = (await _connection
              .query(
                  'SELECT * FROM ${BgDb.TABLE_ACTIVITY_TYPE} WHERE ${BgDb.ACTIVITY_TYPE_ID} = ${reference.typeId}')
              .first)
          .toMap();
      return columns[BgDb.ACTIVITY_TYPE_NAME];
    }

    final typeOverride = await getOverride();
    return new Activity(
        new ItemId(baseActivity[BgDb.ACTIVITY_ID]),
        typeOverride ?? baseActivity[BgDb.ACTIVITY_TYPE],
        baseActivity[BgDb.ACTIVITY_NAME]);
  }
}
