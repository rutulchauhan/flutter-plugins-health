library mobility_app;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:carp_background_location/carp_background_location.dart';
import 'package:mobility_features/mobility_features.dart';

part 'stops_page.dart';
part 'moves_page.dart';
part 'places_page.dart';

void main() => runApp(MyApp());

Widget entry(String key, String value, Icon icon) {
  return Container(
      padding: const EdgeInsets.all(2),
      margin: EdgeInsets.all(3),
      child: ListTile(
        leading: icon,
        title: Text(key),
        trailing: Text(value),
      ));
}

String formatDate(DateTime date) {
  return '${date.year}/${date.month}/${date.day}';
}

String interval(DateTime a, DateTime b) {
  String pad(int x) => '${x.toString().padLeft(2, '0')}';
  return '${pad(a.hour)}:${pad(a.minute)}:${pad(a.second)} - ${pad(b.hour)}:${pad(b.minute)}:${pad(b.second)}';
}

String formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
}

final stopIcon = Icon(Icons.my_location);
final moveIcon = Icon(Icons.directions_walk);
final placeIcon = Icon(Icons.place);
final featuresIcon = Icon(Icons.assessment);
final homeStayIcon = Icon(Icons.home);
final distanceTravelledIcon = Icon(Icons.card_travel);
final entropyIcon = Icon(Icons.equalizer);
final varianceIcon = Icon(Icons.swap_calls);

enum AppState { NO_FEATURES, CALCULATING_FEATURES, FEATURES_READY }

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobility Features Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Mobility Features Demo'),
    );
  }
}

String dtoToString(LocationDto dto) =>
    '${dto.latitude}, ${dto.longitude} @ ${DateTime.fromMillisecondsSinceEpoch(dto.time ~/ 1)}';

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  AppState _state = AppState.NO_FEATURES;

  int _currentIndex = 0;

  // Location Streaming
  Stream<LocationDto> locationStream;
  StreamSubscription<LocationDto> locationSubscription;

  // Mobility Features stream
  StreamSubscription<MobilityContext> mobilitySubscription;
  MobilityContext _mobilityContext;

  @override
  void initState() {
    super.initState();

    // Set up Mobility Features
    MobilityFeatures().stopDuration = Duration(seconds: 20);
    MobilityFeatures().placeRadius = 50.0;
    MobilityFeatures().stopRadius = 5.0;

    // Setup Location Manager
    LocationManager().distanceFilter = 0;
    LocationManager().interval = 1;
    LocationManager().notificationTitle = 'Mobility Features';
    LocationManager().notificationMsg = 'Your geo-location is being tracked';
    streamInit();
  }

  @override
  void dispose() {
    mobilitySubscription?.cancel();
    super.dispose();
  }

  void onMobilityContext(MobilityContext context) {
    print('Context received: ${context.toJson()}');
    setState(() {
      _state = AppState.FEATURES_READY;
      _mobilityContext = context;
    });
  }

  /// Set up streams:
  /// * Subscribe to stream in case it is already running (Android only)
  /// * Subscribe to MobilityContext updates
  void streamInit() async {
    locationStream = LocationManager().locationStream;
    locationSubscription = locationStream.listen(onData);

    // Subscribe if it hasn't been done already
    if (locationSubscription != null) {
      locationSubscription.cancel();
    }
    locationSubscription = locationStream.listen(onData);
    await LocationManager().start();

    Stream<LocationSample> locationSampleStream = locationStream.map((e) =>
        LocationSample(GeoLocation(e.latitude, e.longitude), DateTime.now()));

    MobilityFeatures().startListening(locationSampleStream);
    mobilitySubscription =
        MobilityFeatures().contextStream.listen(onMobilityContext);
  }

  void onData(LocationDto dto) {
    print(dtoToString(dto));
  }

  Widget get featuresOverview {
    return ListView(
      children: <Widget>[
        entry("Stops", "${_mobilityContext.stops.length}", stopIcon),
        entry("Moves", "${_mobilityContext.moves.length}", moveIcon),
        entry("Significant Places",
            "${_mobilityContext.numberOfSignificantPlaces}", placeIcon),
        entry(
            "Home Stay",
            _mobilityContext.homeStay < 0
                ? "?"
                : "${(_mobilityContext.homeStay * 100).toStringAsFixed(1)}%",
            homeStayIcon),
        entry(
            "Distance Travelled",
            "${(_mobilityContext.distanceTravelled / 1000).toStringAsFixed(2)} km",
            distanceTravelledIcon),
        entry(
            "Normalized Entropy",
            "${_mobilityContext.normalizedEntropy.toStringAsFixed(2)}",
            entropyIcon),
        entry(
            "Location Variance",
            "${(111.133 * _mobilityContext.locationVariance).toStringAsFixed(5)} km",
            varianceIcon),
      ],
    );
  }

  List<Widget> get contentNoFeatures {
    return [
      Container(
          margin: EdgeInsets.all(25),
          child: Text(
            'Move around to start generating features',
            style: TextStyle(fontSize: 20),
          ))
    ];
  }

  List<Widget> get contentFeaturesReady {
    return [
      Container(
          margin: EdgeInsets.all(25),
          child: Column(children: [
            Text(
              'Statistics for today,',
              style: TextStyle(fontSize: 20),
            ),
            Text(
              '${formatDate(_mobilityContext.date)}',
              style: TextStyle(fontSize: 20, color: Colors.blue),
            ),
          ])),
      Expanded(child: featuresOverview),
    ];
  }

  Widget get content {
    List<Widget> children;
    if (_state == AppState.FEATURES_READY)
      children = contentFeaturesReady;
    else
      children = contentNoFeatures;
    return Column(children: children);
  }

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Widget _navBar() {
    return BottomNavigationBar(
      onTap: onTabTapped, // new
      currentIndex: _currentIndex, // this will be set when a new tab is tapped
      type: BottomNavigationBarType.fixed,
      items: [
        BottomNavigationBarItem(icon: featuresIcon, label: 'Features'),
        BottomNavigationBarItem(icon: stopIcon, label: 'Stops'),
        BottomNavigationBarItem(icon: placeIcon, label: 'Places'),
        BottomNavigationBarItem(icon: moveIcon, label: 'Moves')
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Stop> stops = [];
    List<Move> moves = [];
    List<Place> places = [];

    if (_mobilityContext != null) {
      for (var x in _mobilityContext.stops) print(x);
      for (var x in _mobilityContext.moves) {
        print(x);
        print('${x.stopFrom} --> ${x.stopTo}');
      }
      stops = _mobilityContext.stops;
      moves = _mobilityContext.moves;
      places = _mobilityContext.places;
    }

    List<Widget> pages = [
      content,
      StopsPage(stops),
      PlacesPage(places),
      MovesPage(moves),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: _navBar(),
    );
  }
}
