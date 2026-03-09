import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/screens/coming_soon/coming_soon_controller.dart';
import 'package:streamit_laravel/utils/colors.dart';

import '../../main.dart';
import '../../utils/empty_error_state_widget.dart';
import 'components/coming_soon_banner_component.dart';
import 'components/coming_soon_vertical_card.dart';
import 'components/coming_soon_tab_bar.dart';

class ComingSoonScreen extends StatelessWidget {
  ComingSoonScreen({super.key});

  final comingSoonCont = Get.put(ComingSoonController());

  /// Helper method to get translated tab name
  String _getTranslatedTabName(String tabName) {
    switch (tabName.toLowerCase()) {
      case 'all':
        return locale.value.all;
      case 'movies':
        return locale.value.movies;
      case 'tv shows':
        return locale.value.tVShows;
      case 'videos':
        return locale.value.videos;
      default:
        return tabName;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Scaffold(
        backgroundColor: appScreenBackgroundDark,
        body: Obx(() => SnapHelperWidget(
              future: comingSoonCont.listContentFuture.value,
              initialData: cachedComingSoonList.isNotEmpty ? cachedComingSoonList : null,
              loadingWidget: Center(
                child: const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(appColorPrimary),
                  strokeWidth: 3,
                ),
              ),
              errorBuilder: (error) => NoDataWidget(
                titleTextStyle: secondaryTextStyle(color: white),
                subTitleTextStyle: primaryTextStyle(color: white),
                title: error,
                retryText: locale.value.reload,
                imageWidget: const ErrorStateWidget(),
                onRetry: comingSoonCont.onRetry,
              ),
              onSuccess: (_) => Obx(() {
                if (comingSoonCont.isLoading.value) {
                  return Stack(
                    children: [
                      if (comingSoonCont.listContent.isNotEmpty)
                        SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: _buildContent(),
                        ),
                      Container(
                        color: Colors.black.withValues(alpha: 0.7),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(appColorPrimary),
                                strokeWidth: 3,
                              ),
                              16.height,
                              Text(
                                '${locale.value.loading} ${_getTranslatedTabName(comingSoonCont.filterTabs[comingSoonCont.currentSelected.value])}...',
                                style: boldTextStyle(color: white, size: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return SingleChildScrollView(
                  controller: comingSoonCont.scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: _buildContent(),
                );
              }),
            )),
      ),
    );
  }

  Widget _buildContent() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (comingSoonCont.listContent.isNotEmpty)
            Stack(
              clipBehavior: Clip.none,
              children: [
                ComingSoonBannerComponent(
                  comingSoonCont: comingSoonCont,
                  comingSoonDet: comingSoonCont.listContent.first,
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.7),
                          Colors.black.withValues(alpha: 0.5),
                          Colors.black.withValues(alpha: 0.2),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.3, 0.6, 1.0],
                      ),
                    ),
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    child: ComingSoonTabBar(),
                  ),
                ),
              ],
            )
          else
            // Show tab bar even when there's no data
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.6),
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 0.6, 1.0],
                ),
              ),
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: ComingSoonTabBar(),
            ),
          16.height,
          if (comingSoonCont.listContent.isEmpty)
            // Show empty state message when there's no data
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 100),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const EmptyStateWidget(),
                    24.height,
                    Text(
                      locale.value.noDataFound,
                      style: boldTextStyle(color: white, size: 18),
                    ),
                    8.height,
                    Text(
                      locale.value.noContentAvailableFor(
                          _getTranslatedTabName(comingSoonCont.filterTabs[comingSoonCont.currentSelected.value])),
                      style: secondaryTextStyle(color: white),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else if (comingSoonCont.listContent.length > 1) ...[
            Text(locale.value.moreComingSoon, style: boldTextStyle()).paddingSymmetric(horizontal: 16),
            16.height,
            _ComingSoonGridWidget(comingSoonCont: comingSoonCont),
          ],
        ],
      );
}

class _ComingSoonGridWidget extends StatelessWidget {
  final ComingSoonController comingSoonCont;

  const _ComingSoonGridWidget({required this.comingSoonCont});

  @override
  Widget build(BuildContext context) => Obx(() {
        final total = comingSoonCont.listContent.length - 1;

        // Ensure grid focus nodes are initialized
        if (comingSoonCont.gridFocusNodes.length != total) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            comingSoonCont.initializeGridFocusNodes();
          });
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.only(left: 16, right: 8, bottom: 50),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: total,
          itemBuilder: (_, i) => i >= comingSoonCont.gridFocusNodes.length
              ? const SizedBox.shrink()
              : _FocusWrapper(
                  node: comingSoonCont.gridFocusNodes[i],
                  onKey: (e) => comingSoonCont.handleGridNavigation(i, e),
                  onEnter: () => comingSoonCont.navigateToDetailScreen(comingSoonCont.listContent[i + 1]),
                  child: ComingSoonVerticalCard(
                    comingSoonCont: comingSoonCont,
                    comingSoonDet: comingSoonCont.listContent[i + 1],
                  ),
                ),
        );
      });
}

class _FocusWrapper extends StatefulWidget {
  final FocusNode node;
  final KeyEventResult Function(KeyEvent) onKey;
  final Widget child;
  final VoidCallback? onEnter;

  const _FocusWrapper({required this.node, required this.onKey, required this.child, this.onEnter});

  @override
  State<_FocusWrapper> createState() => _FocusWrapperState();
}

class _FocusWrapperState extends State<_FocusWrapper> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.node.addListener(_onChange);
  }

  @override
  void didUpdateWidget(_FocusWrapper old) {
    super.didUpdateWidget(old);
    if (old.node != widget.node) {
      old.node.removeListener(_onChange);
      widget.node.addListener(_onChange);
    }
  }

  @override
  void dispose() {
    widget.node.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => mounted ? setState(() => _focused = widget.node.hasFocus) : null;

  KeyEventResult _onKey(FocusNode n, KeyEvent e) {
    if (e is KeyDownEvent && (e.logicalKey == LogicalKeyboardKey.enter || e.logicalKey == LogicalKeyboardKey.select)) {
      if (widget.onEnter != null) {
        widget.onEnter!();
        return KeyEventResult.handled;
      }
    }
    return widget.onKey(e);
  }

  @override
  Widget build(BuildContext context) => Focus(
        focusNode: widget.node,
        onKeyEvent: _onKey,
        child: AnimatedScale(
          scale: _focused ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: _focused ? Border.all(color: appColorPrimary, width: 3) : null,
              boxShadow: _focused
                  ? [BoxShadow(color: appColorPrimary.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 2)]
                  : null,
            ),
            child: widget.child,
          ),
        ),
      );
}
