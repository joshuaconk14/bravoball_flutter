class OnboardingQuestion {
  final String question;
  final List<String> options;
  final bool isInput;
  final bool isMultiSelect;

  OnboardingQuestion({
    required this.question,
    required this.options,
    this.isInput = false,
    this.isMultiSelect = false,
  });
}

final List<OnboardingQuestion> onboardingQuestions = [
  OnboardingQuestion(
    question: 'What is your primary soccer goal?',
    options: [
      'Improve my overall skill level',
      'Be the best player on my team',
      'Get scouted for college',
      'Become a professional footballer',
      'Have fun and enjoy the game',
    ],
  ),
  OnboardingQuestion(
    question: 'How much training experience do you have?',
    options: [
      'Beginner',
      'Intermediate',
      'Advanced',
      'Professional',
    ],
  ),
  OnboardingQuestion(
    question: 'What position do you play?',
    options: [
      'Goalkeeper',
      'Fullback',
      'Center-back',
      'Defensive Midfielder',
      'Center Midfielder',
      'Attacking Midfielder',
      'Winger',
      'Striker',
    ],
  ),
  OnboardingQuestion(
    question: 'What age range do you fall under?',
    options: [
      'Under 12',
      '13–16',
      '17–19',
      '20–29',
      '30+',
    ],
  ),
  OnboardingQuestion(
    question: 'What are your strengths?',
    options: [
      'Passing',
      'Dribbling',
      'Shooting',
      'First touch',
      'Defending',
      'Goalkeeping',
      'Fitness'
    ],
    isMultiSelect: true,
  ),
  OnboardingQuestion(
    question: 'What would you like to work on?',
    options: [
      'Passing',
      'Dribbling',
      'Shooting',
      'First touch',
      'Defending',
      'Goalkeeping',
      'Fitness'
    ],
    isMultiSelect: true,
  ),
];
// Registration step will be handled as a form, not a question. 