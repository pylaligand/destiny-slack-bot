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
    final destinyId = await client.getDestinyId(gamertag, true /* Xbox */) ??
        await client.getDestinyId(gamertag, false /* Playstation */);
    if (destinyId == null) {
      print('Player not found');
      return new shelf.Response.ok(
          'Cannot find player "$gamertag" on XBL or PSN...');
    }
    print('Found id for "$gamertag": $destinyId');

    // Get stats from guardian.gg.
    List<Guardian> guardians =
        await new GuardianGgClient().getTrialsStats(destinyId);
    if (guardians.isEmpty) {
      print('No Trials data found');
      return new shelf.Response.ok(
          'Could not find Trials data for "$gamertag"');
    }
    guardians.forEach((g) => print(g));

    final json = new Map();
    json['response_type'] = 'in_channel';
    json['text'] = _formatReport(guardians);
    final body = JSON.encode(json);
    final headers = {'content-type': 'application/json'};
    return new shelf.Response.ok(body, headers: headers);
  }

  /// Returns the formatted guardian list for display in a bot message.
  static String _formatReport(List<Guardian> guardians) {
    final width =
        guardians.map((guardian) => guardian.name.length).reduce(math.max);
    // Note that the URL below specifies 'ps' but will automatically redirect if
    // the user is on Xbox.
    final list = guardians.map((g) {
      final blanks = width - g.name.length;
      return '<https://my.trials.report/ps/${g.name}|${g.name}>${''.padRight(blanks)}  ${g.elo.toString().padLeft(4)}  ${g.kd}';
    }).join('\n');
    return '```$list```';
  }
}
