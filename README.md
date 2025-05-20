# DarC - Dual Authentication and Riverpod Container

[![pub package](https://img.shields.io/pub/v/darc.svg)](https://pub.dev/packages/darc)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

A Flutter package that simplifies authentication management for apps using both Firebase and
Supabase, with seamless Riverpod integration.

## Features

- 🔄 Unified authentication interface for both Firebase and Supabase
- 🔌 Easy initialization and configuration
- 🌐 Cross-platform support (iOS, Android, Web)
- 🔐 Google Sign-In integration
- 📊 Authentication state streams for both providers
- 🧩 Riverpod integration built-in

## Installation

Add `darc` to your `pubspec.yaml`:

```yaml
dependencies:
  darc: ^1.0.0
```

## Setup

### Prerequisites

1. Set up your Firebase project and generate the `firebase_options.dart` file
2. Create a Supabase project and obtain your URL and anon key
3. Configure Google Sign-In for your platforms

### Initialization

Initialize DarC in your main.dart file:

```dart
import 'package:darc/darc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'src/routing/app_router.dart';

// Create a provider to store the router instance
final routerProvider = Provider<AppRouter>(
      (ref) => AppRouter(),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize DarC with your credentials
  await DarC.initialize(
    supabaseUrl: 'https://xxx.supabase.co',
    supabaseKey: 'xxx',
    firebaseOptions: DefaultFirebaseOptions.currentPlatform,
    webClientId: '', // For web platform - Google Client ID
    scopes: 'openid,email,profile',
  );

  // Wrap your app with DarC's provider scope
  runApp(DarC.providerScope(child: MyApp()));
}
```

### Usage in your app

```dart
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appRouter = ref.read(routerProvider);

    // Initialize and cleanup
    useEffect(() {
      // Clean up when the widget is disposed
      return appRouter.dispose;
    }, const <Object?>[]);

    return MaterialApp.router(
      title: 'DarC Demo',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      routerConfig: appRouter.config(),
    );
  }
}
```

## API Reference

### Authentication State

Monitor authentication state changes for both providers:

```dart
// Supabase auth state stream
Stream<AuthState> authStateStream = DarC.sAuthStateChanges;

// Firebase auth state stream  
Stream<User?> firebaseAuthStateStream = DarC.fAuthStateChanges;
```

### Current User

Get the current authenticated user:

```dart

// Supabase current user
User? supabaseUser = DarC.sUser;

// Firebase current user
FirebaseUser? firebaseUser = DarC.fUser;
```

### Authentication Methods

```dart

// Sign in with Google OAuth Android
await DarC.googleSignInOAuth();

// Sign in with Google OAuth Web (current route where auth is happening)
await DarC.googleSignInOAuth(redirectUrl: 'https://your-app.com/');

// Handle auth redirects (for web platform)
await DarC.handleAuthRedirect('<insert code>');

// Sign out from both providers
await DarC.signOut();
```

## Example: Auth State Listener

```dart
class AuthStateListener extends ConsumerWidget {
  const AuthStateListener({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to Supabase auth state
    ref.listen<AsyncValue<AuthState>>(
      supabaseAuthStateProvider,
          (previous, current) {
        current.whenData((authState) {
          // Handle Supabase auth state changes
        });
      },
    );

    // Listen to Firebase auth state
    ref.listen<AsyncValue<User?>>(
      firebaseAuthStateProvider,
          (previous, current) {
        current.whenData((user) {
          // Handle Firebase auth state changes
        });
      },
    );

    return child;
  }
}

// Define the providers
final supabaseAuthStateProvider = StreamProvider<AuthState>(
      (ref) => DarC.sAuthStateChanges,
);

final firebaseAuthStateProvider = StreamProvider<User?>(
      (ref) => DarC.fAuthStateChanges,
);
```

## Contribution

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
