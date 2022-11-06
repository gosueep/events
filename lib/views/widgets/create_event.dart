import 'dart:typed_data';

import 'package:fling_units/fling_units.dart';
import 'package:flutter/material.dart';
import 'package:intl/number_symbols_data.dart';
import 'package:money2/money2.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import 'package:EventsApp/data/state.dart';
import 'package:EventsApp/data/types.dart';

class CreateEventForm extends StatefulWidget {
  double latitude;
  double longitude;

  CreateEventForm({
    Key? key,
    required this.latitude,
    required this.longitude,
  }) : super(key: key);

  @override
  _CreateEventFormState createState() =>
      _CreateEventFormState(latitude: latitude, longitude: longitude);
}

class _CreateEventFormState extends State<CreateEventForm> {
  final GlobalKey<FormState> formKey = GlobalKey();

  String name = "default";
  String description = "";
  double latitude;
  double longitude;

  _CreateEventFormState({
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add),
            SizedBox(width: 10),
            Text("Create Event"),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Form(
            key: formKey,
            child:
                Consumer<CurrentState>(builder: (context, currentState, child) {
              return Column(
                children: <Widget>[
                  TextFormField(
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      labelText: "Name",
                      labelStyle: TextStyle(
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? Colors.black
                                  : Colors.white),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? Colors.black
                                    : Colors.white,
                            width: 3.0),
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? Colors.black
                                    : Colors.white,
                            width: 3.0),
                      ),
                    ),
                    style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.black
                            : Colors.white),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Cannot be empty";
                      }
                      return null;
                    },
                    onFieldSubmitted: (value) {
                      name = value;
                    },
                    onChanged: (value) {
                      name = value;
                    },
                  ),
                  const SizedBox(
                    height: 8.0,
                  ),
                  TextFormField(
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      labelText: "Decoration",
                      labelStyle: TextStyle(
                          color:
                              Theme.of(context).brightness == Brightness.light
                                  ? Colors.black
                                  : Colors.white),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? Colors.black
                                    : Colors.white,
                            width: 3.0),
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? Colors.black
                                    : Colors.white,
                            width: 3.0),
                      ),
                    ),
                    style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.light
                            ? Colors.black
                            : Colors.white),
                    onFieldSubmitted: (value) {
                      description = value;
                    },
                    onChanged: (value) {
                      description = value;
                    },
                  ),
                  const SizedBox(
                    height: 8.0,
                  ),
                  Row(
                    children: [
                      Expanded(
                          child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(60)),
                        onPressed: () {
                          // Pop without sending
                          Navigator.of(context).pop();
                        },
                        child: const Text("Close"),
                      )),
                      const SizedBox(width: 8.0),
                      Expanded(
                          child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(60)),
                        onPressed: () {
                          currentState.sendCreateEvent(
                              name, description, latitude, longitude);
                          Navigator.of(context).pop();
                        },
                        child: const Text("Create Event"),
                      ))
                    ],
                  ),
                ],
              );
            })),
      ),
    );
  }
}
