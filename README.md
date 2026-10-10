# edstream-mobile

Edstream Mobile is an offline-first, enterprise-grade school management mobile application for teachers and students, built with Flutter.

## Features

- **Multi-Role Authentication**: Dedicated authentication flows for Teachers/Staff and Students with session persistence and auto-recovery.
- **Dynamic Academic Operations**:
  - **Dynamic CA Score Sheet**: Dynamically adapts Continuous Assessment test inputs between 2 CAs (`CA 1 (20)`, `CA 2 (20)`, `Exam (60)`) and 3 CAs (`CA 1 (10)`, `CA 2 (10)`, `CA 3 (10)`, `Exam (70)`) based on live school settings and exam configurations.
  - **Academic Period Tracking**: Prominently displays the Academic Session (e.g. `2024/2025 Session`) and Term (e.g. `3rd Term`) for every class and subject.
  - **Live Grade Calculation**: Real-time total calculation and grading (A to F) with custom brand status indicators.
- **Offline-First Synchronization**:
  - Local caching with optimistic UI updates.
  - Persistent mutation queue for offline grade submissions, auto-syncing when internet connectivity resumes.
  - Visual offline/online status banners.
- **Edstream Brand System**:
  - Built with the official Edstream design system tokens (`#0012BF`, `#4D44B5`, `#303972`, `#EFF0F6`).
  - Google Fonts (Poppins & Inter).

## Tech Stack

- **Framework**: Flutter 3.35.x (Dart 3.8.x)
- **Target Platforms**: Android & iOS
- **Network**: HTTP Client with live REST API (`https://api.edstream.ng/api/v1/`)
- **Storage**: `shared_preferences` local key-value & JSON cache store
