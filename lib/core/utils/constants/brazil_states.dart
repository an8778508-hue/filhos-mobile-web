class BrazilStates{
  static  List<BrazilStatesModel> states = [
    BrazilStatesModel(code: 'AC', name: 'Acre'),
    BrazilStatesModel(code: 'AL', name: 'Alagoas'),
    BrazilStatesModel(code: 'AP', name: 'Amapa'),
    BrazilStatesModel(code: 'AM', name: 'Amazonas'),
    BrazilStatesModel(code: 'BA', name: 'Bahia'),
    BrazilStatesModel(code: 'CE', name: 'Ceara'),
    BrazilStatesModel(code: 'DF', name: 'Distrito Federal'),
    BrazilStatesModel(code: 'ES', name: 'Espírito Santo'),
    BrazilStatesModel(code: 'GO', name: 'Goias'),
    BrazilStatesModel(code: 'MA', name: 'Maranhao'),
    BrazilStatesModel(code: 'MT', name: 'Mato Grosso'),
    BrazilStatesModel(code: 'MS', name: 'Mato Grosso do Sul'),
    BrazilStatesModel(code: 'MG', name: 'Minas Gerais'),
    BrazilStatesModel(code: 'PA', name: 'Para'),
    BrazilStatesModel(code: 'PB', name: 'Paraíba'),
    BrazilStatesModel(code: 'PR', name: 'Parana'),
    BrazilStatesModel(code: 'PE', name: 'Pernambuco'),
    BrazilStatesModel(code: 'PI', name: 'Piaui'),
    BrazilStatesModel(code: 'RJ', name: 'Rio de Janeiro'),
    BrazilStatesModel(code: 'RN', name: 'Rio Grande do Norte'),
    BrazilStatesModel(code: 'RS', name: 'Rio Grande do Sul'),
    BrazilStatesModel(code: 'RO', name: 'Rondonia'),
    BrazilStatesModel(code: 'RR', name: 'Roraima'),
    BrazilStatesModel(code: 'SC', name: 'Santa Catarina'),
    BrazilStatesModel(code: 'SP', name: 'Sao Paulo'),
    BrazilStatesModel(code: 'SE', name: 'Sergipe'),
    BrazilStatesModel(code: 'TO', name: 'Tocantins'),
  ];
}

class BrazilStatesModel {
  final String code;
  final String name;

  BrazilStatesModel({required this.code,required this.name});
}