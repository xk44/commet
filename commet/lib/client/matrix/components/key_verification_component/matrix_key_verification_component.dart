import 'dart:async';

import 'package:commet/client/components/component.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/debug/log.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/navigation/adaptive_dialog.dart';
import 'package:commet/ui/pages/matrix/authentication/matrix_uia_request.dart';
import 'package:commet/ui/pages/matrix/verification/matrix_verification_page.dart';

import 'package:flutter/material.dart';

import 'package:matrix/matrix.dart' as matrix;

class MatrixKeyVerificationComponent
    implements Component<MatrixClient>, NeedsPostLoginInit {
  static const int _maxDialogContextRetries = 20;
  static const Duration _dialogContextRetryDelay = Duration(milliseconds: 250);

  @override
  MatrixClient client;

  MatrixKeyVerificationComponent(this.client);

  @override
  void postLoginInit() {
    Log.i("Registering key verification listeners");
    client.matrixClient.onKeyVerificationRequest.stream.listen((event) {
      _showDialogWhenContextReady(
        builder: (_) => MatrixVerificationPage(request: event),
        title: "Verification Request",
      );
    });

    client.matrixClient.onUiaRequest.stream.listen((event) {
      if (event.state == matrix.UiaRequestState.waitForUser) {
        _showDialogWhenContextReady(
          builder: (_) => MatrixUIARequest(event, client),
          title: "Authentication Request",
        );
      }
    });
  }

  Future<void> _showDialogWhenContextReady({
    required WidgetBuilder builder,
    required String title,
    int attempt = 0,
  }) async {
    final context = navigator.currentContext;
    if (context != null && context.mounted) {
      AdaptiveDialog.show(
        context,
        builder: builder,
        title: title,
      );
      return;
    }

    if (attempt >= _maxDialogContextRetries) {
      Log.e(
        "Failed to show '$title' dialog because no navigator context was available after retries.",
      );
      return;
    }

    await Future.delayed(_dialogContextRetryDelay);
    return _showDialogWhenContextReady(
      builder: builder,
      title: title,
      attempt: attempt + 1,
    );
  }
}
