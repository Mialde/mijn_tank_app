import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart' as sign_in;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:googleapis/sheets/v4.dart' as sheets;

class GoogleSheetsService {
  // Alias gebruikt om errors te voorkomen
  final sign_in.GoogleSignIn _googleSignIn = sign_in.GoogleSignIn(
    scopes: [sheets.SheetsApi.spreadsheetsScope],
  );

  sheets.SheetsApi? _sheetsApi;

  Future<bool> signIn() async {
    try {
      final sign_in.GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return false;

      final AuthClient? client = await _googleSignIn.authenticatedClient();
      if (client == null) return false;

      _sheetsApi = sheets.SheetsApi(client);
      return true;

    } catch (e) {
      debugPrint('Fout bij Google Sign-In: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _sheetsApi = null;
  }

  bool get isSignedIn => _sheetsApi != null;
}