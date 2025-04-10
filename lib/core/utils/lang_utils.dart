String parseLang(String code){
  if (code.contains('_')) {
    return code.split('_').first;
  } else {
    return code;
  }
}