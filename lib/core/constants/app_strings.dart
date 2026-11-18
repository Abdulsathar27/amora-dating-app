/// Every piece of user-facing copy in the app. Widgets reference these
/// instead of hard-coding text, so wording lives in one place (and is ready
/// to hand to a localisation tool later).
class AppStrings {
  AppStrings._();

  // ─── Brand ────────────────────────────────────────────────────────────
  static const wordmark = 'lumé';
  static const tagline = 'Come as you are.';

  // ─── Common ───────────────────────────────────────────────────────────
  static const back = 'Back';
  static const close = 'Close';
  static const cancel = 'Cancel';
  static const continueLabel = 'Continue';
  static const next = 'Next';
  static const done = 'Done';
  static const save = 'Save';
  static const skipForNow = 'Skip for now';
  static const tryAgain = 'Try again';
  static const pleaseTryAgain = 'Please try again.';
  static const verified = 'Verified';
  static const notYet = 'Not yet';
  static const report = 'Report';
  static const block = 'Block';
  static const pause = 'Pause';
  static const today = 'Today';
  static const yesterday = 'Yesterday';
  static const now = 'now';
  static const kids = 'Kids';
  static const smoking = 'Smoking';
  static const distance = 'Distance';
  static const age = 'Age';
  static const messages = 'Messages';
  static const voiceIntro = 'Voice intro';
  static const playVoiceIntro = 'Play voice intro';
  static const editProfile = 'Edit profile';
  static const privacy = 'Privacy';
  static const account = 'Account';
  static const verification = 'Verification';
  static const signOut = 'Sign out';
  static const deleteAccount = 'Delete account';
  static const safetyCentre = 'Safety centre';
  static const ourTeamReviewsEveryReport = 'Our team reviews every report';
  static const voiceNotesComingSoon = 'Voice notes arrive once audio upload is live.';

  // ─── Navigation tabs ──────────────────────────────────────────────────
  static const tabDiscover = 'Discover';
  static const tabLikes = 'Likes';
  static const tabMatches = 'Matches';
  static const tabMessages = 'Messages';
  static const tabProfile = 'Profile';

  // ─── Welcome / splash ─────────────────────────────────────────────────
  static const welcome1Title = 'Be known before you are chosen.';
  static const welcome1Body = 'Voices, stories and small details come first here.';
  static const welcome2Title = 'A voice says more than a bio.';
  static const welcome2Body = 'Add a short voice note or video whenever you feel ready.';
  static const welcome3Title = 'Safe by design, not by chance.';
  static const welcome3Body = 'Adults only, moderated photos, and privacy you control.';
  static const getStarted = 'Get started';
  static const alreadyHaveAccount = 'I already have an account';
  static const welcomeSampleName = 'Priya, 29';
  static const welcomeSampleQuote = '“I laugh at my own jokes. Fair warning.”';
  static const featureVerifiedTitle = 'Verified people';
  static const featureVerifiedBody = 'A quick selfie check confirms it is really them.';
  static const featureLocationTitle = 'Your location stays fuzzy';
  static const featureLocationBody = 'Others only ever see an approximate distance.';
  static const featureConsentTitle = 'You decide who reaches you';
  static const featureConsentBody = 'Photos and voice notes need your OK first.';
  static const featureHelpTitle = 'Help is one tap away';
  static const featureHelpBody = 'Block or report from any profile or chat.';

  // ─── Age gate ─────────────────────────────────────────────────────────
  static const ageGateTitle = 'First, your birthday.';
  static const ageGateSubtitle = 'Lumé is only for adults aged 18 and over.';
  static const day = 'Day';
  static const month = 'Month';
  static const year = 'Year';
  static const dayHint = 'DD';
  static const monthHint = 'MM';
  static const yearHint = 'YYYY';
  static const ageGateNote = 'Your profile shows your age. Your birthday stays private, and you can’t change it later.';
  static const confirmAdult = 'Confirm I’m 18 or over';
  static const ageBlockedTitle = 'Lumé is for adults only.';
  static const ageBlockedBody = 'You need to be 18 or older to join. We haven’t stored your details.';

