import 'package:escola/core/config/app_info.dart';
import 'package:escola/core/config/langs.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/home/models/card_model.dart';
import 'package:escola/features/home/models/section_model.dart';
import 'package:escola/flavors/app_flavors.dart';
import 'package:escola/my_app.dart';

import 'cubit/cubit.dart';
import 'onboard.dart';
import 'styling.dart';

class Config {
  static Config get get => di<ConfigCubit>().state;

  const Config(this.json);

  final Map<String, dynamic> json;

  static const String appUrl = "https://filhos.app";

  String? get logo => json['logo'];

  String? get login_background => json['login_background'];

  String? get logo_horizontal => json['logo_horizontal'];

  Styling get styling => Styling(validateMap(json['styling']));

  final _appInfoJson = const {
    "parent_app_info": {
      "app_name": "Criarte",
      "ios_url": "https://apps.apple.com/us/app/criarte/id6471106451",
      "android_url": "https://play.google.com/store/apps/details?id=com.algoriza.criarte",
      "privacy_url": "https://www.freeprivacypolicy.com/live/70869bc5-3768-4f7e-9419-f6fc9d5f85c1",
      "app_store_id": "6471106451",
    },
    "teacher_app_info": {
      "app_name": "Criarte Professores",
      "ios_url": "https://apps.apple.com/us/app/criarte-professores/id6471573321",
      "android_url": "https://play.google.com/store/apps/details?id=com.algoriza.profecriarte",
      "privacy_url": "https://www.freeprivacypolicy.com/live/6aa78462-f272-43f0-ae1f-56b628b3011f",
      "app_store_id": "6471573321",
    },
  };

  // todo
  AppInfo get appInfo => AppInfo(
      validateMap(_appInfoJson[mainKey.currentContext?.isProfessors == true ? 'teacher_app_info' : 'parent_app_info']));

  Map<String, dynamic> get translations => validateMap(json['translations']);

  // List<OnBoardModel> get onBoards =>
  //     validateDataList(json['onBoards'], (e) => OnBoardModel(e));

  List<OnBoardModel> get onBoards =>
      List<OnBoardModel>.from(json['onboards'].map((e) => OnBoardModel.fromJson(e)).toList());

  List<HomeCardModel> get homeCards {
    return validateDataList(json['home_cards'], (e) => HomeCardModel.fromJson(e));
  }

