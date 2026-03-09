import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/components/app_logo_widget.dart';
import 'package:streamit_laravel/screens/auth/sign_in/sign_in_controller.dart';
import 'package:streamit_laravel/screens/live_tv/live_tv_controller.dart';
import 'package:streamit_laravel/utils/app_common.dart';
import 'package:streamit_laravel/utils/common_base.dart';
import '../../utils/colors.dart';
import 'components/menu.dart';
import 'dashboard_controller.dart';

class DashboardScreen extends StatelessWidget {
  DashboardScreen({super.key});

  final DashboardController dashboardController = Get.put(DashboardController(), permanent: true);

  @override
  Widget build(BuildContext context) {
    return DoublePressBackWidget(
      child: Scaffold(
        extendBody: true,
        backgroundColor: appScreenBackgroundDark,
        extendBodyBehindAppBar: true,
        body: Row(
          children: [
            TvSideDrawer(dashboardController: dashboardController),
            Expanded(
              child: Obx(
                  () => dashboardController.bottomNavItems[dashboardController.selectedBottomNavIndex.value].screen),
            ),
          ],
        ),
      ),
    );
  }
}

// ignore: must_be_immutable
class TvSideDrawer extends StatelessWidget {
  final DashboardController dashboardController;

  TvSideDrawer({super.key, required this.dashboardController});

  bool hasAlreadyFocusedOnce = false;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        bool isExpanded = dashboardController.isDrawerExpanded.value;

        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Container(
            width: isExpanded ? 160 : 70,
            color: Colors.transparent,
            child: Focus(
              onFocusChange: (hasFocus) {
                dashboardController.isDrawerExpanded.value = hasFocus;
                if (hasFocus && !hasAlreadyFocusedOnce) {
                  dashboardController.bottomNavItems[dashboardController.selectedBottomNavIndex.value].focusNode
                      .requestFocus();
                  hasAlreadyFocusedOnce = true;
                }
              },
              child: Column(
                children: [
                  // Logo Area
                  // AnimatedSize(
                  //   duration: const Duration(milliseconds: 300),
                  //   curve: Curves.easeInOut,
                  //   child: CachedImageWidget(
                  //     url: Assets.iconsIcIcon,
                  //     height: isExpanded ? 80 : 40,
                  //     width: isExpanded ? 80 : 40,
                  //   ).paddingSymmetric(vertical: 16),
                  // ),
                  DynamicAppLogoWidget(
                    size: Size(isExpanded ? 80 : 40, isExpanded ? 80 : 40),
                    image: appConfigs.value.appMiniLogo,
                  ).paddingSymmetric(vertical: 16),

                  // Menu Items
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: dashboardController.bottomNavItems.length,
                      itemBuilder: (context, index) {
                        final item = dashboardController.bottomNavItems[index];
                        return Focus(
                          focusNode: item.focusNode,
                          onFocusChange: (hasFocus) {
                            // Skip all focus change logic if we're navigating to content banner
                            if (dashboardController.isNavigatingToContentBanner.value) {
                              return;
                            }

                            if (hasFocus) {
                              // Only navigate if we're not doing an internal focus change
                              // and we're actually changing to a different screen
                              if (!dashboardController.isInternalFocusChange.value &&
                                  dashboardController.selectedBottomNavIndex.value != index) {
                                dashboardController.onBottomTabChange(item.type);
                              }
                              dashboardController.expandDrawer();
                              item.focusNode.requestFocus();
                            }
                          },
                          onKeyEvent: (node, event) {
                            if (event is KeyDownEvent) {
                              if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                                if (index > 0) {
                                  dashboardController.bottomNavItems[index - 1].focusNode.requestFocus();
                                  return KeyEventResult.handled;
                                }
                              } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                                if (index < dashboardController.bottomNavItems.length - 1) {
                                  if (item.type == BottomItem.livetv) {
                                    final signInController = getOrPutController(() => SignInController());
                                    signInController.isLeftFormEmail(false);
                                    Future.delayed(
                                      Duration(milliseconds: 500),
                                      () {
                                        signInController.countryCodeFocus.requestFocus();
                                      },
                                    );
                                    dashboardController.bottomNavItems[index + 1].focusNode.requestFocus();
                                    return KeyEventResult.handled;
                                  }
                                  dashboardController.bottomNavItems[index + 1].focusNode.requestFocus();
                                  return KeyEventResult.handled;
                                }
                              } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                                // Handle right arrow key for search menu item
                                if (item.type == BottomItem.search) {
                                  // Navigate to the search field in the search screen
                                  dashboardController.navigateToSearchField();
                                  return KeyEventResult.handled;
                                }
                                if (item.type == BottomItem.livetv) {
                                  final liveTVController = getOrPutController(() => LiveTVController());
                                  if (liveTVController.liveDashboard.value.data.slider.isNotEmpty) {
                                    FocusManager.instance.primaryFocus?.unfocus();
                                    liveTVController.sliderFocus.requestFocus();
                                    return KeyEventResult.handled;
                                  }
                                }

                                // Handle right arrow key for profile menu item
                                if (item.type == BottomItem.profile) {
                                  // Navigate to the first profile component in the profile screen
                                  dashboardController.navigateToFirstProfileComponent();
                                  return KeyEventResult.handled;
                                }
                                // Handle right arrow key for content screens (movies, tvShows, videos)
                                if (item.type == BottomItem.movies ||
                                    item.type == BottomItem.tvShows ||
                                    item.type == BottomItem.videos) {
                                  dashboardController.navigateToContentBanner();
                                  return KeyEventResult.handled;
                                }
                              }
                            }
                            return KeyEventResult.ignored;
                          },
                          child: Obx(() {
                            bool isSelected = dashboardController.selectedBottomNavIndex.value == index;

                            return InkWell(
                              onTap: () {
                                dashboardController.onBottomTabChange(item.type);
                                dashboardController.expandDrawer();
                              },
                              child: DrawerItem(
                                icon: isSelected ? item.activeIcon : item.icon,
                                title: item.title(),
                                isExpanded: isExpanded,
                                isSelected: isSelected,
                              ),
                            );
                          }),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Drawer Item Widget
class DrawerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isExpanded;
  final bool isSelected;

  const DrawerItem({
    super.key,
    required this.icon,
    required this.title,
    required this.isExpanded,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: isExpanded
          ? Row(
              children: [
                Container(
                  decoration: isSelected
                      ? BoxDecoration(boxShadow: [
                          BoxShadow(color: appColorPrimary.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)
                        ])
                      : null,
                  child: Icon(icon, color: isSelected ? appColorPrimary : iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(title,
                      overflow: TextOverflow.ellipsis,
                      style: primaryTextStyle(color: isSelected ? appColorPrimary : Colors.white)),
                ),
              ],
            )
          : Center(
              child: Container(
                decoration: isSelected
                    ? BoxDecoration(boxShadow: [
                        BoxShadow(color: appColorPrimary.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 2)
                      ])
                    : null,
                child: Icon(icon, color: isSelected ? appColorPrimary : iconColor),
              ),
            ),
    );
  }
}
