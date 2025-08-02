//buradaki IP'yi cmd'ye "ipconfig" yazdıktan sonra IPv4 adresindeki IP ile değiştirmeniz lazım


import 'package:flutter_dotenv/flutter_dotenv.dart';
String? get baseURL => dotenv.env['API_BASE_URL'];

// renk kodu 2D213B

//      python -m uvicorn main:app --host 0.0.0.0 --port 8080

// http://192.168.113.225:8080" eskisi