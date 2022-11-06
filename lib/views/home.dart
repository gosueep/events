import 'dart:io';
import 'dart:convert';
import "dart:async";

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
import 'package:EventsApp/views/widgets/events.dart';
import 'package:geolocator/geolocator.dart';
import 'package:EventsApp/views/widgets/create_event.dart';
import 'package:EventsApp/views/widgets/change_name.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final List<AppLifecycleState> stateHistory = <AppLifecycleState>[];
  bool isLoading = true;
  LatLng initialLocation = const LatLng(0, 0);
  Location currentLocation = Location();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    prepareState();
  }

  void _onMapCreated(GoogleMapController controller) {
    CurrentState currentState =
        Provider.of<CurrentState>(context, listen: false);
    currentState.setMapController(controller);
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

  //Timer? cameraMoveTimer;
  void _onCameraMove(CameraPosition position) async {
    //if (cameraMoveTimer != null) {
    //  cameraMoveTimer?.cancel();
    //}

    //cameraMoveTimer = Timer(const Duration(milliseconds: 10), () async {
    CurrentState currentState =
        Provider.of<CurrentState>(context, listen: false);
    //var center =
    //    await currentState.mapController.getScreenCoordinate(position.target);
//
    //await currentState.sendCameraPosition(center.y.toDouble(),
    //    center.x.toDouble(), position.zoom, position.bearing);

    var topLeft = await currentState.mapController
        .getLatLng(const ScreenCoordinate(x: 0, y: 0));

    //await currentState.sendCameraPosition(
    //    position.target.latitude - topLeft.latitude,
    //    position.target.longitude - topLeft.longitude,
    //    position.zoom,
    //    position.bearing);
    await currentState.sendCameraPosition(
        topLeft.latitude, topLeft.longitude, position.zoom, position.bearing);
    // LAAAAAAGY
    //await currentState.reloadNearbyEvents();
    //});
  }

  void _onMapLongPress(LatLng location) {
    Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => CreateEventForm(
        latitude: location.latitude,
        longitude: location.longitude,
      ),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    ));
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

      //PluginAccess pluginAccess =
      //    Provider.of<PluginAccess>(context, listen: false);
      //await pluginAccess.loadCamera();

      var location = await Geolocator.getCurrentPosition();
      initialLocation = LatLng(location.latitude, location.longitude);
      await currentState.sendCameraPosition(
          location.latitude, location.longitude, 18.0, 0.0);
      await currentState.reloadNearbyEvents();

      Future.delayed(const Duration(milliseconds: 250), () {
        setState(() {
          isLoading = false;
        });
      });
    });
  }

  Future<void> getNearby() async {
    var location = await Geolocator.getCurrentPosition();
    //initialLocation = LatLng(location.latitude, location.longitude);
    CurrentState currentState =
        Provider.of<CurrentState>(context, listen: false);
    currentState.sendLocation(location.latitude, location.longitude);
    currentState.reloadNearbyEvents();

    Future.delayed(const Duration(milliseconds: 1000), () {
      getNearby();
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
            Icon(Icons.signal_wifi_4_bar),
            SizedBox(width: 10),
            Text("Events"),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<CurrentState>(
              builder: (context, currentState, child) {
                return Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: initialLocation,
                        zoom: 18,
                      ),
                      mapType: MapType.normal,
                      onMapCreated: _onMapCreated,
                      onCameraMove: _onCameraMove,
                      onLongPress: _onMapLongPress,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      rotateGesturesEnabled: false, // TODO
                    ),
                    LayoutBuilder(builder: (context, constraints) {
                      return IgnorePointer(
                        child: SizedBox(
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          child: Texture(
                            textureId: currentState.texture,
                            filterQuality: FilterQuality.none,
                          ),
                        ),
                      );
                    }),
                  ],
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
                  onPressed: () async {
                    await currentState.reloadNearbyEvents();
                    Navigator.of(context).push(PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          EventsList(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        const begin = Offset(1.0, 0.0);
                        const end = Offset.zero;
                        const curve = Curves.ease;

                        var tween = Tween(begin: begin, end: end)
                            .chain(CurveTween(curve: curve));

                        return SlideTransition(
                          position: animation.drive(tween),
                          child: child,
                        );
                      },
                    ));
                  },
                  tooltip: "View events nearby",
                  child: const Icon(Icons.signal_wifi_4_bar),
                ),
                SpeedDial(
                  icon: Icons.settings,
                  tooltip: "Settings",
                  heroTag: null,
                  spaceBetweenChildren: 20,
                  children: [
                    SpeedDialChild(
                      onTap: () async {
                        Navigator.of(context).push(PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  ChangeNameForm(),
                          transitionsBuilder:
                              (context, animation, secondaryAnimation, child) {
                            const begin = Offset(1.0, 0.0);
                            const end = Offset.zero;
                            const curve = Curves.ease;

                            var tween = Tween(begin: begin, end: end)
                                .chain(CurveTween(curve: curve));

                            return SlideTransition(
                              position: animation.drive(tween),
                              child: child,
                            );
                          },
                        ));
                      },
                      label: "Change Name",
                      child: const Icon(Icons.person),
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
