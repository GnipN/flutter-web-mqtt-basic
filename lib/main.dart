import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'User Input',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('IoT basic login'),
        ),
        body: LoginForm(),
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final String _ip = '192.168.74.251:3000';
  String _serverMessage = '';
  String _token = '';

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(labelText: 'Username'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your username';
              }
              return null;
            },
          ),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(labelText: 'Password'),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              return null;
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    // Handle login
                    try {
                      final response = await http.post(
                        Uri.parse('http://$_ip/login'),
                        headers: <String, String>{
                          'Content-Type': 'application/json; charset=UTF-8',
                        },
                        body: jsonEncode(<String, String>{
                          'usr': _usernameController.text,
                          'pass': _passwordController.text,
                        }),
                      );

                      // Parse the JSON response
                      Map<String, dynamic> jsonResponse =
                          jsonDecode(response.body);

                      // Set the server message
                      setState(() {
                        _serverMessage = jsonResponse['message'] ??
                            'No message received from the server';
                        ;
                      });

                      if (response.statusCode == 200) {
                        // If the server returns a 200 OK response,
                        // then parse the JSON.
                        _token = jsonResponse['token'] ?? '';
                        print('Login successful: ${response.body}');
                      } else {
                        // If the server returns an unsuccessful response code,
                        print('Login failed: ${response.body}');
                      }
                    } catch (e) {
                      print('Failed to send login request: $e');
                    }
                  }
                },
                child: Text('Login'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    // Handle signup
                    try {
                      // need to Enable CORS on the server
                      final response = await http.post(
                        Uri.parse('http://$_ip/signup'),
                        headers: <String, String>{
                          'Content-Type': 'application/json; charset=UTF-8',
                        },
                        body: jsonEncode(<String, String>{
                          'usr': _usernameController.text,
                          'pass': _passwordController.text,
                        }),
                      );

// Parse the JSON response
                      Map<String, dynamic> jsonResponse =
                          jsonDecode(response.body);

                      // Set the server message
                      setState(() {
                        _serverMessage = jsonResponse['message'] ??
                            'No message received from the server';
                        ;
                      });
                      if (response.statusCode == 200) {
                        // If the server returns a 200 OK response,
                        // then parse the JSON.
                        print('Signup successful: ${response.body}');
                      } else {
                        // If the server returns an unsuccessful response code,
                        print('Signup failed: ${response.body}');
                      }
                    } catch (e) {
                      print('Failed to send signup request: $e');
                    }
                  }
                },
                child: Text('Signup'),
              ),
            ],
          ),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                Text(_serverMessage),
              ]),
        ],
      ),
    );
  }
}
