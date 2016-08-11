// Copyright (c) 2016 P.Y. Laligand

import 'dart:convert';

import 'package:shelf/shelf.dart' as shelf;

/// Creates a response object with simple text content.
shelf.Response createTextResponse(String content,
    {bool private: false, bool expandLinks: true}) {
  final json = new Map();
  if (!private) {
    json['response_type'] = 'in_channel';
  }
  json['unfurl_media'] = expandLinks;
  json['unfurl_links'] = expandLinks;
  json['text'] = content;
  final body = JSON.encode(json);
  final headers = {'content-type': 'application/json'};
  return new shelf.Response.ok(body, headers: headers);
}

/// Creates a response object with some attachments.
shelf.Response createAttachmentsResponse(List<Map> attachments) {
  final json = new Map();
  json['response_type'] = 'in_channel';
  json['attachments'] = attachments;
  final body = JSON.encode(json);
  final headers = {'content-type': 'application/json'};
  return new shelf.Response.ok(body, headers: headers);
}

/// Creates a response object with an attachment.
shelf.Response createAttachmentResponse(Map attachment) {
  return createAttachmentsResponse([attachment]);
}

/// Creates a response object with an error message.
shelf.Response createErrorAttachment(String text) {
  return createAttachmentResponse(
      {'color': '#ff0000', 'text': text, 'fallback': text});
}
