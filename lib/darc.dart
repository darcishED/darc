import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// DarC - Dual Authentication and Riverpod Container
/// A utility class for managing both Firebase and Supabase authentication
/// while integrating with Riverpod. Nothing fancy.
class DarC {
  /// Private constructor
  DarC._();

  static DarC? _instance;
  static Supabase? _supabaseInstance;

  /// Check if DarC was initialized
  bool _initialized = false;

  /// Get the current DarC instance
  ///
  /// An [AssertionError] is thrown if DarC wasn't initialized yet.
  /// Call [DarC.initialize] to initialize it.
  static DarC get instance {
    assert(
    _instance?._initialized == true,
    'DarC must be initialized before calling DarC.instance',
    );
    return _instance;
  }

  /// The Supabase client instance
  static SupabaseClient get supabase => Supabase.instance.client;

  /// The Firebase Auth instance
  static firebase_auth.FirebaseAuth get firebaseAuth =>
      firebase_auth.FirebaseAuth.instance;

  /// The Google Sign In instance
  static GoogleSignIn? _googleSignIn;

  /// Initialize DarC with Firebase and Supabase configurations
  static Future<void> initialize({
    required String supabaseUrl,
    required String supabaseKey,
    required FirebaseOptions firebaseOptions,
    String? webClientId,
    String scopes = 'email,profile',
  }) async {
    assert(
    _instance?._initialized == true,
    'DarC instance is already initialized',
    );

    // avoid crashes
    if (_instance != null) {
      return;
    }

    // Initialize Supabase - only once
    try {
      _supabaseInstance = supabase;
    } on AssertionError catch (e) {
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
      _supabaseInstance = supabase;
    }

    // Initialize Firebase
    await Firebase.initializeApp(options: firebaseOptions);

    // Initialize Google Sign In
    if (kIsWeb && webClientId != null && webClientId.isNotEmpty) {
      _googleSignIn =
          GoogleSignIn(clientId: webClientId, scopes: scopes.split(','));
    } else {
      _googleSignIn = GoogleSignIn(scopes: scopes.split(','));
    }

    _instance = DarC._();
    _initialized = _instance != null;
  }

  /// Wrap the app with ProviderScope for Riverpod
  static ProviderScope providerScope({required Widget child}) {
    return ProviderScope(child: child);
  }

  /// Stream of Supabase authentication state changes
  static Stream<AuthState> get sAuthStateChanges =>
      supabase.auth.onAuthStateChange;

  /// Stream of Firebase authentication state changes
  static Stream<firebase_auth.User?> get fAuthStateChanges =>
      firebaseAuth.authStateChanges();

  /// Current Supabase user
  static User? get sUser => supabase.auth.currentUser;

  /// Current Firebase user
  static firebase_auth.User? get fUser => firebaseAuth.currentUser;

  /// Sign in with Google OAuth for Supabase
  static Future<void> googleSignInOAuth({String? redirectUrl}) async {
    if (kIsWeb) {
      // For web platforms
      await supabase.auth.signInWithOAuth(
          OAuthProvider.google, redirectTo: redirectUrl);
    } else {
      // For mobile platforms
      await _googleSignIn?.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn?.signIn();
      if (googleUser == null) {
        throw Exception('Google Sign In was canceled');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser
          .authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) {
        throw Exception('No ID token found');
      }

      // Sign in to Supabase with Google ID token
      await supabase.auth.signInWithIdToken(
          provider: OAuthProvider.google, idToken: idToken);
    }
  }

  /// Handle auth redirect for web platforms
  static Future<void> handleAuthRedirect(String code) async {
    if (kIsWeb) {
      try {
        // Exchange code for session
        await supabase.auth.exchangeCodeForSession(code);
      } on Exception catch (e) {
        debugPrint('Error handling redirect: $e');
      }
    }
  }

  /// Sign out from both Supabase and Firebase
  static Future<void> signOut() async {
    await supabase.auth.signOut(); // lightest
    await firebaseAuth.signOut(); // lighter
    await _googleSignIn?.signOut(); // light
    // from local cache - heavy (future with local cache)
  }
}
