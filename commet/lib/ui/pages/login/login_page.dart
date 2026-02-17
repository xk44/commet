import 'dart:async';

import 'package:commet/client/auth.dart';
import 'package:commet/client/client.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/main.dart';
import 'package:commet/ui/pages/login/login_page_view.dart';
import 'package:commet/utils/debounce.dart';
import 'package:commet/utils/rng.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.onSuccess, this.canNavigateBack = false});
  final bool canNavigateBack;
  final Function(Client loggedInClient)? onSuccess;

  @override
  State<LoginPage> createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  String get messageLoginFailed => Intl.message("Login Failed...",
      name: "messageLoginFailed",
      desc: "Generic text to show that an attempted login has failed");

  String get messageLoginError => Intl.message("An error occured",
      name: "messageLoginError",
      desc:
          "A generic error message to convey that an error occured when attempting to login");

  String get messageInvalidLoginInput => Intl.message(
        "Please enter a valid homeserver, username, and password",
        name: "messageInvalidLoginInput",
        desc:
            "Shown when login fields are invalid before attempting password login",
      );

  String get messageAlreadyLoggedIn => Intl.message(
        "You have already logged in to this account",
        name: "messageAlreadyLoggedIn",
        desc:
            "An error message displayed when the user attempts to add an account which has already been logged in to on this device",
      );

  StreamSubscription? progressSubscription;
  double? progress;
  List<LoginFlow>? loginFlows;
  Client? loginClient;

  final Debouncer homeserverUpdateDebouncer =
      Debouncer(delay: const Duration(seconds: 1));

  bool loadingServerInfo = false;
  bool isServerValid = false;
  bool isLoggingIn = false;
  String? homeserverErrorMessage;

  @override
  void initState() {
    var internalId = RandomUtils.getRandomString(20);
    MatrixClient.create(internalId).then((client) {
      loginClient = client;

      progressSubscription = loginClient!.connectionStatusChanged.stream
          .listen(onLoginProgressChanged);
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return LoginPageView(
      canNavigateBack: widget.canNavigateBack,
      progress: progress,
      updateHomeserver: (value) {
        setState(() {
          loginFlows = null;
          isServerValid = false;
          loadingServerInfo = true;
          homeserverErrorMessage = null;
        });
        homeserverUpdateDebouncer.run(() => updateHomeserver(value));
      },
      flows: loginFlows,
      doSsoLogin: doSsoLogin,
      doPasswordLogin: doPasswordLogin,
      isLoggingIn: isLoggingIn,
      loadingServerInfo: loadingServerInfo,
      hasSsoSupport: loginFlows?.whereType<SsoLoginFlow>().isNotEmpty == true,
      hasPasswordSupport:
          loginFlows?.whereType<PasswordLoginFlow>().isNotEmpty == true,
      isServerValid: isServerValid,
      homeserverErrorMessage: homeserverErrorMessage,
    );
  }

  Future<void> doLogin(Future<LoginResult> Function() login) async {
    if (loginClient == null) return;
    if (isServerValid == false) {
      return;
    }

    setState(() {
      isLoggingIn = true;
    });
    LoginResult result = LoginResult.error;
    try {
      result = await login();
    } catch (_) {}

    if (result != LoginResult.success) {
      setState(() {
        isLoggingIn = false;
      });
    }

    String? message = switch (result) {
      LoginResult.success => null,
      LoginResult.failed => messageLoginFailed,
      LoginResult.error => messageLoginError,
      LoginResult.alreadyLoggedIn => messageAlreadyLoggedIn,
      LoginResult.cancelled => "Login cancelled"
    };

    if (message != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
          ),
        );
      }
    }

    if (result == LoginResult.success) {
      clientManager?.addClient(loginClient!);
      widget.onSuccess?.call(loginClient!);
    }
  }

  Future<void> doSsoLogin(SsoLoginFlow flow) async {
    if (loginClient == null) return;
    await doLogin(() => loginClient!.executeLoginFlow(flow));
  }

  Future<void> doPasswordLogin(
      PasswordLoginFlow flow, String username, String password) async {
    if (loginClient == null) return;

    var normalizedUsername = username.trim();
    var normalizedPassword = password.trim();

    if (normalizedUsername.isEmpty ||
        normalizedPassword.isEmpty ||
        normalizedUsername.contains(RegExp(r"\s"))) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(messageInvalidLoginInput),
          ),
        );
      }
      return;
    }

    flow.username = normalizedUsername;
    flow.password = normalizedPassword;

    await doLogin(() => loginClient!.executeLoginFlow(flow));
  }

  void onLoginProgressChanged(ClientConnectionStatusUpdate event) {
    if (!mounted) return;
    setState(() {
      progress = event.progress;
    });
  }

  Future<void> updateHomeserver(String input) async {
    if (loginClient == null) return;

    setState(() {
      loginFlows = null;
      loadingServerInfo = true;
      isServerValid = false;
      homeserverErrorMessage = null;
    });

    final normalized = _normalizeHomeserver(input);
    if (normalized == null) {
      setState(() {
        loadingServerInfo = false;
        homeserverErrorMessage = null;
      });
      return;
    }

    var uri = Uri.https(normalized);
    var result = await loginClient!.setHomeserver(uri);

    setState(() {
      loadingServerInfo = false;
      isServerValid = result.$1;
      loginFlows = result.$2;
      homeserverErrorMessage = result.$1
          ? null
          : Intl.message(
              "We couldn't reach that homeserver. Check the address and try again.",
              name: "messageHomeserverUnreachable",
              desc:
                  "Shown when the user enters a homeserver that cannot be reached or does not exist",
            );
    });
  }

  String? _normalizeHomeserver(String input) {
    var normalized = input.trim().toLowerCase();

    normalized = normalized.replaceFirst(RegExp(r"^https?://"), "");
    normalized = normalized.split("/").first;

    if (normalized.isEmpty ||
        normalized.contains(RegExp(r"\s")) ||
        !RegExp(r"^[a-z0-9.-]+(?::[0-9]{1,5})?$").hasMatch(normalized)) {
      return null;
    }

    return normalized;
  }
}
