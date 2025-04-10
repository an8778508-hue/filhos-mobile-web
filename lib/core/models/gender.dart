enum Gender { male, female }

extension FromGenderToString on Gender? {
  String toStringType() {
    if (this == Gender.female) {
      return "female";
    }
    return "male";
  }
}

extension FromStringToGender on String? {
  Gender toGender() {
    if (this == "female") {
      return Gender.female;
    }
    return Gender.male;
  }
}
