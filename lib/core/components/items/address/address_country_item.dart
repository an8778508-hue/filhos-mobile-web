import 'package:escola/core/components/fields/selectable_base_item.dart';
import 'package:escola/features/add_address/models/country_model.dart';
import 'package:flutter/material.dart';

class AddressCountryItem extends StatelessWidget {
  const AddressCountryItem({Key? key, this.selected, required this.model}) : super(key: key);
  final CountryModel? selected ;
  final CountryModel model ;

  @override
  Widget build(BuildContext context) {
    bool isSelected = (selected?.id == model.id && model.id.isNotEmpty);

    return SelectableBaseItem<CountryModel>(isSelected: isSelected, title: model.name,model: model,);
  }
}
