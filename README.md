# CodetyHub

A Flutter GetX app for learning AI skills. Browse AI pathways, explore courses within each pathway, and track your learning journey.

## Features

- **Authentication** — Sign up and log in with local session persistence
- **AI Pathways** — Six curated learning tracks (ML, Deep Learning, NLP, Computer Vision, Generative AI, MLOps)
- **Courses** — Tap a pathway to view its courses with level, duration, and ratings
- **Search** — Filter pathways on the home screen
- **Modern UI** — Dark theme with gradient accents

## Getting Started

```bash
flutter pub get
flutter run
```

## Project Structure

```
lib/
├── main.dart
└── app/
    ├── controllers/   # GetX controllers
    ├── data/          # Auth service & mock data
    ├── models/        # User, Pathway, Course models
    ├── routes/        # GetX routing
    ├── theme/         # App colors & theme
    ├── views/         # Screens (auth, home, pathway)
    └── widgets/       # Reusable UI components
```

## Tech Stack

- Flutter
- GetX (state management, routing, dependency injection)
- GetStorage (local persistence)
- Google Fonts
