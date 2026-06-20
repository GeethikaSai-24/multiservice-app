# MultiService Appointment Booking System Documentation

## Title
**MULTISERVICE APPOINTMENT BOOKING SYSTEM**

Frontend and Backend Project Documentation

## Abstract
The MultiService Appointment Booking System is a full-stack application developed to streamline the process of discovering services, viewing providers, scheduling appointments, managing reviews, and tracking bookings from a single platform. The system consists of a Flutter-based frontend application and a Django REST backend with SQLite database support. The frontend offers user-friendly screens for authentication, category browsing, provider search, booking, payment method selection, and notifications. The backend manages data models, API endpoints, authentication, booking validation, provider filtering, and review storage. This project demonstrates the integration of mobile application development with REST API architecture and database-driven service management.

## Introduction
Many service booking processes are still fragmented across phone calls, separate apps, or manual tracking. This causes inconvenience for users and makes appointment management less efficient. The MultiService Appointment Booking System solves this problem by combining multiple service categories such as doctor consultations and home services into a single digital platform.

The project has two main parts:

- A **Flutter frontend** in `multiservice_frontend` for user interaction
- A **Django backend** in `multiservice_app` for API handling and data management

Together, these parts provide an end-to-end workflow for registration, login, service discovery, provider listing, appointment booking, review management, and booking history tracking.

## Objectives
1. To build a mobile application that supports booking of multiple service types.
2. To design a backend API system for users, services, providers, reviews, and bookings.
3. To provide secure authentication using JWT tokens.
4. To allow location-based provider filtering and slot-based appointment booking.
5. To maintain booking records and cancellation support.
6. To support provider reviews and ratings.
7. To schedule reminder notifications before appointments.
8. To demonstrate frontend-backend integration in a real-world full-stack project.

## Problem Statement
Users often struggle to find reliable service providers and manage appointments efficiently because existing solutions are fragmented. There is a need for a centralized system where users can discover services, compare providers, book time slots, and track appointments in one place.

## Scope of the Project
The project covers both client-side and server-side development for a multi-service appointment booking system. The implemented scope includes:

- User registration and login
- Forgot password and password reset
- Service category and service listing
- Provider filtering by service and location
- Provider detail page with gallery and contact details
- Review creation, updating, deletion, and viewing
- Booking creation with date and slot management
- Booking history and cancellation
- Local appointment reminder notifications
- JWT-based backend authentication
- SQLite-based backend data storage

## Existing System
In conventional systems, users often depend on offline calls, manual appointment records, or separate applications for different services. Such systems lack centralized service discovery, tracking, and convenience.

## Proposed System
The proposed system is a full-stack appointment booking platform where:

- Users can register and log in securely
- Services are grouped under categories
- Providers are displayed based on service and location
- Users can inspect provider details and reviews
- Appointments can be booked using available slots
- Bookings can be viewed and cancelled later
- Reminder notifications improve punctuality and service tracking

## Hardware and Software Requirements

### Hardware Requirements
- Processor: Intel i3 or above
- RAM: 4 GB or above
- Storage: 10 GB or more
- Android device or emulator for frontend testing

### Software Requirements
- Windows 10/11 or equivalent operating system
- Flutter SDK
- Dart SDK
- Android Studio or VS Code
- Python
- Django
- Django REST Framework
- SQLite
- Backend server running on `localhost:8000`

## Tools and Technologies Used

### Frontend
- Flutter
- Dart
- Material UI widgets
- `http`
- `shared_preferences`
- `image_picker`
- `flutter_local_notifications`
- `timezone`
- `url_launcher`

### Backend
- Python
- Django
- Django REST Framework
- Simple JWT
- SQLite
- CORS Headers

## Project Structure

### Frontend Repository
- Project path: `c:\Users\Geethika Sai Unnam\424184\multiservice_frontend`
- Main entry file: `lib/main.dart`

### Backend Repository
- Project path: `c:\Users\Geethika Sai Unnam\424184\multiservice_app`
- Main Django entry file: `manage.py`
- Main configuration package: `config`

## System Architecture
The system follows a client-server architecture.

1. The Flutter frontend handles user input, navigation, rendering, and local persistence.
2. The frontend sends HTTP requests to Django REST endpoints.
3. The Django backend processes requests using views and serializers.
4. Backend models store data in SQLite tables.
5. JWT tokens are used for authentication responses.
6. Shared preferences preserve login state in the frontend.
7. Local notification service schedules reminders on the device.

## Frontend Module Description

### 1. App Initialization Module
The app starts in `main.dart`, initializes local notification support, checks whether an access token exists in local storage, and decides whether to show the login screen or the home screen.

### 2. Authentication Module
This module handles:
- Registration
- Login
- Forgot password
- Password reset
- Local storage of access and refresh tokens