  // ─── Sign in ──────────────────────────────────────────────────────────
  static const signInTitle = 'Glad you’re here.';
  static const signInSubtitle = 'Pick whichever is easiest. We never post anything for you.';
  static const continueWithPhone = 'Continue with phone number';
  static const continueWithApple = 'Continue with Apple';
  static const continueWithGoogle = 'Continue with Google';
  static const continueWithEmail = 'Continue with email';
  static const apple = 'Apple';
  static const google = 'Google';
  static const email = 'email';
  static const signInTerms = 'By continuing, you agree to our Terms and Community Guidelines, and confirm you’re at least 18.';
  static String signInComingSoon(String provider) => 'Sign in with $provider arrives with the backend. Use your phone number for now.';

  // ─── Phone & code ─────────────────────────────────────────────────────
  static const phoneTitle = 'What’s your number?';
  static const phoneSubtitle = 'We’ll text a code. It’s never shown on your profile.';
  static const mobileNumber = 'Mobile number';
  static const messageRates = 'Standard message rates may apply.';
  static const sendCode = 'Send code';
  static const codeTitle = 'Enter the code';
  static const codeMismatch = 'That code didn’t match.';
  static const sendNewCode = 'Send a new code';
  static const verify = 'Verify';
  static const enterFullNumber = 'Enter your full mobile number.';
  static String codeSentTo(String phone) => 'Sent to $phone';
  static String demoCode(String code) => 'Demo code: $code';
  static String resendCodeIn(int seconds) => 'Resend code in 0:${seconds.toString().padLeft(2, '0')}';

  // ─── Pledge ───────────────────────────────────────────────────────────
  static const pledgeTitle = 'One small promise.';
  static const pledgeSubtitle = 'Everyone here agrees to the same three things.';
  static const pledgeRespectTitle = 'Treat people with respect';
  static const pledgeRespectBody = 'Kindness first, even when it’s a no.';
  static const pledgeConsentTitle = 'Ask, and respect the answer';
  static const pledgeConsentBody = 'No means no. Silence isn’t a yes.';
  static const pledgeHonestTitle = 'Be who you say you are';
  static const pledgeHonestBody = 'Real photos, honest intentions.';
  static const iAgree = 'I agree';

  // ─── Create profile ───────────────────────────────────────────────────
  static const nameTitle = 'What should people call you?';
  static const firstName = 'First name';
  static const firstNameHelper = 'Only your first name is ever shown.';
  static const identityTitle = 'How do you identify?';
  static const identitySubtitle = 'Share as much as feels right.';
  static const whoToMeet = 'Who would you like to meet?';
  static const photosTitle = 'Show your world.';
  static const photosSubtitle = 'Add at least one photo where we can see your face.';
  static const photosReviewedNote = 'Every photo is reviewed for safety before anyone sees it.';
  static const intentionTitle = 'What are you hoping for?';
  static const intentionSubtitle = 'You can change this any time.';
  static const interestsTitle = 'What lights you up?';
  static const voiceTitle = 'Say hello in your own voice.';
  static const voiceSubtitle = 'Fifteen seconds is plenty. Try this one:';
  static const saveVoiceIntro = 'Save voice intro';
  static const stopRecording = 'Stop recording';
  static const recordVoiceIntro = 'Record voice intro';
  static String pickUpToFive(int chosen) => 'Pick up to five. $chosen chosen.';

  // ─── Finish setup ─────────────────────────────────────────────────────
  static const getVerified = 'Get verified';
  static const selfieTitle = 'Now, turn your head to the left.';
  static const selfieSubtitle = 'This scan confirms you match your photos. It’s deleted after the check.';
  static const takeSelfie = 'Take selfie';
  static const locationTitle = 'Nearby, but never exact.';
  static const locationSubtitle = 'People see a rounded distance. Your exact location is never shared.';
  static const showApproxDistance = 'Show approximate distance';
  static const approxDistanceExample = 'Example: about 3 km away';
  static const allowLocation = 'Allow while using Lumé';
  static const photosInReview = 'Your photos are being reviewed. It usually takes a minute or two.';
  static const startDiscovering = 'Start discovering';
  static String youreReady(String name) => 'You’re ready, $name.';

