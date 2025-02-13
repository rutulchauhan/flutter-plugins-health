import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:flutter/material.dart';
import 'package:health/health.dart';

void main() => runApp(MaterialApp(home: HealthApp()));

class HealthApp extends StatefulWidget {
  @override
  _HealthAppState createState() => _HealthAppState();
}

enum AppState {
  DATA_NOT_FETCHED,
  FETCHING_DATA,
  DATA_READY,
  NO_DATA,
  AUTH_NOT_GRANTED,
  DATA_ADDED,
  DATA_NOT_ADDED,
  STEPS_READY,
}

class _HealthAppState extends State<HealthApp> {
  AndroidDataSource androidDataSource = AndroidDataSource.HealthConnect;
  List<HealthDataPoint> _healthDataList = [];
  AppState _state = AppState.DATA_NOT_FETCHED;
  int _nofSteps = 10;
  double _mgdl = 10.0;

  // create a HealthFactory for use in the app
  HealthFactory health = HealthFactory();

  /// Fetch data points from the health plugin and show them in the app.
  Future fetchData() async {
    setState(() => _state = AppState.FETCHING_DATA);

    // define the types to get
    final types = [
      HealthDataType.STEPS,
      HealthDataType.WEIGHT,
      HealthDataType.HEIGHT,
      HealthDataType.BLOOD_GLUCOSE,
      // Uncomment this line on iOS - only available on iOS
      // HealthDataType.DISTANCE_WALKING_RUNNING,
    ];

    // with coresponsing permissions
    final permissions = [
      HealthDataAccess.READ,
      HealthDataAccess.READ,
      HealthDataAccess.READ,
      HealthDataAccess.READ,
    ];

    // get data within the last 24 hours
    final now = DateTime.now();
    final yesterday = now.subtract(Duration(days: 1));

    // requesting access to the data types before reading them
    // note that strictly speaking, the [permissions] are not
    // needed, since we only want READ access.
    bool requested =
        await health.requestAuthorization(types, permissions: permissions);

    if (requested) {
      try {
        // fetch health data
        List<HealthDataPoint> healthData =
            await health.getHealthDataFromTypes(yesterday, now, types);

        // save all the new data points (only the first 100)
        _healthDataList.addAll((healthData.length < 100)
            ? healthData
            : healthData.sublist(0, 100));
      } catch (error) {
        print("Exception in getHealthDataFromTypes: $error");
      }

      // filter out duplicates
      _healthDataList = HealthFactory.removeDuplicates(_healthDataList);

      // print the results
      _healthDataList.forEach((x) => print(x));

      // update the UI to display the results
      setState(() {
        _state =
            _healthDataList.isEmpty ? AppState.NO_DATA : AppState.DATA_READY;
      });
    } else {
      print("Authorization not granted");
      setState(() => _state = AppState.DATA_NOT_FETCHED);
    }
  }

  /// Add some random health data.
  /*Future addData() async {
    final now = DateTime.now();
    final earlier = now.subtract(Duration(minutes: 5));

    _nofSteps = Random().nextInt(10);
    final types = [HealthDataType.STEPS, HealthDataType.BLOOD_GLUCOSE];
    final rights = [HealthDataAccess.WRITE, HealthDataAccess.WRITE];

    final typesHealthConnect = [
      HealthDataType.BODYFAT,
      HealthDataType.NUTRITION,
      HealthDataType.WEIGHT
    ];

    final rightsHealthConnect = [
      HealthDataAccess.WRITE,
      HealthDataAccess.WRITE,
      HealthDataAccess.WRITE,
    ];

    final permissions = [
      HealthDataAccess.READ_WRITE,
      HealthDataAccess.READ_WRITE
    ];

    bool? hasPermissions = await HealthFactory.hasPermissions(
        isDataFromHealthConnect ? typesHealthConnect : types,
        isDataFromHealthConnect,
        permissions: isDataFromHealthConnect ? rightsHealthConnect : rights);
    if (hasPermissions == null) {
      print("Health Connect not installed ");
    }
    if (hasPermissions == false && !isDataFromHealthConnect) {
      await health.requestAuthorization(types, permissions: permissions);
    }

    if (!isDataFromHealthConnect) {
      _mgdl = Random().nextInt(10) * 1.0;
      bool success = await health.writeHealthData(
          isDataFromHealthConnect, HealthDataType.STEPS,
          value: _nofSteps.toDouble(), startTime: earlier, endTime: now);

      if (success) {
        success = await health.writeHealthData(
            isDataFromHealthConnect, HealthDataType.BLOOD_GLUCOSE,
            value: _mgdl, startTime: now, endTime: now);
      }

      setState(() {
        _state = success ? AppState.DATA_ADDED : AppState.DATA_NOT_ADDED;
      });
    } else {
      bool success = await health.writeHealthData(
          isDataFromHealthConnect, HealthDataType.WEIGHT,
          value: 100.toDouble(), currentTime: now);

      Fluttertoast.showToast(
          msg: success ? "Data Added" : "Something went wrong",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
      */ /*setState(() {
        _state = success ? AppState.DATA_ADDED : AppState.DATA_NOT_ADDED;
      });*/ /*
    }
  }*/

