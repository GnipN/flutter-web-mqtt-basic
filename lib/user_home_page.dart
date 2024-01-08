import 'package:flutter/material.dart';

class UserHomePage extends StatelessWidget {
  final String usr;
  final String jwtToken;
  final String iotToken;

  const UserHomePage(
      {super.key,
      required this.usr,
      required this.jwtToken,
      required this.iotToken});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$usr Home Page'),
      ),
      body: Center(
        child: Text('Welcome $usr to the User Home Page!\n'
            'Your JWT token is: $jwtToken\n'
            'Your IoT token is: $iotToken'),
      ),
    );
  }
}