  // ─── Discover ─────────────────────────────────────────────────────────
  static const offlineTitle = 'We lost the connection.';
  static const offlineBody = 'Your likes are saved. Check your signal and we’ll pick up right where you left off.';
  static const emptyDeckTitle = 'That’s everyone nearby, for now.';
  static const emptyDeckBody = 'New people join every day. Try widening your distance, or polish your profile while you wait.';
  static const widenSearch = 'Widen my search';
  static const discoveryFilters = 'Discovery filters';
  static const viewFullProfile = 'View full profile';
  static const pauseVoiceIntro = 'Pause voice intro';
  static const pass = 'Pass';
  static const like = 'Like';
  static const superLike = 'Super Like';
  static const sendACompliment = 'Send a compliment';

  // ─── Filters ──────────────────────────────────────────────────────────
  static const filtersTitle = 'Who you’d like to meet';
  static const lookingFor = 'Looking for';
  static const verifiedOnly = 'Verified people only';
  static const hasVoiceIntro = 'Has a voice intro';
  static String ageRange(int min, int max) => '$min to $max';
  static String upToKm(int km) => 'Up to $km km';
  static String showPeople(int count) => 'Show $count people';

  // ─── Full profile ─────────────────────────────────────────────────────
  static const safetyOptions = 'Safety options';
  static const playVideoIntro = 'Play video intro';
  static const videoComingSoon = 'Video playback arrives with media uploads.';
  static const favouriteActivities = 'Favourite activities';
  static const hobbiesAndInterests = 'Hobbies and interests';
  static const relationshipGoals = 'Relationship goals';
  static const conversationStarters = 'Conversation starters';
  static const personality = 'Personality';
  static const onRepeat = 'On repeat';
  static String locationHidden(String distance) => '$distance · Exact location hidden';
  static String blockName(String name) => 'Block $name';

  // ─── Compliments ──────────────────────────────────────────────────────
  static const complimentHint = 'Be specific. It means more.';
  static const complimentPlaceholder = 'Your line about getting lost in bookshops made me smile…';
  static const sendCompliment = 'Send compliment';
  static const complimentVoice = 'Love your voice note';
  static const complimentSmile = 'Your smile!';
  static String complimentTitle(String name) => 'Send $name a compliment';
  static String complimentNote(String name) => '$name can read this and choose whether to reply.';
  static String complimentTaste(String interest) => 'Great $interest taste';
  static String complimentTellMore(String interest) => '$interest? Tell me more';

  // ─── Match ────────────────────────────────────────────────────────────
  static const itsAMatch = 'It’s a Match!';
  static const startConversation = 'Start conversation';
  static const continueDiscovering = 'Continue discovering';
  static String matchBody(String name) => 'You and $name both said yes. Say hello while it’s still exciting.';

  // ─── Likes ────────────────────────────────────────────────────────────
  static const likesEmptyTitle = 'Your admirers are on their way.';
  static const likesEmptyBody = 'Profiles with a voice intro get noticed more. It only takes fifteen seconds.';
  static const addVoiceIntro = 'Add a voice intro';
  static const likesTitle = 'They noticed you.';
  static const likedYourProfile = 'Liked your profile';
  static const compliment = 'Compliment';
  static String likedThisWeek(int count) => '$count ${count == 1 ? 'person' : 'people'} liked your profile this week.';

  // ─── Matches ──────────────────────────────────────────────────────────
  static const matchesEmptyTitle = 'Good things take a moment.';
  static const matchesEmptyBody = 'When someone you like likes you back, they’ll appear here.';
  static const keepDiscovering = 'Keep discovering';
  static const yourMatches = 'Your matches';
  static const waitingForHello = 'Waiting for your hello';
  static const gettingToKnow = 'Getting to know';
  static const matchedToday = 'Matched today';
  static const matchedLastWeek = 'Matched last week';
  static String sayHelloTo(String name) => 'Say hello to $name';
  static String messageName(String name) => 'Message $name';
  static String matchedDaysAgo(int days) => 'Matched $days ${days == 1 ? 'day' : 'days'} ago';

