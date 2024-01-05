import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_browser_client.dart';
import 'package:mqtt_client/mqtt_client.dart';

// for fl_chart
import 'package:fl_chart/fl_chart.dart';
// import 'package:fl_chart_app/cubits/app/app_cubit.dart';
// import 'package:fl_chart_app/presentation/resources/app_resources.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:google_fonts/google_fonts.dart';

// import 'presentation/router/app_router.dart';

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
  final List<FlSpot> _chartData = [FlSpot(0, 0)]; // data for 1st chart
  final List<FlSpot> _chartData2 = [FlSpot(0, 0)]; // data for 2nd chart
  final List<DateTime> _timeData = [DateTime.now()]; // data for time

  @override
  Widget build(BuildContext context) {
    final double maxY = _chartData
        .map((spot) => spot.y)
        .reduce((value, element) => value > element ? value : element);

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
                  if (kDebugMode) {
                    print('IP: ${_ipController.text}');
                  }
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
                    if (kDebugMode) {
                      print('Exception: $e');
                    }
                    client?.disconnect();
                  }

                  if (client?.connectionStatus!.state ==
                      MqttConnectionState.connected) {
                    if (kDebugMode) {
                      print('MQTT client connected');
                    }
                    setState(() {
                      _connectionStatus = 'Connected';
                      _isConnected = true;
                    });
                  } else {
                    if (kDebugMode) {
                      print('ERROR: MQTT client connection failed - '
                          'disconnecting, status is ${client?.connectionStatus}');
                    }
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

                        final int intValue = int.parse(pt);

                        setState(() {
                          _chartData.add(FlSpot(_chartData.length.toDouble(),
                              intValue.toDouble()));
                          _chartData2.add(FlSpot(_chartData2.length.toDouble(),
                              intValue.toDouble() + 100));
                          _timeData.add(DateTime.now());
                          _latestMessage =
                              'Received message:$pt from topic: ${c[0].topic}>';
                          if (kDebugMode) {
                            print(_chartData);
                          }
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
            Expanded(
              child: LineChart(
                LineChartData(
                  // minY: 0,
                  // maxY: 3000,
                  titlesData: FlTitlesData(
                    leftTitles: SideTitles(
                      showTitles: true,
                      getTitles: (value) {
                        if (value == 0) {
                          return '0';
                        } else if (value == maxY) {
                          return '${maxY.toInt()}';
                        } else {
                          return '';
                        }
                      },
                    ),
                    bottomTitles: SideTitles(
                      showTitles: true,
                      getTitles: (value) {
                        if (value.toInt() < _timeData.length) {
                          final time = _timeData[value.toInt()];
                          return '${time.hour}:${time.minute}:${time.second}';
                        } else {
                          return '';
                        }
                      },
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _chartData,
                      isCurved: true,
                      colors: [Colors.blue],
                      barWidth: 2,
                    ),
                    LineChartBarData(
                      spots: _chartData2,
                      isCurved: true,
                      colors: [Colors.red],
                      barWidth: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
