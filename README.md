# auth_http_client

A package that provides an HttpClient with some useful Authorization capabilities.

## Getting Started

To use this package, add `auth_http_client` as a dependency in your `pubspec.yaml` file:

```yaml
dependencies:
  auth_http_client: ^1.2.0
```

## Usage

Import the package in your Dart code:

```dart
import 'package:auth_http_client/auth_http_client.dart';
```

Create an instance of the `HttpAuthClient`:

```dart
final client = HttpAuthClient(
  client: http.Client(),
  sharedPreferences: sharedPreferences,
  refreshTokenUrl: (token, decodedToken) => 'https://example.com/refresh',
);
```

Now, you can use the client to make API calls with Authorization capabilities:

```dart
final response = await client.get('https://api.example.com/data');
```

## Features

- Automatically adds an "Authorization" header with the "Bearer" scheme for authenticated requests.
- Supports token refresh mechanisms.
- Provides custom hooks for refreshing tokens and handling refresh failures.

## Configuration

The `HttpAuthClient` constructor accepts several optional parameters for customization:

- `client`: An instance of `http.Client` to be used for making HTTP requests. Defaults to a new instance of `http.Client`.
- `sharedPreferences`: An instance of `SharedPreferences` to be used for storing and retrieving tokens.
- `refreshTokenUrl`: A function that returns the URL for refreshing tokens.
- `customRefreshTokenResponseParser`: A custom function for parsing the response from the refresh token API.
- `refreshTokenMethod`: The HTTP method to use when requesting a new token. Defaults to 'POST'.
- `maxAge`: The maximum age of a token before it's considered expired.
- `refreshTokenTimeout`: The maximum time to wait for the refresh token API to respond. Defaults to 15 seconds.
- `customRefreshTokenRequestBodyMapper`: A custom function for mapping the refresh token request body.
- `onRefreshToken`: A callback that's called when a refresh token has been successfully retrieved.
- `onRefreshTokenFailure`: A callback that's called when a refresh token fails to be retrieved.

## Example

Here's a complete example of how to use the `auth_http_client` package:

```dart
import 'package:auth_http_client/auth_http_client.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  final sharedPreferences = await SharedPreferences.getInstance();
  final client = HttpAuthClient(
    client: http.Client(),
    sharedPreferences: sharedPreferences,
    refreshTokenUrl: (token, decodedToken) => 'https://example.com/refresh',
  );

  final response = await client.get('https://api.example.com/data');
  print(response.body);
}
```

## License

This package is licensed under the MIT License. See the LICENSE file for more information.
