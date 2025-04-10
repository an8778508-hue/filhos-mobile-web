import 'package:escola/core/components/buttons/button_with_icon.dart';
import 'package:escola/core/components/icons/common_image.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/constants/brazil_states.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:escola/core/utils/funuctions/global_functions.dart';
import 'package:escola/core/utils/safe_x.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/my_addresses/models/address_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AddressItem extends StatelessWidget {
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final AddressModel address;

  const AddressItem({
    required this.onEdit,
    required this.onDelete,
    super.key,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsetsDirectional.symmetric(horizontal: 15.w),
      decoration: BoxDecoration(
        color: context.colors.background,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 15.csh,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 25.csw),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CommonImage(
                      imageUrl: 'assets/icons/map.svg',
                    ),
                    SizedBox(
                      width: 10.csw,
                    ),
                    Text(
                      address.name ?? '',
                      style: TextStyle(
                        fontSize: 20.sp,
                        color: context.colors.primaryDark,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 10.csh,
                ),
                Text(
                  '${LocalizationKeys.address.tr(context)}: ${address.address ?? ''}',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: context.colors.warmGray,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                SizedBox(
                  height: 10.csh,
                ),
                Text(
                  '${LocalizationKeys.city.tr(context)}: ${isBrazilCountry(address.countryModel?.code) ? (address.city ?? (address.cityModel?.name ?? '')) : (address.cityModel?.name ?? (address.city ?? ''))}',
                  maxLines: 2,
                  style: TextStyle(
                    overflow: TextOverflow.ellipsis,
                    color: context.colors.warmGray,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                SizedBox(
                  height: 10.csh,
                ),
                Text(
                  '${(isBrazilCountry(address.countryModel?.code) ? LocalizationKeys.area : LocalizationKeys.region).tr(context)}: ${isBrazilCountry(address.countryModel?.code) ? (address.area ?? (address.regionModel?.name ?? '')) : (address.regionModel?.name ?? (address.brazil_state_code ?? ''))}',
                  maxLines: 2,
                  style: TextStyle(
                    overflow: TextOverflow.ellipsis,
                    color: context.colors.warmGray,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                SizedBox(
                  height: 10.csh,
                ),
                if (isBrazilCountry(address.countryModel?.code) && validString(BrazilStates.states.safeFirstWhere((element) => element.code == address.brazil_state_code)?.name)) ...[
                  Text(
                    '${LocalizationKeys.state.tr(context)}: ${BrazilStates.states.safeFirstWhere((element) => element.code == address.brazil_state_code)?.name}',
                    maxLines: 2,
                    style: TextStyle(
                      overflow: TextOverflow.ellipsis,
                      color: context.colors.warmGray,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  SizedBox(
                    height: 10.csh,
                  ),
                ],
                Text(
                  '${LocalizationKeys.complete_address.tr(context)}: ${address.complement ?? ''}',
                  maxLines: 2,
                  style: TextStyle(
                    overflow: TextOverflow.ellipsis,
                    color: context.colors.warmGray,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                SizedBox(
                  height: 10.csh,
                ),
                if (validString(address.zip_code)) ...[
                  Text(
                    '${LocalizationKeys.zip_code.tr(context)}: ${address.zip_code ?? ''}',
                    maxLines: 2,
                    style: TextStyle(
                      color: context.colors.warmGray,
                      overflow: TextOverflow.ellipsis,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  SizedBox(
                    height: 10.csh,
                  ),
                ],
                if (validString(address.countryModel?.phone_code))
                  Text(
                    '${LocalizationKeys.country_code.tr(context)}: ${address.countryModel?.phone_code ?? ''}',
                    maxLines: 2,
                    style: TextStyle(
                      color: context.colors.warmGray,
                      overflow: TextOverflow.ellipsis,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                SizedBox(
                  height: 10.csh,
                ),
                if (validString(address.countryModel?.name))
                  Text(
                    '${LocalizationKeys.country.tr(context)}: ${address.countryModel?.name ?? ''}',
                    maxLines: 2,
                    style: TextStyle(
                      overflow: TextOverflow.ellipsis,
                      color: context.colors.warmGray,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: 10.csh,
          ),
          Material(
            color: Colors.transparent,
            child: Row(
              children: [
                SizedBox(
                  width: 15.w,
                ),
                ButtonWithIcon(
                  onPressed: () {
                    onEdit.call();
                  },
                  firstIconPath: 'assets/icons/edit_thin.svg',
                  fontSize: 16.sp,
                  marginHeight: 0,
                  marginWidth: 0,
                  padding: EdgeInsets.zero,
                  firstIconHeight: 16.w,
                  firstIconWidth: 16.w,
                  text: (LocalizationKeys.edit).tr(context),
                  textColor: context.colors.warmGray,
                ),
                // ButtonWithIcon(
                //   onPressed: () {
                //     onDelete.call();
                //   },
                //   firstIconPath: 'assets/icons/trash.svg',
                //   fontSize: 14.sp,
                //   padding: EdgeInsets.symmetric(vertical: 10),
                //   firstIconHeight: 16.w,
                //   firstIconWidth: 16.w,
                //   marginWidth: 0,
                //   marginHeight: 0,
                //   text: (LocalizationKeys.trash).tr(context),
                //   textColor: context.colors.warmGray,
                // ),
                SizedBox(
                  width: 15.w,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 15.csh,
          ),
        ],
      ),
    );
  }
}
