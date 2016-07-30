// Copyright (c) 2016 P.Y. Laligand

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';

import '../lib/clients/slack_client.dart';

/// Verifies that the Slack API calls work.
/// Expects one argument: the path to a JSON file containing the following data:
/// - auth_token: token to talk to the API;
/// - channel: name/id of a channel where to exercise tests;
/// - user: handle/id of a user.
main(List<String> args) async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
    print('${rec.level.name}: ${rec.time}: ${rec.loggerName}: ${rec.message}');
  });

  if (args.isEmpty) {
    print('Expected one argument!');
    exit(314);
  }
  final Map params = JSON.decode(new File(args[0]).readAsStringSync());

  final client = new SlackClient(params['auth_token']);
  await _runTest(
      'sendMessage',
      () async =>
          client.sendMessage('Sanity test :jarjar:', params['channel']));
  await _runTest('getUserTimezone',
      () async => (await client.getUserTimezone(params['user'])) != null);
}

_runTest(String name, Future<bool> test()) async {
  print('>> $name');
  if (!(await test())) {
    exit(314);
  }
  print('<< $name');
}
