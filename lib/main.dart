import 'dart:async';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lcu_connector/event_response.dart';
import 'package:lcu_connector/lcu.dart';

final invalidState = ["EveryoneReady", "Error"];

void main() {
  runApp(const MyApp());
  doWhenWindowReady(() {
    appWindow.title = 'League of Legends Utils';
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    Key? key,
  }) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isOpen = false;
  bool _autoAccept = false;
  LcuApi lcu = LcuApi();

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      await checkLoLRunning();
    });
  }

  checkLoLRunning() async {
    try {
      await lcu.start();
      setState(() {
        _isOpen = true;
      });
    } catch (e) {
      setState(() {
        _isOpen = false;
      });
    }
  }

  void onAutoAcceptChange(value) {
    setState(() {
      _autoAccept = value;
    });
    if (_autoAccept) {
      subscribeAutoAccept();
    } else {
      unsubscribeAutoAccept();
    }
  }

  void subscribeAutoAccept() async {
    lcu.events.on('/lol-matchmaking/v1/search', (message) async {
      EventResponse evResponse = message;
      if (evResponse.eventType == 'Update') {
        String searchState = evResponse.data['searchState'];
        String playerResponse = evResponse.data['readyCheck']['playerResponse'];
        String state = evResponse.data['readyCheck']['state'];
        if (searchState == 'Found' &&
            playerResponse != "Accepted" &&
            !invalidState.contains(state)) {
          debugPrint('Accepting');
          acceptMatch();
        }
      }
    });
  }

  void unsubscribeAutoAccept() async {
    lcu.events.removeAllListeners('/lol-matchmaking/v1/search');
  }

  void acceptMatch() async {
    await lcu.request(
        HttpMethod.POST, '/lol-matchmaking/v1/ready-check/accept');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Auto accept', style: Theme.of(context).textTheme.headline4),
            Switch(
              value: _autoAccept,
              onChanged: _isOpen ? onAutoAcceptChange : null,
            ),
            Visibility(
              visible: !_isOpen,
              child: const Text(
                'LoL is not running.',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
