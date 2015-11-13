library ebisu_mongo.mongo_cpp;

import 'package:ebisu/ebisu.dart';
import 'package:ebisu_cpp/ebisu_cpp.dart';
import 'package:id/id.dart';
import 'pod.dart';

// custom <additional imports>
// end <additional imports>

/// Support for generating the c++ class for a Pod
class PodClass {
  PodObject podObject;

  // custom <class PodClass>

  PodClass(this.podObject);

  get podClass => class_(podObject.id)
    ..isStruct = true
    ..isStreamable = true
    ..defaultCtor.usesDefault = true
    ..assignCopy.usesDefault = true
    ..usesStreamers = podObject.hasArray
    ..members = podObject.podFields.map((pf) => _makeMember(pf)).toList()
    ..addFullMemberCtor();

  Member _makeMember(PodField podField) => member(podField.id)
    ..type = getCppType(podField.podType)
    ..init = podField.defaultValue
    ..cppAccess = public;

  // end <class PodClass>

  Class _class;
}

class PodHeader {
  Id get id => _id;
  List<Pod> pods = [];
  Namespace namespace;

  // custom <class PodHeader>

  PodHeader(this._id, [this.pods, this.namespace]);

  toString() => brCompact([
        'namespace $namespace {',
        indentBlock(
            brCompact(['PodHeader($id)', indentBlock(brCompact(pods))])),
        '}'
      ]);

  Header get header {
    if (_header == null) {
      final allPods = new Set<PodObject>();
      pods.forEach((pod) => _collectPods(pod, allPods));

      _header = new Header(id)
        ..namespace = namespace
        ..classes =
            allPods.toList().reversed.map((p) => new PodClass(p).podClass).toList();

      if (allPods.any((p) => p.hasArray)) {
        _header.includes
            .addAll(['vector', 'ebisu/utils/streamers/vector.hpp',]);
      }
    }
    return _header;
  }

  Set _collectPods(PodObject podObject, Set<PodObject> uniquePods) {
    if (!uniquePods.contains(podObject)) {
      uniquePods.add(podObject);
      for (PodField podField in podObject.podFields) {
        final p = podField.podType;
        if (p is PodObject) {
          _collectPods(p, uniquePods);
        } else if (p is PodArray && p.referredType is PodObject) {
          _collectPods(p.referredType, uniquePods);
        }
      }
    }
  }

  // end <class PodHeader>

  Id _id;
  Header _header;
}

// custom <library mongo_cpp>

PodHeader podHeader(id, [List<Pod> pods, Namespace namespace]) =>
    new PodHeader(makeId(id), pods, namespace);

final _bsonToCpp = {
  bsonDouble: 'double',
  bsonString: 'std::string',
  bsonObject: null,
  bsonArray: null,
  bsonBinaryData: null,
  bsonObjectId: 'Object_id_t',
  bsonBoolean: 'bool',
  bsonDate: 'Date_t',
  bsonNull: null,
  bsonRegex: 'Regexp_t',
  bsonInt32: 'int32_t',
  bsonInt64: 'int64_t',
  bsonTimestamp: 'Timestamp_t',
};

String getCppType(PodType podType) {
  final bsonType = podType.bsonType;
  String result;
  if (bsonType == bsonObject) {
    result = podType.id.capCamel;
  } else if (bsonType == bsonArray) {
    result = 'std::vector<${getCppType(podType.referredType)}>';
  } else {
    result = _bsonToCpp[bsonType];
  }
  return result;
}

// end <library mongo_cpp>