  Future addWeightDataToHealthConnect() async {
    final now = DateTime.now();
    bool success = await health.writeHCData(HealthDataType.WEIGHT,
        value: 82.toDouble(), currentTime: now);

    Fluttertoast.showToast(
        msg: success ? "Data Added" : "Something went wrong",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);
    if (success) {
      await Future.delayed(Duration(milliseconds: 700));
      readWeightDataFromHealthConnect();
    }
  }

  List<HealthConnectWeight> healthWeight = [];

  Future readWeightDataFromHealthConnect() async {
    var type = HealthDataType.WEIGHT;
    final startTime = DateTime.now().subtract(Duration(minutes: 100));
    final endTime = DateTime.now();
    List<HealthConnectData> success =
        await health.getHCData(startTime, endTime, type);
    healthWeight = [];
    healthWeight = success.cast<HealthConnectWeight>();
    setState(() {});
  }

  Future deleteWeightDataFromHealthConnect(String uID) async {
    var type = HealthDataType.WEIGHT;

    bool success = await health.deleteHCData(type, uID);
    if (success) {
      healthWeight.removeWhere((element) => element.uID == uID);
      setState(() {});
    }
  }

  Future deleteHealthDataByDateRange(
      HealthDataType type, DateTime startTime, DateTime endTime) async {
    bool success =
        await health.deleteHCDataByDateRange(type, startTime, endTime);
    if (success) {
      if (type == HealthDataType.WEIGHT) {
        healthWeight.clear();
      } else if (type == HealthDataType.BODY_FAT_PERCENTAGE) {
        healthBodyFat.clear();
      } else if (type == HealthDataType.NUTRITION) {
        healthNutrition.clear();
      }
      setState(() {});
    }
  }

  Future addBodyFatDataToHealthConnect() async {
    final now = DateTime.now();
    bool success = await health.writeHCData(HealthDataType.BODY_FAT_PERCENTAGE,
        value: 22.toDouble(), currentTime: now);

    Fluttertoast.showToast(
        msg: success ? "Data Added" : "Something went wrong",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);
    if (success) {
      await Future.delayed(Duration(milliseconds: 700));
      readBodyFatDataFromHealthConnect();
    }
  }

  List<HealthConnectBodyFat> healthBodyFat = [];

  Future readBodyFatDataFromHealthConnect() async {
    var type = HealthDataType.BODY_FAT_PERCENTAGE;
    final startTime = DateTime.now().subtract(Duration(minutes: 100));
    final endTime = DateTime.now();
    List<HealthConnectData> success =
        await health.getHCData(startTime, endTime, type);
    healthBodyFat = [];
    healthBodyFat = success.cast<HealthConnectBodyFat>();
    setState(() {});
  }

  Future deleteBodyDataFromHealthConnect(String uID) async {
    var type = HealthDataType.BODY_FAT_PERCENTAGE;

    bool success = await health.deleteHCData(type, uID);
    if (success) {
      healthBodyFat.removeWhere((element) => element.uID == uID);
      setState(() {});
    }
  }

