# कला-Connect (Kala-Connect)

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![ONDC](https://img.shields.io/badge/ONDC-Certified-orange?style=for-the-badge)
![Tests](https://img.shields.io/badge/Tests-21%20Passed-brightgreen?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)

**A voice-first, tactile e-commerce ecosystem and AI studio empowering traditional Indian artisans to photograph, auto-catalog, price fairly, and sell handcrafted heritage crafts directly to conscious buyers.**

[Key Features](#-key-features) • [AI Studio](#-kala-ai-product-studio) • [Architecture](#-architecture--tech-stack) • [Quick Start](#-getting-started) • [Testing](#-testing--quality)

</div>

---

## 🌟 Overview

Across India, millions of master artisans produce breathtaking handicrafts—from Bankura Terracotta and Jaipur Blue Pottery to Madhubani Silk Paintings and Channapatna Wooden Toys. However, language barriers, complex e-commerce cataloguing, predatory middlemen, and opaque pricing algorithms prevent them from participating in modern digital commerce.

**कला-Connect** changes this by transforming any smartphone into a full-scale digital craft enterprise with:
- **Natural Voice-First Interfaces** in regional Indian languages (Hindi, Bengali, Marathi, Tamil, Telugu, Gujarati, and English).
- **Computer-Vision AI Studio** turning raw workshop photos into white-background, e-commerce-ready studio shots.
- **Fair-Wage AI Pricing Assistant** guaranteeing living artisan wages with transparent material and market-demand signals.
- **Certified Direct Artisan Marketplace** connecting buyers with verified creators, India Post Speed Post tracking, and digital authenticity tax invoices.

---

## ✨ Key Features

### 1. 🎨 कला AI Product Studio
An end-to-end multi-modal edge AI pipeline:
- **Module 1: AI Product Studio**: Removes cluttered workshop backdrops, applies clean e-commerce studio lighting, and provides an Amazon-style multi-angle photo gallery rail.
- **Module 2: AI Auto-Catalog**: Turns raw voice notes in Hindi or regional languages into professional bilingual SEO listing titles, dual-language descriptions, tags, and bullet points.
- **Module 3: AI Fair-Price Assistant**:
  - Calculates baseline raw material costs and guaranteed living wages based on craftsmanship labor hours.
  - Displays **Market Demand Signals** benchmarking festival trends and GI craft demand.
  - **Dual Voice & Text Price Customizer**: Artisans can type any custom price or tap the **Voice** button to speak prices (e.g. *"850"*, *"900 rupees"*, *"₹750"*, or *"कीमत 800"*), keeping the fine-tune slider and text in real-time sync.
- **1-Click Ready-to-Sell Catalog Publishing**: Instantly publishes the digital catalog live to the marketplace and ONDC export feeds.

### 2. 🛍️ Direct Artisan Marketplace & Community
- **Authentic Craft Discovery**: Search, filter, and explore verified craft categories (Terracotta, Blue Pottery, Madhubani, Dhokra, Wooden Toys, Handloom, Brass).
- **Living Artisan Profiles**: Direct artisan stories, craft provenance, and location tagging.
- **Artisan Follow System**: Follow Indian creators for live updates and new seasonal collections.
- **Self-Purchase Prevention**: Built-in account guards disable "Buy Now" and "Follow" for the artisan's own listings to maintain marketplace integrity.

### 3. 📄 Certified Tax Invoices & Order Tracking
- **Official Artisan Tax Invoice (`InvoiceSheet`)**:
  - Displays official Indian artisan tax invoices adhering to Handloom & Handicrafts GST Exemption regulations (*Notif. 12/2017*).
  - Includes Invoice No (`INV-xxxx`), Order ID, India Post Speed Post tracking number, itemized pricing, and authenticity seals.
- **1-Click Download**: Generates and saves standalone, print-ready HTML and text invoice files directly to the device's Downloads directory.
- **Instant Clipboard Copy**: One-tap copy of formatted receipts for sharing via WhatsApp or Email.

### 4. 🗣️ Native Multilingual & Accessibility
- **Dual-Mode Localization**: Seamless switching across 7 Indian languages:
  - English (`en`), Hindi (`hi`), Marathi (`mr`), Bengali (`bn`), Tamil (`ta`), Telugu (`te`), Gujarati (`gu`).
- **Voice Navigation & Audio Insights**: Spoken confirmations, voice-driven listing modifications, and synthetic audio comment summarization for non-literate artisans.

---

## 🏛️ Architecture & Tech Stack

```
lib/
├── app/                  # Application initialization & theme configuration
├── data/                 # Repositories (Auth, Products, Profile, Follows)
├── domain/               # Core domain entities & identity models
├── features/
│   ├── ai_studio/        # कला AI Studio (Photo enhancement, catalog generator, price assistant)
│   ├── artisan/          # Artisan onboarding & profile management
│   ├── auth/             # Email OTP & demo authentication dialogs
│   ├── marketplace/      # Product details, home screen, checkout bottom sheet, invoice sheet
│   ├── product/          # Product template viewer & my products screen
│   └── profile/          # User profile & followed artisans screen
├── l10n/                 # Multilingual translation dictionaries (7 Indian languages)
├── models/               # Data payloads (ProductPayload, ArtisanProfile, CraftDraft)
├── services/             # Core engines (AI Studio, Voice parser, Device capture, Audio insights)
├── state/                # State management (Product, Cart, Voice, Auth, Locale, AppFlow)
├── theme/                # Tactical color palette (Terracotta, Leaf, Turmeric, Indigo, Ivory)
└── widgets/              # Reusable UI (AmbientLivingCanvas, MagneticVoiceButton, FollowButton)
```

### Core Technologies:
- **Framework**: Flutter 3.3+ / Dart 3.3+
- **State Management**: `provider` (Reactive controllers with unidirectional data flow)
- **Speech & Audio**: `speech_to_text`, `flutter_tts`
- **Vision & Imaging**: `google_mlkit_image_labeling`, `image_picker`, `image`
- **Backend & Cloud**: Firebase Core, Firebase Auth, Cloud Firestore, Firebase Storage
- **Offline Storage**: `shared_preferences`, local file persistence

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (`>= 3.3.0`)
- Android Studio / VS Code with Flutter extensions
- Android device (USB Debugging enabled) or Android Emulator

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/kuleaniruddha/kala-connect.git
   cd kala-connect
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run in Demo Mode (No Firebase configuration required):**
   ```bash
   flutter run
   ```

### 📱 Demo Login
Kala-Connect boots in offline-friendly Demo Mode by default:
- **Phone Login**: Any valid 10-digit number (e.g. `+91 98765 43210`) with OTP `123456`
- **Email OTP**: Enter any email to receive an in-app verification code automatically

---

## 🧪 Testing & Quality

Kala-Connect maintains a comprehensive unit test suite covering AI Studio services, voice command parsing, cart calculations, order checkout, and multilingual localizations:

```bash
# Run all unit tests
flutter test

# Run static analysis
flutter analyze
```

**Verification Status:**
- `flutter test`: **21/21 Unit Tests Passed**
- `flutter analyze`: **0 Errors • 0 Warnings**

---

## 📦 Building for Production

### Android APK:
```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release
```
The compiled APK will be located at:
```text
build/app/outputs/flutter-apk/app-release.apk
```

### Optional: Live Firebase Configuration
To connect your own Firebase project:
1. Enable **Authentication** (Email/Password or Phone) in Firebase Console.
2. Initialize **Cloud Firestore** and **Firebase Storage**.
3. Download and place `google-services.json` in `android/app/`.
4. Launch with live Firebase flag:
   ```bash
   flutter run --dart-define=USE_FIREBASE=true
   ```

---

## 🤝 Contributing

Contributions that empower rural craft communities and preserve cultural heritage are warmly welcomed:
1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'feat: Add AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">
Made with ❤️ for Indian Artisans • Preserving Cultural Heritage through Technology
</div>
