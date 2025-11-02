import 'package:app_links/app_links.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:immo/constants.dart';
import 'package:immo/cubit/auth_cubit.dart';
import 'package:immo/cubit/favorites_cubit.dart';
import 'package:immo/cubit/listing_cubit.dart';
import 'package:immo/cubit/maintenance_cubit.dart';
import 'package:immo/cubits/building/building_cubit.dart';
import 'package:immo/cubits/apartment/apartment_cubit.dart';
import 'package:immo/cubits/message/message_cubit.dart';
import 'package:immo/cubits/payment/payment_cubit.dart';
import 'package:immo/cubits/user/user_cubit.dart';
import 'package:immo/cubits/rentbook/rentbook_cubit.dart';
import 'package:immo/cubits/tenant_rentbook/tenant_rentbook_cubit.dart';
import 'package:immo/cubits/utility_bill/utility_bill_cubit.dart';
import 'package:immo/screens/auth/login_screen.dart';
import 'package:immo/screens/auth/register_screen.dart';
import 'package:immo/screens/dashboard/Annonce_screen.dart';
import 'package:immo/screens/main_screen.dart';
import 'package:immo/widgets/auth_gate.dart';
import 'package:immo/screens/messages_screen.dart';
import 'package:immo/screens/order_screen.dart';
import 'package:immo/services/auth_service.dart';
import 'package:immo/services/building_service.dart';
import 'package:immo/services/apartment_service.dart';
import 'package:immo/services/listing_service.dart';
import 'package:immo/services/maintenance_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:immo/services/utility_bill_service.dart';
import 'package:just_audio/just_audio.dart';
import 'repository/favorites_repository.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/payment_storage_service.dart';
import 'package:immo/cubit/product_cubit.dart';
import 'package:immo/cubit/featured_product_cubit.dart';
import 'package:immo/cubit/category_cubit.dart';
import 'package:immo/cubit/category_products_cubit.dart';
import 'package:immo/cubit/cart_cubit.dart';
import 'package:immo/cubit/order_cubit.dart';
import 'package:immo/cubit/merchant_cubit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:immo/cubits/express/express_cubit.dart';
import 'package:immo/screens/test_firebase_screen.dart';
import 'package:immo/screens/admin_version_screen.dart';
import 'package:immo/screens/test_modal_screen.dart';

final AudioPlayer player = AudioPlayer();

// Clé globale pour accéder au contexte de navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _playNotificationSound() async {
  try {
    print('🎵 Tentative de lecture du son...');
    if (Platform.isAndroid) {
      // Pour Android, utiliser le son depuis le dossier raw
      await player.setAsset('res/raw/notif.mp3');
    } else {
      // Pour iOS, utiliser le son depuis le dossier Runner
      await player.setAsset('ios/Runner/notif.caf');
    }
    print('✅ Son chargé avec succès');
    await player.play();
    print('✅ Son joué avec succès');
  } catch (e) {
    print('❌ Erreur lors de la lecture du son: $e');
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await _playNotificationSound();
}

class FirebaseMessagingService {
  static final FirebaseMessagingService _instance = FirebaseMessagingService._internal();
  factory FirebaseMessagingService() => _instance;
  FirebaseMessagingService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static Future<void> saveTokenToFirestore(String token, AuthState authState) async {
    try {
      String? userId;
      String? role;

      if (authState is AuthSuccess && authState.user != null) {
        print('📱 AuthState user data: ${authState.user}');
        userId = authState.user!['id']?.toString();
        role = authState.user!['role'];
        print('📱 From AuthState - userId: $userId, role: $role');
      } else {
        // Si l'état d'authentification n'a pas les données, essayer de les récupérer depuis SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final userDataStr = prefs.getString('user_data');
        print('📱 SharedPreferences user data: $userDataStr');
        
        if (userDataStr != null) {
          try {
            final userData = jsonDecode(userDataStr);
            print('📱 Parsed user data: $userData');
            userId = userData['id']?.toString();
            role = userData['role'];
            print('📱 From SharedPreferences - userId: $userId, role: $role');
          } catch (e) {
            print('❌ Error parsing user data from SharedPreferences: $e');
          }
        }
      }

      if (userId == null) {
        print('❌ userId is null, cannot save token');
        return;
      }

      // Utiliser userId comme identifiant du document
      final docRef = FirebaseFirestore.instance.collection('tokens').doc(userId);
      await docRef.set({
        'token': token,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': Platform.isIOS ? 'ios' : 'android',
        'role': role ?? 'user',
        'userId': userId,
        'permission_status': (await FirebaseMessaging.instance.getNotificationSettings()).authorizationStatus.toString(),
      }, SetOptions(merge: true)); // merge pour ne pas effacer d'autres champs

      print("✅ Token saved to Firestore successfully (by userId)");
    } catch (e) {
      print("❌ Error saving token to Firestore: $e");
    }
  }

