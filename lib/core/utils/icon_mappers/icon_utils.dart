import 'package:recase/recase.dart';

String replaceIcon(String icon) {
  if (icon.startsWith('fas')) {
    icon = icon.replaceFirst('fas', '').trim();
  }
  if (icon.startsWith('far')) {
    icon = icon.replaceFirst('far', '').trim();
  }
  if (icon.startsWith('fab')) {
    icon = icon.replaceFirst('fab', '').trim();
  }
  if (icon.startsWith('fa')) {
    icon = icon.replaceFirst('fa', '').trim();
  }
  if (icon.startsWith('line')) {
    icon = icon.replaceFirst('line', '').trim();
  }
  if (icon.startsWith('-')) {
    icon = icon.replaceFirst('-', '').trim();
  }
  if (icon.contains('material')) {
    icon = icon.replaceAll('material', '').trim();
    return icon;
  }
  ReCase rc = ReCase(icon);
  icon = rc.camelCase;
  return icon;
}
