import '../../models/dcc/dcc_user.dart';

class DccSession {
  static DccUser? currentUser;

  static void setUser(DccUser user) {
    currentUser = user;
  }

  static void clear() {
    currentUser = null;
  }

  static bool get isLoggedIn {
    return currentUser != null;
  }
}