**Frontend files:**
- `lib/features/auth/login_screen.dart`
- `lib/features/auth/register_screen.dart`
- `lib/features/auth/forgot_password_screen.dart`
- `lib/services/auth_service.dart`

### 3. Home and Search Module
This module displays service categories in a grid layout and allows:
- Location entry
- Category search
- Service search
- Navigation to service list and booking history

**Frontend file:**
- `lib/features/home/home_screen.dart`

### 4. Service and Provider Module
This module shows services under each category and displays providers by selected location. It also presents provider information such as:
- Experience
- Rating
- Price
- Phone number
- Description
- Gallery media
- Reviews

**Frontend files:**
- `lib/services/service_list_screen.dart`
- `lib/services/provider_list_screen.dart`
- `lib/services/provider_detail_screen.dart`

### 5. Review Module
This module is implemented inside the provider detail screen and allows:
- Viewing reviews
- Giving star rating
- Writing comments
- Editing existing reviews
- Deleting own reviews

### 6. Booking Module
This module allows users to:
- Select appointment date
- View available and booked slots
- Enter address and phone number
- Add optional service instructions
- Validate doctor availability
- Confirm booking
- View booking details
- View booking history
- Cancel bookings

**Frontend files:**
- `lib/services/booking_screen.dart`
- `lib/services/booking_details_screen.dart`
- `lib/services/booking_history_screen.dart`

### 7. Payment Module
This module handles payment method selection:
- Online payment option
- Pay at service option

The current online payment flow is simulated in the frontend and does not yet integrate with backend payment records.

**Frontend files:**
- `lib/services/payment_method_screen.dart`
- `lib/services/payment_screen.dart`

### 8. Notification Module
This module initializes local notifications and schedules reminders 10 minutes before the appointment time.

**Frontend file:**
- `lib/services/notification_service.dart`

## Backend Module Description

### 1. Configuration Module
The Django project configuration defines:
- Installed apps
- Middleware
- Database connection
- Custom user model
- REST framework authentication
- JWT settings
- CORS policy

**Backend files:**
- `config/settings.py`
- `config/urls.py`

### 2. Users Module
This module manages:
- Custom user model
- User registration
- User login
- Email verification for password reset
- Password reset

Important implementation details:
- The system uses a custom `User` model.
- Roles supported are `USER`, `PROVIDER`, `DOCTOR`, and `ADMIN`.
- JWT tokens are generated during login.

**Backend files:**
- `users/models.py`
- `users/serializers.py`
- `users/views.py`
- `users/urls.py`

### 3. Services Module
This module manages:
- Service categories
- Services under each category
- Category listing with nested services

**Backend files:**
- `services/models.py`
- `services/serializers.py`
- `services/views.py`
- `services/urls.py`

### 4. Providers Module
This module manages:
- Provider information
- Provider media gallery
- Filtering providers by service and location
- Category name exposure through serializer

**Backend files:**
- `providers/models.py`
- `providers/serializers.py`
- `providers/views.py`
- `providers/urls.py`

### 5. Doctors Module
This module introduces a `DoctorProfile` model linked one-to-one with a provider. It stores:
- Specialization
- Hospital name

At present, the doctor app has model support but no dedicated API views connected in project routing.

**Backend files:**
- `doctors/models.py`
- `doctors/views.py`

### 6. Bookings Module
This module manages:
- Booking creation
- Duplicate slot validation
- Retrieval of user bookings
- Retrieval of booked slots
- Booking cancellation
- Daily availability check for doctors

Important implementation details:
- Duplicate booking is prevented for the same provider, date, and time.
- A doctor is marked unavailable if the provider already has 5 bookings on the selected date.

**Backend files:**
- `bookings/models.py`
- `bookings/serializers.py`
- `bookings/views.py`
- `bookings/urls.py`

### 7. Reviews Module
This module manages:
- Review listing by provider
- Adding reviews
- Updating reviews
- Deleting reviews

**Backend files:**
- `reviews/models.py`
- `reviews/serializers.py`
- `reviews/views.py`
- `reviews/urls.py`

### 8. Payments Module
The backend includes a `payments` app, but it is currently a placeholder and does not define active models, serializers, routed APIs, or payment processing logic.

**Backend files:**
- `payments/models.py`
- `payments/views.py`

## Database Design
The backend uses SQLite as its relational database. The main tables identified from the project database are:

- `users_user`
- `services_servicecategory`
- `services_service`
- `providers_provider`
- `providers_providermedia`
- `doctors_doctorprofile`
- `bookings_booking`
- `reviews_review`

