#!/bin/bash
# Copyright (c) 2016 P.Y. Laligand

set -e

dart_files="bin/*.dart lib/*.dart test/*.dart tool/*.dart"

dartanalyzer --fatal-warnings --fatal-hints --fatal-lints $dart_files
pub run test

unformatted_files=`dartfmt -n $dart_files`
if [[ -n "$unformatted_files" ]]; then
  echo "Some files need formatting:"
  echo $unformatted_files
  exit 314
fi
