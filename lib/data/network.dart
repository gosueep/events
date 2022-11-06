import 'dart:convert';
import "dart:async";
import 'dart:ffi';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:flutter/foundation.dart';
import 'package:network_tools/network_tools.dart';
//import 'package:EventsApp/data/types.dart';
import 'package:EventsApp/data/state.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:EventsApp/data/types.dart';

class Server {
  String? serverIp;
  //RecipeDatabase? database;

  // This user's ID
  // All users by default upload recipes, requesting recipes is part of the paid app
  String user = "default";
  String? manufacturer;
  String? model;
  String? deviceVersion;

  double currentLatitude = 0;
  double currentLongitude = 0;

  List<EventInfo> recentEvents = [];
  List<PersonInfo> recentPeople = [];

  Server() {
    //if (kReleaseMode) {
    serverIp = "https://events-app-v3xfr7jk4q-uc.a.run.app";
    //}
  }

  Future<void> startup() async {
    //if (!kReleaseMode && serverIp == null) {
    //  // Scan for local IP of dev server on my LAN
    //  await HostScanner.scanDevicesForSinglePort("10.0.0", 3000, progressCallback: (progress) {
    //    null;
    //  }).listen((host) {
    //    serverIp = "http://${host.address}:3000";
    //  }).asFuture();
    //}
    user = await getDeviceSpecificID();
    await attemptRegisterDevice();
  }

/*
  Future<void> handleUnsynced(List<StoreIngredient> ingredients, List<Recipe> recipes) async {
    // List<Future<void>> metaRequests = [];
    // List<Future<void>> imageRequests = [];

    for (var ingredient in ingredients) {
      if (ingredient.lastSynced == null) {
        await ingredientRequest(ingredient);
        await attemptUploadIngredientImage(ingredient);
      }
    }

    for (var recipe in recipes) {
      if (recipe.lastSynced == null) {
        await recipeRequest(recipe);
        await attemptUploadRecipeImage(recipe);
      }
    }

    //await Future.wait(metaRequests);
    //await Future.wait(imageRequests);
  }
  */

  Future<String> getDeviceSpecificID() async {
    var deviceInfo = DeviceInfoPlugin();
    String? id;
    if (Platform.isIOS) {
      var iosDeviceInfo = await deviceInfo.iosInfo;
      id = iosDeviceInfo.identifierForVendor;
      manufacturer = iosDeviceInfo.identifierForVendor;
      model = iosDeviceInfo.model;
      deviceVersion = iosDeviceInfo.systemVersion;
    } else if (Platform.isAndroid) {
      var androidDeviceInfo = await deviceInfo.androidInfo;
      id = androidDeviceInfo.id;
      manufacturer = androidDeviceInfo.manufacturer;
      model = androidDeviceInfo.model;
      deviceVersion = androidDeviceInfo.version.release;
    }
    return id ?? "default";
  }

  Future<void> attemptRegisterDevice() async {
    if (serverIp != null) {
      var body = jsonEncode(<String, Object>{
        "device_id": user,
        "manufacturer": manufacturer ?? "",
        "model": model ?? "",
        "device_version": deviceVersion ?? "",
        "version": (await PackageInfo.fromPlatform()).version
      });
      var res = await http
          .post(Uri.parse("$serverIp/startup"),
              headers: <String, String>{
                "Content-Type": "application/json",
                "Content-Length": body.codeUnits.length.toString()
              },
              body: body)
          .timeout(const Duration(seconds: 5), onTimeout: () async {
        return http.Response("", 408);
      });

      if (res.statusCode != 202) {
        serverIp = null;
      }
    }
  }

  Future<void> sendLocation(double latitude, double longitude) async {
    currentLatitude = latitude;
    currentLongitude = longitude;
    if (serverIp != null) {
      var body = jsonEncode(<String, Object>{
        "device_id": user,
        "lat": latitude.toString(),
        "long": longitude.toString()
      });
      var res = await http
          .post(Uri.parse("$serverIp/location"),
              headers: <String, String>{
                "Content-Type": "application/json",
                "Content-Length": body.codeUnits.length.toString()
              },
              body: body)
          .timeout(const Duration(seconds: 5), onTimeout: () async {
        return http.Response("", 408);
      });

      if (res.statusCode != 202) {
        serverIp = null;
      }
    }
  }

  Future<void> sendRsvp(int event) async {
    if (serverIp != null) {
      var body = jsonEncode(
          <String, Object>{"device_id": user, "event": event.toString()});
      var res = await http
          .post(Uri.parse("$serverIp/rsvp"),
              headers: <String, String>{
                "Content-Type": "application/json",
                "Content-Length": body.codeUnits.length.toString()
              },
              body: body)
          .timeout(const Duration(seconds: 5), onTimeout: () async {
        return http.Response("", 408);
      });

      if (res.statusCode != 202) {
        serverIp = null;
      }
    }
  }

