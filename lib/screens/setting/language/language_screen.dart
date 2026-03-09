import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:get/get.dart';
import 'package:streamit_laravel/utils/app_common.dart';
import '../../../components/app_scaffold.dart';
import '../../../locale/app_localizations.dart';
import '../../../locale/languages.dart';
import '../../../main.dart';
import '../../../utils/colors.dart';
import '../../../utils/constants.dart';
import '../../../utils/local_storage.dart';

class LanguageScreen extends StatelessWidget {
  LanguageScreen({super.key});

  final FocusNode languageListFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      isLoading: false.obs,
      scaffoldBackgroundColor: appScreenBackgroundDark,
      hasLeadingWidget: false,
      appBartitleText: locale.value.language,
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 30, top: 16),
        itemCount: localeLanguageList.length,
        itemBuilder: (_, index) {
          LanguageDataModel data = localeLanguageList[index];

          return LanguageItem(data: data).paddingSymmetric(horizontal: 8, vertical: 4);
        },
      ),
    );
  }
}

class LanguageItem extends StatelessWidget {
  LanguageItem({
    super.key,
    required this.data,
  });

  final LanguageDataModel data;

  final RxBool hasFocus = false.obs;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Focus(
        onFocusChange: (value) {
          hasFocus(value);
        },
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
              setLanguage();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: InkWell(
          onTap: () {
            setLanguage();
          },
          child: Container(
            decoration: BoxDecoration(
              color: transparentColor,
              borderRadius: radius(4),
              border: Border.all(
                color: hasFocus.value ? white : Colors.white12,
                width: hasFocus.value ? 2 : 1,
              ),
            ),
            child: SettingItemWidget(
              title: data.name.validate(),
              subTitle: data.subTitle,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
              titleTextStyle: primaryTextStyle(),
              leading: (data.flag.validate().isNotEmpty)
                  ? data.flag.validate().startsWith('http')
                      ? Image.network(data.flag.validate(), width: 24)
                      : Image.asset(data.flag.validate(), width: 24)
                  : null,
              trailing: Obx(
                () => Container(
                  padding: const EdgeInsets.all(2),
                  decoration: boxDecorationDefault(shape: BoxShape.circle),
                  child: const Icon(Icons.check, size: 15, color: Colors.black),
                ).visible(selectedLanguageCode.value == data.languageCode.validate()),
              ),
              splashColor: transparentColor,
              borderRadius: 8,
              hoverColor: transparentColor,
              highlightColor: transparentColor,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> setLanguage() async {
    await setValue(SELECTED_LANGUAGE_CODE, data.languageCode);
    selectedLanguageDataModel = data;
    BaseLanguage temp = await const AppLocalizations().load(Locale(data.languageCode.validate()));
    locale = temp.obs;
    setValueToLocal(SELECTED_LANGUAGE_CODE, data.languageCode.validate());
    isRTL(Constants.rtlLanguage.contains(data.languageCode));
    selectedLanguageCode(data.languageCode.validate());
    Get.updateLocale(Locale(data.languageCode.validate()));
    Get.back();
  }
}