import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class HttpAuthClient implements http.Client {

  http.Client _httpClient;
  final SharedPreferences sharedPreferences;

  HttpAuthClient({http.Client client, @required this.sharedPreferences}) {
    _httpClient = client is http.Client? client : http.Client(); 
  }

  @override
  void close() {
    _httpClient.close();
  }

  @override
  Future<http.Response> delete(url, {Map<String, String> headers}) {
    return _httpClient.delete(url, headers: _getCustomHeaders(headers));
  }

  @override
  Future<http.Response> get(url, {Map<String, String> headers}) {
    return _httpClient.get(url, headers: _getCustomHeaders(headers));
  }

  @override
  Future<http.Response> head(url, {Map<String, String> headers}) {
    return _httpClient.head(url, headers: _getCustomHeaders(headers));
  }

  @override
  Future<http.Response> patch(url, {Map<String, String> headers, body, Encoding encoding}) {
    return _httpClient.patch(url, headers: _getCustomHeaders(headers), body: body,encoding: encoding);
  }

  @override
  Future<http.Response> post(url, {Map<String, String> headers, body, Encoding encoding}) {
    return _httpClient.post(url, headers: _getCustomHeaders(headers), body: body, encoding: encoding);
  }

  @override
  Future<http.Response> put(url, {Map<String, String> headers, body, Encoding encoding}) {
    return _httpClient.put(url, headers: _getCustomHeaders(headers), body: body, encoding: encoding);
  }

  @override
  Future<String> read(url, {Map<String, String> headers}) {
    return _httpClient.read(url, headers: _getCustomHeaders(headers));
  }

  @override
  Future<Uint8List> readBytes(url, {Map<String, String> headers}) {
    return _httpClient.readBytes(url, headers: _getCustomHeaders(headers));
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _httpClient.send(request);
  }

  Map<String, String> _getCustomHeaders(Map<String, String> headers) {
    final Map<String, String> baseHeaders = headers is Map? headers : {};
    final authToken = _getToken();
    if(baseHeaders.containsKey(AuthHttpClientKeys.noAuthenticateOverride)) {
      baseHeaders.remove(AuthHttpClientKeys.noAuthenticateOverride);
      return baseHeaders;
    } else if(authToken != null) {
      baseHeaders.putIfAbsent("Authorization", () => "Bearer ${_getToken()}");
    }
    return baseHeaders;
  }

  _getToken() {
    return this.sharedPreferences.getString(AuthHttpClientKeys.sharedPrefsAuthToken);
  }
  
}