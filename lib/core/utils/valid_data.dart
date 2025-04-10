bool validBool(dynamic o) => o != null && o is bool;

bool validInt(dynamic o, [int? min]) => o != null && o is int && ((min != null) ? o > min : true);

bool validDouble(dynamic o, [double? min]) => o != null && o is double && ((min != null) ? o > min : true);

bool checkMinimum(String? value, int min) {
  value = convertSpace(value ?? '');
  return value.length >= min;
}

String convertSpace(String value) => value
    .replaceAll(String.fromCharCode(8206), ' ')
    .replaceAll(String.fromCharCode(8207), ' ')
    .replaceAll(String.fromCharCode(32), ' ');

bool validString(dynamic o, [List<String> blacklist = const []]) =>
    o != null && o is String && o.isNotEmpty && o != 'null' && !blacklist.contains(o);

bool validList<T>(dynamic o) => o != null && o is List<T> && o.isNotEmpty;

bool validMap<K, V>(dynamic o) => o != null && o is Map<K, V> && o.isNotEmpty;

bool stringNotNullOrEmpty(String? s) => s != null && s.isNotEmpty;

bool validateBool(dynamic o, [bool def = false, bool Function(dynamic o)? validator]) =>
    (validator?.call(o) ?? validBool(o) ? o : def);

int validateInt(dynamic o, [int def = 0, bool Function(dynamic o)? validator]) =>
    (validator?.call(o) ?? validInt(o) ? o : def);

double validateDouble(dynamic o, [double def = 0.0, bool Function(dynamic o)? validator]) =>
    (validator?.call(o) ?? validDouble(o) ? o : def);

String validateString(dynamic o, [String def = '', bool Function(dynamic o)? validator]) =>
    (validator?.call(o) ?? validString(o) ? o : def);

List<T> validateList<T>(dynamic o, [List<T> def = const [], bool Function(dynamic o)? validator]) =>
    (validator?.call(o) ?? validList(o) ? o : def);

Map<K, V> validateMap<K, V>(dynamic o, [Map<K, V> def = const {}, bool Function(dynamic o)? validator]) =>
    (validator?.call(o) ?? validMap(o) ? o : def);

bool isSuccess(dynamic o) => o?.toString() == 'true' || o?.toString() == '1';

bool isAssetImage(String imageUrl) =>
    (imageUrl.endsWith('.png') ||
        imageUrl.endsWith('.jpg') ||
        imageUrl.endsWith('.jpeg') ||
        imageUrl.endsWith('.webp')) &&
    imageUrl.startsWith("assets");

bool endsWithImageExtenstion(String imageUrl) => (imageUrl.endsWith('.png') ||
    imageUrl.endsWith('.jpg') ||
    imageUrl.endsWith('.jpeg') ||
    imageUrl.endsWith('.webp'));

double convertToDouble(dynamic o, [double def = 0.0]) =>
    validateDouble(double.tryParse(validateString(o?.toString())), def);

int convertToInt(dynamic o, [int def = 0]) => validateInt(int.tryParse(validateString(o?.toString())), def);

List<T> validateDataList<T>(dynamic o, T Function(Map<String, dynamic> e) builder) {
  if (o != null && o is List) {
    final filtered = [...o.where((e) => e != null && e is Map<String, dynamic>)];
    return filtered.map((e) => builder(e)).toList();
  }
  return [];
}

T? validateDataModel<T>(dynamic o, T Function(Map<String, dynamic> e) builder) {
  if (validMap(o)) {
    return builder(o);
  }
  return null;
}

bool validateMobile(String value) {
  String pattern = r'(^(?:[+0]9)?[0-9]{10,12}$)';
  RegExp regExp = RegExp(pattern);
  return regExp.hasMatch(convertSpace(value));
}

bool isHttpLink(String link) {
  return link.contains("http");
}

bool isImage(String extension) => [
      'jpg',
      'jpeg',
      'png',
      'webp',
      'gif',
    ].any((e) => extension.toLowerCase() == e);

bool isVideo(String extension) => [
      'mp4',
      'avi',
      'mov',
      'wmv',
      'flv',
      '3gp',
      'mkv',
    ].any((e) => extension.toLowerCase() == e);

// getFirstName
String getFirstName(String name) {
  if (name.contains(" ")) {
    return name.split(" ")[0];
  } else {
    return name;
  }
}
