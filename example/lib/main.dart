import 'package:darc/darc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'firebase_options.dart';

// Create a provider for auth state
final StreamProvider<AuthState> supabaseAuthProvider = StreamProvider<AuthState>(
  (StreamProviderRef<AuthState> ref) => DarC.sAuthStateChanges,
);

// if you want to listen to fb Auth
// final StreamProvider<User?> firebaseAuthProvider = StreamProvider<User?>((StreamProviderRef<Object?> ref) => DarC.fAuthStateChanges);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize DarC with your credentials
  await DarC.initialize(
    supabaseUrl: '',
    supabaseKey: '',
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    webClientId: kIsWeb ? '' : null,
    scopes: 'openid,email,profile',
  );

  // Wrap in provider scope
  runApp(DarC.providerScope(child: const MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DarC Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthPage(),
    );
  }
}

class AuthPage extends ConsumerWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch auth states
    final AsyncValue<AuthState> supabaseAuthState = ref.watch(supabaseAuthProvider);

    // for Firebase
    // final AsyncValue<User?> firebaseAuthState = ref.watch(firebaseAuthProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('DarC Authentication Demo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Supabase auth state
            supabaseAuthState.when(
              data: (AuthState authState) {
                final User? user = authState.session?.user;
                return Column(
                  children: <Widget>[
                    const Text('Supabase Auth:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(user != null ? 'Logged in as: ${user.email}' : 'Not logged in'),
                  ],
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (Object err, StackTrace stack) => Text('Error: $err'),
            ),

            const SizedBox(height: 20),

            // For Firebase auth state
            // firebaseAuthState.when(
            //   data: (User? user) {
            //     return Column(
            //       children: <Widget>[
            //         const Text(
            //           'Firebase Auth:',
            //           style: TextStyle(fontWeight: FontWeight.bold),
            //         ),
            //         Text(
            //           user != null
            //               ? 'Logged in as: ${user.email}'
            //               : 'Not logged in',
            //         ),
            //       ],
            //     );
            //   },
            //   loading: () => const CircularProgressIndicator(),
            //   error: (Object err, StackTrace stack) => Text('Error: $err'),
            // ),
            // const SizedBox(height: 40),

            // Auth
            if (DarC.sUser == null)
              ElevatedButton(
                onPressed: () async {
                  try {
                    await DarC.googleSignInOAuth(
                      redirectUrl:
                          kIsWeb ? 'http://localhost:xxx/' : null, // Enter your current web URL
                    );
                  } on Exception catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                child: const Text('Sign in with Google'),
              ),

            if (DarC.sUser != null)
              ElevatedButton(
                onPressed: () async {
                  await DarC.signOut();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Sign out'),
              ),
          ],
        ),
      ),
    );
  }
}
