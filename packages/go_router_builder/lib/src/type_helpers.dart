// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:collection/collection.dart';
import 'package:source_gen/source_gen.dart';
import 'package:source_helper/source_helper.dart';

/// The name of the generated, private helper for converting [String] to [bool].
const String boolConverterHelperName = r'_$boolConverter';

/// The name of the generated, private helper for handling nullable value
/// conversion.
const String convertMapValueHelperName = r'_$convertMapValue';

/// The name of the generated, private helper for converting [Duration] to
/// [bool].
const String durationDecoderHelperName = r'_$durationConverter';

/// The name of the generated, private helper for converting [String] to [Enum].
const String enumExtensionHelperName = r'_$fromName';

/// The property/parameter name used to represent the `extra` data that may
/// be passed to a route.
const String extraFieldName = r'$extra';

/// The name of the generated, private getter for casting `this` (the mixin) to the class type.
const String selfFieldName = '_self';

/// Shared start of error message related to a likely code issue.
const String likelyIssueMessage = 'Should never get here! File an issue!';

/// The name of the generated, private helper for comparing iterables.
const String iterablesEqualHelperName = r'_$iterablesEqual';

/// type checker for CustomParameterCodec
const TypeChecker _customParameterChecker = TypeChecker.fromUrl(
    'package:go_router/src/misc/custom_parameter.dart#CustomParameterCodec');

const List<_TypeHelper> _helpers = <_TypeHelper>[
  _TypeHelperBigInt(),
  _TypeHelperBool(),
  _TypeHelperDateTime(),
  _TypeHelperDouble(),
  _TypeHelperEnum(),
  _TypeHelperInt(),
  _TypeHelperNum(),
  _TypeHelperString(),
  _TypeHelperUri(),
  _TypeHelperIterable(),
  _TypeHelperJson(),
];

extension on TypeChecker {
// get annotated function name only if is annotated on the Element list
  String? _getAnnotatedFunctionName(
      String functionName, DartType type, List<Element?> fieldElements) {
    final Iterable<DartObject> annotations = fieldElements.nonNulls.expand(
      (Element element) => annotationsOf(element, throwOnUnresolved: false),
    );
    return annotations._getFunctionName(functionName, type);
  }
}

extension on Iterable<DartObject> {
  // get annotated info only if have a compatible annotation
  DartObject? _getAnnotatedInfo(DartType type) {
    return firstWhereOrNull(
      (DartObject annotation) {
        final DartType? annotationType = annotation.type;
        if (annotationType is! ParameterizedType ||
            annotationType.typeArguments.isEmpty) {
          return true;
        }
        return annotationType.typeArguments.first
                .getDisplayString(withNullability: false) ==
            type.getDisplayString(withNullability: false);
      },
    );
  }

  // get annotated function name only if have a compatible annotation
  String? _getFunctionName(String functionName, DartType type) {
    return _getAnnotatedInfo(type)
        ?.getField(functionName)
        ?.toFunctionValue()
        ?.displayName;
  }
}

/// Returns the decoded [String] value for [element], if its type is supported.
///
/// Otherwise, throws an [InvalidGenerationSourceError].
String decodeParameter(
  ParameterElement element,
  Set<String> pathParameters,
  FieldElement? fieldElement,
) {
  if (element.isExtraField) {
    return 'state.${_stateValueAccess(element, pathParameters)}';
  }

  final DartType paramType = element.type;
  for (final _TypeHelper helper in _helpers) {
    if (helper._matchesType(paramType)) {
      final String? customDecoder = _customParameterChecker
          ._getAnnotatedFunctionName(
              'decode', paramType, <Element?>[fieldElement]);
      String decoded = helper._decode(element, pathParameters, customDecoder);
      if (element.isOptional && element.hasDefaultValue) {
        if (paramType.isNullableType) {
          throw NullableDefaultValueError(element);
        }
        decoded += ' ?? ${element.defaultValueCode!}';
      }
      if (helper is _TypeHelperString) {
        return _fieldWithEncoder(decoded, customDecoder);
      }
      return decoded;
    }
  }

  throw InvalidGenerationSourceError(
    'The parameter type '
    '`${withoutNullability(paramType.getDisplayString())}` is not supported.',
    element: element,
  );
}