  Future<void> initialize() async {
    try {
      print("🚀 Initializing Firebase Messaging Service...");
      
      // Demander la permission pour les notifications
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: true,
      );

      print('User granted permission: ${settings.authorizationStatus}');

      // Configurer le canal de notification pour Android
      if (Platform.isAndroid) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'order_notifications', // id
          'Order Notifications', // title
          description: 'This channel is used for order notifications.', // description
          importance: Importance.high,
          playSound: true,
          sound: RawResourceAndroidNotificationSound('notif'), // Nom du fichier sans extension
        );

        final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
            FlutterLocalNotificationsPlugin();

        await flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      }

      // Configuration spécifique pour iOS
      if (Platform.isIOS) {
        await _firebaseMessaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      // Configurer le gestionnaire de messages en premier plan
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        print('📩 Message reçu en premier plan: ${message.notification?.title}');
        await _playNotificationSound();
      });

      // Configurer le gestionnaire de messages en arrière-plan
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Listen for token refresh
      _firebaseMessaging.onTokenRefresh.listen((String token) {
        print('🔄 FCM Token Refreshed: $token');
        // saveTokenToFirestore(token, AuthInitial());
      });

      // Get initial token
      String? initialToken = await _firebaseMessaging.getToken();
      if (initialToken != null) {
        print('✅ Initial FCM Token: $initialToken');
        // saveTokenToFirestore(initialToken, AuthInitial());
      } else {
        print('⚠️ No FCM token received');
      }

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        
        // Setup message handlers
        setupFirebaseMessaging();

        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen((String token) {
          print('🔄 FCM Token Refreshed: $token');
          // saveTokenToFirestore(token, AuthInitial());
        });

        // Get initial token
        String? initialToken = await _firebaseMessaging.getToken();
        if (initialToken != null) {
          print('✅ Initial FCM Token: $initialToken');
          // saveTokenToFirestore(initialToken, AuthInitial());
        } else {
          print('⚠️ No FCM token received');
        }
      } else {
        print("❌ Notification permissions not granted: ${settings.authorizationStatus}");
      }
    } catch (e) {
      print("❌ Error initializing Firebase Messaging: $e");
    }
  }

  void setupFirebaseMessaging() {
    try {
      print("🔧 Setting up Firebase Messaging handlers...");
      
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📩 Message reçu en foreground: ${message.notification?.title}');
        print('📩 Message data: ${message.data}');

        if (message.notification != null) {
          _showNotification(message);
        }
      }, onError: (error) {
        print("❌ Error in onMessage listener: $error");
      });

      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('📨 App ouverte via notification: ${message.notification?.title}');
        print('📨 Message data: ${message.data}');
        _handleNotificationTap(message);

      }, onError: (error) {
        print("❌ Error in onMessageOpenedApp listener: $error");
      });

      // Check if app was opened from a notification
      _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          print('📨 App ouverte depuis une notification (état terminé)');
          print('📨 Message data: ${message.data}');
          _handleNotificationTap(message);
        }
      }).catchError((error) {
        print("❌ Error getting initial message: $error");
      });
      
      print("✅ Firebase Messaging handlers setup completed");
    } catch (e, stackTrace) {
      print("❌ Error setting up Firebase Messaging: $e");
      print("Stack trace: $stackTrace");
    }
  }

  void _showNotification(RemoteMessage message) {
    // Pour iOS, nous utilisons le système de notification natif
    if (Platform.isIOS) {
      // Les notifications seront gérées automatiquement par le système iOS
      return;
    }

    // Pour Android, nous pouvons personnaliser l'affichage si nécessaire
    if (Platform.isAndroid) {
      // Les notifications seront gérées automatiquement par le système Android
      return;
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
          Navigator.push(
            navigatorKey.currentContext!,
            MaterialPageRoute(
              builder: (context) => const OrderScreen(
                backNavigation: true,
              ),
            ),
          );
    // Gérer la navigation en fonction du type de notification
    // if (message.data.containsKey('type')) {
    //   switch (message.data['type']) {
    //     case 'order':
    //       String orderId = message.data['orderId'];
    //       print('Naviguer vers la commande: $orderId');
    //       // Naviguer vers la page de commande
    //       Navigator.push(
    //         navigatorKey.currentContext!,
    //         MaterialPageRoute(
    //           builder: (context) => const OrderScreen(
    //             backNavigation: true,
    //           ),
    //         ),
    //       );
    //       break;
    //     case 'chat':
    //       String chatId = message.data['chatId'];
    //       print('Naviguer vers le chat: $chatId');
    //       // TODO: Implémenter la navigation vers la page de chat
    //       break;
    //     default:
    //       print('Type de notification non géré: ${message.data['type']}');
    //   }
    // }
  }
}

