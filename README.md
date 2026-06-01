# TruthLens - Real-Time Scam Detection and Alert System

TruthLens is a student-focused mobile app that helps users verify suspicious digital content in real time before they click, pay, or share sensitive data.

## Implemented MVP

- Submit suspicious messages, URLs, or screenshot notes
- Automatic risk score generation (`Low`, `Medium`, `High`)
- Community voting (`Scam` or `Safe`)
- Real-time feed simulation with periodic new reports
- High-risk alert tab
- Admin review workflow (`open`, `verifiedScam`, `verifiedSafe`)

## Tech Stack

- Frontend: Flutter + Material 3
- State Management: `provider`
- Analysis Engine: rule-based risk analyzer (keyword + URL heuristics)

## Project Structure

- `lib/main.dart` - app bootstrap and provider setup
- `lib/models/scam_report.dart` - report model and enums
- `lib/services/risk_analyzer.dart` - risk scoring logic
- `lib/providers/truthlens_provider.dart` - app state, feed, voting, admin actions
- `lib/screens/home_screen.dart` - report, feed, alerts, and admin UI

## Run Locally

1. Install Flutter SDK
2. In project root run:
   - `flutter pub get`
   - `flutter run`

## How This Maps to Your Proposal

- **Scam Reporting:** `Report` tab
- **Risk Score Generation:** `RiskAnalyzer.evaluate()`
- **Community Validation:** feed voting buttons
- **Real-Time Feed:** periodic simulated incoming suspicious reports
- **Push Alert Equivalent:** `Alerts` tab for high-risk entries
- **Admin Monitoring:** `Admin` tab status updates

## Recommended Next Steps (Production)

- Replace in-memory provider store with Firebase Firestore
- Add Firebase Authentication for student login
- Use Firebase Cloud Messaging for true push notifications
- Add image upload + OCR for screenshot parsing
- Upgrade risk scoring with ML phishing/text classifiers
