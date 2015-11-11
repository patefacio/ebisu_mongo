import "dart:io";
import "package:path/path.dart" as path;
import "package:ebisu/ebisu.dart";
import "package:ebisu/ebisu_dart_meta.dart";
import "package:logging/logging.dart";

String _topDir;

final _logger = new Logger('ebisu_mongo');

void main() {
  Logger.root.onRecord.listen(
      (LogRecord r) => print("${r.loggerName} [${r.level}]:\t${r.message}"));
  String here = path.absolute(Platform.script.toFilePath());

  Logger.root.level = Level.OFF;

  final purpose = '''
A library that supports code generation of Angular2 code
''';

  _topDir = path.dirname(path.dirname(here));
  useDartFormatter = true;
  System ebisu = system('ebisu_mongo')
    ..includesHop = true
    ..license = 'boost'
    ..pubSpec.homepage = 'https://github.com/patefacio/ebisu_mongo'
    ..pubSpec.version = '0.0.1'
    ..pubSpec.doc = purpose
    ..rootPath = _topDir
    ..doc = purpose
    ..testLibraries = [
      library('test_pod'),
    ]
    ..libraries = [

      library('pod')
      ..includesLogger = true
      ..imports = [
        'package:ebisu/ebisu.dart',
        'package:id/id.dart',
      ]
      ..enums = [
        enum_('bson_type')
        ..hasLibraryScopedValues = true
        ..values = [
          'bson_double',
          'bson_string',
          'bson_object',
          'bson_array',
          'bson_binary_data',
          'bson_object_id',
          'bson_boolean',
          'bson_date',
          'bson_null',
          'bson_regex',
          'bson_int32',
          'bson_int64',
          'bson_timestamp',
        ]
      ]
      ..classes = [

        class_('pod_type')
        ..members = [
          member('bson_type')..type = 'BsonType',
        ],

        class_('pod_scalar')
        ..extend = 'PodType'
        ..members = [
        ],

        class_('pod_array')
        ..extend = 'PodType'
        ..members = [
          member('referred_type')..type = 'PodType',
        ],

        class_('pod_field')
        ..members = [
          member('id')..type = 'Id'..access = RO,
          member('is_index')
          ..doc = 'If true the field is defined as index'
          ..classInit = false,
          member('pod_type')..type = 'PodType',
          member('default_value')..type = 'dynamic',
        ],

        class_('pod_object')
        ..extend = 'PodType'
        ..members = [
          member('id')..type = 'Id'..access = RO,
          member('pod_fields')..type = 'List<PodField>'..classInit = [],
        ],

      ]
    ];


  ebisu.generate();

  _logger.warning('''
**** NON GENERATED FILES ****
${indentBlock(brCompact(nonGeneratedFiles))}
''');
}
