import 'package:flash_chat/components/rounded_button.dart';
import 'package:flash_chat/constants.dart';
import 'package:flash_chat/screens/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home_screen.dart';

class RegistrationScreen extends StatefulWidget {
  static const String id = "registration_screen";
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _auth = FirebaseAuth.instance;
  late String email;
  late String password;
  late String name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Flexible(
              child: Hero(
                tag: 'logo',
                child: Container(
                  height: 200.0,
                  child: Image.asset('images/logo.png'),
                ),
              ),
            ),
            SizedBox(
              height: 48.0,
            ),
            TextField(
              keyboardType: TextInputType.emailAddress,
              textAlign: TextAlign.center,
              onChanged: (value) {
                name = value;
              },
              decoration: kTextFieldDecoration.copyWith(hintText: "Enter your Name")
            ),
             SizedBox(
                height: 8.0,
            ),
            TextField(
                keyboardType: TextInputType.emailAddress,
                textAlign: TextAlign.center,
                onChanged: (value) {
                  email = value;
                },
                decoration: kTextFieldDecoration.copyWith(hintText: "Enter your email")
            ),
            SizedBox(
              height: 8.0,
            ),
            TextField(
              obscureText: true,
                textAlign: TextAlign.center,
                onChanged: (value) {
                password = value;
              },
              decoration: kTextFieldDecoration.copyWith(hintText: "Enter your password")
            ),
            SizedBox(
              height: 24.0,
            ),
           RoundedButton(title: 'Register', colour: Colors.blueAccent, onPressed: () async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password
      );

      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(name);

        Navigator.pushNamed(context, HomeScreen.id);
    }
    } catch (e){

      print(e);
    }
           },)
          ],
        ),
      ),
    );
  }
}
