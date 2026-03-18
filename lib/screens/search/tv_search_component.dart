import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:streamit_laravel/generated/assets.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';
import 'package:streamit_laravel/screens/search/search_controller.dart';
import 'package:streamit_laravel/services/focus_sound_service.dart';
import 'package:streamit_laravel/utils/always_focus_node.dart';
import 'package:streamit_laravel/utils/app_common.dart';

import '../../main.dart';
import '../../utils/colors.dart';
import '../../utils/common_base.dart';
import '../dashboard/dashboard_controller.dart';

class KeyboardKeyModel {
  final String text;
  final FocusNode focusNode;

  KeyboardKeyModel({
    required this.text,
    FocusNode? focusNode,
  }) : focusNode = focusNode ?? FocusNode();
}

class TVSearchController extends GetxController {
  Rx<TVSearchConfig> searchConfig;

  TVSearchController({required this.searchConfig});

  RxString searchText = ''.obs;
  String text = '';
  RxBool showSymbols = false.obs;
  final FocusNode keyboardFocusNode = FocusNode();

  final StreamController<String> searchStream = StreamController<String>();

  final List<List<KeyboardKeyModel>> alphabetKeyboard = [
    ['A', 'B', 'C', 'D', 'E', 'F', 'G'],
    ['H', 'I', 'J', 'K', 'L', 'M', 'N'],
    ['O', 'P', 'Q', 'R', 'S', 'T', 'U'],
    ['V', 'W', 'X', 'Y', 'Z', '-', "'"],
  ].map(
    (row) => row
        .map((char) => KeyboardKeyModel(text: char))
        .toList(),
  ).toList();

  final List<List<KeyboardKeyModel>> arabicKeyboard = [
    ['ا', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ'],
    ['د', 'ذ', 'ر', 'ز', 'س', 'ش', 'ص'],
    ['ض', 'ط', 'ظ', 'ع', 'غ', 'ف', 'ق'],
    ['ك', 'ل', 'م', 'ن', 'ه', 'و', 'ي'],
    ['ء', 'أ', 'إ', 'ى', 'ة', 'ئ', 'ؤ'],
  ].map(
    (row) => row
        .map((char) => KeyboardKeyModel(text: char))
        .toList(),
  ).toList();

  final List<List<KeyboardKeyModel>> numberSymbolKeyboard = [
    ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0'],
    ['@', '#', '\$', '%', '&', '*', '(', ')', '_', '+'],
    ['/', '\\', '|', '{', '}', '[', ']', '<', '>', '='],
    ['!', '?', ',', '.', ';', ':', '"', '~', '^', '`'],
  ].map(
    (row) => row
        .map((char) => KeyboardKeyModel(text: char))
        .toList(),
  ).toList();

  RxInt keyboardMode = 0.obs; // 0: Arabic, 1: English, 2: Symbols


  @override
  void onInit() {
    super.onInit();
    onChange();
    searchStream.stream.debounce(const Duration(seconds: 1)).listen((s) {
      if(searchText.value == text) return;
      text = searchText.value;
      onSearch();
    });
  }

  VoidCallback? _listener;

  void onChange() {
    _listener = () {
      searchText.value = searchConfig.value.searchTextCont.text;
      searchStream.add(searchConfig.value.searchTextCont.text);
    };
    searchConfig.value.searchTextCont.addListener(_listener!);
  }

  @override
  void onClose() {
    if (_listener != null) {
      searchConfig.value.searchTextCont.removeListener(_listener!);
    }
    searchStream.close();
    keyboardFocusNode.dispose();
    super.onClose();
  }

  void onKeyPress(String key) {
    searchText.value += key;
    searchConfig.value.searchTextCont.text = searchText.value;
  }

  void onBackspace() {
    if (searchText.isNotEmpty) {
      searchText.value = searchText.value.substring(0, searchText.value.length - 1);
      searchConfig.value.searchTextCont.text = searchText.value;
    }
  }

  void onSpace() {
    searchText.value += ' ';
  }

  void onClear() {
    searchText.value = '';
    searchConfig.value.searchTextCont.text = '';
    searchConfig.value.onClear?.call(searchText.value);
  }

  void onSearch() {
    searchConfig.value.onSearch?.call(searchText.value);
  }

  void toggleSymbols() {
    keyboardMode.value = (keyboardMode.value + 1) % 3;
  }
}

class TVSearchConfig {
  final RxList<String> recentSearches;
  final Function(String)? onSearch;
  final Function(String)? onClear;
  final Function(String)? onRecentSearchTap;
  final String? hintText;
  final bool showRecentSearches;
  final Widget searchResults;
  final TextEditingController searchTextCont;
  final FocusNode searchFocus;
  final FocusNode voiceIconFocus;
  final RxBool searchResultsHasFocus;

