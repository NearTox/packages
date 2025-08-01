// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:go_router/go_router.dart';

@TypedGoRoute<GoodJson>(path: '/')
class GoodJson extends GoRouteData with _$GoodJson {
  const GoodJson({required this.id});

  final JsonExample id;
}

class JsonExample {
  const JsonExample({required this.id});

  factory JsonExample.fromJson(Map<String, dynamic> json) {
    return JsonExample(id: json['id'] as String);
  }

  final String id;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'id': id};
  }
}
