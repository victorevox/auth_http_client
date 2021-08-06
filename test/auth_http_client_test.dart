import 'package:auth_http_client/auth_http_client.dart';
import 'package:auth_http_client/constants.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:mockito/mockito.dart';
import './shared_mocks.mocks.dart';

void main() {
  late HttpAuthClient authClient;
  late MockSharedPreferences mockSharedPreferences;
  // We mockup a http client so that way we can spy on it
  late MockHttpClient mockHttpClient;
  final String mockToken = "TOKEN";
  final Uri mockApiPath = Uri.dataFromString("https://test.com/api");
  final authenticationHeaders = {"Authorization": "Bearer $mockToken"};

  setUp(() {
    mockSharedPreferences = MockSharedPreferences();
    mockHttpClient = MockHttpClient();
    authClient = HttpAuthClient(
      sharedPreferences: mockSharedPreferences,
      client: mockHttpClient,
      refreshTokenUrl: (_, __) => "test",
    );
  });

  setUpStubsOnHttpClient() {
    final successResponse = Response("", 200);
    when(mockHttpClient.head(
      any,
      headers: anyNamed("headers"),
    )).thenAnswer((realInvocation) async {
      return successResponse;
    });
    when(mockHttpClient.patch(
      any,
      headers: anyNamed("headers"),
      body: anyNamed("body"),
      encoding: anyNamed("encoding"),
    )).thenAnswer((realInvocation) async {
      return successResponse;
    });
    when(mockHttpClient.post(
      any,
      headers: anyNamed("headers"),
      body: anyNamed("body"),
      encoding: anyNamed("encoding"),
    )).thenAnswer((realInvocation) async {
      return successResponse;
    });
    when(mockHttpClient.put(
      any,
      headers: anyNamed("headers"),
      body: anyNamed("body"),
      encoding: anyNamed("encoding"),
    )).thenAnswer((realInvocation) async {
      return successResponse;
    });
    when(mockHttpClient.read(
      any,
      headers: anyNamed("headers"),
    )).thenAnswer((realInvocation) async {
      return "successResponse";
    });
    when(mockHttpClient.get(
      any,
      headers: anyNamed("headers"),
    )).thenAnswer((realInvocation) async {
      return successResponse;
    });
  }

  setUpMockSharedPreferenceAsAuthenticated() {
    when(mockSharedPreferences.getString(AuthHttpClientKeys.sharedPrefsAuthToken)).thenReturn(mockToken);
  }

  setUpMockSharedPreferenceAsNotAuthenticated() {
    when(mockSharedPreferences.getString(AuthHttpClientKeys.sharedPrefsAuthToken)).thenReturn(null);
  }

  group("Http client methods when authenticated", () {
    setUp(() {
      setUpMockSharedPreferenceAsAuthenticated();
      setUpStubsOnHttpClient();
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

    test(
        "should not set ${AuthHttpClientKeys.authorizationHeader} Header if ${AuthHttpClientKeys.noAuthenticateOverride} header is set",
        () {
      // act
      authClient.head(mockApiPath, headers: {"${AuthHttpClientKeys.noAuthenticateOverride}": ""});
      authClient.get(mockApiPath, headers: {"${AuthHttpClientKeys.noAuthenticateOverride}": ""});
      authClient.put(mockApiPath, headers: {"${AuthHttpClientKeys.noAuthenticateOverride}": ""});
      authClient.post(mockApiPath, headers: {"${AuthHttpClientKeys.noAuthenticateOverride}": ""});
      authClient.patch(mockApiPath, headers: {"${AuthHttpClientKeys.noAuthenticateOverride}": ""});
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
      setUpStubsOnHttpClient();
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
