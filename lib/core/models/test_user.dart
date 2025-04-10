import 'package:escola/core/models/user_model.dart';

abstract class TestUsers {
  static const teacher = UserModel(
    id: "86",
    name: "Test teacher",
    type: UserType.professor,
    phone: '12345678',
    image:
        'https://feeds.abplive.com/onecms/images/uploaded-images/2023/06/08/a35a3d554a77a855def7bbb99c985aa71686223967201557_original.png',
    email: '',
    classRoom: '',
    accessToken: '',
    isApproval: true,
    countryCode: '',
  );
  static const teacher2 = UserModel(
    id: "97",
    name: "ABDo teacher",
    type: UserType.professor,
    phone: '12345678',
    image:
        'https://feeds.abplive.com/onecms/images/uploaded-images/2023/06/08/a35a3d554a77a855def7bbb99c985aa71686223967201557_original.png',
    email: '',
    classRoom: '',
    accessToken: '',
    isApproval: true,
    countryCode: '',
  );
}
