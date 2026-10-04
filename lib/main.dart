import 'package:flutter/material.dart';

import 'state/app_store.dart';
import 'ui/study_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await AppStore.create();
  runApp(ArekaApp(store: store));
}
