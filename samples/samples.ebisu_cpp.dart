import 'dart:io';
import 'package:ebisu_cpp/ebisu_cpp.dart';
import 'package:ebisu_mongo/mongo_cpp.dart';
import 'package:ebisu_pod/pod.dart';
import 'package:id/id.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';

main() {

  Logger.root
    ..onRecord.listen((LogRecord r) =>
        print("${r.loggerName} [${r.level}]:\t${r.message}"))
    ..level = Level.OFF;

  final address = podObject('address')
    ..podFields = [
      podField('street', podString),
      podField('zipcode', podString),
      podField('state', podString),
    ];

  final person = podObject('person');

  person
    ..podFields = [
      podField('name', podString),
      podField('age', podInt32)..defaultValue = 32,
      podField('birth_date', podDate),
      podField('address', address)..defaultValue = '"foo", "bar", "goo"',
      podArrayField('children', person),
      podArrayField('pet_names', podString),
      podArrayField('pet_ages', podInt32),
    ];

  final ns = namespace(['samples', 'person_sample']);
  final configNamespace = namespace(['config', 'users']);

  final personHeader = podHeader('person')
    ..pods = [person]
    ..namespace = configNamespace;

  final personSample = new Installation(new Id('person_sample'))
    ..includeStackTrace = false
    ..rootFilePath = join(dirname(Platform.script.toFilePath()))
    ..apps = [
      app('person_sample')
      ..namespace = ns
      ..headers = [ personHeader.header ]
    ];

  personSample.generate(generateBuildScripts:true);
}
