import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/components/category_list/movie_horizontal/poster_card_component.dart';
import 'package:streamit_laravel/screens/content/content_details_screen.dart';
import 'package:streamit_laravel/screens/content/model/content_model.dart';
import 'package:streamit_laravel/screens/dashboard/components/menu.dart';
import 'package:streamit_laravel/screens/dashboard/dashboard_controller.dart';
import 'package:streamit_laravel/screens/profile/components/user_profile_component.dart';
import 'package:streamit_laravel/screens/profile/shimmer_profile.dart';
import 'package:streamit_laravel/screens/setting/language/language_screen.dart';
import 'package:streamit_laravel/screens/watch_list/components/empty_watch_list_compnent.dart';
import 'package:streamit_laravel/screens/watch_list/watch_list_controller.dart';
import 'package:streamit_laravel/utils/app_common.dart';

import '../../components/cached_image_widget.dart';
import '../../main.dart';
import '../../services/focus_sound_service.dart';
import '../../utils/colors.dart';
import 'profile_controller.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});
  
  final WatchListController watchListController = Get.put(WatchListController());
  final ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final ProfileController profileCont = Get.put(ProfileController());
    return Obx(
      () => SnapHelperWidget(
        future: profileCont.getProfileDetailsFuture.value,
        initialData: cachedProfileDetails,
        loadingWidget: const ShimmerProfile(),
        errorBuilder: (error) => NoDataWidget(
          title: error,
          retryText: locale.value.reload,
          onRetry: () => profileCont.getProfileDetail(),
        ),
        onSuccess: (res) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                // Profile header section
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(color: backgroundColor.withValues(alpha: 1), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CachedImageWidget(
                            url: profileCont.profileDetailsResp.value.profileImage,
                            height: 60,
                            width: 60,
                            circle: true,
                            fit: BoxFit.cover,
                          ),
                          16.width,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profileCont.profileDetailsResp.value.fullName,
                                style: boldTextStyle(size: 24, color: Colors.white),
                              ),
                              8.height,
                              Text(
                                profileCont.profileDetailsResp.value.email,
                                style: secondaryTextStyle(color: Colors.white70),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Obx(
                            () => Focus(
                              focusNode: profileCont.languageButtonFocusNode,
                              onFocusChange: (value) {
                                profileCont.onLanguageButtonFocusChange(value);
                              },
                              onKeyEvent: (node, event) {
                                return profileCont.handleLanguageButtonKeyEvent(event);
                              },
                              child: InkWell(
                                onTap: () {
                                  Get.to(() => LanguageScreen());
                                },
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: profileCont.isLanguageButtonFocused.value ? appColorPrimary : transparentColor, width: profileCont.isLanguageButtonFocused.value ? 2 : 1),
                                  ),
                                  child: Icon(Icons.language, color: white, size: 28),
                                ),
                              ),
                            ),
                          ),
                          8.width,
                          Obx(
                            () => Focus(
                              focusNode: profileCont.logoutButtonFocusNode,
                              onFocusChange: (value) {
                                if (value) {
                                  FocusSoundService.play();
                                }
                                profileCont.onLogoutButtonFocusChange(value);
                              },
                              onKeyEvent: (node, event) {
                                return profileCont.handleLogoutButtonKeyEvent(event);
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: profileCont.isLogoutButtonFocused.value ? Colors.white : transparentColor, width: profileCont.isLogoutButtonFocused.value ? 2 : 1),
                                ),
                                child: Text(locale.value.logout, style: boldTextStyle(color: appColorPrimary, size: 20)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                16.height,

                // Vertical stacked menu items with their components
                ...profileCont.menuItems.asMap().entries.map((entry) {
                  int index = entry.key;
                  TVMenuItem menuItem = entry.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: backgroundColor.withValues(alpha: 1), borderRadius: BorderRadius.circular(8)),
                        child: Focus(
                          focusNode: menuItem.focusNode,
                          onFocusChange: (value) {
                            menuItem.hasFocus(value);
                            if (value) {
                              FocusSoundService.play();
                              profileCont.currentFocusMenu(menuItem);
                            }
                          },
                          onKeyEvent: (node, event) {
                            if (event is KeyDownEvent) {
                              if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                                if (index > 0) {
                                  profileCont.menuItems[index - 1].focusNode.requestFocus();
                                  return KeyEventResult.handled;
                                }
                              } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                                if (index < profileCont.menuItems.length - 1) {
                                  profileCont.menuItems[index + 1].focusNode.requestFocus();
                                  return KeyEventResult.handled;
                                }
                              } else if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
                                _handleMenuSelection(menuItem.slug);
                                return KeyEventResult.handled;
                              }
                            }
                            return KeyEventResult.ignored;
                          },
                          canRequestFocus: true,
                          child: Text(
                            menuItem.title(),
                            style: boldTextStyle(
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      16.height,
                      _buildComponentForMenuItem(menuItem.slug, profileCont),
                      if (index < profileCont.menuItems.length - 1) 16.height,
                    ],
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildComponentForMenuItem(ProfileMenuType menuType, ProfileController profileCont) {
    return switch (menuType) {
      ProfileMenuType.profile => UserProfileComponentWithFocus(
          firstProfileFocusNode: profileCont.firstProfileFocusNode,
          onUpArrowKeyEvent: () {
            profileCont.languageButtonFocusNode.requestFocus();
            scrollController.animToTop();
          },
          onLeftArrowKeyEvent: () {
            // Move focus to profile navigation bar button
            if (profileCont.menuItems.isNotEmpty) {
              // Set flag to prevent navigation
              DashboardController dashboardCont = Get.find();
              dashboardCont.isInternalFocusChange(true);

              // Find the profile menu item in the dashboard
              int profileIndex = dashboardCont.bottomNavItems.indexWhere((item) => item.type == BottomItem.profile);
              if (profileIndex >= 0) {
                dashboardCont.bottomNavItems[profileIndex].focusNode.requestFocus();
              }

              profileCont.currentFocusMenu(profileCont.menuItems[0]);

              // Reset flag after a short delay
              Future.delayed(Duration(milliseconds: 100), () {
                dashboardCont.isInternalFocusChange(false);
              });
            }
          },
          onRightArrowKeyEvent: () {
            // This will be handled by the profile component's internal navigation
            // No action needed here as it's handled within the UserProfileComponent
          },
          onDownArrowKeyEvent: () {
            if(watchListController.listContent.isNotEmpty) {
              watchListController.listContent[0].itemFocusNode.requestFocus();
            }
          },
        ),
      ProfileMenuType.watchlist => watchListController.listContent.isEmpty
          ? EmptyWatchListComponent()
          : SizedBox(
              height: 160,
              child: AnimatedListView(
                physics: const AlwaysScrollableScrollPhysics(),
                scrollDirection: Axis.horizontal,
                itemCount: watchListController.listContent.length,
                shrinkWrap: false,
                itemBuilder: (context, index) {
                  PosterDataModel movie = watchListController.listContent[index];
                  return PosterCardComponent(
                    key: ValueKey('watchlist_$index'),
                    videoData: null,
                    index: index,
                    contentDetail: movie,
                    width: Get.width / 5,
                    focusNode: movie.itemFocusNode,
                    height: 150,
                    onFocusChange:  (value) {
                      if(value) {
                        Scrollable.ensureVisible(
                          movie.itemFocusNode.context!,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    onArrowLeft: () {
                      if(index > 0) {
                        watchListController.listContent[index - 1].itemFocusNode.requestFocus();
                        return;
                      }
                      DashboardController dashboardCont = Get.find();
                      dashboardCont.isInternalFocusChange(true);
  
                      // Find the profile menu item in the dashboard
                      int profileIndex = dashboardCont.bottomNavItems.indexWhere((item) => item.type == BottomItem.profile);
                      if (profileIndex >= 0) {
                        dashboardCont.bottomNavItems[profileIndex].focusNode.requestFocus();
                      }
  
                      profileCont.currentFocusMenu(profileCont.menuItems[0]);
  
                      // Reset flag after a short delay
                      Future.delayed(Duration(milliseconds: 100), () {
                        dashboardCont.isInternalFocusChange(false);
                      });
                    },
                    onArrowUp: () {
                      profileCont.firstProfileFocusNode.requestFocus();
                    },
                    onArrowRight: () {
                      if(index < watchListController.listContent.length - 1) {
                        watchListController.listContent[index + 1].itemFocusNode.requestFocus();
                      }
                    },
                    onTap: () {
                      if(movie.details.isDeviceSupported.getBoolInt() && movie.details.hasContentAccess.getBoolInt()) {
                        Get.to(() => ContentDetailsScreen(), arguments: movie.details);
                      } else {
                        showSubscriptionDialog(
                            title: locale.value.subscriptionRequired,
                            msg: locale.value.pleaseSubscribeOrUpgrade);
                      }
                    },
                  );
                },
              ),
            ),
    };
  }

  void _handleMenuSelection(ProfileMenuType slug) {
    // No special handling needed for remaining menu items
    // Profile and watchlist are handled by focus changes
  }
}

class UserProfileComponentWithFocus extends StatelessWidget {
  final FocusNode firstProfileFocusNode;
  final Function()? onUpArrowKeyEvent;
  final Function()? onDownArrowKeyEvent;
  final Function()? onLeftArrowKeyEvent;
  final Function()? onRightArrowKeyEvent;

  const UserProfileComponentWithFocus({
    super.key,
    required this.firstProfileFocusNode,
    this.onUpArrowKeyEvent,
    this.onDownArrowKeyEvent,
    this.onLeftArrowKeyEvent,
    this.onRightArrowKeyEvent,
  });

  @override
  Widget build(BuildContext context) {
    return UserProfileComponent(
      firstProfileFocusNode: firstProfileFocusNode,
      onUpArrowKeyEvent: onUpArrowKeyEvent,
      onDownArrowKeyEvent: onDownArrowKeyEvent,
      onLeftArrowKeyEvent: onLeftArrowKeyEvent,
      onRightArrowKeyEvent: onRightArrowKeyEvent,
    );
  }
}

class TVMenuItem {
  final IconData icon;
  final String Function() title;
  final ProfileMenuType slug;

  TVMenuItem({required this.icon, required this.title, required this.slug});

  final FocusNode focusNode = FocusNode();
  final RxBool hasFocus = false.obs;
}
