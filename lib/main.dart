import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MQTT IP Input',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Enter MQTT Broker IP'),
        ),
        body: const IpInputForm(),
      ),
    );
  }
}

class IpInputForm extends StatefulWidget {
  const IpInputForm({Key? key}) : super(key: key);

  @override
  _IpInputFormState createState() => _IpInputFormState();
}

class _IpInputFormState extends State<IpInputForm> {
  MqttBrowserClient? client; // Define client at the class level
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController(text: 'ws://192.168.243.251');
  final _topicController = TextEditingController(
      text: 'test/topic'); // Replace 'test/topic' with your default topic
  final _messageController = TextEditingController();
  String _latestMessage = '';
  String _connectionStatus = '';
  String _subscribeStatus = '';
  bool _isConnected = false;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextFormField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'Enter IP',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an IP';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _topicController,
              decoration: const InputDecoration(
                labelText: 'Enter Topic',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a topic';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Enter Message',
              ),
              // validator: (value) {
              //   if (value == null || value.isEmpty) {
              //     return 'Please enter a message';
              //   }
              //   return null;
              // },
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  print('IP: ${_ipController.text}');
                  // Here you can add the code to connect to the MQTT broker
                  client =
                      MqttBrowserClient(_ipController.text, 'flutter_client');
                  // ip should looklike 'ws://192.168.243.251'
                  // !!! importance must add 'ws://' before ip !!!
                  client?.port =
                      9001; // Change this if your broker is not running on port 1883
                  client?.keepAlivePeriod = 20;
                  try {
                    await client?.connect();
                  } catch (e) {
                    print('Exception: $e');
                    client?.disconnect();
                  }

                  if (client?.connectionStatus!.state ==
                      MqttConnectionState.connected) {
                    print('MQTT client connected');
                    setState(() {
                      _connectionStatus = 'Connected';
                      _isConnected = true;
                    });
                  } else {
                    print('ERROR: MQTT client connection failed - '
                        'disconnecting, status is ${client?.connectionStatus}');
                    setState(() {
                      _connectionStatus = 'Connection failed';
                      _isConnected = false;
                    });
                    client?.disconnect();
                  }
                }
              },
              child: const Text('Connect'),
            ),
            ElevatedButton(
              onPressed: _isConnected
                  ? () {
                      final topic = _topicController.text;
                      client?.subscribe(topic, MqttQos.atLeastOnce);
                      setState(() {
                        _subscribeStatus = 'Subscribed to $topic';
                      });

                      client?.updates!
                          .listen((List<MqttReceivedMessage<MqttMessage>> c) {
                        final MqttPublishMessage recMess =
                            c[0].payload as MqttPublishMessage;
                        final String pt =
                            MqttPublishPayload.bytesToStringAsString(
                                recMess.payload.message!);

                        print(
                            'Received message:$pt from topic: ${c[0].topic}>');
                        setState(() {
                          _latestMessage =
                              'Received message:$pt from topic: ${c[0].topic}>';
                        });
                      });
                    }
                  : null,
              child: const Text('Subscribe'),
            ),
            ElevatedButton(
              onPressed: _isConnected
                  ? () {
                      final topic = _topicController.text;
                      final message = _messageController.text;
                      final MqttClientPayloadBuilder builder =
                          MqttClientPayloadBuilder();
                      builder.addString(message);
                      client?.publishMessage(
                          topic, MqttQos.atLeastOnce, builder.payload!);
                    }
                  : null,
              child: const Text('Publish'),
            ),
            Text(_connectionStatus),
            Text(_subscribeStatus),
            Text(_latestMessage), // Display the latest message
          ],
        ),
      ),
    );
  }
}
