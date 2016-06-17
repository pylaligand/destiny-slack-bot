// Copyright (c) 2016 P.Y. Laligand

import 'dart:convert';

import 'package:http/http.dart' as http;

const _BASE_URL = 'https://api.twitch.tv/kraken/streams?channel=';

/// Checks the status of a list of given Twitch streamers.
class TwitchScanner {
  final String _queryUrl;
  final List<Streamer> _liveStreamers = [];

  TwitchScanner(List<String> streamers)
      : _queryUrl = '$_BASE_URL${streamers.join(",")}';

  /// The list of online streamers.
  List<Streamer> get liveStreamers => new List.from(_liveStreamers);

  /// Updates the status of the tracked streamers.
  update() async {
    final json = JSON.decode(await http.read(_queryUrl));
    _liveStreamers.clear();
    json['streams']
        .map((stream) => new Streamer(
            stream['channel']['name'],
            stream['channel']['display_name'],
            stream['channel']['game'],
            stream['channel']['status']))
        .forEach(_liveStreamers.add);
  }
}

/// Represents a Twitch streamer.
class Streamer {
  /// The channel id.
  final String id;

  /// The streamer's display name.
  final String name;

  /// The game played.
  final String game;

  /// The channel's status.
  final String status;

  Streamer(this.id, this.name, this.game, this.status);

  @override
  String toString() => id;

  @override
  bool operator ==(Object other) => other is Streamer && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
