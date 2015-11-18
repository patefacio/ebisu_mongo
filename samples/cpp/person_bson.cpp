#define TRACE(...)
using Date_t = int;

#include "ebisu/utils/block_indenter.hpp"
#include "ebisu/utils/streamers/vector.hpp"
#include "mongo/client/dbclient.h"
#include <iosfwd>
#include <string>
#include <vector>

namespace config {
namespace users {

template <typename BUILDER, typename T>
inline BUILDER& to_bson(BUILDER& builder, T const& item) {
  builder << item;
  return builder;
}

template <typename BUILDER>
inline BUILDER& to_bson(BUILDER& builder, bson::bo const& object) {
  builder << object;
  return builder;
}

template <typename BUILDER, typename T>
inline void to_bson(BUILDER& builder, std::vector<T> const& items) {
  mongo::BSONArrayBuilder array_builder;
  for (auto const& item : items) {
    bson::bob element_builder;
    array_builder.append(to_bson(element_builder, item));
  }
}

struct Address {
  Address() = default;

  Address(std::string const& street, std::string const& zipcode,
          std::string const& state, mongo::OID const& oid = mongo::OID())
      : street(street), zipcode(zipcode), state(state), oid_(oid) {}

  Address& operator=(Address const&) = default;

  friend inline std::ostream& operator<<(std::ostream& out,
                                         Address const& item) {
    out << "Address(" << &item << ") {";
    out << "\n  street:" << item.street;
    out << "\n  zipcode:" << item.zipcode;
    out << "\n  state:" << item.state;
    out << "\n}\n";
    return out;
  }

  bson::bo to_bson(bool exclude_oid = false) const {
    bson::bob builder;
    to_bson(builder, exclude_oid);
    return builder.obj();
  }

  void to_bson(bson::bob& builder__, bool exclude_oid = false) const {
    if (!exclude_oid) {
      if (!oid_.isSet()) {
        oid_.init();
      }
      builder__ << "_id" << oid_;
    }

    builder__ << "street" << street;
    builder__ << "zipcode" << zipcode;
    builder__ << "state" << state;
  }
  void from_bson(bson::bo const& bson_object) {
    bson::be bson_element;

    try {
      bson_element = bson_object.getField("street");
      if (bson_element.ok()) bson_element.Val(street);
      bson_element = bson_object.getField("zipcode");
      if (bson_element.ok()) bson_element.Val(zipcode);
      bson_element = bson_object.getField("state");
      if (bson_element.ok()) bson_element.Val(state);

    } catch (std::exception const& excp) {
      TRACE(
          "Failed to parse Address with exception: {}"
          " last read bson_element: {}",
          excp.what(), bson_element.jsonString(mongo::Strict, 1).c_str());
      throw;
    }
  }

  std::string street{};
  std::string zipcode{};
  std::string state{};

  //! getter for oid_ (access is Ro)
  mongo::OID const& oid() const { return oid_; }

 private:
  mutable mongo::OID oid_{};
};

struct Person {
  Person() = default;

  Person(std::string const& name, int32_t age, Date_t birth_date,
         Address address, std::vector<Person> children,
         std::vector<std::string> pet_names, std::vector<int32_t> pet_ages,
         mongo::OID const& oid = mongo::OID())
      : name(name),
        age(age),
        birth_date(birth_date),
        address(address),
        children(children),
        pet_names(pet_names),
        pet_ages(pet_ages),
        oid_(oid) {}

  Person& operator=(Person const&) = default;

  friend inline std::ostream& operator<<(std::ostream& out,
                                         Person const& item) {
    using ebisu::utils::streamers::operator<<;
    out << "Person(" << &item << ") {";
    out << "\n  name:" << item.name;
    out << "\n  age:" << item.age;
    out << "\n  birth_date:" << item.birth_date;
    out << "\n  address:" << item.address;
    out << "\n  children:" << item.children;
    out << "\n  pet_names:" << item.pet_names;
    out << "\n  pet_ages:" << item.pet_ages;
    out << "\n}\n";
    return out;
  }

  bson::bo to_bson(bool exclude_oid = false) const {
    bson::bob builder;
    to_bson(builder, exclude_oid);
    return builder.obj();
  }