/// Returns the encoded [String] value for [element], if its type is supported.
///
/// Otherwise, throws an [InvalidGenerationSourceError].
String encodeField(
    PropertyAccessorElement element, FieldElement? fieldElement) {
  for (final _TypeHelper helper in _helpers) {
    if (helper._matchesType(element.returnType)) {
      final String? encoder = _customParameterChecker._getAnnotatedFunctionName(
          'encode', element.returnType, <Element?>[fieldElement]);
      final String encoded = helper._encode(
        '$selfFieldName.${element.name}',
        element.returnType,
        encoder,
      );
      return encoded;
    }
  }

  throw InvalidGenerationSourceError(
    'The return type `${element.returnType}` is not supported.',
    element: element,
  );
}

/// Returns an AstNode type from a InterfaceElement.
T? getNodeDeclaration<T extends AstNode>(InterfaceElement element) {
  final AnalysisSession? session = element.session;
  if (session == null) {
    return null;
  }

  final ParsedLibraryResult parsedLibrary =
      session.getParsedLibraryByElement(element.library) as ParsedLibraryResult;
  final ElementDeclarationResult? declaration =
      parsedLibrary.getElementDeclaration(element);
  final AstNode? node = declaration?.node;

  return node is T ? node : null;
}

/// Returns the comparison of a parameter with its default value.
///
/// Otherwise, throws an [InvalidGenerationSourceError].
String compareField(ParameterElement param, String value1, String value2) {
  for (final _TypeHelper helper in _helpers) {
    if (helper._matchesType(param.type)) {
      return helper._compare(
          '$selfFieldName.${param.name}', param.defaultValueCode!);
    }
  }

  throw InvalidGenerationSourceError(
    'The type `${param.type}` is not supported.',
    element: param,
  );
}

/// Gets the name of the `const` map generated to help encode [Enum] types.
String enumMapName(InterfaceType type) => '_\$${type.element.name}EnumMap';

/// Gets the name of the `const` map generated to help encode [Json] types.
String jsonMapName(InterfaceType type) => type.element.name;

String _stateValueAccess(ParameterElement element, Set<String> pathParameters) {
  if (element.isExtraField) {
    // ignore: avoid_redundant_argument_values
    return 'extra as ${element.type.getDisplayString()}';
  }

  late String access;
  final String suffix =
      !element.type.isNullableType && !element.hasDefaultValue ? '!' : '';
  if (pathParameters.contains(element.name)) {
    access = 'pathParameters[${escapeDartString(element.name)}]$suffix';
  } else {
    access =
        'uri.queryParameters[${escapeDartString(element.name.kebab)}]$suffix';
  }

  return access;
}

/// Returns `true` if the type string ends with a nullability marker (`?` or `*`)
bool _isNullableType(String type) {
  return type.endsWith('?') || type.endsWith('*');
}

/// Returns the type string without a trailing nullability marker
String withoutNullability(String type) {
  return _isNullableType(type) ? type.substring(0, type.length - 1) : type;
}

String _fieldWithEncoder(String field, String? customEncoder) {
  return customEncoder != null ? '$customEncoder($field)' : field;
}

abstract class _TypeHelper {
  const _TypeHelper();

  /// Decodes the value from its string representation in the URL.
  String _decode(ParameterElement parameterElement, Set<String> pathParameters,
      String? customDecoder);

  /// Encodes the value from its string representation in the URL.
  String _encode(String fieldName, DartType type, String? customEncoder);

  bool _matchesType(DartType type);

  String _compare(String value1, String value2) => '$value1 != $value2';
}

class _TypeHelperBigInt extends _TypeHelperWithHelper {
  const _TypeHelperBigInt();

  @override
  String helperName(DartType paramType) {
    if (paramType.isNullableType) {
      return 'BigInt.tryParse';
    }
    return 'BigInt.parse';
  }

  @override
  String _encode(String fieldName, DartType type, String? customEncoder) =>
      _fieldWithEncoder(
          '$fieldName${type.ensureNotNull}.toString()', customEncoder);

  @override
  bool _matchesType(DartType type) =>
      const TypeChecker.fromRuntime(BigInt).isAssignableFromType(type);
}

class _TypeHelperBool extends _TypeHelperWithHelper {
  const _TypeHelperBool();

  @override
  String helperName(DartType paramType) => boolConverterHelperName;

  @override
  String _encode(String fieldName, DartType type, String? customEncoder) =>
      _fieldWithEncoder(
          '$fieldName${type.ensureNotNull}.toString()', customEncoder);

