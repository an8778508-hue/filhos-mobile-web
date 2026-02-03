import 'package:escola/core/components/fields/selectable_base_item.dart';
import 'package:escola/core/utils/constants/brazil_states.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:flutter/material.dart';

class BrazilStateItem extends StatelessWidget {
  const BrazilStateItem({super.key, this.selected, required this.model});
  final BrazilStatesModel? selected ;
  final BrazilStatesModel model ;

  @override
  Widget build(BuildContext context) {
    bool isSelected = (selected?.code == model.code && model.code.isNotEmpty&& validString(selected?.code));

    return SelectableBaseItem<BrazilStatesModel>(isSelected: isSelected, title: model.name,model: model,);
  }
}
