class AuthHttpClientKeys {
  AuthHttpClientKeys._();

  static get sharedPrefsAuthToken => "auth-token";
  static get sharedPrefsAuthRefreshToken => "auth-refresh-token";
  static get authorizationHeader => "Authorization";
  static get noAuthenticateOverride => "X-NO-AUTHENTICATED";
}
