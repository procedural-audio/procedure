import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';

import 'home.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Add debug prints for authentication state
        print("AuthGate: Authentication state changed");
        print("AuthGate: Has data: ${snapshot.hasData}");
        print("AuthGate: Has error: ${snapshot.hasError}");
        
        if (snapshot.hasError) {
          print("AuthGate: Authentication error: ${snapshot.error}");
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red, size: 48),
                SizedBox(height: 16),
                Text(
                  "Authentication Error",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  "${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.red),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Try to sign out and retry
                    FirebaseAuth.instance.signOut();
                  },
                  child: Text("Retry"),
                ),
              ],
            ),
          );
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          print("AuthGate: Waiting for authentication...");
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Checking authentication..."),
              ],
            ),
          );
        }
        
        if (!snapshot.hasData) {
          print("AuthGate: No user data, showing sign in screen");
          return SignInScreen(
            providers: [EmailAuthProvider()], // , GoogleProvider(clientId: clientId)]);  // Modify this line
            actions: [
              AuthStateChangeAction<AuthState>(
                (context, state) {
                  print("AuthGate: Auth state changed to: $state");
                },
              ),
            ],
          );
        }

        print("AuthGate: User authenticated: ${snapshot.data?.uid}");
        return Container();
      },
    );
  }
}