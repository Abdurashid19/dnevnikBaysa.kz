import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_auth_oauth/firebase_auth_oauth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Future<User?> signInWithMicrosoft(BuildContext context) async {
  //   try {
  //     // Используем Firebase для авторизации через Microsoft
  //     final User? user = await FirebaseAuthOAuth().openSignInFlow(
  //         "microsoft.com", // Microsoft как провайдер
  //         ["email", "openid", "profile"], // Права доступа
  //         {"tenant": "common"} // Параметры OAuth, если нужны
  //         );

  //     return user; // Возвращаем объект User?
  //   } catch (e) {
  //     print("Ошибка при авторизации через Microsoft: $e");
  //     return null;
  //   }
  // }
}
