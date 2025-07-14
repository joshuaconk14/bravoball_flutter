# BravoBall - User Journey PRD

## 🎯 Overview
This document maps the complete user journey through the BravoBall app, from first launch to advanced feature usage. It serves as the definitive guide for understanding user flows and interactions.

## 📱 App Entry Points

### 1. First-Time Launch
- **App Store Download** → **Initial Launch** → **Welcome Screen**
- **Options**: Create Account, Login, Try as Guest
- **Key Decision Point**: User chooses their engagement level

### 2. Returning User
- **App Launch** → **Authentication Check** → **Main App**
- **Auto-login**: Uses stored tokens for seamless experience
- **Session Recovery**: Continues from last session if incomplete

## 🚀 User Flow: First-Time Experience

### Welcome Screen
```
App Launch
│
├── [Create Account Button] → Onboarding Flow
├── [Login Button] → Login Screen
└── [Try as Guest Button] → Guest Mode
```

**Decision Factors:**
- New users typically choose "Create Account" for full experience
- Returning users use "Login"
- Hesitant users choose "Try as Guest" for low-commitment trial

### Guest Mode Journey
```
Try as Guest
│
├── Limited Drill Access (28 drills)
├── Basic Session Generation
├── No Progress Tracking
├── Account Creation Prompts
└── Conversion Opportunities
```

**Key Touchpoints:**
- **Drill Limits**: After viewing 10+ drills, show conversion prompt
- **Session Limits**: Allow 2-3 sessions before requiring account
- **Progress Blocking**: "Create account to track progress"
- **Favorites Blocking**: "Sign up to save favorite drills"

## 🎓 Onboarding Flow (New Users)

### Step 1: Welcome & Character Introduction
```
Initial Screen
│
├── [Create Account] → Preview Screen
└── [Login] → Login Flow
```

### Step 2: Bravo Character Introduction
```
Preview Screen
│
├── Bravo Animation (Center → Upper Left)
├── "Hello! I'm Bravo!" (Typewriter Effect)
├── [Next] → "I'll help you train after 6 questions!"
└── [Let's Go!] → Question Flow
```

### Step 3: Six-Question Assessment
```
Questions (with Bravo guidance):
│
├── Q1: "What is your primary soccer goal?"
│   Options: Improve skills, Be best on team, Get scouted, Go pro, Have fun
│
├── Q2: "How much training experience do you have?"
│   Options: Beginner, Intermediate, Advanced, Professional
│
├── Q3: "What position do you play?"
│   Options: GK, Fullback, CB, CDM, CM, CAM, Winger, Striker
│
├── Q4: "What age range do you fall under?"
│   Options: Under 12, 13-16, 17-19, 20-29, 30+
│
├── Q5: "What are your strengths?" (Multi-select)
│   Options: Passing, Dribbling, Shooting, First Touch
│
└── Q6: "What would you like to work on?" (Multi-select)
    Options: Passing, Dribbling, Shooting, First Touch
```

### Step 4: Registration
```
Registration Form
│
├── Email Input (with validation)
├── Password Input (with strength meter)
├── Confirm Password
├── Live Validation Feedback
└── [Create Account] → Account Created
```

### Step 5: Welcome to BravoBall
```
Account Created
│
├── Welcome Animation
├── Initial Session Generation
└── → Main App (Home Field)
```

## 🏠 Main App Navigation

### Tab Structure
```
Main App
│
├── Tab 1: Home (Session Generator)
├── Tab 2: Progress
├── Tab 3: Saved Drills
└── Tab 4: Profile
```

## 🎯 Core User Journey: Training Session

### Step 1: Session Generation (Home Tab)
```
Home Screen
│
├── "Backpack training" Button
├── Filter Options:
│   ├── Time (15min - 2h+)
│   ├── Equipment (Ball, Cones, Goal)
│   ├── Training Style (Low/Medium/High Intensity)
│   ├── Location (Full Field, Small Space, etc.)
│   ├── Difficulty (Beginner, Intermediate, Advanced)
│   └── Target Skills (Passing, Shooting, Dribbling, First Touch)
│
├── [Generate Session] → Session Created
└── [Use Saved Filter] → Quick Generation
```

### Step 2: Session Display
```
Generated Session
│
├── Session Overview:
│   ├── Total Duration
│   ├── Drill Count
│   ├── Equipment Needed
│   └── Skill Focus
│
├── Drill List:
│   ├── Drill 1 (with video thumbnail)
│   ├── Drill 2 (with video thumbnail)
│   └── Drill 3 (with video thumbnail)
│
├── Actions:
│   ├── [Start Session] → Drill Execution
│   ├── [Save Session] → Saved Drills
│   ├── [Regenerate] → New Session
│   └── [Edit Session] → Drill Management
```

### Step 3: Drill Execution
```
Drill Execution
│
├── Drill Video (Auto-play)
├── Drill Details:
│   ├── Instructions
│   ├── Tips
│   ├── Equipment
│   └── Duration/Sets/Reps
│
├── Timer/Counter (if applicable)
├── Controls:
│   ├── [Mark Complete] → Next Drill
│   ├── [Skip] → Next Drill
│   ├── [Favorite] → Save to Favorites
│   └── [Need Help?] → Tips/Instructions
│
└── Session Progress Bar
```

