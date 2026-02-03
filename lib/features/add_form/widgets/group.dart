import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/features/add_form/add_form_screen.dart';
import 'package:escola/features/add_form/models/group_model.dart';
import 'package:flutter/material.dart';
import 'package:separated_column/separated_column.dart';

class GroupWidget extends StatelessWidget {
  const GroupWidget({
    super.key,
    required this.model,
  });

  final GroupFormModel model;

  @override
  Widget build(BuildContext context) {
    final fields = model.items;
    return SeparatedColumn(
      separatorBuilder: (context, index) => SizedBox(height: 12.csh),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: getFields(context, fields),
    );
  }
}
