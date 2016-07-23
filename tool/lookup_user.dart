// Copyright (c) 2016 P.Y. Laligand

import 'dart:io';

import 'package:bungie_client/bungie_client.dart';
import 'package:args/args.dart';

const _FLAG_API_KEY = 'api-key';

main(List<String> args) async {
  final parser = new ArgParser()
    ..addSeparator('Non-flag text specifies a gamertag [required]')
    ..addOption(_FLAG_API_KEY, help: 'Bungie API token [required]');
  final params = parser.parse(args);
  if (!params.options.contains(_FLAG_API_KEY) || params.rest.isEmpty) {
    print(parser.usage);
    exit(314);
  }
  final gamertag = params.rest.join(' ');
  final client = new BungieClient(params[_FLAG_API_KEY]);
  final id = await client.getDestinyId(gamertag);
  if (id != null) {
    print('$gamertag --> ${id.token} (${id.onXbox ? 'XB' : 'PS'})');
  } else {
    print('$gamertag was not found');
  }
}
