// Copyright (c) 2016 P.Y. Laligand

import 'dart:convert';

import 'package:bungie_client/bungie_client.dart';
import 'package:mockito/mockito.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:test/test.dart';

import '../lib/bungie_database.dart';
import '../lib/slack_command_handler.dart';

dynamic getResponse(
    SlackCommandHandler handler, Map<String, dynamic> context) async {
  final request = new shelf.Request(
      'POST', Uri.parse('http://something.com/path'),
      context: context);
  final response = await handler.handle(request);
  expect(response.statusCode, equals(200));
  return JSON.decode(await response.readAsString());
}

class MockBungieClient extends Mock implements BungieClient {}

class MockBungieDatabase extends Mock implements BungieDatabase {}