  TVSearchConfig({
    required this.recentSearches,
    this.onSearch,
    this.onClear,
    this.onRecentSearchTap,
    this.hintText = 'Search',
    this.showRecentSearches = true,
    required this.searchResults,
    required this.searchTextCont,
    required this.searchFocus,
    required this.voiceIconFocus,
    required this.searchResultsHasFocus,
  });
}

class TVSearchComponent extends StatelessWidget {
  final Rx<TVSearchConfig> searchConfig;

  TVSearchComponent({super.key, required this.searchConfig});

  final SearchScreenController searchCont = Get.put(SearchScreenController());
  final AlwaysFocusedNode alwaysFocusNode = AlwaysFocusedNode();

  Widget _buildKeyboardButton(
    String label,
    VoidCallback onPressed, {
    FocusNode? focusNode,
    int? fontSize,
    double? height,
    double? width,
    Color? backgroundColor,
    KeyEventResult Function(FocusNode, KeyEvent)? onKeyEvent,
  }) {
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Focus(
        focusNode: focusNode,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.select ||
               event.logicalKey == LogicalKeyboardKey.enter)) {
            onPressed();
            return KeyEventResult.handled;
          }
          if(onKeyEvent != null) return onKeyEvent(node, event);
          return KeyEventResult.ignored;
        },
        child: Builder(
          builder: (context) {
            final bool isFocused = Focus.of(context).hasFocus;

            return SizedBox(
              height: height ?? 32,
              width: width ?? 32,
              child: TextButton(
                onPressed: onPressed,
                style: ButtonStyle(
                  padding: WidgetStateProperty.all(EdgeInsets.zero),
                  elevation: WidgetStateProperty.all(0),
                  overlayColor:
                      WidgetStateProperty.all(Colors.transparent),
                  backgroundColor:
                      WidgetStateProperty.all(
                    isFocused
                        ? appColorPrimary.withValues(alpha: 0.15)
                        : backgroundColor ?? canvasColor,
                  ),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  side: WidgetStateProperty.all(
                    BorderSide(
                      color: isFocused
                          ? appColorPrimary
                          : Colors.white10,
                      width: isFocused ? 2 : 1,
                    ),
                  ),
                ),
                child: Text(
                  label,
                  style: primaryTextStyle(
                    size: fontSize ?? 14,
                    color: isFocused ? appColorPrimary : null,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return GetBuilder(
        init: TVSearchController(searchConfig: searchConfig),
        builder: (getxCont) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar with Backspace
                    Row(
                      children: [
                        Obx(() {
                          return Focus(
                              onKeyEvent: (node, event) {
                                if (event.runtimeType.toString() == 'KeyDownEvent' && event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                                  try {
                                    final DashboardController dash = Get.find<DashboardController>();
                                    final int idx = dash.selectedBottomNavIndex.value;
                                    dash.bottomNavItems[idx].focusNode.requestFocus();
                                    return KeyEventResult.handled;
                                  } catch (e) {
                                    // ignore if dashboard not found
                                  }
                                }
                                return KeyEventResult.ignored;
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: canvasColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: AppTextField(
                                  textStyle: primaryTextStyle(size: 14),
                                  controller: searchConfig.value.searchTextCont,
                                  textFieldType: TextFieldType.NAME,
                                  cursorColor: white,
                                  readOnly: true,
                                  showCursor: true,
                                  focus: alwaysFocusNode,
                                  decoration: inputDecorationWithFillBorder(
                                    context,
                                    fillColor: Colors.transparent,
                                    filled: true,
                                    hintText: locale.value.searchMoviesShowsAndMore,
                                    prefixIcon: const Padding(
                                      padding: EdgeInsets.all(14.0),
                                      child: Icon(Icons.search, size: 20, color: darkGrayColor),
                                    ),
                                    suffixIcon: Focus(
                                      focusNode: searchConfig.value.voiceIconFocus,
                                      onFocusChange: (hasFocus) {
                                        if (hasFocus) {
                                          FocusSoundService.play();
                                        }
                                        searchCont.voiceIconHasFocus(hasFocus);
                                      },
                                      onKeyEvent: (node, event) {
                                        if (event.runtimeType.toString() == 'KeyDownEvent') {
                                          if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.space) {
                                            if (!searchCont.isListening.value) {
                                              searchCont.startListening();
                                            } else {
                                              searchCont.stopListening();
                                            }
                                            return KeyEventResult.handled;
                                          }
                                        }
                                        return KeyEventResult.ignored;
                                      },
                                      child: Obx(() {
                                        final bool highlighted = searchCont.isListening.value || searchCont.voiceIconHasFocus.value;
                                        return Container(
                                          margin: const EdgeInsets.only(right: 6),
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: highlighted ? appColorPrimary.withValues(alpha: 0.12) : Colors.transparent,
                                            border: Border.all(
                                              color: highlighted ? appColorPrimary : Colors.white10,
                                              width: highlighted ? 2 : 1,
                                            ),
                                          ),
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(18),
                                            onTap: () {
                                              if (!searchCont.isListening.value) {
                                                searchCont.startListening();
                                              } else {
                                                searchCont.stopListening();
                                              }
                                            },
                                            splashColor: Colors.transparent,
                                            highlightColor: Colors.transparent,
                                            hoverColor: Colors.transparent,
                                            child: Center(
                                              child: Icon(
                                                highlighted ? Icons.keyboard_voice : Icons.keyboard_voice_outlined,
                                                size: 22,
                                                color: highlighted ? appColorPrimary : darkGrayColor,
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                ),
                              )).expand();
                        }),
                        Obx(() => getxCont.searchText.isNotEmpty
                            ? Container(margin: EdgeInsets.only(left: 16), width: 120, child: _buildKeyboardButton('CLEAR', getxCont.onClear, height: 50, width: 120))
                            : Offstage()),
                      ],
                    ),
                    const SizedBox(height: 12),
                
                    Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                    Obx(() => searchCont.isListening.value
                        ? Flexible(
                            child: Center(
                                child: Lottie.asset(Assets.lottieVoiceWave,
                                    height: 150, repeat: true)))
                        : Flexible(
                            child: Padding(
                            padding: const EdgeInsets.only(right: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(locale.value.fromRecentSearches, style: TextStyle(fontSize: 14, color: Colors.grey)),
                                12.height,
                                Builder(builder: (context) {
                              final int count = searchCont.searchListData.length < 2 ? searchCont.searchListData.length : 2;
                                  return Column(
                                    children: List.generate(count, (index) {
                                      final PosterDataModel searchData =
                                          searchCont.searchListData[index];
                                      return Obx(() => Align(
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                          margin: const EdgeInsets.symmetric(vertical: 4),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: canvasColor,
                                            borderRadius: BorderRadius.circular(10),
                                            border: focusBorder(searchData.hasFocus.value),
                                              ),
                                              child: InkWell(
                                                canRequestFocus: true,
                                                onFocusChange: (value) {
                                              searchData.hasFocus(value);
                                              if (value) {
                                                FocusSoundService.play();
                                              }
                                                },
                                                onTap: () async {
                                              searchCont.searchTextCont.text = searchData.details.name;
                                              getxCont.searchText(searchData.details.name);
                                                },
                                                child: Row(
                                                  children: [
                                                Icon(Icons.history, color: iconColor, size: 18),
                                                    8.width,
                                                Text(searchData.details.name, style: primaryTextStyle(size: 14, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis).expand(),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ));
                                    }),
                                  );
                                }),
                              ],
                            ).visible(searchCont.searchListData
                                .take(4)
                                .isNotEmpty),
                          ))),
                    Flexible(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // Target 4 rows x 7 columns grid; compute size to avoid overflow
                          const int columns = 7;
                          const int rowsCount = 4;
                          const double gridSpacing = 4;
                          final double actionColMaxWidth = math.min(140.0, constraints.maxWidth * 0.20);
                          final double gridWidth = constraints.maxWidth - actionColMaxWidth - 8; // 8 for gap
                          final double keyWidth = (gridWidth - (gridSpacing * (columns - 1))) / columns;
                          final double keyHeight = ((constraints.maxHeight) - (gridSpacing * (rowsCount - 1))) / rowsCount;
                    
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Grid area
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: gridWidth),
                                  child: Obx(() {
                                    final rows = getxCont.keyboardMode.value == 0 
                                      ? getxCont.arabicKeyboard 
                                      : (getxCont.keyboardMode.value == 1 ? getxCont.alphabetKeyboard : getxCont.numberSymbolKeyboard);
                                    final keys = rows.expand((r) => r).toList();
                                  return Wrap(
                                    spacing: gridSpacing,
                                    runSpacing: gridSpacing,
                                    children: [
                                      for (int i = 0; i < keys.length; i++) 
                                        _buildKeyboardButton(
                                          keys[i].text,
                                          () => getxCont.onKeyPress(keys[i].text),
                                          focusNode: keys[i].focusNode,
                                          width: keyWidth.clamp(20, 45),
                                          height: keyHeight.clamp(18, 32),
                                          onKeyEvent: i % 7 == 0 ? (node, event) {
                                            if (event is KeyDownEvent) {
                                              if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                                                if(searchCont.searchListData.isNotEmpty) {
                                                  searchCont.searchListData.first.itemFocusNode.requestFocus();
                                                  searchCont.searchListData.first.hasFocus(true);
                                                } else {
                                                  final dashboardController = Get.find<DashboardController>();
                                                  dashboardController.bottomNavItems[1].focusNode.requestFocus();
                                                }
                                                return KeyEventResult.handled;
                                              }
                                              if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                                                keys[i + 1].focusNode.requestFocus();
                                                return KeyEventResult.handled;
                                              }
                                            }
                                            return KeyEventResult.ignored;
                                          } : (i + 7) > keys.length ? (node, event) {
                                            if (event is KeyDownEvent) {
                                              if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                                                if(searchCont.searchMovieDetails.isNotEmpty) {
                                                  searchCont.searchMovieDetails.first.itemFocusNode.requestFocus();
                                                  searchCont.searchMovieDetails.first.hasFocus(true);
                                                }
                                                return KeyEventResult.handled;
                                              }
                                            }
                                            return KeyEventResult.ignored;
                                          } : null
                                        ),
                                    ],
                                  );
                                }),
                              ),
                              const SizedBox(width: 8),
                              // Actions column
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: actionColMaxWidth),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildKeyboardButton('⌫', getxCont.onBackspace, fontSize: 14, width: actionColMaxWidth, height: keyHeight.clamp(18, 28)),
                                    Obx(
                                      () {
                                        return _buildKeyboardButton(getxCont.keyboardMode.value == 0 ? 'ABC' : (getxCont.keyboardMode.value == 1 ? '&123' : 'عربي'), getxCont.toggleSymbols, width: actionColMaxWidth, height: keyHeight.clamp(18, 28));
                                      }
                                    ),
                                    _buildKeyboardButton('SPACE', getxCont.onSpace, width: actionColMaxWidth, height: keyHeight.clamp(18, 28)),
                                    _buildKeyboardButton('SEARCH', getxCont.onSearch, focusNode: searchConfig.value.searchFocus, width: actionColMaxWidth, height: keyHeight.clamp(18, 28)),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                                          ],
                                        ),
                  ],
                ),
                searchConfig.value.searchResults,
              ],
            ),
          );
        });
  }
}