  @override
  bool _matchesType(DartType type) => type.isDartCoreBool;
}

class _TypeHelperDateTime extends _TypeHelperWithHelper {
  const _TypeHelperDateTime();

  @override
  String helperName(DartType paramType) {
    if (paramType.isNullableType) {
      return 'DateTime.tryParse';
    }
    return 'DateTime.parse';
  }

  @override
  String _encode(String fieldName, DartType type, String? customEncoder) =>
      _fieldWithEncoder(
          '$fieldName${type.ensureNotNull}.toString()', customEncoder);

  @override
  bool _matchesType(DartType type) =>
      const TypeChecker.fromRuntime(DateTime).isAssignableFromType(type);
}

class _TypeHelperDouble extends _TypeHelperWithHelper {
  const _TypeHelperDouble();

  @override
  String helperName(DartType paramType) {
    if (paramType.isNullableType) {
      return 'double.tryParse';
    }
    return 'double.parse';
  }

  @override
  String _encode(String fieldName, DartType type, String? customEncoder) =>
      _fieldWithEncoder(
          '$fieldName${type.ensureNotNull}.toString()', customEncoder);

  @override
  bool _matchesType(DartType type) => type.isDartCoreDouble;
}

class _TypeHelperEnum extends _TypeHelperWithHelper {
  const _TypeHelperEnum();

  @override
  String helperName(DartType paramType) =>
      '${enumMapName(paramType as InterfaceType)}.$enumExtensionHelperName';

  @override
  String _encode(String fieldName, DartType type, String? customEncoder) =>
      _fieldWithEncoder(
        '${enumMapName(type as InterfaceType)}[$fieldName${type.ensureNotNull}]',
        customEncoder,
      );

  @override
  bool _matchesType(DartType type) => type.isEnum;
}

class _TypeHelperInt extends _TypeHelperWithHelper {
  const _TypeHelperInt();

  @override
  String helperName(DartType paramType) {
    if (paramType.isNullableType) {
      return 'int.tryParse';
    }
    return 'int.parse';
  }

  @override
  String _encode(String fieldName, DartType type, String? customEncoder) =>
      _fieldWithEncoder(
          '$fieldName${type.ensureNotNull}.toString()', customEncoder);

  @override
  bool _matchesType(DartType type) => type.isDartCoreInt;
}

class _TypeHelperNum extends _TypeHelperWithHelper {
  const _TypeHelperNum();

  @override
  String helperName(DartType paramType) {
    if (paramType.isNullableType) {
      return 'num.tryParse';
    }
    return 'num.parse';
  }

  @override
  String _encode(String fieldName, DartType type, String? customEncoder) =>
      _fieldWithEncoder(
          '$fieldName${type.ensureNotNull}.toString()', customEncoder);

  @override
  bool _matchesType(DartType type) => type.isDartCoreNum;
}

class _TypeHelperString extends _TypeHelper {
  const _TypeHelperString();

  @override
  String _decode(ParameterElement parameterElement, Set<String> pathParameters,
          String? customDecoder) =>
      'state.${_stateValueAccess(parameterElement, pathParameters)}';

  @override
  String _encode(String fieldName, DartType type, String? customEncoder) =>
      _fieldWithEncoder(fieldName, customEncoder);

  @override
  bool _matchesType(DartType type) => type.isDartCoreString;
}

class _TypeHelperUri extends _TypeHelperWithHelper {
  const _TypeHelperUri();

  @override
  String helperName(DartType paramType) {
    if (paramType.isNullableType) {
      return 'Uri.tryParse';
    }
    return 'Uri.parse';
  }

  @override
  String _encode(String fieldName, DartType type, String? customEncoder) =>
      _fieldWithEncoder(
          '$fieldName${type.ensureNotNull}.toString()', customEncoder);

  @override
  bool _matchesType(DartType type) =>
      const TypeChecker.fromRuntime(Uri).isAssignableFromType(type);
}

class _TypeHelperIterable extends _TypeHelperWithHelper {
  const _TypeHelperIterable();

  @override
  String helperName(DartType paramType) => iterablesEqualHelperName;

