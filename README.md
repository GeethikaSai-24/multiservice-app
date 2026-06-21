# MultiService App

A Flutter mobile application for a multi-service appointment booking platform. Users can browse service categories, discover providers by location, book appointments, manage bookings, submit reviews, and receive local reminders.

## Project Role

This repository is the frontend client for the full MultiService Appointment Booking System.

Related backend repository:
- https://github.com/GeethikaSai-24/multiservice-backend

## Features

- User registration and login
- Forgot password and reset flow
- Browse service categories and services
- Filter providers by service and location
- View provider details, ratings, and reviews
- Book appointments with slot selection
- View booking history and booking details
- Simulated payment method flow
- Local appointment reminder notifications
- Separate screens for admin and provider flows
- Chat and notification related screens

## Tech Stack

- Flutter
- Dart
- HTTP
- Shared Preferences
- Image Picker
- Flutter Local Notifications
- Timezone
- URL Launcher

## Project Structure

- `lib/features/auth/` authentication screens
- `lib/features/home/` home and discovery flow
- `lib/features/admin/` admin-facing screens
- `lib/features/provider/` provider dashboard screen
- `lib/features/chat/` chat UI screens
- `lib/services/` API, booking, payment, and notification logic
- `lib/main.dart` application entry point

## Getting Started

1. Install Flutter and Dart.
2. Clone this repository.
3. Install dependencies:
   `flutter pub get`
4. Run the app:
   `flutter run`

## Backend Connection

This app is designed to work with the Django backend in `multiservice-backend`.

Before running full flows, make sure:
- the backend server is running
- the API base URL in the frontend points to the backend server
- the emulator or device can reach the backend host

## Current Limitations

- Some flows are still oriented toward local development setup.
- Online payment is not fully integrated with backend payment processing.
- Additional environment-based configuration would improve deployment readiness.

