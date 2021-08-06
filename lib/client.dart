import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:corsac_jwt/corsac_jwt.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class HttpAuthClient implements http.Client {
  late http.Client _httpClient;
  final SharedPreferences sharedPreferences;

  /// Defines a function to get the URL in which a new token can be requested
  /// Defining this property activates the 'refreshToken' mechanism
  final String Function(String token, JWT decodedToken)? refreshTokenUrl;

  /// Defines a custom function to parse the response of your refresh token API, you must return a valid
  /// JWT, so it can replace your current session one
  final String Function(String body)? onParseRefreshTokenResponse;

  /// Defines the 'http' (POST, PUT, etc) method to be used when requesting a new token to the API
  final String refreshTokenMethod;

  /// Defines the JWT age thresshold in which the refresh token logic will trigger
  ///
  /// By default `1 day` is used
  final Duration maxAge;

  /// Every call to any [http.Client] method `post, put, delete, etc` will attempt to trigger the refresh token
  /// if applies, setting a `refreshTokenDebounceTime` will help to prevent excecive calls to the server
  ///
  /// By default `1 second` period time is used
  final Duration refreshTokenDebounceTime;

  /// This Callback is called whenever a refresh token have been successfull retrieved
  final void Function(String token)? onRefreshToken;

  late StreamController _refreshController;

  HttpAuthClient({
    http.Client? client,
    required this.sharedPreferences,
    this.refreshTokenUrl,
    this.onParseRefreshTokenResponse = _defaultParseRefreshTokenResponse,
    this.refreshTokenMethod = "POST",
    this.maxAge = const Duration(days: 1),
    this.refreshTokenDebounceTime = const Duration(seconds: 1),
    this.onRefreshToken,
  }) {
    _httpClient = client is http.Client ? client : http.Client();
    _refreshController = StreamController();
    Timer? debounceTimer;
    _refreshController.stream
      ..listen((_) async {
        if (debounceTimer != null && debounceTimer!.isActive) {
          debounceTimer?.cancel();
        }
        debounceTimer = Timer(Duration(seconds: 1), () async {
          final token = _getToken();
          if (token == null) {
            // it must be logged out, do nothing
            return;
          }
          final JWT decoded = JWT.parse(token);
          final issuedAt = DateTime.fromMillisecondsSinceEpoch(decoded.issuedAt! * 1000);
          final requestNew = issuedAt
              .add(
                this.maxAge,
              )
              .isBefore(
                DateTime.now(),
              );
          if (!requestNew) {
            return;
          }

          if (this.refreshTokenUrl == null) return;

          final sres = await this.send(
            http.Request(
              refreshTokenMethod,
              Uri.parse((this.refreshTokenUrl?.call(token, decoded))!),
            )..bodyFields = {},
          );

          final response = await http.Response.fromStream(sres);
          final refreshedToken = onParseRefreshTokenResponse?.call(response.body);
          if (refreshedToken != null) {
            onRefreshToken?.call(refreshedToken);
            _setToken(refreshedToken);
          }
        });
      });
  }

  @override
  void close() {
    _httpClient.close();
  }

  @override
  Future<http.Response> delete(url, {Map<String, String>? headers, Object? body, Encoding? encoding}) {
    _mayRefreshToken();
    return _httpClient.delete(url, headers: _getCustomHeaders(headers));
  }

  @override
  Future<http.Response> get(url, {Map<String, String>? headers}) {
    _mayRefreshToken();
    return _httpClient.get(url, headers: _getCustomHeaders(headers));
  }

  @override
  Future<http.Response> head(url, {Map<String, String>? headers}) {
    _mayRefreshToken();
    return _httpClient.head(url, headers: _getCustomHeaders(headers));
  }

  @override
  Future<http.Response> patch(url, {Map<String, String>? headers, body, Encoding? encoding}) {
    _mayRefreshToken();
    return _httpClient.patch(url, headers: _getCustomHeaders(headers), body: body, encoding: encoding);
  }

  @override
  Future<http.Response> post(url, {Map<String, String>? headers, body, Encoding? encoding}) {
    _mayRefreshToken();
    return _httpClient.post(url, headers: _getCustomHeaders(headers), body: body, encoding: encoding);
  }

  @override
  Future<http.Response> put(url, {Map<String, String>? headers, body, Encoding? encoding}) {
    _mayRefreshToken();
    return _httpClient.put(url, headers: _getCustomHeaders(headers), body: body, encoding: encoding);
  }

  @override
  Future<String> read(url, {Map<String, String>? headers}) {
    _mayRefreshToken();
    return _httpClient.read(url, headers: _getCustomHeaders(headers));
  }

  @override
  Future<Uint8List> readBytes(url, {Map<String, String>? headers}) {
    _mayRefreshToken();
    return _httpClient.readBytes(url, headers: _getCustomHeaders(headers));
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    // http.BaseRequest newRequest;
    if (request is http.MultipartRequest) {
      return _httpClient.send(
        http.MultipartRequest(
          request.method,
          request.url,
        )
          ..headers.addAll(
            _getCustomHeaders(request.headers),
          )
          ..fields.addAll(request.fields)
          ..files.addAll(request.files),
      );
    } else if (request is http.Request) {
      return _httpClient.send(
        http.Request(
          request.method,
          request.url,
        )
          ..headers.addAll(
            _getCustomHeaders(request.headers),
          )
          ..body = request.body
          ..bodyFields = request.bodyFields
          ..bodyBytes = request.bodyBytes,
      );
    }
    return _httpClient.send(request);
  }

  Map<String, String> _getCustomHeaders(Map<String, String>? headers) {
    final Map<String, String> baseHeaders = headers ?? {};
    final authToken = _getToken();
    if (baseHeaders.containsKey(AuthHttpClientKeys.noAuthenticateOverride)) {
      baseHeaders.remove(AuthHttpClientKeys.noAuthenticateOverride);
      return baseHeaders;
    } else if (authToken != null) {
      baseHeaders.putIfAbsent("Authorization", () => "Bearer ${_getToken()}");
    }
    return baseHeaders;
  }

  _getToken() {
    return this.sharedPreferences.getString(AuthHttpClientKeys.sharedPrefsAuthToken);
  }

  _setToken(String token) {
    this.sharedPreferences.setString(AuthHttpClientKeys.sharedPrefsAuthToken, token);
  }

  _mayRefreshToken() async {
    _refreshController.sink.add(null);
  }
}

String _defaultParseRefreshTokenResponse(String body) {
  return jsonDecode(body)["data"];
}