### Step 4: Session Completion
```
Session Complete
│
├── Completion Celebration
├── Session Summary:
│   ├── Duration Completed
│   ├── Drills Completed
│   ├── Skills Trained
│   └── XP/Points Earned
│
├── Progress Updates:
│   ├── Streak Updates
│   ├── Skill Improvements
│   └── Achievement Unlocks
│
└── [Continue Training] or [Finish Session]
```

## 📊 Progress Tracking Journey

### Progress Tab Features
```
Progress Tab
│
├── Training Overview:
│   ├── Current Streak
│   ├── Total Sessions
│   ├── Hours Trained
│   └── Favorite Skills
│
├── Skill Development:
│   ├── Passing Progress
│   ├── Shooting Progress
│   ├── Dribbling Progress
│   └── First Touch Progress
│
├── Recent Activity:
│   ├── Last 7 Days
│   ├── Session History
│   └── Completed Drills
│
└── Goals & Challenges:
    ├── Weekly Goals
    ├── Monthly Challenges
    └── Achievement Badges
```

## 💾 Saved Drills Management

### Saved Drills Tab
```
Saved Drills Tab
│
├── Drill Collections:
│   ├── Favorites (Auto-generated)
│   ├── Custom Collections
│   └── [Create New Collection]
│
├── Quick Access:
│   ├── Recent Drills
│   ├── Most Used
│   └── Recommended
│
└── Drill Search:
    ├── Search by Name
    ├── Filter by Skill
    ├── Filter by Equipment
    └── Filter by Difficulty
```

### Collection Management
```
Collection Management
│
├── Create Collection:
│   ├── Name Collection
│   ├── Add Description
│   ├── Select Drills
│   └── Save Collection
│
├── Edit Collection:
│   ├── Add/Remove Drills
│   ├── Reorder Drills
│   └── Update Details
│
└── Use Collection:
    ├── Start Collection as Session
    ├── View Individual Drills
    └── Share Collection (Future)
```

## 👤 Profile Management

### Profile Tab Features
```
Profile Tab
│
├── User Info:
│   ├── Email/Username
│   ├── Training Stats
│   └── Account Status
│
├── Account Settings:
│   ├── Edit Details
│   ├── Change Password
│   └── Notification Settings
│
├── App Settings:
│   ├── Training Preferences
│   ├── Video Quality
│   └── Offline Storage
│
├── Support:
│   ├── Discord Community
│   ├── Privacy Policy
│   ├── Terms of Service
│   └── Share App
│
└── Account Actions:
    ├── Logout
    └── Delete Account
```

## 🔍 Advanced Features

### Filter Management
```
Filter System
│
├── Quick Filters:
│   ├── Time-based
│   ├── Equipment-based
│   └── Skill-based
│
├── Advanced Filters:
│   ├── Multiple Criteria
│   ├── Custom Combinations
│   └── Saved Configurations
│
└── Filter Actions:
    ├── Apply Filters
    ├── Save Filter Set
    ├── Clear Filters
    └── Reset to Default
```

### Drill Discovery
```
Drill Discovery
│
├── Browse All Drills:
│   ├── Category View
│   ├── Skill-based Browsing
│   └── Difficulty Progression
│
├── Search Functionality:
│   ├── Text Search
│   ├── Skill Filtering
│   └── Equipment Filtering
│
└── Drill Details:
    ├── Full Instructions
    ├── Video Demonstration
    ├── Tips & Variations
    └── User Ratings (Future)
```

## 🔄 State Management & Persistence

### User State Persistence
```
App State
│
├── Authentication State:
│   ├── Login Status
│   ├── Token Management
│   └── User Preferences
│
├── Session State:
│   ├── Current Session
│   ├── Drill Progress
│   └── Timer States
│
├── Progress State:
│   ├── Completion History
│   ├── Skill Tracking
│   └── Achievement Progress
│
└── Offline State:
    ├── Cached Drills
    ├── Offline Progress
    └── Sync Queue
```

### Cross-Session Continuity
```
Session Continuity
│
├── Interrupted Session:
│   ├── Save Progress
│   ├── Resume Option
│   └── Alternative Completion
│
├── App Backgrounding:
│   ├── Timer Continuation
│   ├── State Preservation
│   └── Notification Support
│
└── Device Changes:
    ├── Cloud Sync
    ├── Cross-device Access
    └── Preference Transfer
```

## 🎯 Conversion Opportunities

### Guest → Registered User
```
Conversion Points
│
├── Drill Limit Reached
├── Progress Tracking Blocked
├── Favorites Feature Blocked
├── Session Save Blocked
└── Social Features Teased
```

### Registered → Premium (Future)
```
Premium Conversion
│
├── Advanced Analytics
├── Unlimited Drill Access
├── Coach Features
├── Priority Support
└── Exclusive Content
```

## 📱 Platform-Specific Considerations

### iOS Specific
- **App Store Guidelines**: Compliance with review guidelines
- **iOS Permissions**: Camera, microphone, notifications
- **iOS Features**: Siri integration, Apple Watch support

### Android Specific
- **Google Play Guidelines**: Compliance with store policies
- **Android Permissions**: Similar to iOS with Android-specific handling
- **Android Features**: Google Assistant, Wear OS support

---

*This user journey serves as the blueprint for all user experience decisions and feature development in BravoBall.* 