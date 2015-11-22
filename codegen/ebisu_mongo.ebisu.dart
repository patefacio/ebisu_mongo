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
Support for generating code providing mongo data access patterns.
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
      library('test_mongo_cpp'),
    ]
    ..libraries = [

      library('mongo_cpp')
      ..imports = [
        'package:ebisu_pod/pod.dart',
        'package:quiver/iterables.dart',
        'package:id/id.dart',
        'package:ebisu/ebisu.dart',
        'package:ebisu_cpp/ebisu_cpp.dart',
      ]
      ..classes = [

        class_('pod_member')
        ..doc = 'Joins the C++ [Member] and the [PodField]'
        ..isImmutable = true
        ..members = [
          member('pod_field')..type = 'PodField',
          member('cpp_member')..type = 'Member',
        ],

        class_('pod_class')
        ..doc = 'Support for generating the c++ class for a Pod'
        ..members = [
          member('pod_object')..type = 'PodObject',
          member('class')..type = 'Class'..access = IA,
          member('pod_members')..type = 'List<PodMember>'..classInit = []..access = IA,
        ],

        class_('pod_header')
        ..members = [
          member('id')..type = 'Id'..access = RO,
          member('pods')..type = 'List<Pod>'..classInit = [],
          member('namespace')..type = 'Namespace',
          member('header')..access = IA..type = 'Header',
        ],
      ],

      library('mongo_py'),

      library('mongo_dart'),

      library('mongo_capnp'),

    ];


  ebisu.generate();

  _logger.warning('''
**** NON GENERATED FILES ****
${indentBlock(brCompact(nonGeneratedFiles))}
''');
}
