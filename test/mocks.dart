import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class MockSharedPreferences extends Mock implements SharedPreferences {}
class MockHttpClient extends Mock implements http.Client {}
