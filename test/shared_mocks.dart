import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

@GenerateMocks([SharedPreferences], customMocks: [MockSpec<http.Client>(as: #MockHttpClient)])
void main(){}