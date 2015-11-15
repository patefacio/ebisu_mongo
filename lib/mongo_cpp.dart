library ebisu_mongo.mongo_cpp;

import 'package:ebisu/ebisu.dart';
import 'package:ebisu_cpp/ebisu_cpp.dart';
import 'package:id/id.dart';
import 'pod.dart';

// custom <additional imports>
// end <additional imports>

/// Joins the C++ [Member] and the [PodField]
class PodMember {
  const PodMember(this.podField, this.cppMember);

  final PodField podField;
  final Member cppMember;

  // custom <class PodMember>

  get name => cppMember.name;
  get vname => cppMember.vname;
  get cppType => cppMember.type;

  // end <class PodMember>

}

/// Support for generating the c++ class for a Pod
class PodClass {
  PodObject podObject;

  // custom <class PodClass>

  PodClass(this.podObject);

  get podClass {
    if (_class == null) {
      _createPodMembers();
      _class = class_(podObject.id)
        ..isStruct = true
        ..isStreamable = true
        ..defaultCtor.usesDefault = true
        ..assignCopy.usesDefault = true
        ..usesStreamers = podObject.hasArray
        ..members = _podMembers.map((pm) => pm.cppMember).toList()
        ..addFullMemberCtor();

      /// add to/from bson
      _class.withCustomBlock(clsPublic, (CodeBlock cb) {
        cb.snippets.addAll([toBson, fromBson]);
      });
    }

    return _class;
  }

  _createPodMembers() {
    assert(_podMembers.isEmpty);
    _podMembers = podObject.podFields
        .map((PodField podField) =>
            new PodMember(podField, _makeMember(podField)))
        .toList();
  }

  String get toBson {
    return brCompact(['bson::bo to_bson(bool exclude_oid = false) {', '}']);
  }

  String get fromBson {
    return brCompact([
      '''
void from_bson(bson::bo const& bson_object) {
  bson::be bson_element;

  try {
${brCompact(_podMembers.map((pm) => _streamMember(pm)))}
  } catch(std::exception const& excp) {
    TRACE("Failed to parse Address with exception: {}"
          " last read bson_element: {}",
           excp.what(),
           bson_element.jsonString(mongo::Strict, 1).c_str());
    throw;
  }
''',
      '}'
    ]);
  }

  String _streamMember(PodMember pm) {
    final podType = pm.podField.podType;
    return podType is PodScalar? _streamMemberScalarFromBson(pm) :
      podType is PodArray? _streamMemberArrayFromBson(pm) :
      podType is PodObject? _streamMemberObjectFromBson(pm) :
      throw 'Invalid PodType $podType';
  }

  String _streamMemberScalarFromBson(PodMember pm) =>
    brCompact([
      '''
    bson_element = bson_ojbect.getField("${pm.name}");
    if(bson_element.ok()) bson_element.Val(${pm.vname});
'''
    ]);

  String _streamMemberArrayFromBson(PodMember pm) =>
    brCompact([
      '''
{
  ${pm.vname}.clear();
  bson_element = bson_object.getField("${pm.name}");
  for(auto const& bson_arr_element__ : bson_element.Array()) {
    ${pm.cppType}::value_type element;
    element.from_bson(bson_arr_element__);
    ${pm.vname}.push_back(element);
  }
}
'''
    ]);

  String _streamMemberObjectFromBson(PodMember pm) =>
    '''
bson_element = bson_object.getField("${pm.name}");
${pm.vname}.from_bson(bson_element.Obj());
''';

  Member _makeMember(PodField podField) {
    return member(podField.id)
      ..type = getCppType(podField.podType)
      ..init = podField.defaultValue
      ..cppAccess = public;
  }

  // end <class PodClass>

  Class _class;
  Lis<PodMember> _podMembers = [];
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
        ..classes = allPods
            .toList()
            .reversed
            .map((p) => new PodClass(p).podClass)
            .toList();

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