  Future<void> registerName(String name) async {
    if (serverIp != null) {
      var body = jsonEncode(<String, Object>{"device_id": user, "name": name});
      var res = await http
          .post(Uri.parse("$serverIp/register"),
              headers: <String, String>{
                "Content-Type": "application/json",
                "Content-Length": body.codeUnits.length.toString()
              },
              body: body)
          .timeout(const Duration(seconds: 5), onTimeout: () async {
        return http.Response("", 408);
      });

      if (res.statusCode != 202) {
        serverIp = null;
      }
    }
  }

  Future<void> getCloseEvents(int withinMiles) async {
    if (serverIp != null) {
      var body = jsonEncode(<String, Object>{
        "device_id": user,
        "range": withinMiles.toString(),
        "lat": currentLatitude.toString(),
        "long": currentLongitude.toString()
      });
      var res = await http
          .post(Uri.parse("$serverIp/events"),
              headers: <String, String>{
                "Content-Type": "application/json",
                "Content-Length": body.codeUnits.length.toString()
              },
              body: body)
          .timeout(const Duration(seconds: 5), onTimeout: () async {
        return http.Response("", 408);
      });

      if (res.statusCode != 202) {
        serverIp = null;
      } else {
        var eventInfo = jsonDecode(res.body);

        recentEvents.clear();
        for (var eventMap in eventInfo["events"]) {
          var event = EventInfo(
            event: eventMap["event"] as int,
            name: eventMap["name"] as String,
            description: eventMap["description"] as String,
            numberProximity: eventMap["numberProximity"] as int,
            latitude: eventMap["lat"] as double,
            longitude: eventMap["long"] as double,
            startTime: DateTime.fromMicrosecondsSinceEpoch(
                eventMap["startTime"] as int),
            endTime:
                DateTime.fromMicrosecondsSinceEpoch(eventMap["endTime"] as int),
          );
          recentEvents.add(event);
        }

        recentPeople.clear();
        for (var personMap in eventInfo["people"]) {
          var person = PersonInfo(
            name: personMap["name"] as String,
            latitude: personMap["lat"] as double,
            longitude: personMap["long"] as double,
          );
          recentPeople.add(person);
        }

        return;
      }
    }

    recentEvents.clear();
    recentPeople.clear();
  }

