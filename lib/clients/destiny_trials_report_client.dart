// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';

import 'package:logging/logging.dart';

import '../utils/json.dart' as json;

/// Client for the destinytrialsreport.com REST API.
class DestinyTrialsReportClient {
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
}
