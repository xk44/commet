import 'package:commet/client/auth.dart';
import 'package:commet/client/client.dart';
import 'package:commet/client/matrix/matrix_client.dart';
import 'package:commet/config/build_config.dart';

import 'package:matrix/matrix.dart' as matrix;

class MatrixPasswordLoginFlow implements PasswordLoginFlow {
  @override
  String? password;

  @override
  String? username;

  @override
  Future<LoginResult> submit(Client client) async {
    if (username == null || password == null) {
      return LoginResult.failed;
    }

    if (client is! MatrixClient) {
      return LoginResult.failed;
    }

    var mx = client.getMatrixClient();
    var result = LoginResult.error;

    try {
      var response = await mx.login(matrix.LoginType.mLoginPassword,
          initialDeviceDisplayName: BuildConfig.appName,
          password: password,
          identifier: matrix.AuthenticationUserIdentifier(user: username!));
      if (response.accessToken.isNotEmpty) {
        result = LoginResult.success;
      } else {
        result = LoginResult.failed;
      }
    } on matrix.MatrixException catch (error) {
      if (error.error == matrix.MatrixError.M_FORBIDDEN) {
        result = LoginResult.failed;
      } else {
        result = LoginResult.error;
      }
    } catch (_) {
      result = LoginResult.error;
    }

    return result;
  }
}
