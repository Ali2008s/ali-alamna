import 'dart:async';
import 'package:get/get.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:streamit_laravel/screens/live_tv/live_tv_details/model/live_tv_details_response.dart';
import 'package:streamit_laravel/screens/live_tv/model/live_tv_dashboard_response.dart';
import '../../../network/core_api.dart';
import '../../../utils/app_common.dart';
import '../../../utils/constants.dart';

class LiveShowDetailsController extends GetxController {
  RxBool isLoading = true.obs;
  RxBool isRefresh = false.obs;
  RxBool isPipMode = false.obs;

  RxBool isFullScreenEnable = false.obs;
  Rx<Future<LiveShowDetailResponse>> getLiveShowDetailsFuture = Future(() => LiveShowDetailResponse(data: LiveShowModel())).obs;
  Rx<LiveShowModel> liveShowDetails = LiveShowModel().obs;

  @override
  void onInit() {
    if (Get.arguments is ChannelModel) {
      liveShowDetails(LiveShowModel.fromJson((Get.arguments as ChannelModel).toJson()));
    }
    getLiveShowDetail();
    super.onInit();
  }

  ///Get Live SHow List
  Future<void> getLiveShowDetail() async {
    String? channelId = Get.arguments is ChannelModel ? (Get.arguments as ChannelModel).id.toString() : Get.arguments as String?;

    if (channelId == "0" || channelId == "-1") {
      log('Custom channel detected, skipping API call');
      isLoading(false);
      return;
    }

    isLoading(true); // Keep loading indicator for valid channels
    await getLiveShowDetailsFuture(CoreServiceApis.getLiveShowDetails(channelId: (Get.arguments as ChannelModel).id, userId: loginUserData.value.id)).then((value) {
      isSupportedDevice(value.data.isDeviceSupported);
      setValue(SharedPreferenceConst.IS_SUPPORTED_DEVICE, value.data.isDeviceSupported);
      liveShowDetails(value.data);
    }).onError((error, stackTrace) {
      log('getLiveShowDetails Err: $error');
    }).whenComplete(() => isLoading(false));
  }

  @override
  Future<void> onClose() async {
    super.onClose();
  }
}