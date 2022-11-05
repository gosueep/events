import 'dart:io';

import 'package:flutter/material.dart';
//import 'package:EventsApp/views/widgets/recipe_card.dart';
//import 'package:EventsApp/views/widgets/modify_recipe.dart';
//import 'package:EventsApp/views/widgets/modify_ingredients.dart';
import 'package:EventsApp/data/state.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/svg.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final List<AppLifecycleState> stateHistory = <AppLifecycleState>[];
  bool isLoading = true;
  late GoogleMapController mapController;
  final LatLng initialLocation = const LatLng(45.521563, -122.677433);
  Location currentLocation = Location();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    prepareState();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    currentLocation.onLocationChanged.listen((l) {
      //mapController.animateCamera(
      //  CameraUpdate.newCameraPosition(
      //    CameraPosition(
      //        target: LatLng(l.latitude ?? initialLocation.latitude,
      //            l.longitude ?? initialLocation.longitude),
      //        zoom: 15),
      //  ),
      //);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> prepareState() async {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      CurrentState currentState =
          Provider.of<CurrentState>(context, listen: false);
      await currentState.startup();

      PluginAccess pluginAccess =
          Provider.of<PluginAccess>(context, listen: false);
      await pluginAccess.loadCamera();

      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    stateHistory.add(state);
    if (state == AppLifecycleState.inactive) {
      // Remove camera
      PluginAccess pluginAccess =
          Provider.of<PluginAccess>(context, listen: false);
      await pluginAccess.disposeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.restaurant_menu),
            SizedBox(width: 10),
            Text("Events"),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<CurrentState>(
              builder: (context, currentState, child) {
                return Center(
                  child: GoogleMap(
                    initialCameraPosition:
                        CameraPosition(target: initialLocation),
                    mapType: MapType.normal,
                    onMapCreated: _onMapCreated,
                    myLocationEnabled: true,
                  ),
                );
              },
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Consumer<CurrentState>(
        builder: (context, currentState, child) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                FloatingActionButton(
                  heroTag: null,
                  onPressed: () {},
                  tooltip: "Modify store ingredients",
                  child: const Icon(Icons.sell),
                ),
                FloatingActionButton(
                  heroTag: null,
                  onPressed: () {},
                  tooltip: "Add recipe",
                  child: const Icon(Icons.add),
                ),
                SpeedDial(
                  icon: Icons.settings,
                  tooltip: "Settings",
                  heroTag: null,
                  spaceBetweenChildren: 20,
                  children: [
                    SpeedDialChild(
                      onTap: () async {},
                      label: "Load recipes from backup",
                      child: const Icon(Icons.file_open),
                    ),
                    SpeedDialChild(
                      onTap: () async {},
                      label: "Backup all recipes",
                      child: const Icon(Icons.download),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
