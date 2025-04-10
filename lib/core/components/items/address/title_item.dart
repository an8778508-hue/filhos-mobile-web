import 'package:escola/core/components/fields/selectable_base_item.dart';
import 'package:escola/features/add_address/models/country_model.dart';
import 'package:escola/features/settings/edit_profile/models/title_model.dart';
import 'package:flutter/material.dart';

class TitleItem extends StatelessWidget {
  const TitleItem({Key? key, this.selected, required this.model}) : super(key: key);
  final TitleModel? selected ;
  final TitleModel model ;

  @override
  Widget build(BuildContext context) {
    bool isSelected = (selected?.id == model.id && model.id.isNotEmpty);

    return SelectableBaseItem<TitleModel>(isSelected: isSelected, title: model.name,model: model,);
  }
}
