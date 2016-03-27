// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:math' as math;

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_route/shelf_route.dart';

import 'bungie_client.dart';
import 'guardian_gg_client.dart';
import 'slack_format.dart';

/// Handles request for Trials of Osiris information.
class TrialsHandler extends Routeable {
  final log = new Logger('TrialsHandler');

  @override
  createRoutes(Router router) {
    router.post('/', _handle);
  }

  Future<shelf.Response> _handle(shelf.Request request) async {
    final params = request.context;
    final String gamertag = params['text'];
    log.info('@${params['user_name']} looking up "$gamertag"');

    // Look up the Destiny ID.
    final BungieClient client = params['bungie_client'];
    final destinyId = await _getDestinyId(client, gamertag);
    if (destinyId == null) {
      log.warning('Player not found');
      return new shelf.Response.ok(
          'Cannot find player "$gamertag" on XBL or PSN...');
    }
    final onXbox = destinyId.onXbox;
    log.info('Found id for "$gamertag": $destinyId (Xbox: ${onXbox})');

    // Get stats from guardian.gg.
    final guardians =
        await new GuardianGgClient().getTrialsStats(destinyId.token);
    if (guardians.isEmpty) {
      log.warning('No Trials data found');
      return new shelf.Response.ok(
          'Could not find Trials data for "$gamertag"');
    }
    final trialsGuardians = <TrialsGuardian>[];
    await Future.forEach(guardians, (guardian) async {
      final id = new DestinyId(onXbox, guardian.destinyId);
      final subclass = (await _getLastUsedSubclass(client, id)) ?? 'Unknown';
      trialsGuardians.add(new TrialsGuardian(guardian, subclass));
    });
    trialsGuardians.forEach((g) => log.info(g));

    return createTextResponse(_formatReport(trialsGuardians));
  }

  /// Attempts to fetch the Destiny id of the player identified by [gamertag].
  ///
  /// If [onXbox] is specified, this method will look for the player on the
  /// appropriate platform, return the Destiny id is found or null otherwise.
  ///
  /// if [onXbox] is not specified, this method will look for the player on both
  /// platforms. If the player is found, the return value will be a pair
  /// consisting of the Destiny id and a boolean representing the platform similar
  /// to [onXbox]. Otherwise null is returned.
  static Future<DestinyId> _getDestinyId(BungieClient client, String gamertag,
      {bool onXbox}) async {
    return onXbox != null
        ? await client.getDestinyId(gamertag, onXbox)
        : (await client.getDestinyId(gamertag, true /* Xbox */) ??
            await client.getDestinyId(gamertag, false /* Playstation */));
  }

  /// Returns the subclass last used by the given player, or null if it could
  /// not be determined.
  Future<String> _getLastUsedSubclass(
      BungieClient client, DestinyId destinyId) async {
    final character = await client.getLastPlayedCharacter(destinyId);
    if (character == null) {
      log.warning('Unable to locate character for $destinyId');
      return null;
    }
    final subclass = await client.getEquippedSubclass(
        destinyId, character.id, character.clazz);
    if (subclass == null) {
      log.warning(
          'Unable to determine subclass for character ${character.id} of $destinyId');
      return null;
    }
    return subclass;
  }

  /// Returns the formatted guardian list for display in a bot message.
  static String _formatReport(List<TrialsGuardian> guardians) {
    final width =
        guardians.map((guardian) => guardian.name.length).reduce(math.max);
    // Note that the URL below specifies 'ps' but will automatically redirect if
    // the user is on Xbox.
    final list = guardians.map((g) {
      final blanks = width - g.name.length;
      return '<https://my.trials.report/ps/${g.name}|${g.name}>${''.padRight(blanks)}  ${g.elo.toString().padLeft(4)}  ${g.kd.toString().padRight(4, '0')}  ${g.subclass}';
    }).join('\n');
    return '```$list```';
  }
}

/// Representation of a player in ToO.
class TrialsGuardian extends Guardian {
  final String subclass;

  TrialsGuardian(Guardian guardian, this.subclass)
      : super(guardian.destinyId, guardian.name, guardian.elo, guardian.kd);

  @override
  String toString() {
    return '$name[$elo, $kd, $subclass]';
  }
}
