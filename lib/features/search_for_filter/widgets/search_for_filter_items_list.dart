import 'package:escola/features/diary/models/school_item.dart';
import 'package:escola/features/search_for_filter/model/search_for_filter_model.dart';
import 'package:escola/features/search_for_filter/widgets/search_for_filter_list_item.dart';
import 'package:flutter/material.dart';

class SearchForFilterItemsList extends StatelessWidget {
  final List<SchoolItem> items;
  final Function(SchoolItem) onSearchForFilterItemsPressed;
  final SearchForFilterModelType searchModelType ;
  const SearchForFilterItemsList(
      {super.key,
      required this.items,
      required this.searchModelType,
      required this.onSearchForFilterItemsPressed,
      });

  @override
  Widget build(BuildContext context) {

    return Expanded(
      child: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          child: Column(
            children: [
              ListView.builder(
                  itemCount: items.length,
                  padding: EdgeInsets.zero,
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final isLast = index == items.length - 1;
                    final item = items[index];
                    return GestureDetector(
                      onTap: () {
                        onSearchForFilterItemsPressed(item);
                      },
                      child: SearchForFilterListItem(
                        item: item,
                        hasBorder: !isLast,
                      ),
                    );
                  }),
            ],
          ),
        ),
      ),
    );
  }
}
