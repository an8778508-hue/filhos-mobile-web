import 'package:escola/core/components/fields/selectable_base_item.dart';
import 'package:escola/features/add_address/models/city_model.dart';
import 'package:flutter/material.dart';

class AddressCityItem extends StatelessWidget {
  const AddressCityItem({super.key, this.selected, required this.model});
  final CityModel? selected ;
  final CityModel model ;

  @override
  Widget build(BuildContext context) {
    bool isSelected = (selected?.id == model.id && model.id.isNotEmpty);

    return SelectableBaseItem<CityModel>(isSelected: isSelected, title: model.name,model: model,);
  }
}
