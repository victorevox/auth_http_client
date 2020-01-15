class AuthHttpClientKeys {
  AuthHttpClientKeys._();
  
  static get sharedPrefsAuthToken => "authToken";
  static get authorizationHeader => "Authorization";
  static get noAuthenticateOverride => "X-NO-AUTHENTICATED";

}