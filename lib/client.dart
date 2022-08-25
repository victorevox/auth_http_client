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

  /// Defines a custom function to parse the response of your refresh token API, you must return an object
  /// with "refreshToken" and "authToken", so it can replace your current session one
  /// Example
  /// {
  ///   "auth-token": "YourParsedAuthToken",
  ///   "auth-refresh-token": "YourParsedRefreshToken"
  /// }
  late Map<String, String> Function(String body) refreshTokenResponseParser;

  /// Provide a function to be used in order to use/pass the refresh token to the
  /// API endpoint
  late Map<String, String> Function(String refreshToken, String authToken) refreshTokenRequestBodyMapper;

  /// Defines the 'http' (POST, PUT, etc) method to be used when requesting a new token to the API
  /// defaults to 'POST'
  late String refreshTokenMethod;

  /// Define a custom period to wait for the refresh token API, after defined period if no response
  /// the API call waiting for the token will throw
  ///
  /// Defaults to 15 seconds
  ///
  late Duration refreshTokenTimeout;

  /// This Callback is called whenever a refresh token have been successfully retrieved
  /// It provides access to the retrieved tokens
  final void Function(Map<String, String> tokens)? onRefreshToken;

  /// This Callback is called whenever a refresh token fail to be retrieved
  /// It provides access to the refresh token used & the exception raised
  final void Function(String token, Object exception)? onRefreshTokenFailure;

  late StreamController<bool> _refreshController;
  bool _requestingNewToken = false;

  HttpAuthClient({
    http.Client? client,
    required this.sharedPreferences,
    this.refreshTokenUrl,
    Map<String, String> Function(String body)? customRefreshTokenResponseParser,
    String? refreshTokenMethod,
    Duration? maxAge,
    Duration? refreshTokenTimeout,
    Map<String, String> Function(String refreshToken, String authToken)? customRefreshTokenRequestBodyMapper,
    this.onRefreshToken,
    this.onRefreshTokenFailure,
  }) {
    this.refreshTokenResponseParser = customRefreshTokenResponseParser ?? _defaultRefreshTokenResponseParser;
    this.refreshTokenMethod = "POST";
    this.refreshTokenRequestBodyMapper =
        customRefreshTokenRequestBodyMapper ?? _defaultCustomRefreshTokenRequestBodyMapper;
    this.refreshTokenTimeout = refreshTokenTimeout ?? const Duration(seconds: 15);

    _httpClient = client is http.Client ? client : http.Client();
    _refreshController = StreamController.broadcast();
  }

  @override
  void close() {
    _httpClient.close();
  }

  @override
  Future<http.Response> delete(url, {Map<String, String>? headers, Object? body, Encoding? encoding}) async {
    await _mayRefreshToken();
    return _httpClient.delete(url, headers: _getCustomHeaders(headers));
  }

  @override
  Future<http.Response> get(url, {Map<String, String>? headers}) async {
    await _mayRefreshToken();
    return _httpClient.get(url, headers: _getCustomHeaders(headers));
  }

  @override
  Future<http.Response> head(url, {Map<String, String>? headers}) async {
    await _mayRefreshToken();
    return _httpClient.head(url, headers: _getCustomHeaders(headers));
  }

  @override
  Future<http.Response> patch(url, {Map<String, String>? headers, body, Encoding? encoding}) async {
    await _mayRefreshToken();
    return _httpClient.patch(url, headers: _getCustomHeaders(headers), body: body, encoding: encoding);
  }

  @override
  Future<http.Response> post(url, {Map<String, String>? headers, body, Encoding? encoding}) async {
    await _mayRefreshToken();
    return _httpClient.post(url, headers: _getCustomHeaders(headers), body: body, encoding: encoding);
  }

  @override
  Future<http.Response> put(url, {Map<String, String>? headers, body, Encoding? encoding}) async {
    await _mayRefreshToken();
    return _httpClient.put(url, headers: _getCustomHeaders(headers), body: body, encoding: encoding);
  }

  @override
  Future<String> read(url, {Map<String, String>? headers}) async {
    await _mayRefreshToken();
    return _httpClient.read(url, headers: _getCustomHeaders(headers));
  }

  @override
  Future<Uint8List> readBytes(url, {Map<String, String>? headers}) async {
    await _mayRefreshToken();
    return _httpClient.readBytes(url, headers: _getCustomHeaders(headers));
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // http.BaseRequest newRequest;
    if (!_requestingNewToken) {
      await _mayRefreshToken();
    }
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
      http.Request newRequest = http.Request(
        request.method,
        request.url,
      )..headers.addAll(
          _getCustomHeaders(request.headers),
        );
      String? contentType = newRequest.headers["content-type"];
      if (request.body != "") {
        newRequest.body = request.body;
      } else if (contentType == "application/x-www-form-urlencoded" && request.bodyFields.isNotEmpty) {
        newRequest.bodyFields = request.bodyFields;
      } else if (request.bodyBytes.isNotEmpty) {
        newRequest.bodyBytes = request.bodyBytes;
      }
      return _httpClient.send(
        newRequest,
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

  String? _getToken() {
    return this.sharedPreferences.getString(AuthHttpClientKeys.sharedPrefsAuthToken);
  }

  String? _getRefreshToken() {
    return this.sharedPreferences.getString(AuthHttpClientKeys.sharedPrefsAuthRefreshToken);
  }

  _setTokens(Map<String, String> tokens) {
    this
        .sharedPreferences
        .setString(AuthHttpClientKeys.sharedPrefsAuthToken, tokens[AuthHttpClientKeys.sharedPrefsAuthToken]!);
    if (tokens.containsKey(AuthHttpClientKeys.sharedPrefsAuthRefreshToken))
      this.sharedPreferences.setString(
          AuthHttpClientKeys.sharedPrefsAuthRefreshToken, tokens[AuthHttpClientKeys.sharedPrefsAuthRefreshToken]!);
  }

  Future<void> _mayRefreshToken() async {
    if (_requestingNewToken) {
      await _refreshController.stream.timeout(refreshTokenTimeout).first;
    } else {
      final refreshToken = _getRefreshToken();
      final authToken = _getToken();
      if (authToken == null) {
        // it must be logged out, do nothing
        return;
      }

      if (refreshToken == null) {
        if (refreshTokenUrl != null) {
          print(
            "Authentication Session cannot be refreshed because not refresh token is present in shared_preferences",
          );
        }
        return;
      }

      try {
        _requestingNewToken = true;

        final JWT decoded = JWT.parse(authToken);
        final num exp = decoded.expiresAt! * 1000;
        final expiresAt = DateTime.fromMillisecondsSinceEpoch(
          exp.toInt(),
        );
        final requestNew = DateTime.now().isAfter(
          expiresAt,
        );
        if (!requestNew) {
          _requestingNewToken = false;
          _refreshController.add(true);
          return;
        }

        if (this.refreshTokenUrl == null) {
          _requestingNewToken = false;
          _refreshController.add(true);
          return;
        }

        final sres = await this
            .send(
          http.Request(
            refreshTokenMethod,
            Uri.parse((this.refreshTokenUrl!.call(refreshToken, decoded))),
          )..bodyFields = refreshTokenRequestBodyMapper.call(refreshToken, authToken),
        )
            .timeout(
          refreshTokenTimeout,
          onTimeout: () {
            throw TimeoutException(
              "Refresh token was not retrieved after: $refreshTokenTimeout",
              refreshTokenTimeout,
            );
          },
        );

        final response = await http.Response.fromStream(sres);
        final data = refreshTokenResponseParser.call(response.body);
        if (data.containsKey(AuthHttpClientKeys.sharedPrefsAuthToken)) {
          _setTokens(data);
          onRefreshToken?.call(data);
          _requestingNewToken = false;
          _refreshController.add(true);
        } else {
          throw Exception("Invalid refresh tokens data parsed, ${jsonEncode(data)}, from response: ${response.body}");
        }
      } catch (e) {
        print(e);
        _requestingNewToken = false;
        this._refreshController.add(true);
        onRefreshTokenFailure?.call(refreshToken, e);
        return;
      }
    }
  }
}

Map<String, String> _defaultRefreshTokenResponseParser(String body) {
  final Map<String, dynamic> decoded = jsonDecode(body);
  final Map<String, String> tokens = {};
  Map<String, dynamic> data;

  if (decoded.containsKey("data") && decoded["data"] is Object && !decoded.containsKey("authToken")) {
    data = decoded["data"];
  } else if (decoded.containsKey("data") && decoded["data"] is String) {
    data = {
      "authToken": decoded["data"],
    };
  } else {
    data = decoded;
  }

  if (data.containsKey("authToken")) {
    tokens
      ..addAll({
        AuthHttpClientKeys.sharedPrefsAuthToken: data["authToken"],
      });
  }

  if (data.containsKey("refreshToken")) {
    tokens
      ..addAll({
        AuthHttpClientKeys.sharedPrefsAuthRefreshToken: data["refreshToken"],
      });
  }
  return tokens;
}

Map<String, String> _defaultCustomRefreshTokenRequestBodyMapper(String refreshToken, String accessToken) {
  return {
    "refreshToken": refreshToken,
  };
}
