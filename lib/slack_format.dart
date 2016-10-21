// Copyright (c) 2016 P.Y. Laligand

import 'dart:convert';

import 'package:shelf/shelf.dart' as shelf;

const ATTACHMENT_COLORS = const ['#4285f4', '#f4b400', '#0f9d58', '#db4437'];

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
shelf.Response createAttachmentsResponse(List<Map> attachments,
    {bool private: false, bool replace: false}) {
  final json = new Map();
  if (!private) {
    json['response_type'] = 'in_channel';
  }
  json['attachments'] = attachments;
  if (replace) {
    json['replace_original'] = true;
  }
  final body = JSON.encode(json);
  final headers = {'content-type': 'application/json'};
  return new shelf.Response.ok(body, headers: headers);
}

/// Creates a response object with an attachment.
shelf.Response createAttachmentResponse(Map attachment,
    {bool private: false, bool replace: false}) {
  return createAttachmentsResponse([attachment],
      private: private, replace: replace);
}

/// Creates a response object with an error message.
shelf.Response createErrorAttachment(String text) {
  return createAttachmentResponse(
      {'color': '#ff0000', 'text': text, 'fallback': text});
}
