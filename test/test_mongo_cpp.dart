library ebisu_mongo.test_mongo_cpp;

import 'package:logging/logging.dart';
import 'package:test/test.dart';

// custom <additional imports>

import 'package:ebisu_cpp/ebisu_cpp.dart';
import '../lib/pod.dart';
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

  final address = podObject('address')
    ..podFields = [
      podField('street', bsonString),
      podField('zipcode', bsonString),
      podField('state', bsonString),
    ];

  final person = podObject('person');

  person
    ..podFields = [
      podField('name', bsonString),
      podField('age', bsonInt32)..defaultValue = 32,
      podField('birth_date', bsonDate),
      podField('address', address)..defaultValue = '"foo", "bar", "goo"',
      podArrayField('children', person),
      podArrayField('pet_names', bsonString),
      podArrayField('pet_ages', bsonInt32),
    ];

  final personHeader = podHeader('person')
    ..pods = [person]
    ..namespace = namespace(['config', 'users']);

  print(clangFormat(personHeader.header.contents));

// end <main>
}
