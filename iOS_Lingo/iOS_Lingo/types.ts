
export type ProficiencyLevel = 'Beginner' | 'Intermediate' | 'Expert';

export interface FeedbackItem {
  score: number; // 1-100
  feedback: string;
}

export interface ChallengeWordFeedback {
  word: string;
  used: boolean;
  feedback: string;
}

export interface AIFeedback {
  grammar: FeedbackItem;
  pronunciation: FeedbackItem;
  fluency: FeedbackItem;
  vocabulary: FeedbackItem;
  clarity: FeedbackItem;
  overallScore: number; // 1-100
  challengeWordsUsed: ChallengeWordFeedback[];
}

export interface Recording {
  id: string;
  prompt: string;
  transcription: string;
  feedback: AIFeedback;
  date: string;
  targetLanguage: string;
  challengeWords: string[];
  proficiencyLevel: ProficiencyLevel;
}

export enum Screen {
  Onboarding,
  Prompt,
  Recording,
  Loading,
  Feedback,
  Complete,
  Dashboard,
  Profile,
}
