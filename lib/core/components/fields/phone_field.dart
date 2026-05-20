import 'package:country_picker/country_picker.dart';
import 'package:escola/core/components/fields/custom_form_field.dart';
import 'package:escola/core/custom_packages/custom_phone_formatter.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/extensions/responsive_ext.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PhoneField extends StatefulWidget {
  final String? Function(String?)? validator;
  final Function(bool)? isCountryValid;
  final Function(String)? onChanged;

  final ValueChanged<Country> onCountrySelected;
  final TextEditingController phoneController;
  final bool readOnly;
  final double? strokeWidth;
  final Color? strokeColor, background;
  final Country country;
  final String? initial;
  final double marginErrorHeight;
  final double marginErrorWidthPercentage;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;

  const PhoneField({
    super.key,
    required this.validator,
    required this.phoneController,
    required this.onCountrySelected,
    required this.country,
    this.marginErrorWidthPercentage = 0.0,
    this.marginErrorHeight = 0.0,
    this.strokeWidth,
    this.padding,
    this.borderRadius = 0.0,
    this.initial,
    this.background,
    this.strokeColor,
    this.readOnly = false,
    this.isCountryValid,
    this.onChanged,
  });

  @override
  State<PhoneField> createState() => _PhoneFieldState();
}

class _PhoneFieldState extends State<PhoneField> {
  late Country _selectedDialogCountry;
  int? maskLength;
  late String hint;

  @override
  void initState() {
    _selectedDialogCountry = widget.country;
    hint = _getHintForCountry(widget.country.countryCode);

    super.initState();
  }
  String _getHintForCountry(String code) {
    // Return appropriate local format hints based on country code
    switch (code) {
    // Arabic countries
      case 'EG': // Egypt
        return '1282088582';
      case 'SA': // Saudi Arabia
        return '512345678';
      case 'AE': // United Arab Emirates
        return '501234567';
      case 'JO': // Jordan
        return '791234567';
      case 'KW': // Kuwait
        return '51234567';
      case 'BH': // Bahrain
        return '31234567';
      case 'QA': // Qatar
        return '33123456';
      case 'OM': // Oman
        return '91234567';

    // Common countries
      case 'US': // United States
        return '2015550123';
      case 'GB': // United Kingdom
        return '7700900123';
      case 'RU': // Russia
        return '9123456789';
      case 'IN': // India
        return '9123456789';
      case 'CN': // China
        return '1381234567';
      case 'BR': // Brazil
        return '11987654321';
      case 'DE': // Germany
        return '15123456789';
      case 'FR': // France
        return '612345678';
      case 'IT': // Italy
        return '3123456789';
      case 'JP': // Japan
        return '9012345678';
      case 'AU': // Australia
        return '412345678';
      case 'CA': // Canada
        return '2045550123';

    // Default case - return a generic example
      default:
        return 'phone number without country code';
    }
  }
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: CustomFormField(
        validator: widget.validator,
        initial: widget.initial,
        marginWidth: widget.marginErrorWidthPercentage,
        marginHeight: widget.marginErrorHeight,
        builder: (field) => Directionality(
          textDirection: TextDirection.ltr,
          child: FilledTextFiled(
            width: double.maxFinite,
            strokeColor: widget.strokeColor,
            padding: widget.padding,
            borderRadius: widget.borderRadius,
            strokeWidth: widget.strokeWidth,
            background: widget.background,
            child: Row(
              children: [
                GestureDetector(
                  onTap: widget.readOnly ? null : () => _onTap(),
                  child: _buildDropdownItem(_selectedDialogCountry, showDetails: true),
                ),
                Expanded(
                  child: TextField(
                    readOnly: widget.readOnly,
                    controller: widget.phoneController,
                    textInputAction: TextInputAction.done,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      CustomPhoneFormatter(
                        allowEndlessPhone: false,
                        onCountrySelected: (data) {
                          final correctMask = data?.getCorrectMask(_selectedDialogCountry.countryCode).length;
                          setState(() => maskLength = correctMask);
                        },
                        defaultCountryCode: _selectedDialogCountry.countryCode,
                      )
                    ],
                    onChanged: (value) {
                      field.didChange(value);
                      checkValidation(value);
                      if (widget.onChanged != null) {
                        widget.onChanged!(value);
                      }
                    },
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.sp, color: context.colors.textColor),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: hint,
                      hintStyle: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.grey.withOpacity(0.7),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 15.csw,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void checkValidation(value) {
    if (widget.isCountryValid != null) {
      if (maskLength == null) {
        widget.isCountryValid!(false);
      } else if ((maskLength!) <= (value.length)) {
        widget.isCountryValid!(true);
      } else {
        widget.isCountryValid!(false);
      }
    }
  }

  _onTap() {
    showCountryPicker(
      showPhoneCode: true,
      useSafeArea: true,
      exclude: ['IL'],
      // countryFilter: ['EG'],
      context: context,
      countryListTheme: CountryListThemeData(
        flagSize: 25.sp,
        margin: EdgeInsets.only(top: 90.csh),
        backgroundColor: context.colors.background,
        textStyle: TextStyle(fontSize: 16.sp, color: context.colors.primary),
        //Optional. Sets the border radius for the bottomsheet.
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(10.r),
          topRight: Radius.circular(10.r),
        ),
        //Optional. Styles the search field.
        inputDecoration: InputDecoration(
          hintText: LocalizationKeys.search_for_country_hint.tr(context),
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: context.colors.greyLighter,
            ),
          ),
        ),
      ),
      onSelect: (Country country) {
        widget.phoneController.text = "";
        widget.isCountryValid!(false);
        setState(() {
          _selectedDialogCountry = country;
          widget.onCountrySelected.call(country);
          maskLength = null;
          hint = _getHintForCountry(country.countryCode);
        });
      },
    );
  }

  Widget _buildDropdownItem(Country country, {bool showDetails = false}) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: showDetails ? MainAxisAlignment.start : MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 25.sp,
                  height: 25.sp,
                  alignment: Alignment.center,
                  child: Text(
                    country.flagEmoji,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 17.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 5.csw,
              ),
              if (showDetails) ...[
                Container(
                  alignment: Alignment.center,
                  child: Text(
                    "+${country.phoneCode} ",
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 15.sp,
                      color: context.colors.textColor,
                    ),
                  ),
                )
              ],
              if (showDetails) ...[
                Align(
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.keyboard_arrow_down_outlined,
                    color: context.colors.textColor,
                    size: 23.sp,
                  ),
                )
              ],
            ],
          ),
        ],
      );
}

class FilledTextFiled extends StatelessWidget {
  final Widget child;
  final double? width, height;
  final double? strokeWidth;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? strokeColor, background;

  const FilledTextFiled(
      {super.key,
      required this.child,
      this.width,
      this.strokeWidth,
      this.padding,
      this.borderRadius,
      this.strokeColor,
      this.background,
      this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
        width: width ?? 358.sp,
        // height: height ?? 56.sp,
        padding: padding ?? EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
            color: background ?? context.colors.background.withOpacity(0.06),
            borderRadius: BorderRadius.circular(borderRadius ?? 10.r),
            border: Border.all(color: strokeColor ?? context.colors.divider, width: strokeWidth ?? 1.sp)),
        child: Center(child: child));
  }
}
