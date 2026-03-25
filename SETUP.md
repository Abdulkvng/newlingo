# Lingo - iOS App + Backend Setup

## Architecture

```
new_lingo/
├── backend/                    # Node.js/Express API server
│   ├── server.js              # Express app entry point
│   ├── database/
│   │   ├── schema.sql         # SQLite schema (auto-created)
│   │   └── db.js              # Database helpers + adaptive learning queries
│   ├── routes/
│   │   ├── auth.js            # Register, login, profile management
│   │   ├── sessions.js        # Prompts, evaluation, history
│   │   └── analytics.js       # Learning insights
│   ├── services/
│   │   ├── gemini.js          # Gemini AI integration
│   │   └── adaptive.js        # Adaptive prompt selection + analytics
│   └── middleware/
│       └── auth.js            # JWT authentication
│
└── ios/Lingo/Lingo/           # Native SwiftUI iOS app
    ├── LingoApp.swift         # App entry point
    ├── Models/Models.swift    # All data models
    ├── Theme/LingoTheme.swift # Color palette + reusable styles
    ├── Services/
    │   ├── APIService.swift   # Backend API client
    │   └── AudioRecorder.swift # Microphone recording
    ├── ViewModels/
    │   └── AppState.swift     # Central app state (MVVM)
    └── Views/
        ├── RootView.swift     # Screen router
        ├── Screens/           # Full-screen views
        │   ├── OnboardingView.swift
        │   ├── PromptView.swift
        │   ├── RecordingView.swift
        │   ├── LoadingView.swift
        │   ├── FeedbackView.swift
        │   ├── CompletionView.swift
        │   ├── DashboardView.swift
        │   └── ProfileView.swift
        └── Components/        # Reusable UI components
            ├── LingoHeader.swift
            ├── ScoreCardView.swift
            ├── ChallengeWordsCard.swift
            ├── RadarChartView.swift
            ├── ProficiencyPicker.swift
            ├── FlowLayout.swift
            └── ScoreTrendChart.swift
```

## Backend Setup

1. Navigate to the backend directory:
   ```bash
   cd new_lingo/backend
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Create a `.env` file from the example:
   ```bash
   cp .env.example .env
   ```

4. Add your Gemini API key to `.env`:
   ```
   GEMINI_API_KEY=your_key_here
   JWT_SECRET=a_random_secret_string
   ```

5. Start the server:
   ```bash
   npm run dev
   ```

The SQLite database is auto-created on first run at `backend/lingo.db`.

## iOS App Setup

1. Open Xcode and create a new project:
   - Choose **App** template
   - Product Name: **Lingo**
   - Interface: **SwiftUI**
   - Language: **Swift**

2. Delete the auto-generated `ContentView.swift`

3. Drag all files from `new_lingo/ios/Lingo/Lingo/` into your Xcode project

4. In your target settings, add `Info.plist` entries:
   - `NSMicrophoneUsageDescription`: "Lingo needs microphone access to record your speech for language evaluation."

5. Update `APIService.swift` with your backend URL:
   - For simulator: `http://localhost:3001/api`
   - For device on same network: `http://YOUR_IP:3001/api`

6. Build and run

## Key Features (Beyond Web App)

### Adaptive Learning Engine
- Tracks your weakest skills across all sessions
- Selects prompts that target your weak areas
- Generates challenge words based on what you need to practice
- Spaced repetition for vocabulary mastery

### User Authentication
- Secure JWT-based auth
- Persistent login across sessions
- All progress synced to backend

### Database-Backed Progress
- Full session history stored in SQLite
- Skill profiles with rolling averages
- Streak tracking (daily practice)
- Vocabulary bank with mastery levels

### Learning Analytics
- Skill breakdown with rolling averages
- Improvement rate tracking
- Practice pattern analysis (which days you practice)
- Vocabulary mastery statistics

### iOS-Native Experience
- Native SwiftUI with iOS design patterns
- Custom radar chart (no external dependencies)
- Custom line chart for score trends
- Flow layout for challenge word tags
- Native audio recording with AVFoundation
- Spring animations on completion
