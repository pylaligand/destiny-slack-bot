// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';

import 'package:logging/logging.dart';

import '../utils/json.dart' as json;

/// The result of a call to [getHoursWellEnjoyed].
class HourLookupResult {
  final int hours;
  final String url;

  const HourLookupResult(this.hours, this.url);

  const HourLookupResult.invalid() : this(-1, null);

  bool get isValid => hours > 0 && url != null;
}

/// Client for the wastedondestiny.com API.
class WastedOnDestinyClient {
  /// Returns the number of hours the given player spent on Destiny, or -1 if
  /// that number could not be found.
  Future<HourLookupResult> getHoursWellEnjoyed(
      String gamertag, bool onXbox) async {
    final uri = new Uri.https('www.wastedondestiny.com', 'api',
        {'user': gamertag, 'console': (onXbox ? 1 : 2).toString()});
    final data =
        await json.get(uri.toString(), new Logger('WastedOnDestinyClient'));
    if (data == null || data['Info']['Status'] == 'Error') {
      return const HourLookupResult.invalid();
    }
    final num seconds = data['Response']['totalTimePlayed'] +
        data['Response']['totalTimeWasted'];
    return new HourLookupResult(
        (seconds / Duration.SECONDS_PER_HOUR).round(),
        new Uri.https('www.wastedondestiny.com',
                '${onXbox ? 'xbox' : 'playstation'}/$gamertag')
            .toString());
  }
}
