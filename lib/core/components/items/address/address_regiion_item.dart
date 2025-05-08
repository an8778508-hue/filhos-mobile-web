import 'package:escola/core/components/fields/selectable_base_item.dart';
import 'package:escola/features/add_address/models/region_model.dart';
import 'package:flutter/material.dart';

class AddressRegionItem extends StatelessWidget {
  const AddressRegionItem({Key? key, this.selected, required this.model}) : super(key: key);
  final RegionModel? selected ;
  final RegionModel model ;

  @override
  Widget build(BuildContext context) {
    bool isSelected = (selected?.id == model.id && model.id.isNotEmpty);

    return SelectableBaseItem<RegionModel>(isSelected: isSelected, title: model.name,model: model,);
  }
}
