// Copyright (c) 2016 P.Y. Laligand

import 'dart:convert';

import 'package:shelf/shelf.dart' as shelf;

/// Creates a response object with simple text content.
shelf.Response createTextResponse(String content, {bool private: false}) {
  final json = new Map();
  if (!private) {
    json['response_type'] = 'in_channel';
  }
  json['text'] = content;
  final body = JSON.encode(json);
  final headers = {'content-type': 'application/json'};
  return new shelf.Response.ok(body, headers: headers);
}

/// Creates a response object with an attachment.
shelf.Response createAttachmentResponse(Map<String, String> attachment) {
  final json = new Map();
  json['response_type'] = 'in_channel';
  json['attachments'] = [attachment];
  final body = JSON.encode(json);
  final headers = {'content-type': 'application/json'};
  return new shelf.Response.ok(body, headers: headers);
}
