import 'package:escola/core/components/empty/empty_widget.dart';
import 'package:escola/core/components/loading/loading.dart';
import 'package:escola/core/components/widgets/app_bar.dart';
import 'package:escola/core/components/widgets/pagination_widget.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/features/diary/models/child_model.dart';
import 'package:escola/features/diary/presentation/dairy_screen.dart';
import 'package:escola/features/settings/my_children/bloc/my_children_bloc.dart';
import 'package:escola/features/settings/my_children/bloc/my_children_events.dart';
import 'package:escola/features/settings/my_children/bloc/my_children_states.dart';
import 'package:escola/features/settings/my_children/widget/child_item.dart';
import 'package:escola/shared/assets/assets.gen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyChildrenScreen extends StatefulWidget {
  const MyChildrenScreen({
    super.key,
  });

  @override
  State<MyChildrenScreen> createState() => _MyChildrenScreenState();
}

class _MyChildrenScreenState extends State<MyChildrenScreen> {
  late final PaginationController<ChildModel> controller;

  @override
  void initState() {
    controller = PaginationController<ChildModel>(getNextPage: (context, page) {
      context.read<MyChildrenBloc>().add(FetchMyChildren(page));
    });
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.scaffold,
      appBar: MyAppBar(
        title: LocalizationKeys.my_children.tr(context),
        hasNotification: true,
      ),
      body: BlocProvider<MyChildrenBloc>(
        create: (BuildContext context) => di<MyChildrenBloc>()..add(const FetchMyChildren(1)),
        child: Builder(
          builder: (context) {
            return BlocConsumer<MyChildrenBloc, MyChildrenStates>(
              listener: (context, state) {
                if (!state.childrenState.loading && state.childrenState.error == null) {
                  controller.addPage(state.childrenState.data);
                }
              },
              builder: (context, state) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 15.h),
                  Expanded(
                    child: PaginationWidget<ChildModel>(
                      controller: controller,
                      error: state.childrenState.error?.message,
                      loadingWidget: const Loading(),
                      isLoading: state.childrenState.loading,
                      itemBuilder: (context, item, index) {
                        final child = item;
                        return ChildItem(
                          imageUrl: child.avatar ?? '',
                          title: child.name ?? '',
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => DiaryScreen(child: child)));
                          },
                          subTitle: child.classRoom ?? '',
                        );
                      },
                      emptyWidget: Center(
                        child:
                            EmptyWidget(title: LocalizationKeys.no_children.tr(context), icon: Assets.icons.child.path),
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
