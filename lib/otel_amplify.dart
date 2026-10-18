// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

/// OpenTelemetry instrumentation for AWS Amplify BaaS calls.
///
/// Four callback-shaped helpers: `tracedAmplifyAuth`,
/// `tracedAmplifyApi`, `tracedAmplifyDataStore`, `tracedAmplifyStorage`.
/// Each wraps the corresponding Amplify category in a CLIENT span
/// with `amplify.*` attributes plus relevant user/model/key context.
library;

export 'src/otel_amplify.dart';
export 'src/otel_amplify_suppression.dart';
