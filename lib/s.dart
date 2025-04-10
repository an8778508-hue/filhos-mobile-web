main(){
  print(simplifyNumber('1900'));
}

String simplifyNumber(String numberString) {
  final numberInt = int.tryParse(numberString);
  if (numberInt == null) {
    return numberString;
  }
  const million = 1000000;
  const thousand = 1000;
  if (numberInt > million) {
    final number = numberInt / million;
    String numberString = '$number';
    if(number % 100 == 0){
      numberString = number.toStringAsFixed(2);
    }
    if(number % 10 == 0){
      numberString = number.toStringAsFixed(1);
    }
    return '$numberString M';
  }
  if (numberInt > thousand) {
    final number = numberInt / thousand;
    String numberString = '$number';
    if(number % 100 == 0){
      numberString = number.toStringAsFixed(2);
    }
    if(number % 10 == 0){
      numberString = number.toStringAsFixed(1);
    }
    return '$numberString K';
  }

  return numberString;
}