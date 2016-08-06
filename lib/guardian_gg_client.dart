// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';

import 'package:logging/logging.dart';

import 'utils/json.dart' as json;

/// Stats of a given guardian.
class Guardian implements Comparable {
  final String destinyId;
  final String name;
  final int elo;
  final num kd;

  const Guardian(this.destinyId, this.name, this.elo, this.kd);

  @override
  int compareTo(Guardian other) => elo - other.elo;

  @override
  String toString() => '$name[$elo, $kd]';
}

/// Client for guardian.gg REST API.
class GuardianGgClient {
  /// Returns stats for the given player and their most recent fireteam members.
  Future<List<Guardian>> getTrialsStats(String destinyId) async {
    final url = 'https://api.guardian.gg/fireteam/14/$destinyId';
    final data = await json.get(url, new Logger('GuardianGgClient'));
    if (data == null) {
      return [];
    }
    return data.map((Map guardian) {
      final destinyId = guardian['membershipId'];
      final name = guardian['name'];
      final elo = guardian['elo'].round();
      final deaths = guardian['deaths'];
      final kd = num.parse(
          (deaths > 0 ? (guardian['kills'] / deaths) : 0).toStringAsFixed(2));
      return new Guardian(destinyId, name, elo, kd);
    }).toList()..sort();
  }
}