  @override
  String _decode(
    ParameterElement parameterElement,
    Set<String> pathParameters,
    String? customDecoder,
  ) {
    if (parameterElement.type is ParameterizedType) {
      final DartType iterableType =
          (parameterElement.type as ParameterizedType).typeArguments.first;

      // get a type converter for values in iterable
      String entriesTypeDecoder = '(e) => e';
      String convertToNotNull = '';
      String formatIterableType = '';
      String asParameterType = ' as ${parameterElement.type}';

      if (parameterElement.hasDefaultValue) {
        asParameterType += '?';
      }

      for (final _TypeHelper helper in _helpers) {
        if (helper._matchesType(iterableType) &&
            helper is _TypeHelperWithHelper) {
          if (!iterableType.isNullableType) {
            if (parameterElement.type.isDartCoreList) {
              formatIterableType = '?.toList()';
            } else if (parameterElement.type.isDartCoreSet) {
              formatIterableType = '?.toSet()';
            }
            convertToNotNull =
                '.cast<$iterableType>()$formatIterableType$asParameterType';
          }
          entriesTypeDecoder = helper.helperName(iterableType);
          if (customDecoder != null) {
            entriesTypeDecoder =
                '(e) => $entriesTypeDecoder($customDecoder(e))';
          }
        }
      }

      // get correct type for iterable
      String iterableCaster = '';
      String fallBack = '';
      if (const TypeChecker.fromRuntime(List)
          .isAssignableFromType(parameterElement.type)) {
        iterableCaster += '?.toList()';
        if (!parameterElement.type.isNullableType &&
            !parameterElement.hasDefaultValue) {
          fallBack = '?? const []';
        }
      } else if (const TypeChecker.fromRuntime(Set)
          .isAssignableFromType(parameterElement.type)) {
        iterableCaster += '?.toSet()';
        if (!parameterElement.type.isNullableType &&
            !parameterElement.hasDefaultValue) {
          fallBack = '?? const {}';
        }
      }

      return '''
(state.uri.queryParametersAll[
        ${escapeDartString(parameterElement.name.kebab)}]
        ?.map($entriesTypeDecoder)$convertToNotNull)$iterableCaster$fallBack''';
    }
    return '''
state.uri.queryParametersAll[${escapeDartString(parameterElement.name.kebab)}]''';
  }

  @override
  String _encode(String fieldName, DartType type, String? customEncoder) {
    final String nullAwareAccess = type.isNullableType ? '?' : '';
    if (type is ParameterizedType) {
      final DartType iterableType = type.typeArguments.first;

      // get a type encoder for values in iterable
      String entriesTypeEncoder = '';
      for (final _TypeHelper helper in _helpers) {
        if (helper._matchesType(iterableType)) {
          entriesTypeEncoder = '''
$nullAwareAccess.map((e) => ${helper._encode('e', iterableType, customEncoder)}).toList()''';
        }
      }
      return '''
$fieldName$entriesTypeEncoder''';
    }

    return '''
$fieldName$nullAwareAccess.map((e) => e.toString()).toList()''';
  }

  @override
  bool _matchesType(DartType type) =>
      const TypeChecker.fromRuntime(Iterable).isAssignableFromType(type);

  @override
  String _compare(String value1, String value2) =>
      '!$iterablesEqualHelperName($value1, $value2)';
}

class _TypeHelperJson extends _TypeHelperWithHelper {
  const _TypeHelperJson();

  @override
  String helperName(DartType paramType) {
    return _helperNameN(paramType, 0);
  }

  @override
  String _encode(String fieldName, DartType type, String? customEncoder) =>
      _fieldWithEncoder('jsonEncode($fieldName${type.ensureNotNull}.toJson())',
          customEncoder);

  @override
  bool _matchesType(DartType type) {
    if (type is! InterfaceType) {
      return false;
    }

    final MethodElement? toJsonMethod =
        type.lookUpMethod2('toJson', type.element.library);
    if (toJsonMethod == null ||
        !toJsonMethod.isPublic ||
        toJsonMethod.parameters.isNotEmpty) {
      return false;
    }

    // test for template
    if (_isNestedTemplate(type)) {
      // check for deep compatibility
      return _matchesType(type.typeArguments.first);
    }

    final ConstructorElement? fromJsonMethod =
        type.element.getNamedConstructor('fromJson');

    if (fromJsonMethod == null ||
        !fromJsonMethod.isPublic ||
        fromJsonMethod.parameters.length != 1 ||
        fromJsonMethod.parameters.first.type
                .getDisplayString(withNullability: false) !=
            'Map<String, dynamic>') {
      throw InvalidGenerationSourceError(
        'The parameter type '
        '`${type.getDisplayString(withNullability: false)}` not have a supported fromJson definition.',
        element: type.element,
      );
    }

    return true;
  }

