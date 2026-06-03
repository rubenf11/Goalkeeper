# GoalKeeper

GoalKeeper is a multi-platform Flutter habit tracking app focused on consistent progress. Users can create habits, log entries, attach photo moments, track progress over time, and unlock category-based achievements.

The project code is available on GitHub, in the following repository: https://github.com/rubenf11/Goalkeeper

## Project Overview

The app uses a layered architecture:

- UI: screens and reusable widgets
- Services: application logic and orchestration
- Repositories: persistence and backend integrations
- Models: typed domain entities

Authentication and structured data are managed with Firebase (Auth + Firestore). Media uploads are stored in Supabase Storage.

## Core Features

- Email/password authentication (register, login, logout)
- Habit creation with:
	- Category
	- Frequency (daily, weekly, monthly, yearly)
	- Goal and unit
	- Tracking mode: manual, step counter, or chronometer
	- Optional "limit goal" mode
- Habit progress and analytics:
	- Current progress against goal
	- Streak, highest streak, completed periods
	- Daily/weekly/monthly charts
- Entry logging:
	- Manual value or time duration
	- Optional photo and caption per entry
- Moments gallery:
	- View photo moments by user or habit
	- Open moment details linked to its entry
- Achievement system:
	- Category medals (bronze/silver/gold/green) based on completion points
- Profile:
	- Upload/update profile photo
	- View active/completed habits and moments
- Background recording notifications:
	- Ongoing notifications while step/timer tracking is active

## App Structure

Key folders under `lib/`:

- `main.dart`: app bootstrap, Firebase/Supabase initialization, providers, auth gate
- `screens/`: primary app views (login, register, home, habit details, profile, achievements, etc.)
- `services/`: business logic for auth, habits, entries, moments, tracking
- `data/models/`: domain models (`Habit`, `Entry`, `MomentPhoto`, achievements, tracking data)
- `data/repositories/`: Firestore/Auth/Supabase data access
- `widgets/`: reusable UI components (habit cards, filters, dialogs, sheets)
- `config/`: app config, including Supabase constants

## Navigation Flow

1. App starts and initializes Firebase + Supabase.
2. Auth state is observed in `main.dart`.
3. If signed out, user sees `LoginScreen`.
4. If signed in, user enters `MainScreen` with bottom tabs:
	 - Home
	 - Add Habit
	 - Achievements
	 - Profile

## Data and Backend

- Firebase Auth: account management
- Cloud Firestore:
	- `users` collection for profile metadata
	- `habits` collection for habit documents
	- `habits/{habitId}/entries` subcollection for logs/moments
- Supabase Storage:
	- `moments` bucket for entry and profile images

When entries are created, habit stats are recalculated to keep progress, streaks, and completion metrics up to date.

## Tech Stack

- Flutter (Material)
- Provider (dependency injection / service access)
- Firebase Core, Auth, Firestore
- Supabase Flutter (storage)
- fl_chart (analytics charts)
- image_picker (camera/gallery)
- pedometer + permission_handler (step tracking)
- flutter_background_service + flutter_local_notifications (background status notifications)

## Local Setup

### Prerequisites

- Flutter SDK (stable)
- Dart SDK (compatible with this project)
- Android Studio and/or Xcode (for mobile targets)
- Firebase project configured for your platforms
- Supabase project and storage bucket

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Firebase configuration

- Ensure `lib/firebase_options.dart` matches your Firebase project.
- Ensure platform files are present and valid (for example `android/app/google-services.json`).

### 3. Supabase configuration

- Update `lib/config/supabase_config.dart` with your project URL and anon key.
- Ensure the storage bucket used by the app exists (default: `moments`).

### 4. Run the app

```bash
flutter run
```

## Testing

Run tests with:

```bash
flutter test
```

## Notes

- Background recording and step tracking behavior can vary by platform and OS battery settings.
- Camera/gallery and activity recognition require runtime permissions on supported platforms.