  Future addNutritionDataToHealthConnect() async {
    final startTime = DateTime.now().subtract(Duration(minutes: 30));
    final endTime = DateTime.now();
    bool success = await health.writeHCNutrition(
        isOverWrite: true,
        startTime: DateTime.now().subtract(
          Duration(hours: 3),
        ),
        endTime: DateTime.now(),
        listNutrition: [
          HealthConnectNutrition(startTime, endTime,
              name: "Pixelapps BreakFast",
              mealType: MealType.BREAKFAST,
              biotin: Mass(0.07, type: Type.KILOGRAMS),
              energy: Energy(1000, type: EType.CALORIES)),
          HealthConnectNutrition(startTime, endTime,
              name: "Pixelapps BreakFast",
              mealType: MealType.BREAKFAST,
              biotin: Mass(0.08, type: Type.KILOGRAMS),
              energy: Energy(100, type: EType.CALORIES)),
        ]);

    Fluttertoast.showToast(
        msg: success ? "Data Added" : "Something went wrong",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);
    if (success) {
      await Future.delayed(Duration(milliseconds: 700));
      readNutritionDataFromHealthConnect();
    }
  }

  List<HealthConnectNutrition> healthNutrition = [];

  Future readNutritionDataFromHealthConnect() async {
    var type = HealthDataType.NUTRITION;
    final startTime = DateTime.now().subtract(Duration(minutes: 700));
    final endTime = DateTime.now();
    List<HealthConnectData> success =
        await health.getHCData(startTime, endTime, type);
    healthNutrition = [];
    healthNutrition = success.cast<HealthConnectNutrition>();
    setState(() {});
  }

  Future deleteNutritionDataFromHealthConnect(String uID) async {
    var type = HealthDataType.NUTRITION;

    bool success = await health.deleteHCData(type, uID);
    if (success) {
      healthNutrition.removeWhere((element) => element.uID == uID);
      setState(() {});
    }
  }

  /// Fetch steps from the health plugin and show them in the app.
  Future fetchStepData() async {
    int? steps;

    // get steps for today (i.e., since midnight)
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);

    bool requested = await health.requestAuthorization([HealthDataType.STEPS]);

