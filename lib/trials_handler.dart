// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_route/shelf_route.dart';

import 'bungie_client.dart';
import 'guardian_gg_client.dart';

/// Handles request for Trials of Osiris information.
class TrialsHandler extends Routeable {
  @override
  createRoutes(Router router) {
    router.post('trials', _handle);
  }

  Future<shelf.Response> _handle(shelf.Request request) async {
    final params = request.context;
    final String gamertag = params['text'];
    print('@${params['user_name']} looking up "$gamertag"');

    // Look up the Destiny ID.
    final BungieClient client = params['bungie_client'];
    final destinyParams = await _getDestinyId(client, gamertag);
    if (destinyParams == null) {
      print('Player not found');
      return new shelf.Response.ok(
          'Cannot find player "$gamertag" on XBL or PSN...');
    }
    final destinyId = destinyParams[0];
    final onXbox = destinyParams[1];
    print('Found id for "$gamertag": $destinyId (Xbox: ${onXbox})');

    // Get stats from guardian.gg.
    final guardians = await new GuardianGgClient().getTrialsStats(destinyId);
    if (guardians.isEmpty) {
      print('No Trials data found');
      return new shelf.Response.ok(
          'Could not find Trials data for "$gamertag"');
    }
    final trialsGuardians = <TrialsGuardian>[];
    await Future.forEach(guardians, (guardian) async {
      final subclass =
          (await _getLastUsedSubclass(client, guardian.destinyId, onXbox)) ??
              'Unknown';
      trialsGuardians.add(new TrialsGuardian(guardian, subclass));
    });
    trialsGuardians.forEach((g) => print(g));

    final json = new Map();
    json['response_type'] = 'in_channel';
    json['text'] = _formatReport(trialsGuardians);
    final body = JSON.encode(json);
    final headers = {'content-type': 'application/json'};
    return new shelf.Response.ok(body, headers: headers);
  }

  /// Attempts to fetch the Destiny id of the player identified by [gamertag].
  ///
  /// If [onXbox] is specified, this method will look for the player on the
  /// appropriate platform, return the Destiny id is found or null otherwise.
  ///
  /// if [onXbox] is not specified, this method will look for the player on both
  /// platforms. If the player is found, the return value will be a pair
  /// consisting of the Destiny id and a bool representing the platform similar
  /// to [onXbox]. Otherwise null is returned.
  static dynamic _getDestinyId(BungieClient client, String gamertag,
      {bool onXbox}) async {
    if (onXbox != null) {
      return await client.getDestinyId(gamertag, onXbox);
    }
    final xboxId = await client.getDestinyId(gamertag, true /* Xbox */);
    if (xboxId != null) {
      return [xboxId, true];
    }
    final psId = await client.getDestinyId(gamertag, false /* Playstation */);
    if (psId != null) {
      return [psId, false];
    }
    return null;
  }

  /// Returns the subclass last used by the given player, or null if it could
  /// not be determined.
  static Future<String> _getLastUsedSubclass(
      BungieClient client, String destinyId, bool onXbox) async {
    final character = await client.getLastPlayedCharacter(destinyId, onXbox);
    if (character == null) {
      print('Unable to locate character for $destinyId');
      return null;
    }
    final subclass = await client.getEquippedSubclass(
        destinyId, onXbox, character.id, character.clazz);
    if (subclass == null) {
      print(
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
