import 'package:get/get.dart';
import 'package:streamit_laravel/utils/common_base.dart';

/// Base controller with common functionality
abstract class BaseController<T> extends GetxController {
  RxBool isLoading = false.obs;
  RxBool isError = false.obs;
  RxString errorMessage = ''.obs;

  /// Future for FutureBuilder
  Rx<Future<T>?> contentFuture = Rx<Future<T>?>(null);

  /// Reactive data holder
  Rx<T?> content = Rx<T?>(null);

  bool get hasContent => content.value != null;

  /// Generic content handler
  Future<void> getContent({
    required Future<T> Function() contentApiCall,
    required void Function(T data) onSuccess,
    void Function(String error)? onError,
    bool showLoader = true,
  }) async {
    if (isLoading.value) return;

    setLoading(showLoader);

    // assign the API call Future to Rx for FutureBuilder
    final future = contentApiCall();

    contentFuture.value = future;

    await future.then((value) {
      content.value = value;
      onSuccess(value);
    }).catchError((e) {
      final message = e.toString();
      onError?.call(message);
      errorMessage.value = message;
      isError.value = true;
    }).whenComplete(() => setLoading(false));
  }

  void setLoading(bool loading) => isLoading.value = loading;

  void showSuccessMessage(String message) => successSnackBar(message);

  void showErrorMessage(String message) => errorSnackBar(error: message);
}

/// Base controller for list operations
abstract class BaseListController<T> extends BaseController {
  Rx<Future<List<T>>> listContentFuture = Future(() => <T>[]).obs;
  RxList<T> listContent = <T>[].obs;
  RxInt currentPage = 1.obs;
  RxBool isLastPage = false.obs;

  @override
  void onInit() {
    super.onInit();
    getListData(showLoader: false);
  }

  Future<void> onSwipeRefresh() async {
    currentPage.value = 1;
    listContent.clear();
    getListData();
  }

  Future<void> onRetry() async {
    await getListData();
  }

  // Pagination methods
  Future<void> onNextPage() async {
    if (!isLastPage.value) {
      currentPage.value++;
      getListData();
    }
  }

  // Abstract method to be implemented by subclasses
  Future<void> getListData({bool showLoader = true});
}