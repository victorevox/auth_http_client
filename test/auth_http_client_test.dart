import 'package:auth_http_client/auth_http_client.dart';
import 'package:auth_http_client/constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import './mocks.dart';

void main(){

  HttpAuthClient authClient;
  MockSharedPreferences mockSharedPreferences;
  // We mockup a http client so that way we can spy on it
  MockHttpClient mockHttpClient;
  final String mockToken = "TOKEN";
  final String mockApiPath = "https://test.com/api";
  final authenticationHeaders = {
    "Authorization": "Bearer $mockToken"
  };

  setUp(() {
    mockSharedPreferences = MockSharedPreferences();
    mockHttpClient = MockHttpClient();
    authClient = HttpAuthClient(
      sharedPreferences: mockSharedPreferences,
      client: mockHttpClient
    );
  });

  setUpMockSharedPreferenceAsAuthenticated() {
    when(mockSharedPreferences.getString(AuthHttpClientKeys.sharedPrefsAuthToken)).thenReturn(mockToken);
  }

  setUpMockSharedPreferenceAsNotAuthenticated() {
    when(mockSharedPreferences.getString(AuthHttpClientKeys.sharedPrefsAuthToken)).thenReturn(null);
  }

  group("Http client methods when authenticated", () {
    setUp(() {
      setUpMockSharedPreferenceAsAuthenticated();
    });
    test("should set ${AuthHttpClientKeys.authorizationHeader} Header To 'Bearer $mockToken'", () {
      // act
      authClient.head(mockApiPath);
      authClient.get(mockApiPath);
      authClient.put(mockApiPath);
      authClient.post(mockApiPath);
      authClient.patch(mockApiPath);
      // assert
      verify(mockHttpClient.head(mockApiPath, headers: authenticationHeaders));
      verify(mockHttpClient.get(mockApiPath, headers: authenticationHeaders));
      verify(mockHttpClient.put(mockApiPath, headers: authenticationHeaders));
      verify(mockHttpClient.post(mockApiPath, headers: authenticationHeaders));
      verify(mockHttpClient.patch(mockApiPath, headers: authenticationHeaders));
    });

    test("should not set ${AuthHttpClientKeys.authorizationHeader} Header if ${AuthHttpClientKeys.noAuthenticateOverride} header is set", () {
      // act
      authClient.head(mockApiPath, headers: {
        "${AuthHttpClientKeys.noAuthenticateOverride}": ""
      });
      authClient.get(mockApiPath, headers: {
        "${AuthHttpClientKeys.noAuthenticateOverride}": ""
      });
      authClient.put(mockApiPath, headers: {
        "${AuthHttpClientKeys.noAuthenticateOverride}": ""
      });
      authClient.post(mockApiPath, headers: {
        "${AuthHttpClientKeys.noAuthenticateOverride}": ""
      });
      authClient.patch(mockApiPath, headers: {
        "${AuthHttpClientKeys.noAuthenticateOverride}": ""
      });
      // assert
      verify(mockHttpClient.head(mockApiPath, headers: {}));
      verify(mockHttpClient.get(mockApiPath, headers: {}));
      verify(mockHttpClient.put(mockApiPath, headers: {}));
      verify(mockHttpClient.post(mockApiPath, headers: {}));
      verify(mockHttpClient.patch(mockApiPath, headers: {}));
    });
  });

  group("Http client methods when authenticated", () {
    setUp(() {
      setUpMockSharedPreferenceAsNotAuthenticated();
    });
    test("should not set Authorization Header when token is not available", () {
      // act
      authClient.head(mockApiPath);
      authClient.get(mockApiPath);
      authClient.put(mockApiPath);
      authClient.post(mockApiPath);
      authClient.patch(mockApiPath);
      // assert
      verify(mockHttpClient.head(mockApiPath, headers: {}));
      verify(mockHttpClient.get(mockApiPath, headers: {}));
      verify(mockHttpClient.put(mockApiPath, headers: {}));
      verify(mockHttpClient.post(mockApiPath, headers: {}));
      verify(mockHttpClient.patch(mockApiPath, headers: {}));
    });
  });




}