// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:math' as math;

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart' as shelf;

import 'bungie_client.dart';
import 'bungie_database.dart';
import 'bungie_types.dart';
import 'guardian_gg_client.dart';
import 'slack_command_handler.dart';
import 'slack_format.dart';

/// Handles requests for Trials of Osiris information.
class TrialsHandler extends SlackCommandHandler {
  final _log = new Logger('TrialsHandler');

  final GuardianGgClient _guardianGgClient;

  factory TrialsHandler() {
    return new TrialsHandler.withClient(new GuardianGgClient());
  }

  TrialsHandler.withClient(this._guardianGgClient);

  @override
  Future<shelf.Response> handle(shelf.Request request) async {
    final params = request.context;
    final String gamertag = params['text'];
    _log.info('@${params['user_name']} looking up "$gamertag"');

    // Look up the Destiny ID.
    final BungieClient client = params['bungie_client'];
    final destinyId = await client.getDestinyId(gamertag);
    if (destinyId == null) {
      _log.warning('Player not found');
      return createTextResponse(
          'Cannot find player "$gamertag" on XBL or PSN...',
          private: true);
    }
    final onXbox = destinyId.onXbox;
    _log.info('Found id for "$gamertag": $destinyId (Xbox: $onXbox)');

    // Get stats from guardian.gg.
    final guardians = await _guardianGgClient.getTrialsStats(destinyId.token);
    if (guardians.isEmpty) {
      _log.warning('No Trials data found');
      return createTextResponse('Could not find Trials data for "$gamertag"',
          private: true);
    }

    // Add inventory data.
    final BungieDatabase database = params['bungie_database'];
    await database.connect();
    final trialsGuardians = <_TrialsGuardian>[];
    await Future.forEach(guardians, (guardian) async {
      final id = new DestinyId(onXbox, guardian.destinyId);
      final inventory = (await _getLastInventory(client, id));
      final subclass = inventory?.subclass ?? 'Unknown';
      final weapons = inventory != null
          ? await database.getWeapons(inventory.weaponIds).toList()
          : [];
      final armors = inventory != null
          ? await database.getArmorPieces(inventory.armorIds).toList()
          : [];
      trialsGuardians.add(new _TrialsGuardian(
          guardian, subclass, weapons..sort(), armors..sort()));
    });
    trialsGuardians.forEach((g) => _log.info(g));

    return createTextResponse(_formatReport(trialsGuardians));
  }

  /// Returns the subclass last used by the given player, or null if it could
  /// not be determined.
  Future<Inventory> _getLastInventory(
      BungieClient client, DestinyId destinyId) async {
    final character = await client.getLastPlayedCharacter(destinyId);
    if (character == null) {
      _log.warning('Unable to locate character for $destinyId');
      return null;
    }
    final inventory = await client.getInventory(destinyId, character.id);
    if (inventory == null) {
      _log.warning(
          'Unable to determine subclass for character ${character.id} of $destinyId');
      return null;
    }
    return inventory;
  }

  /// Returns the formatted guardian list for display in a bot message.
  static String _formatReport(List<_TrialsGuardian> guardians) {
    const url = 'https://my.trials.report/ps';
    maxLength(Iterable<String> content) =>
        content.map((item) => item.length).reduce(math.max);
    final maxNameWidth = maxLength(guardians.map((guardian) => guardian.name));
    final maxSubclassWidth =
        maxLength(guardians.map((guardian) => guardian.subclass));
    final maxPrimaryWidth = maxLength(
        guardians.map((guardian) => _getWeaponLabel(guardian.primary)));
    final maxSpecialWidth = maxLength(
        guardians.map((guardian) => _getWeaponLabel(guardian.special)));
    final maxHeavyWidth =
        maxLength(guardians.map((guardian) => _getWeaponLabel(guardian.heavy)));
    // Note that the URL below specifies 'ps' but will automatically redirect if
    // the user is on Xbox.
    final list = guardians.map((g) {
      final nameBlanks = maxNameWidth - g.name.length;
      String result = '<$url/${g.name}|${g.name}>${''.padRight(nameBlanks)}'
          '  ${g.elo.toString().padLeft(4)}'
          '  ${g.kd.toString().padRight(4, '0')}'
          '  ${g.subclass.padRight(maxSubclassWidth)}'
          '  |'
          '  ${_getWeaponLabel(g.primary).padRight(maxPrimaryWidth)}'
          '  ${_getWeaponLabel(g.special).padRight(maxSpecialWidth)}'
          '  ${_getWeaponLabel(g.heavy).padRight(maxHeavyWidth)}';
      final exoticArmor = g.armors.firstWhere(
          (armor) => armor.rarity == Rarity.EXOTIC,
          orElse: () => null);
      if (exoticArmor != null) {
        result += '  |  ${exoticArmor.name}';
      }
      return result;
    }).join('\n');
    return '```$list```';
  }
}

const _UNKNOWN_WEAPON =
    const Weapon(const ItemId(-1), 'Unknown', WeaponType.AUTO, Rarity.COMMON);

/// Representation of a player in ToO.
class _TrialsGuardian extends Guardian {
  final String subclass;
  final List<Weapon> weapons;
  final List<Armor> armors;

  _TrialsGuardian(Guardian guardian, this.subclass, this.weapons, this.armors)
      : super(guardian.destinyId, guardian.name, guardian.elo, guardian.kd);

  Weapon get primary => weapons.firstWhere((weapon) => weapon.isPrimary,
      orElse: () => _UNKNOWN_WEAPON);

  Weapon get special => weapons.firstWhere((weapon) => weapon.isSpecial,
      orElse: () => _UNKNOWN_WEAPON);

  Weapon get heavy => weapons.firstWhere((weapon) => weapon.isHeavy,
      orElse: () => _UNKNOWN_WEAPON);

  @override
  String toString() {
    return '$name[$elo, $kd, $subclass]';
  }
}

/// Returns the display label for the given [weapon].
String _getWeaponLabel(Weapon weapon) {
  return weapon.rarity == Rarity.EXOTIC || weapon == _UNKNOWN_WEAPON
      ? weapon.name
      : getWeaponTypeNickname(weapon.type);
}
