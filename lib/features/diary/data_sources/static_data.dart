import 'package:escola/core/models/gender.dart';
import 'package:escola/features/diary/models/activities.dart';
import 'package:escola/features/diary/models/category_menu_item.dart';
import 'package:escola/features/diary/models/child_model.dart';
import 'package:escola/features/diary/models/professor.dart';
import 'package:escola/features/diary/models/question_category.dart';
import 'package:escola/features/diary/models/questions_models/check_question.dart';
import 'package:escola/features/diary/models/questions_models/duration_question.dart';
import 'package:escola/features/diary/models/questions_models/image_question.dart';
import 'package:escola/features/diary/models/questions_models/info_question.dart';
import 'package:escola/features/diary/models/questions_models/question.dart';
import 'package:escola/features/diary/models/questions_models/rating_question.dart';

abstract class StaticActvities {
  static List<Activity> activities = [
    Activity(
      // id: 1,
      childModel: child,
      questionCategories: [
        questionCategory1,
        questionCategory2,
        questionCategory3,
        questionCategory5,
        questionCategory6,
      ],
      professor: professor,
      fromDate: DateTime.now(),
      date: DateTime.now(),
      toDate: DateTime.now().add(const Duration(hours: 4)),
    )
  ];

  static ChildModel child = const ChildModel(
    id: 1,
    name: "Yara",
    age: "24",
    classRoom: "Grad 1",
    parent: null,
    avatar: "https://cdn4.iconfinder.com/data/icons/avatars-xmas-giveaway/128/girl_avatar_child_kid-512.png",
  );

  static Professor professor = const Professor(id: 1, name: "Professor Ahmed", gender: Gender.male, avatar: null
      // "https://cdn0.iconfinder.com/data/icons/education-and-school-flat-1/128/man_old_teacher_professor_teach_leader_avatar-512.png",
      );

  static List<Question> questions = [
    const CheckQuestion(id: 1, title: "Presença", value: "YES"),
    const RatingQuestion(
      id: 1,
      label: 'Lunch Da Manhã ',
      subtitle: 'Tudo',
      rating: 3,
    ),
    const InfoQuestion(
      id: 1,
      info: 'Fizemos salada de frutas',
    ),
    const DurationQuestion(id: 1, label: "Dormiu as", duration: "30:15"),
    const ImagesQuestion(
      id: 1,
      label: "Momentos no Parque",
      images: [
        "https://daily.jstor.org/wp-content/uploads/2015/07/school_1050x700.jpg",
        "https://daily.jstor.org/wp-content/uploads/2015/07/school_1050x700.jpg",
        "https://daily.jstor.org/wp-content/uploads/2015/07/school_1050x700.jpg",
        "https://daily.jstor.org/wp-content/uploads/2015/07/school_1050x700.jpg",
      ],
    )
  ];

  static QuestionCategory questionCategory1 = QuestionCategory(
    statusType: "attendance",
    id: 1,
    title: "ChamAda",
    icon: "assets/icons/food_icon.svg",
    questions: [questions[0]],
    type: null,
    value: null,
  );

  static QuestionCategory questionCategory2 = QuestionCategory(
    id: 2,
    statusType: "attendance",
    title: "REFEIÇÕES",
    icon: "assets/icons/food_icon.svg",
    questions: [questions[1]],
    type: null,
    value: null,
  );
  static QuestionCategory questionCategory3 = QuestionCategory(
    id: 3,
    title: "INFORMAÇÃO",
    statusType: "attendance",
    icon: "assets/icons/food_icon.svg",
    questions: [questions[2]],
    type: null,
    value: null,
  );

  static QuestionCategory questionCategory5 = QuestionCategory(
    id: 4,
    title: "SONINHO",
    statusType: "attendance",
    icon: "assets/icons/food_icon.svg",
    questions: [questions[3]],
    type: null,
    value: null,
  );

  static QuestionCategory questionCategory6 = QuestionCategory(
    id: 5,
    statusType: "attendance",
    title: "BERÇÁRIO",
    icon: "assets/icons/food_icon.svg",
    questions: [questions[4]],
    type: null,
    value: null,
  );

  static Menu menu1 = const Menu(
    title: "Lanche da manha",
    items: ["Roda da fruta"],
  );

  static Menu menu2 = const Menu(
    title: "Almoco",
    items: ["Arroz", "Feijao", "peixe ensopado"],
  );

  static Menu menu3 = const Menu(
    title: "Jantar",
    items: ["Sopa de feiiao", "Arroz", "Feijao", "peixe ensopado"],
  );
}
