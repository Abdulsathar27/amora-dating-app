/// Every route path in the app (go_router).
class AppRoutes {
  AppRoutes._();

  // Welcome & sign in
  static const splash = '/';
  static const welcome = '/welcome';
  static const ageGate = '/age';
  static const ageBlocked = '/age/blocked';
  static const signIn = '/sign-in';
  static const phone = '/sign-in/phone';
  static const verifyCode = '/sign-in/verify';
  static const pledge = '/pledge';

  // Create your profile
  static const createName = '/create/name';
  static const createIdentity = '/create/identity';
  static const createPhotos = '/create/photos';
  static const createIntention = '/create/intention';
  static const createInterests = '/create/interests';
  static const createVoice = '/create/voice';
  static const verifySelfie = '/create/selfie';
  static const locationPrivacy = '/create/location';
  static const profileReady = '/create/ready';

  // Tabs
  static const discover = '/discover';
  static const likes = '/likes';
  static const matches = '/matches';
  static const messages = '/messages';
  static const profile = '/profile';

  // Pushed over the tabs
  static const filters = '/filters';
  static const itsAMatch = '/match';
  static const person = '/person';
  static String chat(String matchId) => '/chat/$matchId';
  static const editProfile = '/profile/edit';
  static const managePhotos = '/profile/photos';
  static const voiceIntro = '/profile/voice';
  static const relationshipPrefs = '/profile/preferences';
  static const privacy = '/profile/privacy';
  static const account = '/profile/account';
  static const verification = '/profile/verification';
  static const safetyCentre = '/safety';
  static const datingSafely = '/safety/dating';

  // Report flow (person passed as query parameters)
  static String reportReason(String userId, String name) =>
      '/report/reason?user=$userId&name=${Uri.encodeComponent(name)}';
  static String reportDetails(String userId, String name) =>
      '/report/details?user=$userId&name=${Uri.encodeComponent(name)}';
  static const reportSent = '/report/sent';

  static bool isPreAuth(String loc) => loc.startsWith(welcome) || loc.startsWith(ageGate) || loc.startsWith(signIn);
  static bool isOnboarding(String loc) => loc == pledge || loc.startsWith('/create');
}
