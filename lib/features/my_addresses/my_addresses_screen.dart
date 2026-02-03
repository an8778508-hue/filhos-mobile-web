import 'package:escola/core/components/dialogs/dialogs_functions.dart';
import 'package:escola/core/components/loading/loading.dart';
import 'package:escola/core/components/widgets/app_bar.dart';
import 'package:escola/core/dependency_injection/di.dart';
import 'package:escola/core/localization/localization_keys.dart';
import 'package:escola/core/utils/extensions/colors_ext.dart';
import 'package:escola/features/add_address/add_address_screen.dart';
import 'package:escola/features/my_addresses/bloc/my_addresses_bloc.dart';
import 'package:escola/features/my_addresses/bloc/my_addresses_events.dart';
import 'package:escola/features/my_addresses/bloc/my_addresses_states.dart';
import 'package:escola/features/my_addresses/widgets/address_item.dart';
import 'package:escola/features/my_addresses/widgets/empty_address.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MyAddressesScreen extends StatefulWidget {
  const MyAddressesScreen({
    super.key,
  });

  @override
  State<MyAddressesScreen> createState() => _MyAddressesScreenState();
}

class _MyAddressesScreenState extends State<MyAddressesScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.scaffold,
      appBar: MyAppBar(
        title: LocalizationKeys.my_addresses.tr(context),
        // actionWidget: GestureDetector(
        //   onTap: () {
        //     Navigator.push(context, MaterialPageRoute(builder: (_) => AddAddressScreen()));
        //   },
        //   child: Padding(
        //     padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 0.w),
        //     child: Assets.icons.add.svg(),
        //   ),
        // ),
      ),
      body: BlocProvider<MyAddressesBloc>(
        create: (BuildContext context) => di<MyAddressesBloc>()..add(const FetchAddresses()),
        child: Builder(builder: (context) {
          return BlocSelector<MyAddressesBloc, MyAddressesStates, AddressesState>(
            selector: (state) => state.addressesState,
            builder: (context, state) {
              final addresses = state.data;
              final loading = state.loading;
              if (loading) {
                return const Center(child: Loading());
              }
              if(addresses.isEmpty){
                return  EmptyAddress(onAddNewTapped: () async {
              final f=   await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const AddAddressScreen()));
              debugPrint('1111111111111111111111111111111111111111111');
                if(f==true && context.mounted){
                  BlocProvider.of<MyAddressesBloc>(context).add(const FetchAddresses());
                  debugPrint('222222222222222222222222222222222222222222');
                }
                },);
              }
              return Column(
                children: [
                  SizedBox(
                    height: 15.h,
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        BlocProvider.of<MyAddressesBloc>(context).add(const FetchAddresses());
                      },
                      child: ListView.separated(
                        itemCount: addresses.length,
                        padding: EdgeInsets.only(bottom: 18.h),
                        separatorBuilder: (context, index) => SizedBox(height: 18.h),
                        itemBuilder: (context, index) {
                          final address = addresses[index];
                          return AddressItem(
                            address: address,
                            onEdit: () async {
                              final bloc= BlocProvider.of<MyAddressesBloc>(context);
                              final f = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => AddAddressScreen(
                                            addressModel: address,
                                          )));
                              if(f == true){
                                bloc.add(const FetchAddresses());
                              }
                            },
                            onDelete: () async {
                              final confirm = await confirmDialog(
                                  context: context,
                                  titleKey: LocalizationKeys.delete_address_title,
                                  bodyKey: LocalizationKeys.delete_address_content);
                              if (confirm == true) {
                                //todo
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        }),
      ),
    );
  }
}
