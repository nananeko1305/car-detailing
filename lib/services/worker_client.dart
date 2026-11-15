import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// The push worker (see push_worker/). Its address is no secret: without the
/// ID token of an active account it does nothing.
const pushWorkerUrl = 'https://car-detailing-push.car-expenses.workers.dev';

/// Asks the worker to tell everyone about one job, as the signed-in account,
/// and returns the status it answered with. Which answer comes back makes
/// little difference: a job stays unannounced until the worker marks it, so
/// it is asked again on the next start.
Future<int> announceJob(String id) async {
  final token = await FirebaseAuth.instance.currentUser?.getIdToken();
  if (token == null) return HttpStatus.unauthorized;
  final response = await http
      .post(
        Uri.parse('$pushWorkerUrl/announce'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'kind': 'job', 'id': id}),
      )
      .timeout(const Duration(seconds: 20));
  return response.statusCode;
}
