import 'dart:io';

import 'package:chat_app/widgets/user_image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

final _firebase = FirebaseAuth.instance;

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _form = GlobalKey<FormState>();

  var _isLogin = true;
  var _enteredEmail = '';
  var _enteredUsername = '';
  var _enteredPassword = '';
  File? _selectedImage;
  var _isUploadingImage = false;

  void _submit() async {
    final isValid = _form.currentState!.validate();

    if (isValid) {
      _form.currentState!.save();
    }

    try {
      setState(() {
        _isUploadingImage = true;
      });
      if (_isLogin) {
        final userCredentials = await _firebase.signInWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);
      } else {
        var imageURL = null;
        final userCredentials = await _firebase.createUserWithEmailAndPassword(
            email: _enteredEmail, password: _enteredPassword);
        if (_selectedImage != null) {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('${userCredentials.user!.uid}.jpg');
          await storageRef.putFile(_selectedImage!);
          imageURL = await storageRef.getDownloadURL();
          print("IMAGE >> " + imageURL);
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredentials.user!.uid)
            .set({
          'username': _enteredUsername,
          'email': _enteredEmail,
          'image_url': imageURL ?? ''
        });
      }
    } on FirebaseAuthException catch (error) {
      if (error.code == 'email-already-in-use') {
        // ...
      }
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error.message ?? "Authentication failed"),
      ));
    }
    setState(() {
      _isUploadingImage = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
          child: SingleChildScrollView(
        child: Column(children: [
          Container(
            margin:
                const EdgeInsets.only(bottom: 20, top: 30, left: 20, right: 20),
            width: 200,
            child: Image.asset('assets/images/chat_bubble.png'),
          ),
          Card(
              margin: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                          key: _form,
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            if (!_isLogin)
                              UserImagePicker(
                                onPickImage: (pickedImage) {
                                  _selectedImage = pickedImage;
                                },
                              ),
                            if (!_isLogin)
                              TextFormField(
                                  key: const ValueKey('username'),
                                  textCapitalization: TextCapitalization.words,
                                  enableSuggestions: false,
                                  decoration: const InputDecoration(
                                      labelText: 'Username'),
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty ||
                                        value.length < 4) {
                                      return 'Please enter at least 4 characters.';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    _enteredUsername = value!;
                                  }),
                            TextFormField(
                                keyboardType: TextInputType.emailAddress,
                                autocorrect: false,
                                textCapitalization: TextCapitalization.none,
                                decoration: const InputDecoration(
                                    labelText: 'Email address'),
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().isEmpty ||
                                      !value.contains('@')) {
                                    return 'Please enter a valid email address.';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  _enteredEmail = value!;
                                }),
                            TextFormField(
                                obscureText: true,
                                decoration: const InputDecoration(
                                    labelText: 'Password'),
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().isEmpty ||
                                      value.length < 7) {
                                    return 'Password must be at least 7 characters long.';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  _enteredPassword = value!;
                                }),
                            const SizedBox(height: 12),
                            if (_isUploadingImage)
                              const CircularProgressIndicator(),
                            if (!_isUploadingImage)
                              ElevatedButton(
                                onPressed: _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                ),
                                child: Text(_isLogin ? 'Login' : 'Signup'),
                              ),
                            if (!_isUploadingImage)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isLogin = !_isLogin;
                                  });
                                },
                                child: Text(_isLogin
                                    ? 'Create new account'
                                    : 'I already have an account'),
                              )
                          ]))))),
        ]),
      )),
    );
  }
}
