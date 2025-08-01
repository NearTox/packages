// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// Autogenerated from Pigeon (v25.5.0), do not edit directly.
// See also: https://pub.dev/packages/pigeon
// ignore_for_file: public_member_api_docs, non_constant_identifier_names, avoid_as, unused_import, unnecessary_parenthesis, unnecessary_import, no_leading_underscores_for_local_identifiers
// ignore_for_file: avoid_relative_lib_imports
import 'dart:async';
import 'dart:typed_data' show Float64List, Int32List, Int64List, Uint8List;
import 'package:flutter/foundation.dart' show ReadBuffer, WriteBuffer;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:file_selector_macos/src/messages.g.dart';

class _PigeonCodec extends StandardMessageCodec {
  const _PigeonCodec();
  @override
  void writeValue(WriteBuffer buffer, Object? value) {
    if (value is int) {
      buffer.putUint8(4);
      buffer.putInt64(value);
    } else if (value is AllowedTypes) {
      buffer.putUint8(129);
      writeValue(buffer, value.encode());
    } else if (value is SavePanelOptions) {
      buffer.putUint8(130);
      writeValue(buffer, value.encode());
    } else if (value is OpenPanelOptions) {
      buffer.putUint8(131);
      writeValue(buffer, value.encode());
    } else {
      super.writeValue(buffer, value);
    }
  }

  @override
  Object? readValueOfType(int type, ReadBuffer buffer) {
    switch (type) {
      case 129:
        return AllowedTypes.decode(readValue(buffer)!);
      case 130:
        return SavePanelOptions.decode(readValue(buffer)!);
      case 131:
        return OpenPanelOptions.decode(readValue(buffer)!);
      default:
        return super.readValueOfType(type, buffer);
    }
  }
}

abstract class TestFileSelectorApi {
  static TestDefaultBinaryMessengerBinding? get _testBinaryMessengerBinding =>
      TestDefaultBinaryMessengerBinding.instance;
  static const MessageCodec<Object?> pigeonChannelCodec = _PigeonCodec();

  /// Shows an open panel with the given [options], returning the list of
  /// selected paths.
  ///
  /// An empty list corresponds to a cancelled selection.
  Future<List<String>> displayOpenPanel(OpenPanelOptions options);

  /// Shows a save panel with the given [options], returning the selected path.
  ///
  /// A null return corresponds to a cancelled save.
  Future<String?> displaySavePanel(SavePanelOptions options);

  static void setUp(
    TestFileSelectorApi? api, {
    BinaryMessenger? binaryMessenger,
    String messageChannelSuffix = '',
  }) {
    messageChannelSuffix =
        messageChannelSuffix.isNotEmpty ? '.$messageChannelSuffix' : '';
    {
      final BasicMessageChannel<
          Object?> pigeonVar_channel = BasicMessageChannel<
              Object?>(
          'dev.flutter.pigeon.file_selector_macos.FileSelectorApi.displayOpenPanel$messageChannelSuffix',
          pigeonChannelCodec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        _testBinaryMessengerBinding!.defaultBinaryMessenger
            .setMockDecodedMessageHandler<Object?>(pigeonVar_channel, null);
      } else {
        _testBinaryMessengerBinding!.defaultBinaryMessenger
            .setMockDecodedMessageHandler<Object?>(pigeonVar_channel,
                (Object? message) async {
          assert(message != null,
              'Argument for dev.flutter.pigeon.file_selector_macos.FileSelectorApi.displayOpenPanel was null.');
          final List<Object?> args = (message as List<Object?>?)!;
          final OpenPanelOptions? arg_options = (args[0] as OpenPanelOptions?);
          assert(arg_options != null,
              'Argument for dev.flutter.pigeon.file_selector_macos.FileSelectorApi.displayOpenPanel was null, expected non-null OpenPanelOptions.');
          try {
            final List<String> output =
                await api.displayOpenPanel(arg_options!);
            return <Object?>[output];
          } on PlatformException catch (e) {
            return wrapResponse(error: e);
          } catch (e) {
            return wrapResponse(
                error: PlatformException(code: 'error', message: e.toString()));
          }
        });
      }
    }
    {
      final BasicMessageChannel<
          Object?> pigeonVar_channel = BasicMessageChannel<
              Object?>(
          'dev.flutter.pigeon.file_selector_macos.FileSelectorApi.displaySavePanel$messageChannelSuffix',
          pigeonChannelCodec,
          binaryMessenger: binaryMessenger);
      if (api == null) {
        _testBinaryMessengerBinding!.defaultBinaryMessenger
            .setMockDecodedMessageHandler<Object?>(pigeonVar_channel, null);
      } else {
        _testBinaryMessengerBinding!.defaultBinaryMessenger
            .setMockDecodedMessageHandler<Object?>(pigeonVar_channel,
                (Object? message) async {
          assert(message != null,
              'Argument for dev.flutter.pigeon.file_selector_macos.FileSelectorApi.displaySavePanel was null.');
          final List<Object?> args = (message as List<Object?>?)!;
          final SavePanelOptions? arg_options = (args[0] as SavePanelOptions?);
          assert(arg_options != null,
              'Argument for dev.flutter.pigeon.file_selector_macos.FileSelectorApi.displaySavePanel was null, expected non-null SavePanelOptions.');
          try {
            final String? output = await api.displaySavePanel(arg_options!);
            return <Object?>[output];
          } on PlatformException catch (e) {
            return wrapResponse(error: e);
          } catch (e) {
            return wrapResponse(
                error: PlatformException(code: 'error', message: e.toString()));
          }
        });
      }
    }
  }
}