### Main Entity Relationships
- One **service category** has many **services**
- One **service** can have many **providers**
- One **provider** can have many **media items**
- One **provider** can have one **doctor profile**
- One **user** can create many **bookings**
- One **provider** can have many **bookings**
- One **user** can create many **reviews**
- One **provider** can receive many **reviews**

## Important Backend Models

### User Model
Fields include:
- `username`
- `email`
- `name`
- `phone`
- `role`
- `is_active`
- `is_staff`
- `created_at`

### ServiceCategory Model
Fields include:
- `name`
- `icon`

### Service Model
Fields include:
- `category`
- `name`
- `description`
- `base_price`
- `duration_minutes`
- `is_active`

### Provider Model
Fields include:
- `name`
- `service`
- `description`
- `hero_image`
- `experience_years`
- `phone_number`
- `rating`
- `price`
- `location`
- `is_available`

### ProviderMedia Model
Fields include:
- `provider`
- `file`
- `media_type`
- `uploaded_by_customer`

### DoctorProfile Model
Fields include:
- `provider`
- `specialization`
- `hospital_name`

### Booking Model
Fields include:
- `user`
- `provider`
- `address`
- `phone_number`
- `date`
- `time`
- `description`
- `status`
- `created_at`
- `consultation_type`

### Review Model
Fields include:
- `provider`
- `user`
- `rating`
- `comment`
- `created_at`

## API Endpoints Used in the Project

### User APIs
- `POST /api/users/register/`
- `POST /api/users/login/`
- `POST /api/users/forgot-password/`
- `POST /api/users/reset-password/`

### Service APIs
- `GET /api/services/categories/`

### Provider APIs
- `GET /api/providers/?service=<service_id>&location=<location>`

### Booking APIs
- `POST /api/bookings/`
- `GET /api/bookings/slots/?provider=<provider_id>&date=<yyyy-mm-dd>`
- `GET /api/bookings/user/?user=<user_id>`
- `POST /api/bookings/<booking_id>/cancel/`
- `GET /api/bookings/check-availability/?provider=<provider_id>&date=<yyyy-mm-dd>`

### Review APIs
- `GET /api/reviews/?provider=<provider_id>`
- `POST /api/reviews/add/`
- `PUT /api/reviews/<review_id>/update/`
- `DELETE /api/reviews/<review_id>/delete/`

## End-to-End Workflow

### 1. User Authentication Workflow
1. User opens the Flutter app.
2. The app checks for access token in shared preferences.
3. If token exists, the app opens the home screen.
4. Otherwise, the app shows the login screen.
5. During login, credentials are sent to `/api/users/login/`.
6. Backend validates the credentials and returns JWT tokens.
7. Frontend stores tokens locally and proceeds to the home screen.

### 2. Service Discovery Workflow
1. Home screen loads categories from `/api/services/categories/`.
2. Categories and nested services are displayed to the user.
3. User enters a location and search query.
4. The app filters matching categories and services.
5. User selects a category, then a service.

### 3. Provider Selection Workflow
1. Frontend requests providers using selected service and location.
2. Backend filters providers using `service_id` and `location__icontains`.
3. Matching providers are returned.
4. User can open the provider detail page or directly start booking.

### 4. Review Workflow
1. Provider detail screen fetches reviews for the provider.
2. User can submit a new review with rating and comment.
3. Existing reviews can be edited or deleted by the same user in the frontend flow.
4. Backend stores the review in the review table.

### 5. Booking Workflow
1. User selects provider and opens booking screen.
2. User chooses a date using the date picker.
3. Frontend requests booked slots from the backend.
4. User selects an available slot.
5. User enters address, phone number, and optional instructions.
6. For doctor providers, frontend requests availability validation.
7. Frontend sends booking data to `/api/bookings/`.
8. Backend checks whether the selected slot is already booked.
9. If valid, booking is stored in the database.
10. Frontend opens booking details and payment method selection.
11. After payment choice, frontend schedules a reminder notification.

### 6. Booking History Workflow
1. Frontend requests bookings for a user using `/api/bookings/user/?user=<id>`.
2. Backend returns booking records ordered by date.
3. Frontend displays booking cards with status and cancel option.
4. Cancel request updates booking status using `/api/bookings/<id>/cancel/`.

## Algorithms / Internal Logic

### Duplicate Slot Prevention
When a booking request is sent, the backend checks whether another booking already exists for the same provider, date, and time. If yes, the API returns an error that the slot is already booked.

### Doctor Availability Rule
For doctor-related bookings, the backend checks the total number of bookings for that provider on the selected date. If the count is 5 or more, the provider is considered unavailable for that day.

### Search Filtering
The home screen searches both category names and service names so users can discover relevant services through either search type.

### Token Persistence
The frontend stores JWT access and refresh tokens using shared preferences so that the login session can continue when the app is reopened.

