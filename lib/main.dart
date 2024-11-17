import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:nyc_public_space_map/map_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
Future<void> initDynamicLinks(BuildContext context) async {
  print('Initializing dynamic links...');

  // Listen for dynamic link while app is in the foreground
  FirebaseDynamicLinks.instance.onLink.listen((PendingDynamicLinkData? dynamicLinkData) async {
    final Uri? deepLink = dynamicLinkData?.link;

    if (deepLink != null && FirebaseAuth.instance.isSignInWithEmailLink(deepLink.toString())) {
      try {
        // The client SDK will parse the code from the link for you.
        final UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailLink(
          email: "chris.m.whong@gmail.com", // Replace with the user's email
          emailLink: deepLink.toString(),
        );

        // You can access the new user via userCredential.user.
        final String? emailAddress = userCredential.user?.email;

        print('Successfully signed in with email link!');
        print('Email Address: $emailAddress');
      } catch (error) {
        print('Error signing in with email link: $error');
      }
    } else {
      print('Dynamic link received, but it is not a valid email sign-in link.');
    }
  }).onError((error) {
    print('Error processing dynamic link: $error');
  });
}
  


// void _handleSignInLink(BuildContext context, Map<String, String> queryParameters) {
//   final String? mode = queryParameters['mode'];
//   final String? oobCode = queryParameters['oobCode'];
//   final String? apiKey = queryParameters['apiKey'];
//   print('here');
//   print(mode);
//   print(oobCode);

//   if (mode == 'signIn' && oobCode != null) {
//     print('Handling sign-in with oobCode: $oobCode');

//     // Complete the sign-in process using Firebase Auth
//     FirebaseAuth.instance
//         .signInWithEmailLink(email: 'user@example.com', emailLink: oobCode)
//         .then((userCredential) {
//       print('Sign-in successful: ${userCredential.user}');
//       // Navigate to your app's main screen
//       Navigator.pushNamed(context, '/home');
//     }).catchError((error) {
//       print('Error completing sign-in: $error');
//     });
//   } else {
//     print('Invalid sign-in link or missing parameters');
//   }
// }

void main() {
  // ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  // read the mapbox access token from environment variable
  String accessToken = const String.fromEnvironment("ACCESS_TOKEN");
  MapboxOptions.setAccessToken(accessToken);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown, // Optional: allow upside-down portrait
  ]).then((_) async {
    // debugPaintSizeEnabled = true; // For debugging purposes

    await Firebase.initializeApp();
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Bottom Navigation',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
    @override
  void initState() {
    super.initState();
    // Initialize dynamic links handling
    initDynamicLinks(context);
  }

  int _selectedIndex = 0;

  // list of pages for the navigation
  static final List<Widget> _pages = <Widget>[
    MapScreen(),
    AboutScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // show content for the selected index
      body: MapScreen(),
      // bottomNavigationBar: BottomNavigationBar(
      //   items: const <BottomNavigationBarItem>[
      //     BottomNavigationBarItem(
      //       icon: Icon(FontAwesomeIcons.map),
      //       label: 'Map',
      //     ),
      //     BottomNavigationBarItem(
      //       icon: Icon(FontAwesomeIcons.infoCircle),
      //       label: 'About',
      //     ),
      //   ],
      //   currentIndex: _selectedIndex,
      //   selectedItemColor: Colors.blue,
      //   onTap: _onItemTapped,
      // ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'About Screen',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}
