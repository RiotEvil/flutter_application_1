// OAuth Configuration
//
// WARNING: For production apps, these values should be fetched from a backend
// API or Firebase Remote Config to prevent exposure in the binary.
// This is a temporary solution for development/MVP.
//
// See: https://developers.google.com/identity/protocols/oauth2

class OAuthConfig {
  /// Google OAuth 2.0 Server Client ID
  /// Used for serverAuthCode flow in Google Sign-In
  /// Should be the Web OAuth client ID (not Android or iOS)
  static const String googleServerClientId =
      '802635202251-r85tlha23jths01s2gf3cqskkvcod7v3.apps.googleusercontent.com';

  // TODO: For production: Fetch this from Firebase Cloud Functions or REST API
  // static Future<String> getGoogleServerClientId() async {
  //   final response = await http.get(Uri.parse('$backendUrl/config/google-oauth-client-id'));
  //   if (response.statusCode == 200) {
  //     return jsonDecode(response.body)['clientId'];
  //   }
  //   throw Exception('Failed to load OAuth config');
  // }
}
