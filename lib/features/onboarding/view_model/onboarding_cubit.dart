import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/models/discovery.dart';
import '../../../data/models/profile.dart';
import '../../../data/repositories/discovery_repository.dart';
import '../../../data/repositories/profile_repository.dart';

const kPromptQuestions = [
  'A perfect Sunday',
  'My love language is',
  'I geek out on',
  'Green flags I look for',
  'Two truths and a lie',
  'The way to win me over',
];

const kInterestOptions = [
  'Travel', 'Coffee', 'Music', 'Movies', 'Hiking', 'Cooking', 'Gaming', 'Reading', 'Fitness',
  'Photography', 'Art', 'Dance', 'Pets', 'Cricket', 'Football', 'Yoga', 'Foodie', 'Tech',
];

enum OnboardingStep { basics, gender, intent, about, prompts, interests }

class OnboardingState extends Equatable {
  const OnboardingState({
    this.step = OnboardingStep.basics,
    this.name = '',
    this.age = 24,
    this.gender,
    this.interestedIn = InterestedIn.everyone,
    this.intent,
    this.bio = '',
    this.jobTitle = '',
    this.promptQuestion = 'A perfect Sunday',
    this.promptAnswer = '',
    this.interests = const {},
    this.isSubmitting = false,
    this.isDone = false,
    this.error,
  });

  final OnboardingStep step;
  final String name;
  final int age;
  final Gender? gender;
  final InterestedIn interestedIn;
  final RelationshipIntent? intent;
  final String bio;
  final String jobTitle;
  final String promptQuestion;
  final String promptAnswer;
  final Set<String> interests;
  final bool isSubmitting;
  final bool isDone;
  final String? error;

  bool get canContinue => switch (step) {
        OnboardingStep.basics => name.trim().length >= 2 && age >= 18,
        OnboardingStep.gender => gender != null,
        OnboardingStep.intent => intent != null,
        OnboardingStep.about => bio.trim().length >= 10,
        OnboardingStep.prompts => promptAnswer.trim().length >= 3,
        OnboardingStep.interests => interests.length >= 3,
      };

  bool get isLast => step == OnboardingStep.values.last;
  double get progress => (step.index + 1) / OnboardingStep.values.length;

  OnboardingState copyWith({
    OnboardingStep? step,
    String? name,
    int? age,
    Gender? gender,
    InterestedIn? interestedIn,
    RelationshipIntent? intent,
    String? bio,
    String? jobTitle,
    String? promptQuestion,
    String? promptAnswer,
    Set<String>? interests,
    bool? isSubmitting,
    bool? isDone,
    String? error,
  }) =>
      OnboardingState(
        step: step ?? this.step,
        name: name ?? this.name,
        age: age ?? this.age,
        gender: gender ?? this.gender,
        interestedIn: interestedIn ?? this.interestedIn,
        intent: intent ?? this.intent,
        bio: bio ?? this.bio,
        jobTitle: jobTitle ?? this.jobTitle,
        promptQuestion: promptQuestion ?? this.promptQuestion,
        promptAnswer: promptAnswer ?? this.promptAnswer,
        interests: interests ?? this.interests,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        isDone: isDone ?? this.isDone,
        error: error,
      );

  @override
  List<Object?> get props => [
        step, name, age, gender, interestedIn, intent, bio, jobTitle,
        promptQuestion, promptAnswer, interests, isSubmitting, isDone, error,
      ];
}

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit(this._profiles, this._discovery, {String initialName = ''})
      : super(OnboardingState(name: initialName));

  final ProfileRepository _profiles;
  final DiscoveryRepository _discovery;

  void nameChanged(String v) => emit(state.copyWith(name: v));
  void ageChanged(int v) => emit(state.copyWith(age: v));
  void genderSelected(Gender g) => emit(state.copyWith(gender: g));
  void interestedInSelected(InterestedIn v) => emit(state.copyWith(interestedIn: v));
  void intentSelected(RelationshipIntent v) => emit(state.copyWith(intent: v));
  void bioChanged(String v) => emit(state.copyWith(bio: v));
  void jobChanged(String v) => emit(state.copyWith(jobTitle: v));
  void promptQuestionSelected(String q) => emit(state.copyWith(promptQuestion: q));
  void promptAnswerChanged(String v) => emit(state.copyWith(promptAnswer: v));

  void interestToggled(String i) {
    final next = Set<String>.of(state.interests);
    next.contains(i) ? next.remove(i) : next.add(i);
    emit(state.copyWith(interests: next));
  }

  void back() {
    if (state.step.index == 0) return;
    emit(state.copyWith(step: OnboardingStep.values[state.step.index - 1]));
  }

  Future<void> next() async {
    if (!state.canContinue) return;
    if (!state.isLast) {
      emit(state.copyWith(step: OnboardingStep.values[state.step.index + 1]));
      return;
    }
    emit(state.copyWith(isSubmitting: true));
    try {
      await _profiles.updateMyProfile({
        'name': state.name.trim(),
        'age': state.age,
        'gender': state.gender!.value,
        'intent': state.intent!.value,
        'bio': state.bio.trim(),
        if (state.jobTitle.trim().isNotEmpty) 'job_title': state.jobTitle.trim(),
        'prompts': [ProfilePrompt(question: state.promptQuestion, answer: state.promptAnswer.trim()).toJson()],
        'interests': state.interests.toList(),
        'complete_onboarding': true,
      });
      final prefs = await _discovery.preferences();
      await _discovery.savePreferences(prefs.copyWith(interestedIn: state.interestedIn));
      emit(state.copyWith(isSubmitting: false, isDone: true));
    } on ApiException catch (e) {
      emit(state.copyWith(isSubmitting: false, error: e.message));
    }
  }
}
