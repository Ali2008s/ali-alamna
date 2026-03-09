import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/components/loader_widget.dart';
import 'package:streamit_laravel/utils/colors.dart';

import '../utils/common_base.dart';
import 'body_widget.dart';

class AppScaffold extends StatelessWidget {
  final bool hideAppBar;
  final Widget? leadingWidget;
  final Widget? appBarTitle;
  final List<Widget>? actions;
  final bool isCenterTitle;
  final bool automaticallyImplyLeading;
  final double? appBarElevation;
  final String? appBarTitleText;
  final Color? appBarbackGroundColor;
  final Widget body;
  final Color? scaffoldBackgroundColor;
  final RxBool? isLoading;
  final Widget? bottomNavBar;
  final Widget? fabWidget;
  final bool hasLeadingWidget;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool? resizeToAvoidBottomPadding;
  final bool? extendBodyBehindAppBar;

  const AppScaffold({
    super.key,
    this.hideAppBar = false,
    //
    this.leadingWidget,
    this.appBarTitle,
    this.actions,
    this.appBarElevation = 0,
    this.appBarTitleText,
    this.appBarbackGroundColor,
    this.isCenterTitle = false,
    this.hasLeadingWidget = true,
    this.automaticallyImplyLeading = false,
    this.extendBodyBehindAppBar = false,
    //
    required this.body,
    this.isLoading,
    //
    this.bottomNavBar,
    this.fabWidget,
    this.floatingActionButtonLocation,
    this.resizeToAvoidBottomPadding,
    this.scaffoldBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: resizeToAvoidBottomPadding,
      extendBodyBehindAppBar: extendBodyBehindAppBar ?? false,
      appBar: hideAppBar
          ? null
          : PreferredSize(
        preferredSize: Size(Get.width, 52),
        child: AppBar(
          elevation: appBarElevation,
          automaticallyImplyLeading: automaticallyImplyLeading,
          centerTitle: isCenterTitle,
          titleSpacing: 2,
          title: appBarTitle ??
              Text(
                appBarTitleText ?? "",
                style: commonW600PrimaryTextStyle(size: 18),
              ).paddingLeft(hasLeadingWidget ? 0 : 16),
          actions: actions,
          leading: leadingWidget ?? (hasLeadingWidget ? backButton() : null),
        ).paddingTop(0),
      ),
      backgroundColor: scaffoldBackgroundColor ?? context.scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        child: Body(
          isLoading: isLoading ?? false.obs,
          child: body,
        ),
      ),
      bottomNavigationBar: bottomNavBar,
      floatingActionButton: fabWidget,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}

class NewAppScaffold extends StatelessWidget {
  final ScrollController scrollController = ScrollController();

  final Widget body;
  final Widget? appBarChild;
  final Widget? leadingWidget;
  final String? appBarTitleText;
  final List<Widget>? actions;
  final bool? resizeToAvoidBottomPadding;
  final Color? scaffoldBackgroundColor;
  final RxBool? isLoading;

  final List<Widget> widgetsStackedOverBody;
  final bool hideAppBar;
  final bool isBlurBackgroundLoader;
  final RxInt? currentPage;
  final Widget? floatingActionButton;
  final PreferredSize? appBarBottomWidget;
  final bool applyLeadingBackButton;
  final FlexibleSpaceBar? flexibleSpaceBarWidget;
  final double? collapsedHeight;
  final double? expandedHeight;
  final VoidCallback? onNextPage;
  final VoidCallback? onRefresh;
  final Color? statusBarColor;

  final Widget? drawer;

  /// Flag to ensure scroll listener is added only once
  final RxBool listenerAdded = false.obs;

