import 'package:brasil_fields/brasil_fields.dart';
import 'package:escola/core/components/buttons/button_with_icon.dart';
import 'package:escola/core/components/fields/custom_text_field.dart';
import 'package:escola/core/components/fields/error_field.dart';
import 'package:escola/core/components/fields/selectable_field.dart';
import 'package:escola/core/components/fromatters/row_formatters.dart';
import 'package:escola/core/components/items/address/address_city_item.dart';
import 'package:escola/core/components/items/address/address_country_item.dart';
import 'package:escola/core/components/items/address/address_regiion_item.dart';
import 'package:escola/core/components/items/address/brazil_state_item.dart';
import 'package:escola/core/components/loading/loading_overlay.dart';
import 'package:escola/core/components/widgets/app_bar.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/constants/brazil_states.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/core/utils/funuctions/global_functions.dart';
import 'package:escola/core/utils/safe_x.dart';
import 'package:escola/core/utils/size_config.dart';
import 'package:escola/core/utils/valid_data.dart';
import 'package:escola/features/add_address/bloc/add_address_bloc.dart';
import 'package:escola/features/add_address/bloc/add_address_events.dart';
import 'package:escola/features/add_address/bloc/add_address_states.dart';
import 'package:escola/features/add_address/models/city_model.dart';
import 'package:escola/features/add_address/models/country_model.dart';
import 'package:escola/features/add_address/models/region_model.dart';
import 'package:escola/features/my_addresses/models/address_model.dart';
import 'package:escola/features/settings/edit_profile/widgets/edit_profile_field_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:search_cep/search_cep.dart';

enum AddressType { drop, pickup, both }

class AddAddressScreen extends StatefulWidget {
  const AddAddressScreen({
    super.key,
    this.addressModel,
  });

  final AddressModel? addressModel;

  @override
  State<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends State<AddAddressScreen> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController areaController;
  late final TextEditingController nameController;
  late final TextEditingController addressController;
  late final TextEditingController cityController;
  late final TextEditingController completeAddressController;
  late final TextEditingController cepController;
  late final ValueNotifier<BrazilStatesModel?> brazilStatesModel;
  late final ValueNotifier<String?> errorCep;
  late final ValueNotifier<bool> loadingCep;
   CityModel?chosenCityModel;
   RegionModel?chosenRegionModel;
  bool get isUpdate => widget.addressModel != null;