  Future<int> createEvent(String name, String description, double latitude,
      double longitude, DateTime start, DateTime end) async {
    if (serverIp != null) {
      var body = jsonEncode(<String, Object>{
        "device_id": user,
        "name": name,
        "description": description,
        "latitude": latitude.toString(),
        "longitude": longitude.toString(),
        "start_time": start,
        "end_time": end,
      });
      var res = await http
          .post(Uri.parse("$serverIp/create_event"),
              headers: <String, String>{
                "Content-Type": "application/json",
                "Content-Length": body.codeUnits.length.toString()
              },
              body: body)
          .timeout(const Duration(seconds: 5), onTimeout: () async {
        return http.Response("", 408);
      });

      if (res.statusCode != 202) {
        serverIp = null;
      } else {
        return jsonDecode(body)["id"] as int;
      }
    }

    return -1;
  }

/*
  Map<int, Timer> ingredientTimers = {};
  Future<void> attemptCreateUpdateIngredient(StoreIngredient ingredient) async {
    if (serverIp != null && ingredient.id != null) {
      // Batch calls by 1 second
      if (ingredientTimers.containsKey(ingredient.id)) {
        ingredientTimers[ingredient.id]?.cancel();
      }

      ingredientTimers[ingredient.id!] = Timer(const Duration(seconds: 2), () async {
        // If this is some time has passed with no modifications
        await ingredientRequest(ingredient);
        ingredientTimers.remove(ingredient.id);
      });
    } else {
      ingredient.lastSynced = null;
      await database?.syncIngredient(ingredient);
    }
  }

  Future<void> ingredientRequest(StoreIngredient ingredient) async {
    if (serverIp != null) {
      var body = jsonEncode(<String, Object>{
        "name": ingredient.name,
        "volume_type": ingredient.volumeType.toPrettyString(),
        "volume_quantity": ingredient.volumeQuantity,
        "price": ingredient.price,
      });
      var res = await http
          .post(Uri.parse("$serverIp/updates/ingredient"),
              headers: <String, String>{
                "Content-Type": "application/json",
                "Content-Length": body.codeUnits.length.toString(),
                "User": user,
                "Id": ingredient.id.toString(),
              },
              body: body)
          .timeout(const Duration(seconds: 5), onTimeout: () async {
        return http.Response("", 408);
      });

      if (res.statusCode == 202) {
        ingredient.lastSynced = DateTime.now().millisecondsSinceEpoch;
        await database?.syncIngredient(ingredient);
      } else {
        ingredient.lastSynced = null;
        await database?.syncIngredient(ingredient);
        serverIp = null;
      }
    }
  }

  Map<int, Timer> recipeTimers = {};
  Future<void> attemptCreateUpdateRecipe(Recipe recipe) async {
    if (serverIp != null && recipe.id != null) {
      // Batch calls by 1 second
      if (recipeTimers.containsKey(recipe.id)) {
        recipeTimers[recipe.id]?.cancel();
      }

      recipeTimers[recipe.id!] = Timer(const Duration(seconds: 2), () async {
        // If this is called some time has passed with no modifications
        await recipeRequest(recipe);
        recipeTimers.remove(recipe.id);
      });
    } else {
      recipe.lastSynced = null;
      await database?.syncRecipe(recipe);
    }
  }

  Future<void> recipeRequest(Recipe recipe) async {
    if (serverIp != null) {
      var body = jsonEncode(<String, Object>{
        "name": recipe.name,
        "expected_servings": recipe.expectedServings,
        "url": recipe.url,
        "ingredients": recipe.ingredients
            .map((ingredient) => <String, Object>{
                  "id": ingredient.id ?? 0,
                  "volume_type": ingredient.volumeType.toPrettyString(),
                  "volume_quantity": ingredient.volumeQuantity,
                  "store_ingredient": ingredient.storeIngredient?.id ?? 0,
                })
            .toList(),
      });
      var res = await http
          .post(Uri.parse("$serverIp/updates/recipe"),
              headers: <String, String>{
                "Content-Type": "application/json",
                "Content-Length": body.codeUnits.length.toString(),
                "User": user,
                "Id": recipe.id.toString(),
              },
              body: body)
          .timeout(const Duration(seconds: 5), onTimeout: () async {
        return http.Response("", 408);
      });

      if (res.statusCode == 202) {
        recipe.lastSynced = DateTime.now().millisecondsSinceEpoch;
        await database?.syncRecipe(recipe);
      } else {
        recipe.lastSynced = null;
        await database?.syncRecipe(recipe);
        serverIp = null;
      }
    }
  }

  Future<void> attemptDeleteIngredient(StoreIngredient ingredient) async {
    if (serverIp != null) {
      var res = await http
          .post(Uri.parse("$serverIp/updates/ingredient"),
              headers: <String, String>{
                "Content-Type": "application/json",
                "Content-Length": "2",
                "User": user,
                "Id": ingredient.id.toString(),
                "Delete": "1"
              },
              body: "{}")
          .timeout(const Duration(seconds: 5), onTimeout: () async {
        return http.Response("", 408);
      });

      if (res.statusCode != 202) {
        serverIp = null;
      }
    }
  }

  Future<void> attemptDeleteRecipe(Recipe recipe) async {
    if (serverIp != null) {
      var res = await http
          .post(Uri.parse("$serverIp/updates/recipe"),
              headers: <String, String>{
                "Content-Type": "application/json",
                "Content-Length": "2",
                "User": user,
                "Id": recipe.id.toString(),
                "Delete": "1"
              },
              body: "{}")
          .timeout(const Duration(seconds: 5), onTimeout: () async {
        return http.Response("", 408);
      });

      if (res.statusCode != 202) {
        serverIp = null;
      }
    }
  }

  Future<void> attemptUploadIngredientImage(StoreIngredient ingredient) async {
    if (serverIp != null && ingredient.id != null) {
      var res = await http
          .post(
        Uri.parse("$serverIp/updates/image"),
        headers: <String, String>{
          "Content-Type": "image/png",
          "Content-Length": ingredient.image.length.toString(),
          "Image-Type": "ingredient",
          "User": user,
          "Id": ingredient.id.toString()
        },
        body: ingredient.image,
      )
          .timeout(const Duration(seconds: 5), onTimeout: () async {
        return http.Response("", 408);
      });

      if (res.statusCode != 202) {
        ingredient.lastSynced = null;
        await database?.syncIngredient(ingredient);
        serverIp = null;
      }
    } else {
      ingredient.lastSynced = null;
      await database?.syncIngredient(ingredient);
    }
  }

  Future<void> attemptUploadRecipeImage(Recipe recipe) async {
    if (serverIp != null && recipe.id != null) {
      var res = await http
          .post(
        Uri.parse("$serverIp/updates/image"),
        headers: <String, String>{
          "Content-Type": "image/png",
          "Content-Length": recipe.image.length.toString(),
          "Image-Type": "recipe",
          "User": user,
          "Id": recipe.id.toString()
        },
        body: recipe.image,
      )
          .timeout(const Duration(seconds: 5), onTimeout: () async {
        return http.Response("", 408);
      });

      if (res.statusCode != 202) {
        recipe.lastSynced = null;
        await database?.syncRecipe(recipe);
        serverIp = null;
      }
    } else {
      recipe.lastSynced = null;
      await database?.syncRecipe(recipe);
    }
  }
  */
}
