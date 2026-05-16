// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_amplify/otel_amplify.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_amplify-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('Auth signIn carries user.name + amplify.operation', () async {
    await tracedAmplifyAuth<String>(
      operation: 'signIn',
      username: 'ada',
      invoke: () async => 'ok',
    );
    final span = spans.findSpanByName('amplify.auth signIn');
    expect(span, isNotNull);
    final a = attrsOf(span!);
    expect(a['amplify.operation'], 'signIn');
    expect(a['user.name'], 'ada');
  });

  test('API call has amplify.api.name', () async {
    await tracedAmplifyApi<String>(
      apiName: 'graphql',
      operation: 'listOrders',
      invoke: () async => 'ok',
    );
    final span = spans.findSpanByName('amplify.api listOrders');
    expect(attrsOf(span!)['amplify.api.name'], 'graphql');
  });

  test('DataStore records model + operation', () async {
    await tracedAmplifyDataStore<String>(
      operation: 'save',
      modelName: 'Order',
      invoke: () async => 'ok',
    );
    final span = spans.findSpanByName('amplify.datastore save');
    expect(attrsOf(span!)['amplify.datastore.model'], 'Order');
  });

  test('Storage records key + access_level', () async {
    await tracedAmplifyStorage<String>(
      operation: 'uploadFile',
      key: 'user-42/avatar.png',
      accessLevel: 'private',
      invoke: () async => 'ok',
    );
    final span = spans.findSpanByName('amplify.storage uploadFile');
    final a = attrsOf(span!);
    expect(a['amplify.storage.key'], 'user-42/avatar.png');
    expect(a['amplify.storage.access_level'], 'private');
  });

  test('records exception on throw', () async {
    await expectLater(
      tracedAmplifyAuth<String>(
        operation: 'signIn',
        invoke: () async => throw StateError('not_authorized'),
      ),
      throwsA(isA<StateError>()),
    );
    expect(
      spans.findSpanByName('amplify.auth signIn')!.status,
      SpanStatusCode.Error,
    );
  });

  test('suppression skips spans across helpers', () async {
    await runWithoutAmplifyInstrumentationAsync(() async {
      await tracedAmplifyAuth<String>(
        operation: 'signOut',
        invoke: () async => 'ok',
      );
      await tracedAmplifyStorage<String>(
        operation: 'list',
        key: '/',
        invoke: () async => 'ok',
      );
    });
    expect(spans.findSpansStartingWith('amplify.'), isEmpty);
  });
}