  // ─── Messages ─────────────────────────────────────────────────────────
  static const messagesEmptyTitle = 'Every great story starts with hello.';
  static const messagesEmptyBody = 'Once you match, your conversations will live here.';
  static const seeMyMatches = 'See my matches';
  static const moneyWarning = 'Never send money or personal details to someone you haven’t met.';
  static String youPreview(String preview) => 'You: $preview';
  static String unreadSuffix(int count) => '. $count unread';
  static String minutesShort(int m) => '${m}m';
  static String hoursShort(int h) => '${h}h';
  static String tabBadge(String label, int count) => '$label, $count new';

  // ─── Chat ─────────────────────────────────────────────────────────────
  static const conversationEnded = 'This conversation has ended.';
  static const matchRemoved = 'The match may have been removed.';
  static const onlineNow = 'Online now';
  static const conversationOptions = 'Conversation options';
  static const shareSomething = 'Share something';
  static const gifs = 'GIFs';
  static const send = 'Send';
  static const recordVoiceNote = 'Record a voice note';
  static const closeReactions = 'Close reactions';
  static const moreReactions = 'More reactions';
  static const reply = 'Reply';
  static const copyText = 'Copy text';
  static const reportMessage = 'Report message';
  static const photos = 'Photos';
  static const camera = 'Camera';
  static const voice = 'Voice';
  static const cameraComingSoon = 'The camera opens once photo upload is live.';
  static const searchGifs = 'Search GIFs';
  static const gifTrending = 'Trending';
  static const gifLaugh = 'Laugh';
  static const gifYes = 'Yes!';
  static const gifBlush = 'Blush';
  static const muteNotifications = 'Mute notifications';
  static const unmatch = 'Unmatch';
  static const unmatchSubtitle = 'Ends the conversation for both of you';
  static const gif = 'GIF';
  static const playVoiceMessage = 'Play voice message';
  static const photoHiddenBody = 'It stays hidden until you choose to see it.';
  static const viewPhoto = 'View photo';
  static const notNow = 'Not now';
  static const typing = 'Typing';
  static String matchedTodayWith(String name) => 'You and $name matched today';
  static String startersFrom(String name) => 'Something from $name’s profile to start with';
  static String photoConsentNote(String name) => '$name will be asked before any photo is shown.';
  static String viewProfileOf(String name) => 'View $name’s profile';
  static String wontBeTold(String name) => '$name won’t be told';
  static String sentPhotoAt(String time) => 'Sent a photo · $time';
  static String readAt(String time) => '$time · Read';
  static String sentAPhoto(String name) => '$name sent a photo';

  // ─── My profile ───────────────────────────────────────────────────────
  static const profileLoadFailed = 'Couldn’t load your profile.';
  static const profile = 'Profile';
  static const addVoiceTo100 = 'Add a voice intro to reach 100%';
  static const managePhotos = 'Manage photos';
  static const relationshipPreferences = 'Relationship preferences';
  static String percentComplete(int pct) => '$pct% complete';

  // ─── Edit profile ─────────────────────────────────────────────────────
  static const aboutYou = 'About you';
  static const yourPrompts = 'Your prompts';
  static const interests = 'Interests';
  static const saveChanges = 'Save changes';
  static String charactersOf(int used, int max) => '$used of $max characters';
  static String chosenCount(int count) => '$count chosen';

  // ─── Photos ───────────────────────────────────────────────────────────
  static const yourPhotos = 'Your photos';
  static const reorderHint = 'Hold and drag to reorder. Your first photo is the one people see first.';
  static const photoRejectedNote = 'One photo didn’t meet our guidelines because no person is visible. Tap it to replace it.';

  // ─── Relationship preferences ─────────────────────────────────────────
  static const prefsTitle = 'What you’re looking for';
  static const intention = 'Intention';
  static const openToMeeting = 'Open to meeting';
  static String km(int km) => '$km km';