void main() async {
  try {
    print("🚀 Starting app initialization...");
    WidgetsFlutterBinding.ensureInitialized();
    
    print("📦 Initializing Hive...");
    await Hive.initFlutter();
    await FavoritesRepository.init();
    await PaymentStorageService.init();
    
    print("🔥 Initializing Firebase...");
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    print("📱 Initializing Firebase Messaging...");
    await FirebaseMessagingService().initialize();

    print("✅ App initialization completed successfully");
    runApp(const MyApp());
  } catch (e, stackTrace) {
    print("❌ Error during app initialization: $e");
    print("Stack trace: $stackTrace");
    // Still run the app even if there's an error
    runApp(const MyApp());
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final AuthCubit _authCubit = AuthCubit(AuthService());
  final AppLinks _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Ne pas appeler checkAuth() ici car AuthGate s'en charge
    // _authCubit.checkAuth();
    _initializeAppLinks();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initializeFirebaseMessaging();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initializeAppLinks() async {
    try {
      // Get the initial link that opened the app
      final uri = await _appLinks.getInitialLink();
      if (uri != null) {
        // Handle the deep link here
        _handleDeepLinks(uri);
      }
      // Listen to incoming links while the app is running
      _appLinks.uriLinkStream.listen((Uri? uri) {
        if (uri != null) {
          _handleDeepLinks(uri);
        }
      });
    } catch (e) {
      print('Error initializing app links: $e');
    }
  }

  void _handleDeepLinks(Uri uri) {
    String? annonceId;
    if (uri.pathSegments.contains("annonce")) {
      annonceId = uri.pathSegments.last;
    }

    if (annonceId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => AnnonceScreen(annonceId: annonceId!)),
      );
    }
  }

  Future<void> _initializeFirebaseMessaging() async {
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        print("🚀 Initializing Firebase Messaging (attempt ${retryCount + 1}/$maxRetries)...");
        FirebaseMessaging messaging = FirebaseMessaging.instance;

        // Request permission first
        NotificationSettings settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: true,
        );

        print("📱 Notification settings: ${settings.authorizationStatus}");

        if (settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional) {

          // Listen for token refresh
          messaging.onTokenRefresh.listen((String token) {
            print('🔄 FCM Token Refreshed: $token');
            // saveTokenToFirestore(token, AuthInitial());
          });

          if (Platform.isIOS) {
            // Get APNS token with retry
            int apnsRetryCount = 0;
            String? apnsToken;
            
            while (apnsToken == null && apnsRetryCount < 3) {
              try {
                apnsToken = await messaging.getAPNSToken();
                if (apnsToken == null) {
                  print("⏳ Waiting for APNS token... (attempt ${apnsRetryCount + 1})");
                  await Future.delayed(const Duration(seconds: 2));
                  apnsRetryCount++;
                } else {
                  print("✅ APNS Token received: $apnsToken");
                }
              } catch (e) {
                print("⚠️ Error getting APNS token: $e");
                await Future.delayed(const Duration(seconds: 2));
                apnsRetryCount++;
              }
            }

            if (apnsToken == null) {
              print("⚠️ Failed to get APNS token after $apnsRetryCount attempts");
              // Continue anyway as FCM might still work
            }
          }

          // Get FCM token
          String? token = await messaging.getToken();
          if (token != null) {
            print('✅ FCM Token received: $token');
            // saveTokenToFirestore(token, AuthInitial());
            return; // Success, exit the retry loop
          } else {
            print('⚠️ No FCM token received');
            throw Exception('No FCM token received');
          }
        } else {
          print("❌ Notification permissions not granted: ${settings.authorizationStatus}");
          throw Exception('Notification permissions not granted');
        }
      } catch (e) {
        print("❌ Error initializing Firebase Messaging: $e");
        retryCount++;
        
        if (retryCount < maxRetries) {
          print("⏳ Retrying in 3 seconds...");
          await Future.delayed(const Duration(seconds: 3));
        } else {
          print("❌ Failed to initialize Firebase Messaging after $maxRetries attempts");
          // Don't throw the error, just log it and continue
          break;
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authCubit),
        BlocProvider<BuildingCubit>(
          create: (context) => BuildingCubit(BuildingService()),
        ),
        BlocProvider<ApartmentCubit>(
          create: (context) => ApartmentCubit(ApartmentService()),
        ),
        BlocProvider(create: (context) => ListingCubit(ListingService())),
        BlocProvider(create: (context) => MessageCubit()),
        BlocProvider(create: (context) => UserCubit()),
        BlocProvider(create: (context) => RentbookCubit()),
        BlocProvider(create: (context) => TenantRentbookCubit()),
        BlocProvider(create: (context) => PaymentCubit()),
        BlocProvider(
            create: (context) => MaintenanceCubit(MaintenanceService())),
        BlocProvider(
            create: (context) => UtilityBillCubit(UtilityBillService())),
        BlocProvider(create: (context) => ProductCubit()),
        BlocProvider(create: (context) => FeaturedProductCubit()),
        BlocProvider(create: (context) => CategoryCubit()),
        BlocProvider(create: (context) => CategoryProductsCubit()),
        BlocProvider(create: (context) => CartCubit()),
        BlocProvider(create: (context) => OrderCubit()),
        BlocProvider(create: (context) => MerchantCubit()),
        BlocProvider(create: (context) => FavoritesCubit()),
        BlocProvider(create: (context) => ExpressCubit()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Rapidos App',
        supportedLocales: const [
          Locale('en'),
          Locale('fr'),
        ],
        localizationsDelegates: const [
          CountryLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.background,
          textTheme: GoogleFonts.plusJakartaSansTextTheme(
            Theme.of(context).textTheme,
          ),
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            secondary: AppColors.secondary,
            background: AppColors.background,
          ),
        ),
        home: const AuthGate(),
        routes: {
          AppRoutes.login: (context) => const LoginScreen(),
          AppRoutes.register: (context) => const RegisterScreen(),
          AppRoutes.main: (context) => const MainScreen(),
          AppRoutes.chat: (context) {
            final Map<dynamic, dynamic> rawArgs = ModalRoute.of(context)!
                .settings
                .arguments as Map<dynamic, dynamic>;
            final Map<String, dynamic> args =
                Map<String, dynamic>.from(rawArgs);
            return ChatScreen(conversation: args);
          },
          '/test-firebase': (context) => const TestFirebaseScreen(),
          '/admin-version': (context) => const AdminVersionScreen(),
          '/test-modals': (context) => const TestModalScreen(),
        },
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?q=80&w=2070',
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              fit: BoxFit.cover,
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeText(),
                        _buildSearchBar(),
                        _buildContent(),
                      ],
                    ),
                  ),
                ),
                _buildBottomNavigation(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: const [
                Icon(Icons.location_on, size: 16),
                SizedBox(width: 4),
                Text('Norway', style: TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          CircleAvatar(
            backgroundColor: Colors.white,
            child: IconButton(
              icon: const Icon(Icons.person_outline),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeText() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: const Text(
        'Hey, Martin!\nTell us where you want to go',
        style: TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.white),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Search places',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Date range • Number of guests',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'The most relevant',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildPropertyCard(),
          const SizedBox(height: 24),
          const Text(
            'Discover new places',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildDiscoverSection(),
          const SizedBox(height: 16), // Ajouter un peu d'espace en bas
        ],
      ),
    );
  }

  Widget _buildPropertyCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  'https://images.unsplash.com/photo-1449158743715-0a90ebb6d2d8?q=80&w=2070',
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
              const Positioned(
                top: 12,
                right: 12,
                child: Icon(
                  Icons.favorite_border,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Tiny home in Rœlingen',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: const [
                        Icon(Icons.star, size: 16),
                        Text('4.96 (217)'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '4 guests • 2 bedrooms • 2 beds • 1 bathroom',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(color: Colors.black),
                    children: [
                      TextSpan(
                        text: '€91 ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: 'night • '),
                      TextSpan(text: '€273 total'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverSection() {
    final List<String> discoverImages = [
      'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?q=80&w=2070',
      'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?q=80&w=2070',
      'https://images.unsplash.com/photo-1494526585095-c41746248156?q=80&w=2070',
    ];

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: discoverImages.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              discoverImages[index],
              width: 160,
              height: 120,
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(Icons.search, 'Discover', true),
          _buildNavItem(Icons.favorite_border, 'Favorites', false),
          _buildNavItem(Icons.calendar_today, 'Bookings', false),
          _buildNavItem(Icons.message_outlined, 'Messages', false),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isSelected ? Colors.black : Colors.grey,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