  NewAppScaffold({
    super.key,
    required this.body,
    this.appBarChild,
    this.leadingWidget,
    this.appBarTitleText,
    this.actions,
    this.resizeToAvoidBottomPadding,
    this.scaffoldBackgroundColor,
    this.isLoading,
    this.hideAppBar = false,
    this.isBlurBackgroundLoader = false,
    this.currentPage,
    this.floatingActionButton,
    this.appBarBottomWidget,
    this.applyLeadingBackButton = true,
    this.widgetsStackedOverBody = const <Widget>[],
    this.flexibleSpaceBarWidget,
    this.collapsedHeight,
    this.expandedHeight,
    this.onNextPage,
    this.onRefresh,
    this.statusBarColor,
    this.drawer,
  }) {
    // Add scroll listener only once
    ever(listenerAdded, (added) {
      if (!added) {
        scrollController.addListener(() {
          if (onNextPage != null && !_isLoading() && _isNearBottom()) {
            onNextPage!();
          }
        });
        listenerAdded.value = true;
      }
    });
  }

  /// Checks if scroll position is near bottom
  bool _isNearBottom({double threshold = 200}) {
    if (!scrollController.hasClients) return false;
    final maxScroll = scrollController.position.maxScrollExtent;
    final currentScroll = scrollController.offset;
    return maxScroll - currentScroll <= threshold;
  }

  /// Checks if loading is in progress
  bool _isLoading() => (isLoading?.value ?? false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: drawer,
      resizeToAvoidBottomInset: resizeToAvoidBottomPadding,
      backgroundColor: scaffoldBackgroundColor ?? cardBackgroundBlackDark,
      body: RefreshIndicator(
        color: appColorPrimary,
        onRefresh: () async => onRefresh?.call(),
        child: Stack(
          children: [
            NestedScrollView(
              controller: scrollController,
              floatHeaderSlivers: true,
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  if (!hideAppBar)
                    SliverAppBar(
                      pinned: true,
                      floating: true,
                      expandedHeight: expandedHeight ?? Get.height * 0.08,
                      collapsedHeight: collapsedHeight ?? kToolbarHeight,
                      toolbarHeight: kToolbarHeight,
                      centerTitle: false,
                      automaticallyImplyLeading: false,
                      systemOverlayStyle: SystemUiOverlayStyle(
                        statusBarBrightness: Brightness.light,
                        statusBarIconBrightness: Brightness.light,
                        statusBarColor: (statusBarColor ?? appColorSecondary).withValues(alpha: 0.25),
                        systemNavigationBarIconBrightness: Brightness.light,
                      ),
                      backgroundColor: Colors.transparent,
                      foregroundColor: (statusBarColor ?? appColorSecondary).withValues(alpha: 0.08),
                      surfaceTintColor: Colors.transparent,
                      leading: applyLeadingBackButton ? (leadingWidget ?? backButton()) : null,
                      leadingWidth: (applyLeadingBackButton || leadingWidget != null) ? 48 : 0,
                      titleSpacing: 16,
                      title: appBarChild ??
                          ((appBarTitleText?.isNotEmpty ?? false)
                              ? Text(
                            appBarTitleText!,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          )
                              : null),
                      actions: actions,
                      bottom: appBarBottomWidget,
                      flexibleSpace: flexibleSpaceBarWidget ??
                          FlexibleSpaceBar(
                            collapseMode: CollapseMode.parallax,
                            background: Container(
                              height: collapsedHeight ?? (Get.height * 0.12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: List.generate(
                                    5,
                                        (i) => (statusBarColor ?? appColorSecondary).withValues(
                                      alpha: [0.16, 0.12, 0.08, 0.02, 0.01][i],
                                    ),
                                  ),
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ),
                    ),
                ];
              },
              body: PrimaryScrollController(
                controller: scrollController,
                child: body,
              ),
            ),

            // Extra stacked widgets
            ...widgetsStackedOverBody,

            // Loading overlay
            Obx(() => currentPage != null && currentPage!.value > 1
                ? Positioned(bottom: 32, left: 0, right: 0, child: LoaderWidget(isBlurBackground: isBlurBackgroundLoader).visible((isLoading ?? false.obs).value))
                : LoaderWidget(isBlurBackground: isBlurBackgroundLoader).center().visible((isLoading ?? false.obs).value)),
          ],
        ),
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}