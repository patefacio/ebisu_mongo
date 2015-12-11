library ebisu_mongo.mongo_cpp;

import 'package:ebisu/ebisu.dart';
import 'package:ebisu_cpp/ebisu_cpp.dart';
import 'package:ebisu_pod/ebisu_pod.dart';
import 'package:id/id.dart';
import 'package:quiver/iterables.dart';

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

  get podType => podField.podType;
  get isArray => podField.podType.isArray;
  get isObject => podField.podType.isObject;

  toString() => '${cppMember.name}';

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
        ..members.add(member('oid')
          ..isStreamable = false
          ..isByRef = true
          ..access = ro
          ..type = 'mongo::OID'
          ..isMutable = true)
        ..memberCtors = [
          memberCtor(concat([
            _podMembers.map((pm) => pm.cppMember.id.snake),
            [memberCtorParm('oid')..defaultValue = 'mongo::OID()']
          ]))
        ];

      /// add to/from bson
      _class.withCustomBlock(clsPublic, (CodeBlock cb) {
        cb.snippets.addAll([toBson, fromBson]);
      });
    }

    return _class;
  }

  _createPodMembers() {
    assert(_podMembers.isEmpty);
    _podMembers = podObject.fields
        .where((f) => f is PodType)

        /// TODO: deal with PodTypeRef
        .map((PodField podField) =>
            new PodMember(podField, _makeMember(podField)))
        .toList();
  }

  String get toBson {
    return brCompact([
      '''
bson::bo to_bson(bool exclude_oid = false) const {
  bson::bob builder;
  to_bson(builder, exclude_oid);
  return builder.obj();
}

void to_bson(bson::bob &builder__, bool exclude_oid = false) const {
  if(!exclude_oid) {
    if(!oid_.isSet()) {
      oid_.init();
    }
    builder__ << "_id" << oid_;
  }

${brCompact(_podMembers.map((pm) => _streamMemberToBson(pm)))}

}
'''
    ]);
  }

  String _streamMemberToBson(PodMember pm) {
    final podType = pm.podField.podType;
    return podType is PodArray
        ? _streamMemberArrayToBson(pm)
        : podType is PodObject
            ? _streamMemberObjectToBson(pm)
            : _streamMemberScalarToBson(pm);
  }

  String _streamMemberScalarToBson(PodMember pm) =>
      'builder__ << "${pm.name}" << ${pm.vname};\n';

  String _streamArrayMemberToBson(PodType podType) => podType is PodObject
      ? '''
  auto bson_object__ = entry__.to_bson();
  array_builder.append(bson_object__);
'''
      : podType is PodArray
          ? throw 'Arrays may not nest be stored in arrays $podType'
          : 'array_builder.append(entry__);';

  String _streamMemberArrayToBson(PodMember pm) => brCompact([
        '''
{
  mongo::BSONArrayBuilder array_builder(builder__.subarrayStart("${pm.name}"));
  for(auto const& entry__ : ${pm.vname}) {
${_streamArrayMemberToBson((pm.podType as PodArray).referredType)}
  }
}
'''
      ]);

  String _streamMemberObjectToBson(PodMember pm) => '''
''';

  String get fromBson {
    return brCompact([
      '''
void from_bson(bson::bo const& bson_object) {
  bson::be bson_element;

  try {
${brCompact(_podMembers.map((pm) => _streamMemberFromBson(pm)))}
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

  String _streamMemberFromBson(PodMember pm) {
    return pm.isArray
        ? _streamMemberArrayFromBson(pm)
        : pm.isObject
            ? _streamMemberObjectFromBson(pm)
            : _streamMemberScalarFromBson(pm);
  }

  String _streamMemberScalarFromBson(PodMember pm) => brCompact([
        '''
    bson_element = bson_object.getField("${pm.name}");
    if(bson_element.ok()) bson_element.Val(${pm.vname});
'''
      ]);

  String _streamMemberArrayFromBson(PodMember pm) {
    final referredType = (pm.podType as PodArray).referredType;
    return brCompact([
      '''
{
  ${pm.vname}.clear();
  bson_element = bson_object.getField("${pm.name}");
  for(auto const& bson_arr_element__ : bson_element.Array()) {
''',
      (referredType is PodArray
          ? '''
    ${getCppType(pm.podType.referredType)} temp__;
    bson_arr_element__.Val(temp__);
    ${pm.vname}.push_back(temp__);
'''
          : '''
    ${pm.cppType}::value_type element;
    element.from_bson(bson_arr_element__.Obj());
    ${pm.vname}.push_back(element);
'''),
      '''
  }
}
'''
    ]);
  }

  String _streamMemberObjectFromBson(PodMember pm) => '''
bson_element = bson_object.getField("${pm.name}");
if(bson_element.ok()) {
  ${pm.vname}.from_bson(bson_element.Obj());
} else {
  TRACE("Missing PodMember(${_class.className} :: $pm)");
}
''';

  Member _makeMember(PodField podField) {
    return member(podField.id)
      ..type = getCppType(podField.podType)
      ..init = podField.defaultValue
      ..cppAccess = public;
  }

  // end <class PodClass>

  Class _class;
  List<PodMember> _podMembers = [];
}

/// Support for turning one or more PodPackages into C++ code definitions within a single header
class PodHeader {
  Id get id => _id;
  List<PodPackage> podPackages = [];
  Namespace namespace;

  // custom <class PodHeader>

  PodHeader(this._id, [this.podPackages, this.namespace]);

  toString() => brCompact([
        'namespace $namespace {',
        indentBlock(
            brCompact(['PodHeader($id)', indentBlock(brCompact(pods))])),
        '}'
      ]);

  Header get header {
    if (_header == null) {
      final allPods = concat(podPackages.map(
          (podPackage) => podPackage.allTypes.where((t) => t is PodObject)));

      _header = new Header(id)
        ..namespace = namespace
        ..includes.addAll(['mongo/client/dbclient.h'])
        ..getCodeBlock(fcbBeginNamespace).snippets.add(_helperCppFunctions)
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

  get _helperCppFunctions => '''

template < typename BUILDER, typename T >
inline BUILDER& to_bson(BUILDER &builder, T const& item) {
  builder << item;
  return builder;
}

template < typename BUILDER >
inline BUILDER& to_bson(BUILDER &builder, bson::bo const& object) {
  builder << object;
  return builder;
}

template < typename BUILDER, typename T >
inline void to_bson(BUILDER &builder, std::vector< T > const& items) {
  mongo::BSONArrayBuilder array_builder;
  for(auto const& item : items) {
    bson::bob element_builder;
    array_builder.append(to_bson(element_builder, item));
  }
}

''';

  // end <class PodHeader>

  Id _id;
  Header _header;
}

// custom <library mongo_cpp>

PodHeader podHeader(id, [List<Pod> pods, Namespace namespace]) =>
    new PodHeader(makeId(id), pods, namespace);

final _podScalarTypeToCpp = {
  Double: 'double',
  String: 'std::string',
  BinaryData: null,
  ObjectId: 'Object_id_t',
  Boolean: 'bool',
  Date: 'Date_t',
  Null: null,
  Regex: 'Regexp_t',
  Int32: 'int32_t',
  Int64: 'int64_t',
  Timestamp: 'Timestamp_t',
};

String getCppType(PodType podType) {
  String result;
  if (podType.isObject) {
    result = podType.id.capCamel;
  } else if (podType.isArray) {
    result = 'std::vector<${getCppType(podType.referredType)}>';
  } else {
    result = _podScalarTypeToCpp[podType];
  }
  return result;
}

// end <library mongo_cpp>