    if (requested) {
      try {
        steps = await health.getTotalStepsInInterval(midnight, now);
      } catch (error) {
        print("Caught exception in getTotalStepsInInterval: $error");
      }

      print('Total number of steps: $steps');

      setState(() {
        _nofSteps = (steps == null) ? 0 : steps;
        _state = (steps == null) ? AppState.NO_DATA : AppState.STEPS_READY;
      });
    } else {
      print("Authorization not granted");
      setState(() => _state = AppState.DATA_NOT_FETCHED);
    }
  }

  Widget _contentFetchingData() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Container(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(
              strokeWidth: 10,
            )),
        Text('Fetching data...')
      ],
    );
  }

  Widget _contentDataReady() {
    return ListView.builder(
        itemCount: _healthDataList.length,
        itemBuilder: (_, index) {
          HealthDataPoint p = _healthDataList[index];
          return ListTile(
            title: Text("${p.typeString}: ${p.value}"),
            trailing: Text('${p.unitString}'),
            subtitle: Text('${p.dateFrom} - ${p.dateTo}'),
          );
        });
  }

  Widget _contentNoData() {
    return Text('No Data to show');
  }

  Widget _contentNotFetched() {
    return Column(
      children: [
        Text('Press the download button to fetch data.'),
        Text('Press the plus button to insert some random data.'),
        Text('Press the walking button to get total step count.'),
      ],
      mainAxisAlignment: MainAxisAlignment.center,
    );
  }

  Widget _authorizationNotGranted() {
    return Text('Authorization not given. '
        'For Android please check your OAUTH2 client ID is correct in Google Developer Console. '
        'For iOS check your permissions in Apple Health.');
  }

  Widget _dataAdded() {
    return Text('$_nofSteps steps and $_mgdl mgdl are inserted successfully!');
  }

  Widget _stepsFetched() {
    return Text('Total number of steps: $_nofSteps');
  }

  Widget _dataNotAdded() {
    return Text('Failed to add data');
  }

  Widget _content() {
    if (_state == AppState.DATA_READY)
      return _contentDataReady();
    else if (_state == AppState.NO_DATA)
      return _contentNoData();
    else if (_state == AppState.FETCHING_DATA)
      return _contentFetchingData();
    else if (_state == AppState.AUTH_NOT_GRANTED)
      return _authorizationNotGranted();
    else if (_state == AppState.DATA_ADDED)
      return _dataAdded();
    else if (_state == AppState.STEPS_READY)
      return _stepsFetched();
    else if (_state == AppState.DATA_NOT_ADDED) return _dataNotAdded();

    return _contentNotFetched();
  }

  requestHealthConnectPermission() async {
    // define the types to get
    final types = [
      HealthDataType.WEIGHT,
      HealthDataType.BODY_FAT_PERCENTAGE,
      HealthDataType.NUTRITION,
      HealthDataType.WEIGHT,
      HealthDataType.BODY_FAT_PERCENTAGE,
      HealthDataType.NUTRITION,
    ];

    // with coresponsing permissions
    final permissions = [
      HealthDataAccess.READ,
      HealthDataAccess.READ,
      HealthDataAccess.READ,
      HealthDataAccess.WRITE,
      HealthDataAccess.WRITE,
      HealthDataAccess.WRITE,
    ];
    bool requested =
        await health.requestHCPermissions(types, permissions: permissions);
    Fluttertoast.showToast(msg: "Access Already Granted $requested");
    return requested;
  }

  hasHealthConnectPermission() async {
    // define the types to get
    final types = [
      HealthDataType.WEIGHT,
      HealthDataType.BODY_FAT_PERCENTAGE,
      HealthDataType.NUTRITION,
      HealthDataType.WEIGHT,
      HealthDataType.BODY_FAT_PERCENTAGE,
      HealthDataType.NUTRITION,
    ];

    // with coresponsing permissions
    final permissions = [
      HealthDataAccess.READ,
      HealthDataAccess.READ,
      HealthDataAccess.READ,
      HealthDataAccess.WRITE,
      HealthDataAccess.WRITE,
      HealthDataAccess.WRITE,
    ];

    bool hasPermission =
        await health.hasHCPermissions(types, permissions: permissions);
    if (hasPermission) {
      Fluttertoast.showToast(msg: "Access Already Granted");
    } else {
      Fluttertoast.showToast(
          msg: "Permission not granted. Please ask for permission");
    }
    return hasPermission;
  }

  checkAvailability() async {
    bool isAvailable = await health.isHealthConnectAvailable();
    if (isAvailable) {
      Fluttertoast.showToast(msg: "Health Connect is Available");
    } else {
      Fluttertoast.showToast(msg: "Health Connect is Not Available");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Health'),
            actions: <Widget>[
              /*IconButton(
                icon: Icon(Icons.file_download),
                onPressed: () {
                  fetchData();
                },
              ),
              IconButton(
                onPressed: () {
                  addData();
                },
                icon: Icon(Icons.add),
              ),
              IconButton(
                onPressed: () {
                  fetchStepData();
                },
                icon: Icon(Icons.nordic_walking),
              )*/
            ],
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    ElevatedButton(
                        onPressed: () {
                          if (androidDataSource ==
                              AndroidDataSource.HealthConnect) {
                            checkAvailability();
                            return;
                          }
                          Fluttertoast.showToast(
                              msg:
                                  "Please mark bottom checkbox for Health Connect data");
                        },
                        child: Text("Check HealthConnect Availability")),
                    ElevatedButton(
                        onPressed: () {
                          if (androidDataSource ==
                              AndroidDataSource.HealthConnect) {
                            hasHealthConnectPermission();
                            return;
                          }
                          Fluttertoast.showToast(
                              msg:
                                  "Please mark bottom checkbox for Health Connect data");
                        },
                        child: Text("Has Permission???")),
                    ElevatedButton(
                        onPressed: () {
                          if (androidDataSource ==
                              AndroidDataSource.HealthConnect) {
                            requestHealthConnectPermission();
                            return;
                          }
                          Fluttertoast.showToast(
                              msg:
                                  "Please mark bottom checkbox for Health Connect data");
                        },
                        child: Text("Request Permission")),
                    ElevatedButton(
                        onPressed: () {
                          if (androidDataSource ==
                              AndroidDataSource.HealthConnect) {
                            addWeightDataToHealthConnect();
                            return;
                          }
                          Fluttertoast.showToast(
                              msg:
                                  "Please mark bottom checkbox for Health Connect data");
                        },
                        child: Text("Weight add to Health Connect")),
                    ElevatedButton(
                        onPressed: () {
                          readWeightDataFromHealthConnect();
                        },
                        child: Text("Read Weight from Health Connect")),
                    ListView.builder(
                        itemCount: healthWeight.length,
                        shrinkWrap: true,
                        itemBuilder: (_, index) {
                          HealthConnectWeight data = healthWeight[index];
                          return ListTile(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text(
                                        "Are you sure you want delete entry?"),
                                    actions: [
                                      TextButton(
                                        child: Text("Delete"),
                                        onPressed: () {
                                          Navigator.of(context)
                                              .pop(); // dismiss dialog
                                          deleteWeightDataFromHealthConnect(
                                              data.uID);
                                        },
                                      ),
                                      TextButton(
                                        child: Text("Cancel"),
                                        onPressed: () {
                                          Navigator.of(context)
                                              .pop(); // dismiss dialog
                                        },
                                      )
                                    ],
                                  );
                                },
                              );
                            },
                            title:
                                Text("Weight: ${data.weight.getInKilograms}"),
                            subtitle: Text(
                                'DateTime ${data.zonedDateTime}\nuID ${data.uID}'),
                          );
                        }),
                    ElevatedButton(
                        onPressed: () {
                          if (androidDataSource ==
                              AndroidDataSource.HealthConnect) {
                            addBodyFatDataToHealthConnect();
                            return;
                          }
                          Fluttertoast.showToast(
                              msg:
                                  "Please mark bottom checkbox for Health Connect data");
                        },
                        child: Text("BodyFat add to Health Connect")),
                    ElevatedButton(
                        onPressed: () {
                          if (androidDataSource ==
                              AndroidDataSource.HealthConnect) {
                            readBodyFatDataFromHealthConnect();
                            return;
                          }
                          Fluttertoast.showToast(
                              msg:
                                  "Please mark bottom checkbox for Health Connect data");
                        },
                        child: Text("Read BodyFat from Health Connect")),
                    ListView.builder(
                        itemCount: healthBodyFat.length,
                        shrinkWrap: true,
                        itemBuilder: (_, index) {
                          HealthConnectBodyFat data = healthBodyFat[index];
                          return ListTile(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text(
                                        "Are you sure you want delete entry?"),
                                    actions: [
                                      TextButton(
                                        child: Text("Delete"),
                                        onPressed: () {
                                          Navigator.of(context)
                                              .pop(); // dismiss dialog
                                          deleteBodyDataFromHealthConnect(
                                              data.uID);
                                        },
                                      ),
                                      TextButton(
                                        child: Text("Cancel"),
                                        onPressed: () {
                                          Navigator.of(context)
                                              .pop(); // dismiss dialog
                                        },
                                      )
                                    ],
                                  );
                                },
                              );
                            },
                            title: Text("BodyFat: ${data.bodyFat}%"),
                            subtitle: Text(
                                'DateTime ${data.zonedDateTime}\nuID ${data.uID}'),
                          );
                        }),
                    ElevatedButton(
                        onPressed: () {
                          if (androidDataSource ==
                              AndroidDataSource.HealthConnect) {
                            addNutritionDataToHealthConnect();
                            return;
                          }
                          Fluttertoast.showToast(
                              msg:
                                  "Please mark bottom checkbox for Health Connect data");
                        },
                        child: Text("Nutrition add to Health Connect")),
                    ElevatedButton(
                        onPressed: () {
                          if (androidDataSource ==
                              AndroidDataSource.HealthConnect) {
                            readNutritionDataFromHealthConnect();
                            return;
                          }
                          Fluttertoast.showToast(
                              msg:
                                  "Please mark bottom checkbox for Health Connect data");
                        },
                        child: Text("Read Nutrition from Health Connect")),
                    ListView.builder(
                        itemCount: healthNutrition.length,
                        shrinkWrap: true,
                        itemBuilder: (_, index) {
                          HealthConnectNutrition data = healthNutrition[index];
                          return ListTile(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text(
                                        "Are you sure you want delete entry?"),
                                    actions: [
                                      TextButton(
                                        child: Text("Delete"),
                                        onPressed: () {
                                          Navigator.of(context)
                                              .pop(); // dismiss dialog
                                          deleteNutritionDataFromHealthConnect(
                                              data.uID ?? "");
                                        },
                                      ),
                                      TextButton(
                                        child: Text("Cancel"),
                                        onPressed: () {
                                          Navigator.of(context)
                                              .pop(); // dismiss dialog
                                        },
                                      )
                                    ],
                                  );
                                },
                              );
                            },
                            title: Text(
                                "Name: ${data.name} MealType: ${getMealTypeAsString(data.mealType ?? MealType.UNKNOWN)}"),
                            subtitle: Text(
                                'Energy: ${data.energy?.getInKilocalories} DateTime ${data.startTime} - ${data.endTime}\nuID ${data.uID}\nbiotin : ${data.biotin?.getInGram} gram'),
                          );
                        }),
                    ElevatedButton(
                        onPressed: () {
                          if (androidDataSource ==
                              AndroidDataSource.HealthConnect) {
                            deleteHealthDataByDateRange(
                                HealthDataType.WEIGHT,
                                DateTime.now().subtract(Duration(hours: 5)),
                                DateTime.now());
                            return;
                          }
                          Fluttertoast.showToast(
                              msg:
                                  "Please mark bottom checkbox for Health Connect data");
                        },
                        child: Text(
                          "Delete Weight Data from\nHealth Connect using date range",
                          textAlign: TextAlign.center,
                        )),
                    ElevatedButton(
                        onPressed: () {
                          if (androidDataSource ==
                              AndroidDataSource.HealthConnect) {
                            deleteHealthDataByDateRange(
                                HealthDataType.BODY_FAT_PERCENTAGE,
                                DateTime.now().subtract(Duration(hours: 5)),
                                DateTime.now());
                            return;
                          }
                          Fluttertoast.showToast(
                              msg:
                                  "Please mark bottom checkbox for Health Connect data");
                        },
                        child: Text(
                          "Delete BodyFat Data from\nHealth Connect using date range",
                          textAlign: TextAlign.center,
                        )),
                    ElevatedButton(
                        onPressed: () {
                          if (androidDataSource ==
                              AndroidDataSource.HealthConnect) {
                            deleteHealthDataByDateRange(
                                HealthDataType.NUTRITION,
                                DateTime.now().subtract(Duration(hours: 5)),
                                DateTime.now());
                            return;
                          }
                          Fluttertoast.showToast(
                              msg:
                                  "Please mark bottom checkbox for Health Connect data");
                        },
                        child: Text(
                          "Delete Nutrition Data from\nHealth Connect using date range",
                          textAlign: TextAlign.center,
                        )),
                    const SizedBox(
                      height: 100,
                    )
                  ],
                ),
              ),
              Platform.isAndroid
                  ? Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.white,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Android Data from Health Connect"),
                            Checkbox(
                                value: androidDataSource ==
                                        AndroidDataSource.HealthConnect
                                    ? true
                                    : false,
                                onChanged: (value) {
                                  if (value ?? false) {
                                    androidDataSource =
                                        AndroidDataSource.HealthConnect;
                                  } else {
                                    androidDataSource =
                                        AndroidDataSource.GoogleFit;
                                  }
                                  setState(() {});
                                }),
                          ],
                        ),
                      ),
                    )
                  : Container()
            ],
          )),
    );
  }
}
