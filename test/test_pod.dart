library ebisu_mongo.test_pod;

import 'package:logging/logging.dart';
import 'package:test/test.dart';

// custom <additional imports>

import 'package:ebisu/ebisu.dart';
import 'package:id/id.dart';
import 'package:ebisu/ebisu.dart';
import '../lib/pod.dart';

// end <additional imports>

final _logger = new Logger('test_pod');

// custom <library test_pod>
// end <library test_pod>

main([List<String> args]) {
  Logger.root.onRecord.listen(
      (LogRecord r) => print("${r.loggerName} [${r.level}]:\t${r.message}"));
  Logger.root.level = Level.OFF;
// custom <main>

  test('pod field', () {
    final int32Field = podField('int32', bsonInt32);
    print(int32Field);
  });

  test('pod', () {
    final address = podObject('address')
      ..podFields = [
        podField('street', bsonString),
        podField('zipcode', bsonString),
        podField('state', bsonString),
      ];

    print(address);

    final person = podObject('person');

    person
      ..podFields = [
        podField('name', bsonString),
        podField('age', bsonInt32)..defaultValue = 32,
        podField('birth_date', bsonDate),
        podField('address', address)..defaultValue = '"foo", "bar", "goo"',
        podArrayField('children', person)
      ];

    print(person);
  });

// end <main>
}
