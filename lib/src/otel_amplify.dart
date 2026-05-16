// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_amplify_suppression.dart';

const _tracerName = 'dartastic_otel_libs_amplify';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

/// Wraps an AWS Amplify Auth operation (signIn, signOut, signUp,
/// confirmSignUp, resetPassword, fetchAuthSession, …) in a CLIENT
/// span.
Future<T> tracedAmplifyAuth<T>({
  required String operation,
  required Future<T> Function() invoke,
  String? username,
  String? userId,
}) {
  final m = <String, Object>{'amplify.operation': operation};
  if (username != null) m[User.userName.key] = username;
  if (userId != null) m[User.userId.key] = userId;
  return _run(
    spanName: 'amplify.auth $operation',
    attributes: m,
    invoke: invoke,
  );
}

/// Wraps an Amplify API (GraphQL or REST) call in a CLIENT span.
Future<T> tracedAmplifyApi<T>({
  required String apiName,
  required String operation,
  required Future<T> Function() invoke,
}) {
  return _run(
    spanName: 'amplify.api $operation',
    attributes: {
      'amplify.api.name': apiName,
      'amplify.operation': operation,
    },
    invoke: invoke,
  );
}

/// Wraps an Amplify DataStore call (`save`, `query`, `delete`,
/// `start`, `stop`, `clear`).
Future<T> tracedAmplifyDataStore<T>({
  required String operation,
  required Future<T> Function() invoke,
  String? modelName,
}) {
  final m = <String, Object>{'amplify.operation': operation};
  if (modelName != null) m['amplify.datastore.model'] = modelName;
  return _run(
    spanName: 'amplify.datastore $operation',
    attributes: m,
    invoke: invoke,
  );
}

/// Wraps an Amplify Storage call (`uploadFile`, `downloadFile`,
/// `remove`, `getUrl`, `list`).
Future<T> tracedAmplifyStorage<T>({
  required String operation,
  required String key,
  required Future<T> Function() invoke,
  String? accessLevel,
}) {
  final m = <String, Object>{
    'amplify.operation': operation,
    'amplify.storage.key': key,
  };
  if (accessLevel != null) {
    m['amplify.storage.access_level'] = accessLevel;
  }
  return _run(
    spanName: 'amplify.storage $operation',
    attributes: m,
    invoke: invoke,
  );
}

Future<T> _run<T>({
  required String spanName,
  required Map<String, Object> attributes,
  required Future<T> Function() invoke,
}) async {
  if (amplifyInstrumentationSuppressed()) return invoke();
  final span = _tracer().startSpan(
    spanName,
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(attributes),
  );
  try {
    return await invoke();
  } catch (e, st) {
    span.addAttributes(
      OTel.attributes([
        OTel.attributeString(
          ErrorResource.errorType.key,
          e.runtimeType.toString(),
        ),
      ]),
    );
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
