// GENERATED CODE - DO NOT MODIFY BY HAND

// ignore_for_file: always_specify_types, public_member_api_docs

part of 'json_nested_example.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
      $homeRoute,
    ];

RouteBase get $homeRoute => GoRouteData.$route(
      path: '/',
      name: 'Home',
      factory: _$HomeRoute._fromState,
      routes: [
        GoRouteData.$route(
          path: 'json',
          factory: _$JsonRoute._fromState,
        ),
      ],
    );

mixin _$HomeRoute on GoRouteData {
  static HomeRoute _fromState(GoRouterState state) => const HomeRoute();

  @override
  String get location => GoRouteData.$location(
        '/',
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin _$JsonRoute on GoRouteData {
  static JsonRoute _fromState(GoRouterState state) => JsonRoute(
        (String json0) {
          return JsonExampleNested.fromJson(
            jsonDecode(json0) as Map<String, dynamic>,
            (Object? json1) {
              return JsonExample.fromJson(json1 as Map<String, dynamic>);
            },
          );
        }(state.uri.queryParameters['json']!),
      );

  JsonRoute get _self => this as JsonRoute;

  @override
  String get location => GoRouteData.$location(
        '/json',
        queryParams: {
          'json': jsonEncode(_self.json.toJson()),
        },
      );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}
