library ebisu_mongo.test_mongo_cpp;

import 'package:logging/logging.dart';
import 'package:test/test.dart';

// custom <additional imports>

import 'package:ebisu_cpp/ebisu_cpp.dart';
import 'package:ebisu_pod/ebisu_pod.dart';
import 'package:ebisu_pod/example/balance_sheet.dart';
import '../lib/mongo_cpp.dart';

// end <additional imports>

final _logger = new Logger('test_mongo_cpp');

// custom <library test_mongo_cpp>
// end <library test_mongo_cpp>

main([List<String> args]) {
  Logger.root.onRecord.listen(
      (LogRecord r) => print("${r.loggerName} [${r.level}]:\t${r.message}"));
  Logger.root.level = Level.OFF;
// custom <main>

  final balanceSheetHeader = podHeader('balance_sheet')
    ..podPackages = [balanceSheet]
    ..namespace = namespace(['example']);

  print(clangFormat(balanceSheetHeader.header.contents));

// end <main>
}
