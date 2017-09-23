FROM google/dart:1.23

WORKDIR /app

ADD pubspec.yaml /app
RUN pub get

ADD . /app
RUN pub get --offline

EXPOSE 9999
CMD pub run bin/server.dart
