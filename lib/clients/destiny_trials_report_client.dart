// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';

import 'package:logging/logging.dart';

import '../utils/json.dart' as json;

/// Client for the destinytrialsreport.com REST API.
class DestinyTrialsReportClient {
  /// Returns the number of flawless Trials run for the given user.
  Future<int> getLighthouseTripCount(String destinyId) async {
    final url = 'https://api.destinytrialsreport.com/player/$destinyId';
    final data = await json.get(url, new Logger('DestinyTrialsReportClient'));
    if (data == null || data.isEmpty) {
      return 0;
    }
    final flawlessData = data[0]['flawless'];
    if (flawlessData == null || flawlessData.isEmpty) {
      return 0;
    }
    return flawlessData['years']
        .values
        .fold(0, (value, year) => value + year['count']);
  }

  /// Returns a URL to the given player's Trials profile.
  String getProfileUrl(String gamertag, bool onXbox) {
    final platform = onXbox ? 'xb' : 'ps';
    return 'https://my.trials.report/$platform/$gamertag';
  }
}
