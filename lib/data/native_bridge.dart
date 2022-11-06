import 'dart:ffi';

import 'package:flutter/services.dart';
import 'package:EventsApp/data/types.dart';

// https://www.evertop.pl/en/mediastore-in-flutter/
// Allows for downloads
class NativeBridge {
  static const _channel = MethodChannel("flutter_native_bridge");

  Future<void> addItem(String file, String name, String mime) async {
    await _channel.invokeMethod(
        "addDownload", {"path": file, "name": name, "mime": mime});
  }

  Future<int> createTexture() async {
    return await _channel.invokeMethod("createTexture");
  }

  Future<bool> sendRecent(
      List<EventInfo> eventInfo, List<PersonInfo> personInfo) async {
    return await _channel.invokeMethod(
      "sendRecent",
      {
        "events": eventInfo.map((event) {
          return {
            "event": event.event,
            "name": event.name,
            "description": event.description,
            "numberProximity": event.numberProximity,
            "latitude": event.latitude,
            "longitude": event.longitude,
          };
        }).toList(),
        "people": personInfo.map((person) {
          return {
            "name": person.name,
            "latitude": person.latitude,
            "longitude": person.longitude
          };
        }).toList()
      },
    );
  }

  Future<bool> sendCameraPosition(
      double latitude, double longitude, double zoom, double tilt) async {
    return await _channel.invokeMethod("sendCameraPosition", {
      "latitude": latitude,
      "longitude": longitude,
      "zoom": zoom,
      "tilt": tilt
    });
  }
}
