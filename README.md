<div align="center">


### 🥗 Smart Sri Lankan Meal Prep & Nutrition Tracker

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![FastAPI](https://img.shields.io/badge/FastAPI-0.100+-009688?style=for-the-badge&logo=fastapi&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-Firestore-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Python](https://img.shields.io/badge/Python-3.11+-3776AB?style=for-the-badge&logo=python&logoColor=white)
![License](https://img.shields.io/badge/License-Academic-14D97D?style=for-the-badge)

> **NutriFlex** is a mobile nutrition companion built for Sri Lankans — combining real local food data, BMI-aware meal planning, and smart recipe discovery in one beautifully designed app.

---

**Team Nutrition Navigators** · SDGP - Group Coursework CW2

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Tech Stack](#-tech-stack)
- [Architecture](#-architecture)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
- [Backend Setup](#-backend-setup)
- [Flutter Setup](#-flutter-setup)
- [Firebase Configuration](#-firebase-configuration)
- [Environment Variables](#-environment-variables)
- [API Reference](#-api-reference)
- [Team](#-team)


---

## 🌿 Overview

NutriFlex solves a real problem — there's no nutrition app built around **Sri Lankan food**. Most apps don't know what Mallum, Ambul Thiyal, or Kola Kenda are, let alone their macro breakdown.

We built NutriFlex from scratch with:
- A custom Sri Lankan food database in Firebase Firestore
- A BMI calculator that accounts for local health conditions (diabetes, blood pressure, cholesterol)
- A meal prep builder that constructs a full Sri Lankan plate and calculates your daily intake vs requirements in real time
- Recipe discovery powered by the USDA API with Firebase caching
- Full user onboarding, authentication, and profile management

---

## ✨ Features

### 🔐 Authentication
- Email/password signup with email verification
- Google Sign-In
- Animated splash screen with routing logic
- Secure session management via Firebase Auth

### 🧭 Onboarding
- 5-step personalized onboarding flow
- Live Firestore writes per step using merge strategy
- Medical condition selection (Diabetes, Blood Pressure, Cholesterol)
- Goal and activity level configuration

### 🏠 Home
- Trending recipe feed powered by USDA API
- Personalized daily calorie target display
- Recipe search with nutritional breakdown
- Beautiful glassmorphism card UI

### ⚖️ BMI Calculator
- Height, weight, age, gender inputs
- Activity level and fitness goal selection
- Health condition-aware macro adjustments
- Animated BMI scale bar
- Personalized daily calorie and macro targets
- Results saved to Firestore for meal prep integration

### 🍛 Meal Prep Builder
- 6-card Sri Lankan meal plate builder:
  - Steamed Rice (10 varieties)
  - Mallum (Greens)
  - Vegetable Curry 1 & 2 (24 options each)
  - Meat / Fish (13 options)
  - Fresh Salad (6 options)
- Per-gram weight input for each component
- Real-time nutrition calculation via FastAPI backend
- Animated progress bars for Calories, Protein, Carbs, Fat
- Daily accumulation — tracks everything eaten throughout the day

### 🗺️ Store Locator & Order Placement
- Interactive map powered by **Flutter Map** with OpenStreetMap tiles
- Detects user's current GPS location automatically
- Reverse geocoding via **Nominatim API** to display human-readable location name
- Nearby health food stores fetched using **Geoapify Places API** within a configurable radius
- Each store card shows:
  - Distance (km) and estimated travel time
  - Star rating
  - Ingredient availability percentage with animated progress bar
  - Warning banner when availability is below 90%
- Tap **Select Store** to proceed to cart checkout for that store
- Location can be manually changed via the **Change** button

### 🛒 Shopping Cart
- Add recipes and meal items to a persistent cart stored in Firestore (`users/{uid}/cart`)
- Cart supports quantity updates, individual item removal, and full cart clear
- Promo code support with backend validation
- Order summary with subtotal, delivery fee, discount, and total
- **Place Order** flow — saves the order to Firestore and triggers an order confirmation notification
- Cart state synced via `ApiService` with live Firestore reads on page load

### 🔔 Notifications
- Firebase Cloud Messaging (FCM) integration
- 7 notification types: Cart, Recipe, Trending, Order, Fitness, Progress, Broadcast
- Persistent read/unread state via SharedPreferences
- Real-time foreground message handling
- Animated notification cards with weekly summary

### 👤 User Profile
- Profile picture upload via Cloudinary
- Editable fields: Full Name, Mobile, Birthday, Gender
- Sri Lankan phone number auto-formatting to E.164
- Animated staggered row reveals
- Glassmorphism card design with radial gradient background
- Logout with Firebase sign-out

---

## 🛠 Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile Frontend | Flutter (Dart) |
| Backend API | FastAPI (Python) |
| Primary Database | Firebase Firestore |
| Authentication | Firebase Auth |
| Push Notifications | Firebase Cloud Messaging |
| Image Storage | Cloudinary |
| Food Data | USDA FoodData Central API |
| Map & Store Discovery | Geoapify Places API + Nominatim (OpenStreetMap) |
| State Management | Provider (CalorieProvider) |
| Local Storage | SharedPreferences |
| HTTP Client | `http` package (Dart) |

---

## 🏗 Architecture

```
┌─────────────────────────────────────────────────────┐
│                   Flutter App                        │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │
│  │  Screens │  │ Widgets  │  │    Services       │  │
│  │          │  │          │  │  api_service.dart │  │
│  │ home     │  │ bottom   │  │  calorie_provider │  │
│  │ bmi      │  │ nav      │  │                  │  │
│  │ meal_prep│  │ cards    │  └──────────────────┘  │
│  │ onboard  │  └──────────┘                        │
│  │ profile  │                                       │
│  │ notifs   │                                       │
│  └──────────┘                                       │
└────────────────────────┬────────────────────────────┘
                         │ HTTP / REST
                         ▼
┌─────────────────────────────────────────────────────┐
│                 FastAPI Backend                      │
│                                                     │
│  /onboarding        /bmi/calculate                  │
│  /recipes/trending  /recipes/search                 │
│  /Meal_Prep_With_Five_Cards                         │
│  /api/v1/profile    /notifications/*                │
│  /core_nutrients    /add_SriLankanfood_to_user      │
│  /api/v1/map/*      /api/v1/cart/*                  │
└───────────┬────────────────────┬────────────────────┘
            │                    │
            ▼                    ▼
┌──────────────────┐  ┌──────────────────────────────┐
│  Firebase        │  │  External APIs               │
│  Firestore       │  │  USDA FoodData Central       │
│  Firebase Auth   │  │  Cloudinary (images)         │
│  Firebase FCM    │  │  Google OAuth                │
└──────────────────┘  │  Geoapify (store discovery)  │
                      │  Nominatim (reverse geocode) │
                      └──────────────────────────────┘
```

---

## 📁 Project Structure

```
NutriFlex/
├── frontend/                          # Flutter app
│   ├── lib/
│   │   ├── main.dart                  # App entry, providers, routes
│   │   ├── main_shell.dart            # Bottom nav shell (4 tabs)
│   │   ├── screens/
│   │   │   ├── splash_screen.dart     # Animated splash → /auth
│   │   │   ├── login_page.dart        # Email + Google sign-in
│   │   │   ├── signup_page.dart       # Registration + email verify
│   │   │   ├── onboarding.dart        # 5-step onboarding flow
│   │   │   ├── home_page.dart         # Recipe feed + search
│   │   │   ├── bmi_screen.dart        # BMI calculator
│   │   │   ├── meal_prep_page.dart    # 6-card meal builder
│   │   │   ├── map_screen.dart        # Store locator + order placement
│   │   │   ├── cart_screen.dart       # Shopping cart + checkout
│   │   │   ├── notification_page.dart # Alerts + weekly summary
│   │   │   └── userProfile.dart       # Profile management
│   │   ├── services/
│   │   │   ├── api_service.dart       # All HTTP + notification calls
│   │   │   └── calorie_provider_service.dart
│   │   ├── widgets/
│   │   │   └── bottom_nav.dart        # Animated bottom navigation
│   │   └── assets/
│   │       ├── NutriFlex_Logo_1.jpeg
│   │       ├── rice.jpg
│   │       ├── mallum.jpg
│   │       ├── veg1.jpg / veg2.jpg
│   │       ├── meat.jpg
│   │       └── salad.jpg
│   └── pubspec.yaml
│
└── backend/                           # FastAPI backend
    └── app/
        ├── main.py                    # App init, router registration
        ├── routers/
        │   ├── onboarding_router.py   # Onboarding endpoints
        │   ├── bmi.py                 # BMI calculation + storage
        │   ├── recipes.py             # USDA recipe search + trending
        │   ├── nutrients.py           # Meal prep + nutrition tracking
        │   ├── profile.py             # User profile CRUD
        │   ├── notifications.py       # FCM notification endpoints
        │   ├── map.py                 # Store locator
        │   └── usda.py               # USDA API wrapper
        ├── services/
        │   ├── bmi_service.py
        │   ├── usda_service.py
        │   └── recipe_service.py
        ├── models/
        │   └── bmi_models.py
        └── database/
            └── firebase_key.json      
```

---

## 🚀 Getting Started

### Prerequisites

| Tool | Version |
|------|---------|
| Flutter | 3.x |
| Dart | 3.x |
| Python | 3.11+ |
| Android Studio / VS Code | Latest |
| Java JDK | 17+ |
| Firebase CLI | Latest |

---

## 🐍 Backend Setup

```bash
# 1. Clone the repo
git clone https://github.com/your-org/nutriflex.git
cd nutriflex/backend

# 2. Create virtual environment
python -m venv venv

# Windows
venv\Scripts\activate

# Mac/Linux
source venv/bin/activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Add your .env file (see Environment Variables section)

# 5. Place your Firebase service account key
#    Path: backend/app/database/firebase_key.json

# 6. Run the server
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

The API will be available at `http://YOUR_IP:8000`

---

## 📱 Flutter Setup

```bash
cd nutriflex/frontend

# Install dependencies
flutter pub get

# Update the IP address in api_service.dart
# Line: const String kBaseUrl = 'http://YOUR_MACHINE_IP:8000';

# Run on connected device
flutter run

# Build APK
flutter build apk --release
```

### Android Configuration

In `android/app/build.gradle.kts`:
```kotlin
compileSdk = 35
minSdk = 21
```

In `android/gradle/wrapper/gradle-wrapper.properties`:
```
distributionUrl=https\://services.gradle.org/distributions/gradle-8.11.1-all.zip
```

In `android/settings.gradle.kts`:
```kotlin
id("com.android.application") version "8.9.1" apply false
id("com.google.gms.google-services") version "4.4.2" apply false
id("org.jetbrains.kotlin.android") version "2.1.0" apply false
```

---

## 🔥 Firebase Configuration

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add an Android app with package name `com.example.flutter_application_1`
3. Add SHA-1 and SHA-256 fingerprints
4. Download `google-services.json` → place in `android/app/`
5. Run `flutterfire configure` to generate `lib/services/firebase_options.dart`
6. Enable in Firebase Console:
   - **Authentication** → Email/Password + Google
   - **Firestore Database**
   - **Cloud Messaging**

### Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### Add to `.gitignore`
```
lib/services/firebase_options.dart
android/app/google-services.json
backend/app/database/firebase_key.json
backend/app/database/customfoods_firebase_key.json
backend/.env
```

---

## 🔑 Environment Variables

Create `backend/.env`:

```env
# Firebase service account key path
FIREBASE_KEY_PATH=app/database/firebase_key.json

# Second Firebase project — custom Sri Lankan food database
CUSTOMFOODS_FIREBASE_KEY_PATH=app/database/customfoods_firebase_key.json

# USDA FoodData Central API
USDA_API_KEY=your_usda_api_key_here

# Cloudinary (profile picture uploads)
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret

# Geoapify (nearby store discovery)
GEOAPIFY_API_KEY=your_geoapify_api_key_here
```

Get your USDA API key free at [fdc.nal.usda.gov](https://fdc.nal.usda.gov/api-guide.html)

---

## 📡 API Reference

### Base URL
```
http://YOUR_IP:8000
```

### Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/onboarding/{uid}` | Save onboarding step |
| `POST` | `/bmi/calculate` | Calculate BMI + macros |
| `GET` | `/recipes/trending` | Get trending recipes |
| `GET` | `/recipes/search` | Search USDA recipes |
| `POST` | `/Meal_Prep_With_Five_Cards` | Save meal + get nutrition |
| `GET` | `/core_nutrients/` | Get food nutrient data |
| `GET` | `/add_SriLankanfood_to_user` | Add food to daily log |
| `POST` | `/add_daily_nutrient_requirements` | Save BMI requirements |
| `GET` | `/api/v1/profile/{uid}` | Get user profile |
| `PATCH` | `/api/v1/profile/{uid}` | Update profile fields |
| `DELETE` | `/api/v1/profile/{uid}/field` | Delete a profile field |
| `POST` | `/api/v1/profile/{uid}/upload-picture` | Upload profile photo |
| `POST` | `/api/v1/map/nearby-stores` | Find nearby stores via Geoapify |
| `GET` | `/api/v1/map/reverse-geocode` | Reverse geocode via Nominatim |
| `POST` | `/api/v1/map/{uid}/place-order` | Place an order |
| `GET` | `/api/v1/cart/{uid}` | Get user cart |
| `POST` | `/api/v1/cart/{uid}/add` | Add item to cart |
| `DELETE` | `/api/v1/cart/{uid}/remove/{id}` | Remove item from cart |
| `PATCH` | `/api/v1/cart/{uid}/quantity/{id}` | Update item quantity |
| `DELETE` | `/api/v1/cart/{uid}/clear` | Clear entire cart |
| `POST` | `/api/v1/cart/{uid}/promo` | Apply promo code |
| `POST` | `/notifications/register-token` | Register FCM token |
| `POST` | `/notifications/broadcast` | Broadcast to all users |

### Meal Prep Request Example
```
POST /Meal_Prep_With_Five_Cards?
  access_token=USER_UID&
  rice=Fried+Rice&rice_size=100&
  meat=Chicken+Curry&meat_size=100&
  vegetable1=Dhal+Curry%2C+Thick&vegetable1_size=100&
  vegetable2=Carrot+Curry&vegetable2_size=100&
  mallum=Mallum&mallum_size=100&
  salad=Cucumber+Salad&salad_size=100
```

### Meal Prep Response Example
```json
{
  "Calory consumed: ": "529.0kcal",
  "Calory requirement: ": "2400.0kcal",
  "Calory consumed percentage: ": 22.04,
  "Protein consumed: ": "25.25g",
  "Protein requirement: ": "150.0g",
  "Protein consumed percentage: ": 16.83,
  "Carbohydrate consumed: ": "51.5g",
  "Carbohydrate requirement: ": "620.0g",
  "Carbohydrate consumed percentage: ": 8.31,
  "Fat consumed: ": "20.22g",
  "Fat requirement: ": "220.0g",
  "Fat consumed percentage: ": 9.19
}
```

---

## 👨‍💻 Team

<div align="center">

| Member | Role |
|--------|------|
| **Matheesha** | Backend — BMI, Meal prep, Home |
| **Kavindu** | Backend — Onboarding, Login/Signup, Home, Map |
| **Senuja** | Backend — Userprofile, Map, Cart |
| **Hasith** | Frontend — Login/Signup, Cart, Meal prep |
| **Abdul** | Frontend — BMI, Map, Onboarding|
| **Mevindu** | Frontend — Userprofile, Notification, Splash |


**Team Name:** Nutrition Navigators  
**Module:** Software Development Group Project (SDGP)
**Institution:** Informatics Institute of Technology (IIT)

</div>

---

<div align="center">

Built with 💚 in Sri Lanka by Nutrition Navigators

*NutriFlex — Because your nutrition app should know what Mallum is.*

</div>