

import 'package:flutter_dotenv/flutter_dotenv.dart';

String? get baseURL => dotenv.env['API_BASE_URL'];
