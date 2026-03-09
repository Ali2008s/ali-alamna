import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../utils/constants.dart';
import '../../subscription/model/subscription_plan_model.dart';
import '../model/login_response.dart';

//region FIREBASE AUTH
final FirebaseAuth auth = FirebaseAuth.instance;
//endregion

class GoogleSignInAuthService {
  static final GoogleSignIn googleSignIn = GoogleSignIn();

  static Future<UserData> signInWithGoogle() async {
    GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();

    if (googleSignInAccount != null) {
      final GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      final UserCredential authResult = await auth.signInWithCredential(credential);
      final User user = authResult.user!;
      assert(!user.isAnonymous);

      final User currentUser = auth.currentUser!;
      assert(user.uid == currentUser.uid);

      log('CURRENTUSER: $currentUser');

      await googleSignIn.signOut();

      String firstName = '';
      String lastName = '';
      if (currentUser.displayName.validate().split(' ').isNotEmpty) firstName = currentUser.displayName.splitBefore(' ');
      if (currentUser.displayName.validate().split(' ').length >= 2) lastName = currentUser.displayName.splitAfter(' ');

      /// Create a temporary request to send
      UserData tempUserData = UserData(planDetails: SubscriptionPlanModel())
        ..mobile = currentUser.phoneNumber.validate()
        ..email = currentUser.email.validate()
        ..firstName = firstName.validate()
        ..lastName = lastName.validate()
        ..profileImage = currentUser.photoURL.validate()
        ..loginType = LoginTypeConst.LOGIN_TYPE_GOOGLE
        ..fullName = currentUser.displayName.validate();

      return tempUserData;
    } else {
      throw "User not created";
    }
  }
}