  List<SectionModel> get homeSections => [
        {
          "id": 1,
          "to": "timeline",
          "title": "timeline",
          "icon":
              "https://firebasestorage.googleapis.com/v0/b/escola-cede2.appspot.com/o/temp%2Fg4608%402x.png?alt=media&token=13dae3ad-c345-475a-815f-43ba43593c5b&_gl=1*wjkfm*_ga*MzEyMTMyMDI2LjE2OTYxNTMyOTU.*_ga_CW55HF8NVT*MTY5NzAxODgyOC4yNy4xLjE2OTcwMTg5NDQuMTIuMC4w"
        },
        {
          "id": 2,
          "to": "chats",
          "title": "chats",
          "icon":
              "https://firebasestorage.googleapis.com/v0/b/escola-cede2.appspot.com/o/temp%2Fchatting%402x.png?alt=media&token=9ead3cf4-8a9f-439b-9d7f-aee533941276&_gl=1*gz9pqn*_ga*MzEyMTMyMDI2LjE2OTYxNTMyOTU.*_ga_CW55HF8NVT*MTY5NzAxODgyOC4yNy4xLjE2OTcwMTg5NjYuNTEuMC4w"
        },
        {
          "id": 3,
          "to": "events",
          "title": "events",
          "icon":
              "https://firebasestorage.googleapis.com/v0/b/escola-cede2.appspot.com/o/temp%2FXMLID_306_%402x.png?alt=media&token=81a28d9c-0c07-4374-9df4-d88b1cd88970&_gl=1*m5f40x*_ga*MzEyMTMyMDI2LjE2OTYxNTMyOTU.*_ga_CW55HF8NVT*MTY5NzAxODgyOC4yNy4xLjE2OTcwMTg5OTAuMjcuMC4w"
        },
        {
          "id": 4,
          "to": "announcements",
          "title": "announcements",
          "icon":
              "https://firebasestorage.googleapis.com/v0/b/escola-cede2.appspot.com/o/temp%2FGroup%2010798%402x.png?alt=media&token=f08e8fe8-ae19-4d01-823a-d8406a3d9227"
        },
        {
          "id": 5,
          "to": "authorizations",
          "title": "authorizations",
          "icon":
              "https://firebasestorage.googleapis.com/v0/b/escola-cede2.appspot.com/o/temp%2FLayer_x0020_1%402x.png?alt=media&token=847de253-6e5c-418f-a0d2-a02b7b07c717&_gl=1*1nbi47c*_ga*MzEyMTMyMDI2LjE2OTYxNTMyOTU.*_ga_CW55HF8NVT*MTY5NzAxODgyOC4yNy4xLjE2OTcwMTkwNDEuNjAuMC4w"
        },
        {
          "id": 6,
          "to": "multimedia",
          "title": "multimedia",
          "icon":
              "https://firebasestorage.googleapis.com/v0/b/escola-cede2.appspot.com/o/temp%2FGroup%2010798%402x.png?alt=media&token=f08e8fe8-ae19-4d01-823a-d8406a3d9227"
        },
        {
          "id": 6,
          "to": "medicines",
          "title": "medicines",
          "icon":
              "https://firebasestorage.googleapis.com/v0/b/escola-cede2.appspot.com/o/temp%2Fg1071%402x.png?alt=media&token=9b82ebbb-0a97-4b35-807f-8b2ad2f43615&_gl=1*4jc4ml*_ga*MzEyMTMyMDI2LjE2OTYxNTMyOTU.*_ga_CW55HF8NVT*MTY5NzAxODgyOC4yNy4xLjE2OTcwMTg5NzcuNDAuMC4w"
        },
      ].map((e) => SectionModel.fromJson(e)).toList();

  List<LangsModel> get langs {
    //todo
    final list = validateDataList(json['languages'], (e) => LangsModel(e));
    if (validList(list)) return list;
    final fallback = json['fallbackLang'];
    if (validMap(fallback)) return [LangsModel(fallback)];

    return [
      const LangsModel({
        'code': 'pt',
        'name': 'Portuguese',
        'image':
            'https://firebasestorage.googleapis.com/v0/b/escola-cede2.appspot.com/o/images%2Fcriarte_parents%2Fbrazil-flag.png?alt=media&token=c01d9d38-63d4-44f8-ae28-179d72eb6e10&_gl=1*8qw95c*_ga*MzEyMTMyMDI2LjE2OTYxNTMyOTU.*_ga_CW55HF8NVT*MTY5NjE2MDQzOS4zLjEuMTY5NjE2MTA5OS43LjAuMA..',
        'textColor': '#04a558',
        'color': '#d7f9e9',
      }),
      const LangsModel({
        'code': 'en',
        'name': 'English',
        'image':
            'https://firebasestorage.googleapis.com/v0/b/escola-cede2.appspot.com/o/images%2Fcriarte_parents%2Fcdn.britannica.webp?alt=media&token=c1dc5480-3849-47f6-a81d-6c32b3a55ce3',
        'textColor': '#d80027',
        'color': '#ffe9ed',
      }),
    ];
  }

  List<BottomBarItemModel> get bottomBar => validateDataList(json['bottomBar'], (e) => BottomBarItemModel(e));
}

class BottomBarModel {
  const BottomBarModel(this.json);

  final Map<String, dynamic> json;

  List<BottomBarItemModel> get items => validateDataList(json['items'], (e) => BottomBarItemModel(e));
}

enum PageID { home, diary, events, settings }

class BottomBarItemModel {
  const BottomBarItemModel(this.json);

  final Map<String, dynamic> json;

  String get id => validateString(json['id']);

  String get translationKey => validateString(json['key']);

  String get title => validateString(json['title']);

  String get activeIcon => validateString(json['activeIcon']);

  String get inActiveIcon => validateString(json['inActiveIcon']);
}
