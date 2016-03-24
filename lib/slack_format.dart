// Copyright (c) 2016 P.Y. Laligand

import 'dart:convert';

import 'package:shelf/shelf.dart' as shelf;

/// Creates a response object with Slack's expected format.
shelf.Response createResponse(String content, {bool private: false}) {
  final json = new Map();
  if (!private) {
    json['response_type'] = 'in_channel';
  }
  json['text'] = content;
  final body = JSON.encode(json);
  final headers = {'content-type': 'application/json'};
  return new shelf.Response.ok(body, headers: headers);
}