  void to_bson(bson::bob& builder__, bool exclude_oid = false) const {
    if (!exclude_oid) {
      if (!oid_.isSet()) {
        oid_.init();
      }
      builder__ << "_id" << oid_;
    }

    builder__ << "name" << name;
    builder__ << "age" << age;
    builder__ << "birth_date" << birth_date;
    {
      mongo::BSONArrayBuilder array_builder(
          builder__.subarrayStart("children"));
      for (auto const& entry__ : children) {
        auto bson_object__ = entry__.to_bson();
        array_builder.append(bson_object__);
      }
    }
    {
      mongo::BSONArrayBuilder array_builder(
          builder__.subarrayStart("pet_names"));
      for (auto const& entry__ : pet_names) {
        array_builder.append(entry__);
      }
    }
    {
      mongo::BSONArrayBuilder array_builder(
          builder__.subarrayStart("pet_ages"));
      for (auto const& entry__ : pet_ages) {
        array_builder.append(entry__);
      }
    }
  }
  void from_bson(bson::bo const& bson_object) {
    bson::be bson_element;

    try {
      bson_element = bson_object.getField("name");
      if (bson_element.ok()) bson_element.Val(name);
      bson_element = bson_object.getField("age");
      if (bson_element.ok()) bson_element.Val(age);
      bson_element = bson_object.getField("birth_date");
      if (bson_element.ok()) bson_element.Val(birth_date);
      bson_element = bson_object.getField("address");
      if (bson_element.ok()) {
        address.from_bson(bson_element.Obj());
      } else {
        TRACE("Missing PodMember(Person :: address)");
      }
      {
        children.clear();
        bson_element = bson_object.getField("children");
        for (auto const& bson_arr_element__ : bson_element.Array()) {
          std::vector<Person>::value_type element;
          element.from_bson(bson_arr_element__.Obj());
          children.push_back(element);
        }
      }
      {
        pet_names.clear();
        bson_element = bson_object.getField("pet_names");
        for (auto const& bson_arr_element__ : bson_element.Array()) {
          std::string temp__;
          bson_arr_element__.Val(temp__);
          pet_names.push_back(temp__);
        }
      }
      {
        pet_ages.clear();
        bson_element = bson_object.getField("pet_ages");
        for (auto const& bson_arr_element__ : bson_element.Array()) {
          int32_t temp__;
          bson_arr_element__.Val(temp__);
          pet_ages.push_back(temp__);
        }
      }

    } catch (std::exception const& excp) {
      TRACE(
          "Failed to parse Address with exception: {}"
          " last read bson_element: {}",
          excp.what(), bson_element.jsonString(mongo::Strict, 1).c_str());
      throw;
    }
  }

  std::string name{};
  int32_t age{32};
  Date_t birth_date{};
  Address address{"foo", "bar", "goo"};
  std::vector<Person> children{};
  std::vector<std::string> pet_names{};
  std::vector<int32_t> pet_ages{};

  //! getter for oid_ (access is Ro)
  mongo::OID const& oid() const { return oid_; }

 private:
  mutable mongo::OID oid_{};
};

}  // namespace users
}  // namespace config

int main(int argc, char** argv) {

  using namespace config::users;

  Person p1;
  p1.name = "Dan";
  p1.birth_date = 132321;
  Person p2 { p1 };
  p2.name = "Karen";

  for(int i=0; i<10; i++) {
    Person p3;
    p3.name = "Ethan:";
    p3.name += std::to_string(i);
    p3.birth_date = i;
    p2.children.push_back(p3);
  }

  p2.pet_names.push_back("atlas");
  p2.pet_names.push_back("sadie");
  p2.pet_ages.push_back(3);
  p2.pet_ages.push_back(7);

  auto p2_bson = p2.to_bson();

  std::cout << "BSON OBJECT FOLLOWS: "
            << p2_bson.jsonString(mongo::Strict, 1) << std::endl;

  Person p3;
  p3.from_bson(p2_bson);

  std::cout << "Reserialized person: " << p3 << std::endl;

  return 0;
}
