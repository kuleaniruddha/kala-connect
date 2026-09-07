# कला-Connect implementation status

Last updated: 2026-09-05

## Current runnable state

- [x] Flutter Android project is generated and debug APK builds.
- [x] App identity uses `कला-Connect` on Android.
- [x] Provider is the shared state-management mechanism.
- [x] Viewport safety gate is present before intensive rendering.
- [x] Animated ambient canvas, magnetic controls, scanner reticle/laser, and product entrance animations are implemented.
- [x] Product details screen hydrates from one structured JSON payload.
- [x] Product details includes hero image, AI description, suggested price, additional image rail, more-info section, and native-language comments.
- [x] Voice controller parses English/Hindi price-change commands.
- [x] Comment-insight and speech contracts exist with a deterministic mock implementation.
- [x] Language-selection and voice-led profile prototype flows exist.
- [x] Futuristic landing page routes to phone authentication.
- [x] Firebase dependencies are installed: Core, Auth, Firestore, Storage, Google Sign-In.
- [x] Firebase Phone OTP repository and demo fallback repository exist.
- [x] Firebase product repository writes Firestore documents and uploads local image files to Storage.
- [x] Firestore and Storage rules are included and lock access to the authenticated artisan owner.
- [x] Artisan profiles are cached locally with SharedPreferences and sync through the profile repository when Firebase is configured.
- [x] "My Products" reads the signed-in artisan's live Firestore catalog through the repository abstraction.
- [x] Device camera hero-photo capture and gallery-image selection are connected; selected local files publish through Firebase Storage.
- [x] Unit tests cover product JSON hydration and English/Hindi voice price parsing.
- [x] Demo/offline product publishing persists in SharedPreferences and the local catalog updates from a stream.
- [x] Android microphone permission, device STT with live partial transcripts, and system TTS are wired through the existing voice controller.
- [x] Voice commands now support price editing, appending product information, gallery-image deletion, and selected-language changes.

## Important current limitation

Firebase project files are present, but Firebase Phone Authentication is not yet ready for use in this build. The app deliberately defaults to a visual demo login: use any valid-looking phone number and OTP `123456`. The real Firebase path is opt-in with `--dart-define=USE_FIREBASE=true` after Phone Authentication and Android SHA fingerprints are configured. The demo OTP must not be used in a production build.

## Next implementation order

### 1. Bind and validate Firebase

- [ ] Run `firebase login`, install FlutterFire CLI, and run `flutterfire configure`.
- [ ] Register the Android application id in the selected Firebase project.
- [ ] Enable Phone Authentication, add SHA-1/SHA-256 fingerprints, and test real OTP on a physical Android device.
- [ ] Create Firestore and Storage, deploy `firestore.rules` and `storage.rules`.
- [ ] Remove the demo authentication path for release builds.
- [x] Persist name, location, and language under `artisans/{uid}` with a local offline cache.
- [ ] Add Google Sign-In implementation; the dependency is present but no sign-in action is wired.

### 2. Complete product catalog persistence

- [x] Add a Firestore-backed "My products" list and detail reopen/edit path.
- [ ] Add draft/published status, created timestamp, dimensions, material, category, and marketplace fields to the product schema.
- [ ] Replace the `MissingPluginException` scanner fallback JSON with a real capture response.
- [ ] Add a background sync queue for failed Firestore/Storage writes.
- [ ] Add buyer/public catalog projection with Cloud Functions; do not weaken current owner-only rules.

### 3. Camera and edge AI

- [ ] Add camera/image-picker integration with runtime permission handling.
- [ ] Add multi-image capture and a gallery review flow.
- [ ] Add YOLO TFLite model asset, label map, preprocessing, inference isolate, and live bounding-box painter.
- [ ] Add background segmentation model (U²-Net or MODNet), foreground crop, and lighting enhancement.
- [ ] Implement Android/iOS `in.kalaconnect/edge_ai` MethodChannel handlers or replace it with Flutter-native inference.
- [ ] Measure latency/memory on a low-end Android device and tune model quantization.

### 4. Real voice and multilingual experience

- [x] Replace `VoiceAssistantService` mock with device speech recognition and live partial transcription.
- [x] Replace `AudioInsightService` mock speech output with system TTS.
- [ ] Expand NLU for description, material, translation, publishing, and comment replies; current rules cover price, more info, gallery deletion, and language selection.
- [ ] Create ARB localization files for English plus Hindi, Bengali, Tamil, Telugu, Marathi, Gujarati, Kannada, Malayalam, Odia, and Punjabi.
- [ ] Persist and instantly apply language changes.

### 5. Cloud AI and buyer interactions

- [ ] Build Firebase Cloud Functions as the protected server-side boundary for AI keys.
- [ ] Implement description, translation, price recommendation, and comment-insight endpoints.
- [ ] Keep provider credentials out of the Flutter binary.
- [ ] Add comment creation, translation, sentiment clustering, artisan voice replies, and notifications.
- [ ] Select model/provider and add budget/rate-limit/error policies.

### 6. Marketplace and hardening

- [ ] Implement ONDC/Amazon export adapters through Cloud Functions or a secured partner backend.
- [ ] Add App Check, Crashlytics, analytics consent, retry policy, monitoring, and release signing.
- [ ] Add unit tests for voice parsing, auth state, repository mapping, and price updates.
- [ ] Add emulator/integration tests for login → onboarding → capture → publish.
- [ ] Produce release APK/AAB, architecture report, API documentation, and deployment runbook.

## Files to resume from

- `lib/app/kala_connect_app.dart` — app routing and dependency providers.
- `lib/core/firebase_bootstrap.dart` — guarded Firebase initialization.
- `lib/data/auth/firebase_auth_repository.dart` — real phone OTP integration.
- `lib/data/products/firebase_product_repository.dart` — Firestore + Storage publishing.
- `lib/features/landing/landing_screen.dart` — entry surface.
- `lib/features/product/product_template.dart` — review/edit/publish product template.
- `lib/services/edge_pipeline_service.dart` — camera/YOLO/TFLite integration seam.
- `lib/services/voice_assistant_service.dart` and `lib/services/audio_insight_service.dart` — mocks to replace.
