import 'package:app_links/app_links.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:immo/constants.dart';
import 'package:immo/cubit/auth_cubit.dart';
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
import 'package:immo/screens/dashboard/dashboard_screen.dart';
import 'package:immo/screens/home_screen.dart';
import 'package:immo/screens/main_screen.dart';
import 'package:immo/screens/messages_screen.dart';
import 'package:immo/services/auth_service.dart';
import 'package:immo/services/building_service.dart';
import 'package:immo/services/apartment_service.dart';
import 'package:immo/services/listing_service.dart';
import 'package:immo/services/maintenance_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:immo/services/utility_bill_service.dart';
import 'repository/favorites_repository.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/payment_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await FavoritesRepository.init();
  await PaymentStorageService.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AuthCubit _authCubit = AuthCubit(AuthService());
  final AppLinks _appLinks = AppLinks();
  
  @override
  void initState() {
    super.initState();
    // Vérifier l'authentification au démarrage de l'application
    _authCubit.checkAuth();
    _initializeAppLinks();
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
        MaterialPageRoute(builder: (context) => AnnonceScreen(annonceId: annonceId!)),
      );
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
        BlocProvider(create: (context) => MaintenanceCubit(MaintenanceService())),
        BlocProvider(create: (context) => UtilityBillCubit(UtilityBillService())),
      ],
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Immo App',
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
            home: state is AuthSuccess && state.token != null
                ? const MainScreen()
                : const LoginScreen(),
            routes: {
              AppRoutes.login: (context) => const LoginScreen(),
              AppRoutes.register: (context) => const RegisterScreen(),
              AppRoutes.profile: (context) => const DashboardScreen(),
              AppRoutes.main: (context) => const MainScreen(),
              AppRoutes.chat: (context) {
                final Map<dynamic, dynamic> rawArgs = ModalRoute.of(context)!.settings.arguments as Map<dynamic, dynamic>;
                final Map<String, dynamic> args = Map<String, dynamic>.from(rawArgs);
                return ChatScreen(conversation: args);
              },
            },
          );
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