  String _helperNameN(DartType paramType, int index) {
    final String mainType = index == 0 ? 'String' : 'Object?';
    final String mainDecoder = index == 0
        ? 'jsonDecode(json$index) as Map<String, dynamic>'
        : 'json$index as Map<String, dynamic>';
    if (_isNestedTemplate(paramType as InterfaceType)) {
      return '''
($mainType json$index) {
  return ${jsonMapName(paramType)}.fromJson(
    $mainDecoder,
    ${_helperNameN(paramType.typeArguments.first, index + 1)},
  );
}''';
    }
    return '''
($mainType json$index) {
  return ${jsonMapName(paramType)}.fromJson($mainDecoder);
}''';
  }

  bool _isNestedTemplate(InterfaceType type) {
    // check if has fromJson constructor
    final ConstructorElement? fromJsonMethod =
        type.element.getNamedConstructor('fromJson');
    if (fromJsonMethod == null || !fromJsonMethod.isPublic) {
      return false;
    }

    if (type.typeArguments.length != 1) {
      return false;
    }

    // check if fromJson method receive two parameters
    final List<ParameterElement> parameters = fromJsonMethod.parameters;
    if (parameters.length != 2) {
      return false;
    }

    final ParameterElement firstParam = parameters[0];
    if (firstParam.type.getDisplayString(withNullability: false) !=
        'Map<String, dynamic>') {
      throw InvalidGenerationSourceError(
        'The parameter type '
        '`${type.getDisplayString(withNullability: false)}` not have a supported fromJson definition.',
        element: type.element,
      );
    }

    // Test for (T Function(Object? json)).
    final ParameterElement secondParam = parameters[1];
    if (secondParam.type is! FunctionType) {
      return false;
    }

    final FunctionType functionType = secondParam.type as FunctionType;
    if (functionType.parameters.length != 1 ||
        functionType.returnType.getDisplayString() !=
            type.element.typeParameters.first.getDisplayString() ||
        functionType.parameters[0].type.getDisplayString() != 'Object?') {
      throw InvalidGenerationSourceError(
        'The parameter type '
        '`${type.getDisplayString(withNullability: false)}` not have a supported fromJson definition.',
        element: type.element,
      );
    }

    return true;
  }
}

abstract class _TypeHelperWithHelper extends _TypeHelper {
  const _TypeHelperWithHelper();

  String helperName(DartType paramType);

  @override
  String _decode(
    ParameterElement parameterElement,
    Set<String> pathParameters,
    String? customDecoder,
  ) {
    final DartType paramType = parameterElement.type;
    final String parameterName = parameterElement.name;

    if (!pathParameters.contains(parameterName) &&
        (paramType.isNullableType || parameterElement.hasDefaultValue)) {
      return '$convertMapValueHelperName('
          '${escapeDartString(parameterName.kebab)}, '
          'state.uri.queryParameters, '
          '${helperName(paramType)})';
    }
    final String decode = _fieldWithEncoder(
        'state.${_stateValueAccess(parameterElement, pathParameters)} ${!parameterElement.isRequired ? " ?? '' " : ''}',
        customDecoder);
    final bool resultIsNonNull = this is! _TypeHelperJson;
    return '${helperName(paramType)}($decode)${resultIsNonNull ? '!' : ''}';
  }
}

/// Extension helpers on [DartType].
extension DartTypeExtension on DartType {
  /// Convenient helper for nullability checks.
  String get ensureNotNull => isNullableType ? '!' : '';
}

/// Extension helpers on [ParameterElement].
extension ParameterElementExtension on ParameterElement {
  /// Convenient helper on top of [isRequiredPositional] and [isRequiredNamed].
  bool get isRequired => isRequiredPositional || isRequiredNamed;

  /// Returns `true` if `this` has a name that matches [extraFieldName];
  bool get isExtraField => name == extraFieldName;
}

/// An error thrown when a default value is used with a nullable type.
class NullableDefaultValueError extends InvalidGenerationSourceError {
  /// An error thrown when a default value is used with a nullable type.
  NullableDefaultValueError(
    Element element,
  ) : super(
          'Default value used with a nullable type. Only non-nullable type can have a default value.',
          todo: 'Remove the default value or make the type non-nullable.',
          element: element,
        );
}
