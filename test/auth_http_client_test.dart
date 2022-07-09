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
  final String mockToken = "token";
  final Uri mockApiPath = Uri.dataFromString("https://test.com/api");
  final authenticationHeaders = {"Authorization": "Bearer $mockToken"};
  final refreshTokenUrl = mockApiPath.toString() + "/refresh";

  setUpSharedPreferencesSet() {
    when(mockSharedPreferences.setString(any, any)).thenAnswer((realInvocation) async => true);
  }

  setUp(() {
    mockSharedPreferences = MockSharedPreferences();
    mockHttpClient = MockHttpClient();
    authClient = HttpAuthClient(
        sharedPreferences: mockSharedPreferences,
        client: mockHttpClient,
        refreshTokenUrl: (_, __) => refreshTokenUrl,
        refreshTokenMethod: "POST");

    setUpSharedPreferencesSet();
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

  setUpMockSharedPreferenceAsAuthenticated([String? customToken]) {
    when(mockSharedPreferences.getString(AuthHttpClientKeys.sharedPrefsAuthToken)).thenReturn(customToken ?? mockToken);
    when(mockSharedPreferences.getString(AuthHttpClientKeys.sharedPrefsAuthRefreshToken))
        .thenReturn(customToken ?? mockToken);
  }

  setUpMockSharedPreferenceAsNotAuthenticated() {
    when(mockSharedPreferences.getString(AuthHttpClientKeys.sharedPrefsAuthToken)).thenReturn(null);
    when(mockSharedPreferences.getString(AuthHttpClientKeys.sharedPrefsAuthRefreshToken)).thenReturn(null);
  }

  group("Http client methods when authenticated", () {
    setUp(() {
      setUpMockSharedPreferenceAsAuthenticated();
      setUpStubsOnHttpClient();
    });
    test("should set ${AuthHttpClientKeys.authorizationHeader} Header To 'Bearer $mockToken'", () async {
      // act
      authClient.head(mockApiPath);
      authClient.get(mockApiPath);
      authClient.put(mockApiPath);
      authClient.post(mockApiPath);
      authClient.patch(mockApiPath);
      // assert
      await Future.delayed(Duration(milliseconds: 100));
      verify(mockHttpClient.head(mockApiPath, headers: authenticationHeaders));
      verify(mockHttpClient.get(mockApiPath, headers: authenticationHeaders));
      verify(mockHttpClient.put(mockApiPath, headers: authenticationHeaders));
      verify(mockHttpClient.post(mockApiPath, headers: authenticationHeaders));
      verify(mockHttpClient.patch(mockApiPath, headers: authenticationHeaders));
    });

    test(
        "should not set ${AuthHttpClientKeys.authorizationHeader} Header if ${AuthHttpClientKeys.noAuthenticateOverride} header is set",
        () async {
      // act
      authClient.head(mockApiPath, headers: {"${AuthHttpClientKeys.noAuthenticateOverride}": ""});
      authClient.get(mockApiPath, headers: {"${AuthHttpClientKeys.noAuthenticateOverride}": ""});
      authClient.put(mockApiPath, headers: {"${AuthHttpClientKeys.noAuthenticateOverride}": ""});
      authClient.post(mockApiPath, headers: {"${AuthHttpClientKeys.noAuthenticateOverride}": ""});
      authClient.patch(mockApiPath, headers: {"${AuthHttpClientKeys.noAuthenticateOverride}": ""});
      // assert
      await Future.delayed(Duration(milliseconds: 100));
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
    test("should not set Authorization Header when token is not available", () async {
      // act
      authClient.head(mockApiPath);
      authClient.get(mockApiPath);
      authClient.put(mockApiPath);
      authClient.post(mockApiPath);
      authClient.patch(mockApiPath);
      // assert
      await Future.delayed(Duration(milliseconds: 100));
      verify(mockHttpClient.head(mockApiPath, headers: {}));
      verify(mockHttpClient.get(mockApiPath, headers: {}));
      verify(mockHttpClient.put(mockApiPath, headers: {}));
      verify(mockHttpClient.post(mockApiPath, headers: {}));
      verify(mockHttpClient.patch(mockApiPath, headers: {}));
    });
  });

  group("refreshLogic", () {
    setUp(() {
      setUpMockSharedPreferenceAsAuthenticated(
        // this token is already expired
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyLCJleHAiOjE1MTYyMzkwMjJ9.4Adcj3UFYzPUVaVF43FmMab6RlaQD8A9V8wFzzht-KQ",
      );

      setUpStubsOnHttpClient();

      when(
        mockHttpClient.send(any),
      ).thenAnswer((realInvocation) async {
        return StreamedResponse(
          Stream.value(
            """{
  "user": {
    "email": "string",
    "phone": "string",
    "firstName": "string",
    "lastName": "string",
    "country": "string",
    "profilePictureUrl": "string",
    "authProviders": [
      "string"
    ]
  },
  "authToken": "authToken",
  "refreshToken": "refreshToken"
}
"""
                .codeUnits,
          ),
          200,
        );
      });
    });

    test("refresh api to be called", () async {
      authClient.get(mockApiPath);
      authClient.put(mockApiPath);

      // assert
      await Future.delayed(Duration(milliseconds: 300));
      verify(mockHttpClient.send(
        argThat(
          TypeMatcher<BaseRequest>()
              .having(
                (p0) => p0.url.toString(),
                "refresh API url",
                refreshTokenUrl,
              )
              .having(
                (p0) => p0.method,
                "method",
                "POST",
              ),
        ),
      )).called(1);
      verify(mockHttpClient.get(
        mockApiPath,
        headers: anyNamed("headers"),
      ));
      verify(mockHttpClient.put(
        mockApiPath,
        headers: anyNamed("headers"),
      ));
    });
  });

  group("misc", () {
    setUp(() {
      setUpMockSharedPreferenceAsNotAuthenticated();
      setUpStubsOnHttpClient();
      when(
        mockHttpClient.send(any),
      ).thenAnswer((realInvocation) async {
        return StreamedResponse(
          Stream.value(
            """{
  "user": {
    "email": "string",
    "phone": "string",
    "firstName": "string",
    "lastName": "string",
    "country": "string",
    "profilePictureUrl": "string",
    "authProviders": [
      "string"
    ]
  },
  "authToken": "authToken",
  "refreshToken": "refreshToken"
}
"""
                .codeUnits,
          ),
          200,
        );
      });
    });
    test("send $Request", () async {
      final request = Request(
        "POST",
        Uri.parse("https://google.com"),
      );

      await authClient.send(request);
      // mockHttpClient.
    });
  });
}
