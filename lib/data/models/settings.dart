import 'package:equatable/equatable.dart';

/// Privacy + account switches (Privacy and Account screens).
class AppSettings extends Equatable {
  const AppSettings({
    this.showInDiscover = true,
    this.showOnline = false,
    this.readReceipts = true,
    this.approximateDistance = true,
    this.hidePhotosUntilApproved = true,
    this.voiceFromMatchesOnly = true,
    this.twoStep = true,
    this.phoneMasked = '',
    this.email,
    this.blockedCount = 0,
  });

  final bool showInDiscover;
  final bool showOnline;
  final bool readReceipts;
  final bool approximateDistance;
  final bool hidePhotosUntilApproved;
  final bool voiceFromMatchesOnly;
  final bool twoStep;
  final String phoneMasked;
  final String? email;
  final int blockedCount;

  static const keys = {
    'show_in_discover',
    'show_online',
    'read_receipts',
    'approximate_distance',
    'hide_photos_until_approved',
    'voice_from_matches_only',
    'two_step',
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    showInDiscover: json['show_in_discover'] as bool? ?? true,
    showOnline: json['show_online'] as bool? ?? false,
    readReceipts: json['read_receipts'] as bool? ?? true,
    approximateDistance: json['approximate_distance'] as bool? ?? true,
    hidePhotosUntilApproved: json['hide_photos_until_approved'] as bool? ?? true,
    voiceFromMatchesOnly: json['voice_from_matches_only'] as bool? ?? true,
    twoStep: json['two_step'] as bool? ?? true,
    phoneMasked: json['phone_masked'] as String? ?? '',
    email: json['email'] as String?,
    blockedCount: (json['blocked_count'] as num?)?.toInt() ?? 0,
  );

  bool flag(String key) => switch (key) {
    'show_in_discover' => showInDiscover,
    'show_online' => showOnline,
    'read_receipts' => readReceipts,
    'approximate_distance' => approximateDistance,
    'hide_photos_until_approved' => hidePhotosUntilApproved,
    'voice_from_matches_only' => voiceFromMatchesOnly,
    'two_step' => twoStep,
    _ => false,
  };

  AppSettings withFlag(String key, bool v) => AppSettings(
    showInDiscover: key == 'show_in_discover' ? v : showInDiscover,
    showOnline: key == 'show_online' ? v : showOnline,
    readReceipts: key == 'read_receipts' ? v : readReceipts,
    approximateDistance: key == 'approximate_distance' ? v : approximateDistance,
    hidePhotosUntilApproved: key == 'hide_photos_until_approved' ? v : hidePhotosUntilApproved,
    voiceFromMatchesOnly: key == 'voice_from_matches_only' ? v : voiceFromMatchesOnly,
    twoStep: key == 'two_step' ? v : twoStep,
    phoneMasked: phoneMasked,
    email: email,
    blockedCount: blockedCount,
  );

  @override
  List<Object?> get props => [
    showInDiscover,
    showOnline,
    readReceipts,
    approximateDistance,
    hidePhotosUntilApproved,
    voiceFromMatchesOnly,
    twoStep,
    phoneMasked,
    email,
    blockedCount,
  ];
}

enum ReportReason {
  harassment('harassment', 'Harassment or hate'),
  photos('inappropriate_photos', 'Inappropriate photos'),
  fake('fake_or_scam', 'Fake profile or scam'),
  underage('under_18', 'Seems under 18'),
  other('other', 'Something else');

  const ReportReason(this.value, this.label);
  final String value;
  final String label;
}
