import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/features/add_form/add_form_screen.dart';
import 'package:escola/features/add_form/models/collection_model.dart';
import 'package:escola/features/add_form/widgets/forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:separated_column/separated_column.dart';

class CollectionWidget extends StatelessWidget {
  const CollectionWidget({
    Key? key,
    required this.model,
  }) : super(key: key);

  final CollectionFormModel model;

  @override
  Widget build(BuildContext context) {
    final fields = model.items;
    return FormCard(
      forceNotNested: true,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.csw, vertical: 30.h),
        child: SeparatedColumn(
          separatorBuilder: (context, index) => SizedBox(height: 13.csh),
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: getFields(context, fields),
        ),
      ),
    );
  }
}