### Reminder Scheduling
Once booking and payment flow complete, the app calculates a reminder time 10 minutes before the booked time and schedules a local notification.

## Testing and Validation
The project has been validated primarily through manual testing. The following cases are covered by current implementation:

- User registration
- User login with JWT generation
- Token persistence in local storage
- Forgot password email verification flow
- Password reset flow
- Category and nested service retrieval
- Location-based provider filtering
- Provider detail view with reviews
- Review create, edit, and delete flows
- Slot fetching and slot selection
- Duplicate slot validation on backend
- Booking creation
- Booking cancellation
- Booking history retrieval
- Local reminder notification scheduling

## Results
The project successfully demonstrates a working integration between Flutter frontend and Django backend. The user can authenticate, browse categories, discover providers, submit reviews, create bookings, choose payment methods, and track appointment history. The backend organizes the system into modular apps and stores persistent records in SQLite. The overall result is a functional academic full-stack appointment booking system.

## Advantages
- Full-stack implementation with clear frontend-backend separation
- Modular backend app structure
- Supports multiple service domains in one application
- JWT-based login system
- Location-aware provider filtering
- Slot-based booking control
- Review and rating functionality
- Booking history and cancellation support
- Local notification reminders
- Good foundation for future deployment and scaling

## Limitations
- The frontend currently uses `localhost` or `127.0.0.1`, so deployment needs environment-based API configuration.
- Some frontend flows use hardcoded user id values such as `1` for bookings and reviews.
- The payment flow is only simulated in the frontend.
- The backend `payments` app is not yet implemented functionally.
- The doctor app has a model but no dedicated routed API endpoints.
- Backend authentication exists, but several frontend API calls do not yet attach bearer tokens in request headers.
- Booking status choices in the model list `pending`, `confirmed`, and `completed`, while cancellation updates status to `cancelled`, so the status choice design can be refined.

## Future Enhancements
- Connect real payment gateway integration
- Add backend payment transaction models and APIs
- Replace hardcoded user ids with authenticated user extraction from JWT
- Add role-based dashboards for provider and admin
- Add appointment rescheduling
- Add provider availability calendars
- Add media upload storage instead of URL-only media
- Add stronger validation and authorization checks
- Add deployment-ready environment configuration
- Add API documentation using Swagger or DRF schema tools

## Conclusion
The MultiService Appointment Booking System is a complete academic full-stack project that combines Flutter-based mobile development with Django REST backend services. It covers important real-world concepts such as authentication, API integration, database design, modular architecture, slot validation, reviews, booking history, and notifications. The system already provides a strong end-to-end booking workflow and can be extended further into a production-ready service marketplace with payment integration, better authorization, and deployment support.

## References
1. Flutter Documentation: https://docs.flutter.dev/
2. Dart Documentation: https://dart.dev/
3. Django Documentation: https://docs.djangoproject.com/
4. Django REST Framework Documentation: https://www.django-rest-framework.org/
5. Simple JWT Documentation
6. SQLite Documentation
7. Flutter Local Notifications Documentation

## Viva Questions and Answers

### 1. What type of project is this?
This is a full-stack multi-service appointment booking system with Flutter frontend and Django REST backend.

### 2. Which database is used in the project?
SQLite is used as the backend database.

### 3. How is authentication handled in the backend?
Authentication is handled using JWT tokens generated with Simple JWT during login.

### 4. How does the app remember the logged-in user?
The frontend stores the access and refresh tokens in shared preferences.

### 5. How are service categories displayed in the app?
The frontend calls the backend category API, which returns categories along with nested services.

### 6. How does the system prevent double booking?
The backend checks whether the same provider, date, and time combination already exists before saving a booking.

### 7. How are providers filtered?
Providers are filtered by selected service and by matching the given location string.

### 8. What is the role of the review module?
It allows users to post ratings and comments about providers and helps future users evaluate service quality.

### 9. Is payment fully implemented?
No. Payment selection exists in the frontend, but backend payment processing is not implemented yet.

### 10. What can be improved in the future?
Real payment integration, JWT-based user mapping, provider dashboards, deployment configuration, and better authorization can be added.

## Screenshots Section
Add screenshots in the final report under these headings:

1. Login Screen
2. Register Screen
3. Home Screen
4. Service Categories Screen
5. Provider List Screen
6. Provider Detail Screen
7. Booking Screen
8. Payment Method Screen
9. Booking History Screen
10. Backend API or Admin Panel Screenshot

## Notes for Final Submission
- Certificate page is intentionally excluded as requested.
- This document now reflects both frontend and backend repositories.
- Add student details, guide details, department name, college name, and screenshots before final submission.
- If your faculty format uses fixed headings from the PDF, copy this content under those exact headings.