  @override
  void initState() {
    super.initState();
    areaController = TextEditingController(text: widget.addressModel?.regionModel?.name ?? '');
    nameController = TextEditingController(text: widget.addressModel?.name ?? '');
    addressController = TextEditingController(text: widget.addressModel?.address ?? '');
    cepController = TextEditingController(text: CepInputFormatter().formatEditUpdate(const TextEditingValue(text: ''),TextEditingValue(text:  widget.addressModel?.zip_code ?? '')).text);
    cityController = TextEditingController(text: widget.addressModel?.cityModel?.name ?? '');
    completeAddressController = TextEditingController(text: widget.addressModel?.complement ?? '');
    errorCep = ValueNotifier(null);
    loadingCep = ValueNotifier(false);
    BrazilStatesModel? model =
        BrazilStates.states.safeFirstWhere((element) => element.code == widget.addressModel?.brazil_state_code);
    brazilStatesModel = ValueNotifier(model);
    if(widget.addressModel?.cityModel != null) {
      chosenCityModel = widget.addressModel?.cityModel;
    }
    if(widget.addressModel?.regionModel != null) {
      chosenRegionModel = widget.addressModel?.regionModel;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    addressController.dispose();
    cepController.dispose();
    cityController.dispose();
    completeAddressController.dispose();
    errorCep.dispose();
    loadingCep.dispose();
    brazilStatesModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AddAddressBloc>(
      create: (BuildContext context) => di<AddAddressBloc>()..add(FetchCountries(addressModel: widget.addressModel)),
      child: Builder(
        builder: (context) {
          return MultiBlocListener(
            listeners: [
              BlocListener<AddAddressBloc, AddAddressStates>(
                listenWhen: (p, c) => p.submitAddressState.error != c.submitAddressState.error,
                listener: (BuildContext context, AddAddressStates state) async {
                  if (validString(state.submitAddressState.error)) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(state.submitAddressState.error!)));
                  }
                },
              ),
              BlocListener<AddAddressBloc, AddAddressStates>(
                listenWhen: (p, c) => p.submitAddressState.success != c.submitAddressState.success,
                listener: (BuildContext context, AddAddressStates state) async {
                  if (isUpdate) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        backgroundColor: context.colors.success,
                        content: Text(LocalizationKeys.address_updated_successfully.tr(context))));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        backgroundColor: context.colors.success,
                        content: Text(LocalizationKeys.address_added_successfully.tr(context))));
                  }
                  Navigator.of(context).pop(true);
                },
              ),
            ],
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Scaffold(
                backgroundColor: context.colors.scaffold,
                appBar: MyAppBar(
                  title: (isUpdate ? LocalizationKeys.edit_address : LocalizationKeys.add_address).tr(context),
                ),
                body: Form(
                  key: formKey,
                  child: Stack(
                    children: [
                      SizedBox.expand(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              SizedBox(
                                height: getHeightByNumber(12),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: getHeightByNumber(27),
                                ),
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: getHeightByNumber(30),
                                    ),
                                    // Row(
                                    //   children: [
                                    //     Text(
                                    //       lc.tr(LocalKeys.address_type),
                                    //       textAlign: TextAlign.start,
                                    //       style: TextStyle(
                                    //         fontWeight: FontWeight.w500,
                                    //         fontSize: 14.sp,
                                    //         color: Colors.black,
                                    //         height: 1,
                                    //       ),
                                    //     ),
                                    //     Text(
                                    //       ' *',
                                    //       textAlign: TextAlign.start,
                                    //       style: TextStyle(
                                    //         fontWeight: FontWeight.w500,
                                    //         fontSize: 16.sp,
                                    //         color: Colors.red,
                                    //         height: 1.2,
                                    //       ),
                                    //     ),
                                    //   ],
                                    // ),
                                    // SizedBox(
                                    //   height: getHeightByNumber(10),
                                    // ),
                                    // ValueListenableBuilder(
                                    //   valueListenable: addressType,
                                    //   builder: (context, value, child) => CupertinoSlidingSegmentedControl<AddressType>(
                                    //     backgroundColor: Colors.white,
                                    //     thumbColor: kPrimaryColor,
                                    //     groupValue: value,
                                    //     onValueChanged: (value) {
                                    //       if (value != null) {
                                    //         addressType.value = value;
                                    //       }
                                    //     },
                                    //     children: allowedAddressTypes.asMap().map(
                                    //           (k, v) => MapEntry(
                                    //             v,
                                    //             TabItem(
                                    //               header: tr(v.name),
                                    //               isCurrent: value == v,
                                    //             ),
                                    //           ),
                                    //         ),
                                    //   ),
                                    // ),
                                    // SizedBox(
                                    //   height: getHeightByNumber(20),
                                    // ),
                                    const FieldTitle(
                                      textKey: LocalizationKeys.name,
                                    ),
                                    SizedBox(
                                      height: getHeightByNumber(10),
                                    ),
                                    CustomTextField(
                                      initial: nameController.text,
                                      validator: (value) {
                                        if (!stringNotNullOrEmpty(value)) {
                                          return (LocalizationKeys.this_field_cant_be_empty).tr(context);
                                        }
                                        return null;
                                      },
                                      isPassword: false,
                                      controller: nameController,
                                      hasBorder: false,
                                      borderColor: context.colors.secondaryScaffold,
                                      contentPaddingHorizontal: getWidthByNumber(19),
                                      marginWidth: 0.0,
                                      marginHeight: 0.0,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      padding: EdgeInsets.symmetric(
                                          vertical: getHeightByNumber(0), horizontal: getWidthByNumber(0)),
                                      textColor: context.colors.textColor,
                                      hintColor: Colors.grey,
                                      backgroundColor: Colors.white,
                                      hint: (LocalizationKeys.name).tr(context),
                                      maxLines: 1,
                                      borderRadius: 30.r,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w500,
                                      textInputAction: TextInputAction.done,
                                    ),
                                    SizedBox(
                                      height: getHeightByNumber(20),
                                    ),
                                    const FieldTitle(textKey: LocalizationKeys.country),
                                    BlocSelector<AddAddressBloc, AddAddressStates, CountriesState>(
                                      selector: (state) => state.countriesState,
                                      builder: (context, state) => SelectableField<CountryModel>(
                                        whereCondition: (model, String searchValue) {
                                          return model.name.toLowerCase().contains(searchValue.toLowerCase().trim());
                                        },
                                        item: (model) => AddressCountryItem(
                                          model: model,
                                          selected: state.selected,
                                        ),
                                        list: state.data,
                                        onSelected: (value) {
                                          final bloc = BlocProvider.of<AddAddressBloc>(context);
                                          bloc.add(SelectCountry(value));
                                        },
                                        value: state.selected?.name,
                                        hintKey: (LocalizationKeys.country).tr(context),
                                        background: Colors.white,
                                        padding: EdgeInsetsDirectional.symmetric(
                                          vertical: getHeightByNumber(20),
                                        ).add(EdgeInsetsDirectional.only(
                                          start: getWidthByNumber(20),
                                          end: getWidthByNumber(10),
                                        )),
                                        borderRadius: 30.r,
                                        validator: (_) {
                                          if (state.selected == null) {
                                            return (LocalizationKeys.this_field_cant_be_empty).tr(context);
                                          }
                                          return null;
                                        },
                                        strokeWidth: 0.0,
                                        strokeColor: context.colors.background,
                                        elevation: 0,
                                        marginErrorWidthPercentage: 0.0,
                                      ),
                                    ),
                                    SizedBox(height: getHeightByNumber(14)),
                                    BlocSelector<AddAddressBloc, AddAddressStates, CountriesState>(
                                      selector: (state) => state.countriesState,
                                      builder: (context, state) => isBrazilCountry(state.selected?.code)
                                          ? const SizedBox()
                                          : Column(
                                              children: [
                                                const FieldTitle(textKey: LocalizationKeys.city),
                                                BlocSelector<AddAddressBloc, AddAddressStates, CitiesState>(
                                                  selector: (state) => state.citiesState,
                                                  builder: (context, state) {
                                                    return SelectableField<CityModel>(
                                                    whereCondition: (model, String searchValue) {
                                                      return model.name
                                                          .toLowerCase()
                                                          .contains(searchValue.toLowerCase().trim());
                                                    },
                                                    item: (model) => AddressCityItem(
                                                      model: model,
                                                      selected:state.selected?? chosenCityModel,
                                                    ),
                                                    list: state.data,
                                                    onSelected: (value) {
                                                      final bloc = BlocProvider.of<AddAddressBloc>(context);
                                                      bloc.add(SelectCity(value));
                                                    },
                                                    value: state.selected == null  ? chosenCityModel?.name : state.selected?.name,
                                                    hintKey: (LocalizationKeys.city).tr(context),
                                                    background: Colors.white,
                                                    padding: EdgeInsetsDirectional.symmetric(
                                                      vertical: getHeightByNumber(20),
                                                    ).add(EdgeInsetsDirectional.only(
                                                      start: getWidthByNumber(20),
                                                      end: getWidthByNumber(10),
                                                    )),
                                                    borderRadius: 30.r,
                                                    validator: (_) {
                                                      if (state.selected == null) {
                                                        return (LocalizationKeys.this_field_cant_be_empty).tr(context);
                                                      }
                                                      return null;
                                                    },
                                                    strokeWidth: 0.0,
                                                    strokeColor: context.colors.background,
                                                    elevation: 0,
                                                    marginErrorWidthPercentage: 0.0,
                                                  );
                                                  },
                                                ),
                                                SizedBox(height: getHeightByNumber(14)),
                                                const FieldTitle(textKey: LocalizationKeys.region),
                                                BlocSelector<AddAddressBloc, AddAddressStates, RegionsState>(
                                                  selector: (state) => state.regionsState,
                                                  builder: (context, state) => SelectableField<RegionModel>(
                                                    whereCondition: (model, String searchValue) {
                                                      return model.name
                                                          .toLowerCase()
                                                          .contains(searchValue.toLowerCase().trim());
                                                    },
                                                    item: (model) => AddressRegionItem(
                                                      model: model,
                                                      selected: state.selected ?? chosenRegionModel,
                                                    ),
                                                    list: state.data,
                                                    onSelected: (value) {
                                                      final bloc = BlocProvider.of<AddAddressBloc>(context);
                                                      bloc.add(SelectRegion(value));
                                                    },
                                                    value: state.selected == null ? chosenRegionModel?.name : state.selected?.name,
                                                    hintKey: (LocalizationKeys.region).tr(context),
                                                    background: Colors.white,
                                                    padding: EdgeInsetsDirectional.symmetric(
                                                      vertical: getHeightByNumber(20),
                                                    ).add(EdgeInsetsDirectional.only(
                                                      start: getWidthByNumber(20),
                                                      end: getWidthByNumber(10),
                                                    )),
                                                    borderRadius: 30.r,
                                                    validator: (_) {
                                                      if (validList(state.data) ? (state.selected == null) : false) {
                                                        return (LocalizationKeys.this_field_cant_be_empty).tr(context);
                                                      }
                                                      return null;
                                                    },
                                                    strokeWidth: 0.0,
                                                    strokeColor: context.colors.background,
                                                    elevation: 0,
                                                    marginErrorWidthPercentage: 0.0,
                                                  ),
                                                ),
                                                SizedBox(height: getHeightByNumber(14)),
                                              ],
                                            ),
                                    ),
                                    BlocSelector<AddAddressBloc, AddAddressStates, CountriesState>(
                                      selector: (state) => state.countriesState,
                                      builder: (context, state) {
                                        final bool isBrazil = isBrazilCountry(state.selected?.code);
                                        return Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (isBrazil) const FieldTitle(textKey: LocalizationKeys.cep),
                                            if (isBrazil)
                                              RowFormatters(
                                                controller: cepController,
                                                onSubmitted: (value) async {
                                                  final postmonSearchCep = PostmonSearchCep();
                                                  print('onSubmitted $value');
                                                  loadingCep.value = true;
                                                  final infoCep = await postmonSearchCep.searchInfoByCep(cep: value);
                                                  print('infoCepJSON $infoCep');

                                                  await infoCep.fold((l) async {
                                                    errorCep.value = l.errorMessage;
                                                  }, (r) async {
                                                    print('infoCepJSON 1 $r');
                                                    errorCep.value = null;
                                                    addressController.text = r.logradouro ?? '';
                                                    areaController.text = r.bairro?? '';
                                                    print('_AddAddressScreenState.build ${r.toString()}');
                                                    print(r.toString());
                                                    cityController.text = r.cidade ?? '';
                                                    try {
                                                      brazilStatesModel.value = BrazilStates.states
                                                          .firstWhere((element) => element.code == (r.estado ?? ''));
                                                    } on Exception {}
                                                    print(infoCep);
                                                  });
                                                  loadingCep.value = false;
                                                },
                                                label: '',
                                                formatter: CepInputFormatter(),
                                              ),
                                            ValueListenableBuilder(
                                              valueListenable: errorCep,
                                              builder: (context, error, child) {
                                                if (error == null) {
                                                  return const SizedBox();
                                                }
                                                return Container(
                                                  margin: EdgeInsets.only(top: 10.h),
                                                  child: ErrorField(text: error),
                                                );
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                    SizedBox(height: getHeightByNumber(14)),
                                    const FieldTitle(
                                      textKey: LocalizationKeys.address,
                                    ),
                                    CustomTextField(
                                      initial: addressController.text,
                                      validator: (value) {
                                        if (!validString(addressController.text)) {
                                          return LocalizationKeys.this_field_cant_be_empty.tr(context);
                                        }
                                        return null;
                                      },
                                      controller: addressController,
                                      backgroundColor: context.colors.background,
                                      hasBorder: false,
                                      padding: EdgeInsets.symmetric(vertical: getHeightByNumber(5), horizontal: 20.w),
                                      borderColor: context.colors.primary,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      hintColor: context.colors.divider,
                                      hint: LocalizationKeys.address.tr(context),
                                      maxLines: 1,
                                      keyboardType: TextInputType.emailAddress,
                                      borderRadius: 30.sp,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w300,
                                      textInputAction: TextInputAction.done,
                                    ),
                                    SizedBox(height: getHeightByNumber(20)),
                                    const FieldTitle(
                                      textKey: LocalizationKeys.complete_address,
                                    ),
                                    CustomTextField(
                                      initial: completeAddressController.text,
                                      validator: (value) {
                                        return null;
                                      },
                                      controller: completeAddressController,
                                      backgroundColor: context.colors.background,
                                      hasBorder: false,
                                      padding: EdgeInsets.symmetric(vertical: getHeightByNumber(5), horizontal: 20.w),
                                      borderColor: context.colors.primary,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      hintColor: context.colors.divider,
                                      hint: LocalizationKeys.complete_address.tr(context),
                                      maxLines: 1,
                                      keyboardType: TextInputType.emailAddress,
                                      borderRadius: 30.sp,
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.w300,
                                      textInputAction: TextInputAction.done,
                                    ),
                                    BlocSelector<AddAddressBloc, AddAddressStates, CountriesState>(
                                      selector: (state) => state.countriesState,
                                      builder: (context, state) => !isBrazilCountry(state.selected?.code)
                                          ? const SizedBox()
                                          : Column(
                                              children: [
                                                SizedBox(height: getHeightByNumber(14)),
                                                const FieldTitle(textKey: LocalizationKeys.area),
                                                CustomTextField(
                                                  initial: areaController.text,
                                                  validator: (value) {
                                                    if (!validString(areaController.text)) {
                                                      return LocalizationKeys.this_field_cant_be_empty.tr(context);
                                                    }
                                                    return null;
                                                  },
                                                  controller: areaController,
                                                  backgroundColor: context.colors.background,
                                                  hasBorder: false,
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: getHeightByNumber(5), horizontal: 20.w),
                                                  borderColor: context.colors.primary,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  hintColor: context.colors.divider,
                                                  hint: LocalizationKeys.area.tr(context),
                                                  maxLines: 1,
                                                  keyboardType: TextInputType.emailAddress,
                                                  borderRadius: 30.sp,
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.w300,
                                                  textInputAction: TextInputAction.done,
                                                ),
                                                SizedBox(height: getHeightByNumber(14)),
                                                const FieldTitle(textKey: LocalizationKeys.city),
                                                CustomTextField(
                                                  initial: cityController.text,
                                                  validator: (value) {
                                                    if (!validString(cityController.text)) {
                                                      return LocalizationKeys.this_field_cant_be_empty.tr(context);
                                                    }
                                                    return null;
                                                  },
                                                  controller: cityController,
                                                  backgroundColor: context.colors.background,
                                                  hasBorder: false,
                                                  padding: EdgeInsets.symmetric(
                                                      vertical: getHeightByNumber(5), horizontal: 20.w),
                                                  borderColor: context.colors.primary,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  hintColor: context.colors.divider,
                                                  hint: LocalizationKeys.city.tr(context),
                                                  maxLines: 1,
                                                  keyboardType: TextInputType.emailAddress,
                                                  borderRadius: 30.sp,
                                                  fontSize: 16.sp,
                                                  fontWeight: FontWeight.w300,
                                                  textInputAction: TextInputAction.done,
                                                ),
                                                SizedBox(height: getHeightByNumber(14)),
                                                const FieldTitle(textKey: LocalizationKeys.state),
                                                ValueListenableBuilder(
                                                  valueListenable: brazilStatesModel,
                                                  builder: (context, selected, child) =>
                                                      SelectableField<BrazilStatesModel>(
                                                        whereCondition: (model, String searchValue) {
                                                          return model.name
                                                              .toLowerCase()
                                                              .contains(searchValue.toLowerCase().trim());
                                                        },
                                                        item: (model) => BrazilStateItem(
                                                          model: model,
                                                          selected: selected,
                                                        ),
                                                        list: BrazilStates.states,
                                                        onSelected: (value) {
                                                          brazilStatesModel.value = value;
                                                          errorCep.value = null;
                                                          addressController.text = '';
                                                          areaController.text = '';
                                                          cityController.text = '';
                                                        },
                                                        value: selected?.name,
                                                        hintKey: (LocalizationKeys.state).tr(context),
                                                        background: Colors.white,
                                                        padding: EdgeInsetsDirectional.symmetric(
                                                          vertical: getHeightByNumber(20),
                                                        ).add(EdgeInsetsDirectional.only(
                                                          start: getWidthByNumber(20),
                                                          end: getWidthByNumber(10),
                                                        )),
                                                        borderRadius: 30.r,
                                                        validator: (_) {
                                                          if (selected == null) {
                                                            return (LocalizationKeys.this_field_cant_be_empty).tr(context);
                                                          }
                                                          return null;
                                                        },
                                                        strokeWidth: 0.0,
                                                        strokeColor: context.colors.background,
                                                        elevation: 0,
                                                        marginErrorWidthPercentage: 0.0,
                                                      ),
                                                ),
                                              ],
                                            ),
                                    ),
                                    SizedBox(height: getHeightByNumber(30)),
                                    BlocSelector<AddAddressBloc, AddAddressStates, AddAddressStates>(
                                      selector: (state) => state,
                                      builder: (context, state) => ButtonWithIcon(
                                        isLoading: false,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        marginWidth: 0.0,
                                        onPressed: () {
                                          formKey.currentState?.save();
                                          if (formKey.currentState?.validate() ?? false) {
                                            final bloc = BlocProvider.of<AddAddressBloc>(context);
                                            bloc.add(
                                              SubmitAddAddressEvent(
                                                name: nameController.text,
                                                region_id: isBrazilCountry(state.countriesState.selected?.code)?null: bloc.state.regionsState.selected?.id ?? '',
                                                city_id:isBrazilCountry(state.countriesState.selected?.code)?null: bloc.state.citiesState.selected?.id,
                                                id: widget.addressModel?.id,
                                                country_id: state.countriesState.selected?.id,
                                                country: state.countriesState.selected?.name,
                                                city: cityController.text,
                                                brazil_state_code: brazilStatesModel.value?.code,
                                                state: brazilStatesModel.value?.name,
                                                area: areaController.text,
                                                address: addressController.text,
                                                zip_code: cepController.text.replaceAll('.', '').replaceAll('-', ''),
                                                complement: completeAddressController.text,
                                              ),
                                            );
                                          }
                                        },
                                        buttonBackgroundColor: context.colors.primary,
                                        textColor: context.colors.secondaryTextColor,
                                        text: (isUpdate ? LocalizationKeys.save_address : LocalizationKeys.save_address)
                                            .tr(context),
                                        padding: EdgeInsets.symmetric(vertical: 10.h),
                                        borderRadius: 30.r,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    BlocSelector<AddAddressBloc, AddAddressStates, String?>(
                                      selector: (state) => state.submitAddressState.error,
                                      builder: (context, error) => validString(error)
                                          ? Padding(
                                              padding: const EdgeInsets.only(bottom: 20.0),
                                              child: Center(child: ErrorField(text: error!)),
                                            )
                                          : const SizedBox(),
                                    ),
                                    SizedBox(
                                      height: getHeightByNumber(20),
                                    ),
                                    SizedBox(
                                      height: MediaQuery.of(context).viewInsets.bottom,
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ValueListenableBuilder(
                        valueListenable: loadingCep,
                        builder:(context, loadingCep, child) => BlocSelector<AddAddressBloc, AddAddressStates, bool>(
                          selector: (state) => state.countriesState.loading || state.citiesState.loading || state.regionsState.loading || state.submitAddressState.loading,
                          builder: (context, loading) => loadingCep || loading ? const LoadingOverlay() : const SizedBox(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