  // ─── Voice intro ──────────────────────────────────────────────────────
  static const recordYourVoiceIntro = 'Record your voice intro';
  static const recordNewOne = 'Record a new one';
  static const upTo30Seconds = 'Up to 30 seconds';
  static const removeVoiceIntro = 'Remove voice intro';

  // ─── Settings ─────────────────────────────────────────────────────────
  static const showInDiscover = 'Show me in Discover';
  static const showInDiscoverSubtitle = 'Pause to hide your profile';
  static const showOnline = 'Show when I’m online';
  static const readReceipts = 'Read receipts';
  static const location = 'Location';
  static const approxDistanceOnly = 'Approximate distance only';
  static const exactLocationNeverShared = 'Exact location is never shared';
  static const hidePhotosUntilApproved = 'Hide photos until I approve';
  static const voiceFromMatchesOnly = 'Voice notes from matches only';
  static const backendComingSoon = 'Available once the backend is live.';
  static const phoneNumber = 'Phone number';
  static const emailLabel = 'Email';
  static const addForRecovery = 'Add for account recovery';
  static const twoStep = 'Two-step verification';
  static const notifications = 'Notifications';
  static const helpAndSupport = 'Help and support';
  static const signOutTitle = 'Sign out?';
  static const signOutBody = 'You can sign back in any time with your phone number.';
  static const deleteTitle = 'Delete your account?';
  static const deleteBody = 'Your profile, matches and messages will be removed permanently. This can’t be undone.';
  static const youreVerified = 'You’re verified.';
  static const notVerifiedYet = 'Not verified yet.';
  static const takeSelfieToVerify = 'Take a quick selfie so people know your photos are really you.';
  static const scanDeleted = 'Your verification scan was deleted after the check.';
  static String verifiedOn(String date) => ' Verified on $date.';
  static String verifiedBadgeBody(String suffix) => 'Your badge tells people your photos are really you.$suffix';

  // ─── Safety ───────────────────────────────────────────────────────────
  static const reportTitle = 'What happened?';
  static const reportConfidential = 'Your report is confidential.';
  static const reportMoreTitle = 'Tell us a little more.';
  static const reportMoreSubtitle = 'Only if you’d like to. It helps us act faster.';
  static const details = 'Details';
  static const alsoBlock = 'Also block this person';
  static const sendReport = 'Send report';
  static const reportThanksTitle = 'Thank you for telling us.';
  static const reportThanksBody = 'Our team will review this, usually within 24 hours. You won’t hear from this person again.';
  static const safetyHeroTitle = 'You deserve to feel safe here.';
  static const safetyHeroBody = 'Tools and support, whenever you need them.';
  static const reportSomeone = 'Report someone';
  static const blockedPeople = 'Blocked people';
  static const blockedPeopleInfo = 'Blocked people can’t see you or message you.';
  static const photoModeration = 'Photo moderation';
  static const photoModerationSubtitle = 'How we review images';
  static const photoModerationInfo = 'Every photo is checked by our team before anyone sees it.';
  static const locationPrivacy = 'Location privacy';
  static const approximateOnly = 'Approximate only';
  static const datingSafelyAndConsent = 'Dating safely and consent';
  static const datingSafely = 'Dating safely';
  static const datingSafelyHero = 'Good dates start with clear, kind communication.';
  static const askFirstTitle = 'Ask first, every time';
  static const askFirstBody = 'Before photos, calls or changing plans.';
  static const noIsFullTitle = 'No is a full sentence';
  static const noIsFullBody = 'Anyone can change their mind at any time.';
  static const meetPublicTitle = 'Meet in public';
  static const meetPublicBody = 'And tell a friend where you’ll be.';
  static const noMoneyTitle = 'Keep money out of it';
  static const noMoneyBody = 'Never send money to someone you’ve met here.';
  static String reportAbout(String name) => 'Your report about $name is confidential.';
  static String blockQuestion(String name) => 'Block $name?';
  static String blockBody(String name) => 'You won’t see each other again and your conversation will be removed. $name won’t be told.';

  // ─── Components ───────────────────────────────────────────────────────
  static String stepOf(int step, int total) => 'Step $step of $total';
}
