import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:todoapp/pages/HomePage.dart';

class AuthClass {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/contacts.readonly',
    ],
  );

  final storage = const FlutterSecureStorage();

  Future<void> googleSignIn(BuildContext context) async {
    try {
      GoogleSignInAccount? googleSignInAccount = await _googleSignIn.signIn();
      if (googleSignInAccount != null) {
        GoogleSignInAuthentication googleSignInAuthentication =
            await googleSignInAccount.authentication;
        AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleSignInAuthentication.accessToken,
          idToken: googleSignInAuthentication.idToken,
        );
        UserCredential userCredential =
            await _auth.signInWithCredential(credential);
        storeTokenAndData(userCredential);
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (builder) => const HomePage()),
            (route) => false);

        final snackBar =
            SnackBar(content: Text(userCredential.user!.displayName ?? "User"));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      } else {
        throw Exception('Google sign in aborted or failed.');
      }
    } catch (e) {
      final snackBar = SnackBar(content: Text(e.toString()));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  Future<void> signOut({BuildContext? context}) async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      await storage.delete(key: "token");
      if (context != null) {
        const snackBar = SnackBar(content: Text("Signed out"));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e) {
      if (context != null) {
        final snackBar = SnackBar(content: Text(e.toString()));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    }
  }

  void storeTokenAndData(UserCredential userCredential) async {
    print("storing token and data");
    String? token =
        userCredential.credential?.token?.toString(); // Convert int? to String?
    await storage.write(key: "token", value: token);
    await storage.write(
        key: "usercredential", value: userCredential.toString());
  }

  Future<String?> getToken() async {
    return await storage.read(key: "token");
  }

  Future<void> verifyPhoneNumber(
      String phoneNumber, BuildContext context, Function setData) async {
    verificationCompleted(PhoneAuthCredential phoneAuthCredential) async {
      showSnackBar(context, "Verification Completed");
    }

    verificationFailed(FirebaseAuthException exception) {
      showSnackBar(context, exception.toString());
    }

    codeSent(String verificationID, int? forceResendingToken) {
      showSnackBar(context, "Verification Code sent on the phone number");
      setData(verificationID);
    }

    codeAutoRetrievalTimeout(String verificationID) {
      showSnackBar(context, "Time out");
    }

    try {
      await _auth.verifyPhoneNumber(
          timeout: const Duration(seconds: 60),
          phoneNumber: phoneNumber,
          verificationCompleted: verificationCompleted,
          verificationFailed: verificationFailed,
          codeSent: codeSent,
          codeAutoRetrievalTimeout: codeAutoRetrievalTimeout);
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  Future<void> signInwithPhoneNumber(
      String verificationId, String smsCode, BuildContext context) async {
    try {
      AuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId, smsCode: smsCode);

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      storeTokenAndData(userCredential);
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (builder) => const HomePage()),
          (route) => false);

      showSnackBar(context, "logged In");
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  void showSnackBar(BuildContext context, String text) {
    final snackBar = SnackBar(content: Text(text));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
