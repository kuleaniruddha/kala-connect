import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/marketplace/main_marketplace_shell.dart';
import '../services/ai_studio_service.dart';
import '../services/audio_insight_service.dart';
import '../services/edge_pipeline_service.dart';
import '../services/device_capture_service.dart';
import '../services/image_analysis_service.dart';
import '../services/voice_assistant_service.dart';
import '../data/auth/auth_repository.dart';
import '../data/auth/demo_auth_repository.dart';
import '../data/auth/firebase_auth_repository.dart';
import '../data/products/firebase_product_repository.dart';
import '../data/products/local_product_repository.dart';
import '../data/products/product_repository.dart';
import '../data/profile/artisan_follow_repository.dart';
import '../data/profile/firebase_profile_repository.dart';
import '../data/profile/local_profile_repository.dart';
import '../data/profile/profile_repository.dart';
import '../features/splash/splash_screen.dart';
import '../state/app_flow_controller.dart';
import '../state/auth_controller.dart';
import '../state/cart_and_orders_controller.dart';
import '../state/locale_controller.dart';
import '../state/product_controller.dart';
import '../state/voice_controller.dart';
import '../theme/kala_theme.dart';

/// Global application shell.
class KalaConnectApp extends StatelessWidget {
  const KalaConnectApp({required this.firebaseReady, super.key});

  final bool firebaseReady;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>(
          create: (_) => firebaseReady ? FirebaseAuthRepository() : DemoAuthRepository(),
        ),
        Provider<ProductRepository>(
          create: (_) => firebaseReady ? FirebaseProductRepository() : LocalProductRepository(),
        ),
        Provider<ProfileRepository>(
          create: (_) => firebaseReady ? FirebaseProfileRepository() : LocalProfileRepository(),
        ),
        Provider<EdgePipelineService>(create: (_) => EdgePipelineService()),
        Provider<DeviceCaptureService>(create: (_) => DeviceCaptureService()),
        Provider<ImageAnalysisService>(create: (_) => ImageAnalysisService()),
        Provider<AudioInsightService>(create: (_) => AudioInsightService()),
        Provider<VoiceAssistantService>(create: (_) => VoiceAssistantService()),
        Provider<AiStudioService>(create: (_) => AiStudioService()),
        Provider<ArtisanFollowRepository>(create: (_) => ArtisanFollowRepository()),
        ChangeNotifierProvider<AppFlowController>(
          create: (context) => AppFlowController(context.read<ProfileRepository>()),
        ),
        ChangeNotifierProvider<AuthController>(
          create: (context) => AuthController(context.read<AuthRepository>())..start(),
        ),
        ChangeNotifierProvider<ProductController>(
          create: (context) => ProductController(context.read<ProductRepository>()),
        ),
        ChangeNotifierProvider<CartAndOrdersController>(
          create: (_) => CartAndOrdersController(),
        ),
        ChangeNotifierProvider<LocaleController>(
          create: (_) => LocaleController(),
        ),
        ChangeNotifierProvider<VoiceController>(
          create: (context) => VoiceController(
            assistant: context.read<VoiceAssistantService>(),
            insights: context.read<AudioInsightService>(),
            products: context.read<ProductController>(),
            appFlow: context.read<AppFlowController>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'कला-Connect',
        debugShowCheckedModeBanner: false,
        theme: KalaTheme.light(),
        home: const ViewportSafetyGate(child: _AppRouter()),
      ),
    );
  }
}

class _AppRouter extends StatefulWidget {
  const _AppRouter();

  @override
  State<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends State<_AppRouter> {
  String? _bindingUserId;
  bool _showSplash = true;

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(
        onFinish: () {
          if (mounted) setState(() => _showSplash = false);
        },
      );
    }

    final auth = context.watch<AuthController>();
    final appFlow = context.watch<AppFlowController>();

    // If user is signed in, bind profile in background
    if (auth.isSignedIn) {
      final userId = auth.identity!.uid;
      if (!appFlow.isBoundTo(userId) && _bindingUserId != userId) {
        _bindingUserId = userId;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.read<AppFlowController>().bindArtisan(userId);
        });
      }
    } else {
      _bindingUserId = null;
    }

    return const MainMarketplaceShell();
  }
}

/// Prevents expensive animation trees from being built during the first frame
/// when a platform briefly reports a zero-width viewport.
class ViewportSafetyGate extends StatelessWidget {
  const ViewportSafetyGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).size.width == 0) {
      return const ColoredBox(color: KalaColors.ink);
    }
    return child;
  }
}
