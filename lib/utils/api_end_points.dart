class APIEndPoints {
  static const String appConfiguration = 'app-configuration';

  //Auth & User
  static const String register = 'register';
  static const String socialLogin = 'social-login';
  static const String login = 'login';
  static const String logout = 'logout';
  static const String deviceLogout = 'device-logout';

  static const String deviceLogoutNoAuth = 'device-logout-data';
  static const String changePassword = 'change-password';
  static const String forgotPassword = 'forgot-password';
  static const String userDetail = 'user-detail';
  static const String updateProfile = 'update-profile';
  static const String deleteUserAccount = 'delete-account';
  static const String logOutAll = 'logout-all';
  static const String logOutAllNoAuth = 'logout-all-data';
  static const String getNotification = 'notification-list';
  static const String removeNotification = 'notification-remove';
  static const String clearAllNotification = 'notification-deleteall';

  //home choose service api
  static const String dashboardDetails = 'dashboard-detail';
  static const String dashboardDetailsOtherData = 'dashboard-detail-data';
  static const String genresDetails = 'genre-list';
  static const String actorDetails = 'castcrew-list';
  static const String watchList = 'watch-list';
  static const String deleteWatchList = 'delete-watchlist';
  static const String deleteDownloads = 'delete-download';
  static const String videoList = 'video-list';
  static const String planLists = 'plan-list';
  static const String movieLists = 'movie-list';
  static const String channelList = 'channel-list';
  static const String tvShowList = 'tvshow-list';
  static const String liveTvDashboard = 'livetv-dashboard';
  static const String liveTvDetails = 'livetv-details';
  static const String episodeList = 'episode-list';
  static const String contentDetails = 'content-details';
  static const String contentList = 'content-list';
  static const String saveRating = 'save-rating';
  static const String deleteRating = 'delete-rating';
  static const String saveDownload = 'save-download';
  static const String saveContinueWatch = 'save-continuewatch';
  static const String saveLikes = 'save-likes';
  static const String searchList = 'search-list';
  static const String searchContent = 'get-search';
  static const String comingSoon = 'coming-soon';
  static const String saveWatchlist = 'save-watchlist';
  static const String saveEntertainmentViews = 'save-entertainment-views';

  static const String profileDetails = 'profile-details';
  static const String accountSetting = 'account-setting';
  static const String reviewDetails = 'get-rating';
  static const String editProfile = 'update-profile';
  static const String saveReminder = 'save-reminder';
  static const String saveSubscriptionDetails = 'save-subscription-details';
  static const String subscriptionHistory = 'user-subscription_histroy';
  static const String cancelSubscription = 'cancle-subscription';
  static const String pageList = 'page-list';

  // Continue Watching Api
  static const String continueWatchList = 'continuewatch-list';
  static const String deleteContinueWatch = 'delete-continuewatch';

  // watch profile
  static const String getWatchingProfileList = 'user-profile-list';
  static const String editWatchingProfile = 'save-userprofile';
  static const String deleteWatchingProfile = 'delete-userprofile';

  // search
  static const String saveSearch = 'save-search';
  static const String deleteSearch = 'delete-search';
  static const String saveEntertainmentCompletedView = 'save-watch-content';

  static const String faqList = 'faq-list';
  static const String bannerList = 'banner-data';

  //TV Session Check
  static const String tvSessionCheck = 'tv/check-session';

  static const String initiateSession = 'tv/initiate-session';

  //   Unlocked video
  static const String rentedContentList = 'rented-content-list';
  static const String startDate = 'start-date';

  // Ads
  static const String getActiveVastAds = 'vast-ads/get-active';
  static const String getCustomAds = 'custom-ads/get-active';
}

class ApiRequestKeys {
  static const String idKey = 'id';

  static const String channelKey = 'channel_id';
  static const String userIdKey = 'user_id';
  static const String profileIdKey = 'profile_id';
  static const String deviceIdKey = 'device_id';

  static const String deviceNameKey = 'device_name';

  static const String platformKey = 'platform';
  static const String isRestrictedKey = 'is_restricted';
  static const String typeKey = 'type';
  static const String pageKey = 'page';
  static const String perPageKey = 'per_page';
  static const String seasonIdKey = 'season_id';
  static const String tvShowIdKey = 'tv_show_id';

  //region Review Ratings
  static const String reviewKey = 'review';

  //region User
  static String firstName = 'first_name';
  static String lastName = 'last_name';
  static String username = 'username';
  static String email = 'email';
  static String password = 'password';
  static String confirmPassword = 'confirm_password';
  static String mobile = 'mobile';
  static String address = 'address';
  static String displayName = 'display_name';
  static String profileImage = 'profile_image';
  static String oldPassword = 'old_password';
  static String newPassword = 'new_password';
  static String loginType = 'login_type';
  static String contactNumber = 'contact_number';
  static String fileUrl = 'file_url';
  static String isDemoUser = 'is_demo_user';
  static String gender = 'gender';
  static String dateOfBirth = 'date_of_birth';
//endregion
}
