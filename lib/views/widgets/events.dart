import 'dart:typed_data';

import 'package:fling_units/fling_units.dart';
import 'package:flutter/material.dart';
import 'package:intl/number_symbols_data.dart';
import 'package:money2/money2.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import 'package:EventsApp/data/state.dart';
import 'package:EventsApp/data/types.dart';
import 'package:intl/intl.dart';

class EventsList extends StatefulWidget {
  EventsList({
    Key? key,
  }) : super(key: key);

  @override
  _EventsListState createState() => _EventsListState();
}

class _EventsListState extends State<EventsList> {
  _EventsListState();

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
            Icon(Icons.signal_wifi_4_bar),
            SizedBox(width: 10),
            Text("Nearby Events"),
          ],
        ),
      ),
      body: Padding(
          padding: const EdgeInsets.all(8.0),
          child:
              Consumer<CurrentState>(builder: (context, currentState, child) {
            return Column(
              children: <Widget>[
                Expanded(
                    child: ListView.builder(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  itemCount: currentState.nearbyEvents().length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                        onTap: () {
                          var event = currentState.nearbyEvents()[index];
                          currentState.zoomToLocation(
                              event.latitude, event.longitude);

                          Navigator.of(context).pop();
                        },
                        child: Column(children: [
                          Container(
                              padding: const EdgeInsets.all(10.0),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).brightness ==
                                          Brightness.light
                                      ? Colors.black
                                      : Colors.white,
                                  style: BorderStyle.solid,
                                  width: 5.0,
                                ),
                                borderRadius: const BorderRadius.all(
                                    Radius.circular(5.0)),
                                //image: DecorationImage(
                                //  image: MemoryImage(currentState.ingredient(index).image),
                                //  fit: BoxFit.cover,
                                //),
                              ),
                              child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      currentState.nearbyEvents()[index].name,
                                      style: TextStyle(
                                        color: Theme.of(context).brightness ==
                                                Brightness.light
                                            ? Colors.black
                                            : Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 45,
                                      ),
                                      textAlign: TextAlign.left,
                                    ),
                                    Text(
                                      currentState
                                          .nearbyEvents()[index]
                                          .description,
                                      style: TextStyle(
                                        color: Theme.of(context).brightness ==
                                                Brightness.light
                                            ? Colors.black
                                            : Colors.white,
                                        fontSize: 25,
                                      ),
                                      textAlign: TextAlign.left,
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.person),
                                        Text(
                                          "${currentState.nearbyEvents()[index].numberProximity}",
                                          style: TextStyle(
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.light
                                                    ? Colors.black
                                                    : Colors.white,
                                            fontSize: 25,
                                          ),
                                          textAlign: TextAlign.left,
                                        )
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time),
                                        Text(
                                          DateFormat("yyyy/MM/dd H:m:s").format(
                                              currentState
                                                  .nearbyEvents()[index]
                                                  .startTime),
                                          style: TextStyle(
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.light
                                                    ? Colors.black
                                                    : Colors.white,
                                            fontSize: 25,
                                          ),
                                          textAlign: TextAlign.left,
                                        )
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time_filled),
                                        Text(
                                          DateFormat("yyyy/MM/dd H:m:s").format(
                                              currentState
                                                  .nearbyEvents()[index]
                                                  .endTime),
                                          style: TextStyle(
                                            color:
                                                Theme.of(context).brightness ==
                                                        Brightness.light
                                                    ? Colors.black
                                                    : Colors.white,
                                            fontSize: 25,
                                          ),
                                          textAlign: TextAlign.left,
                                        )
                                      ],
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          minimumSize:
                                              const Size.fromHeight(60)),
                                      onPressed: () async {
                                        await currentState.sendRsvp(currentState
                                            .nearbyEvents()[index]
                                            .event);
                                      },
                                      child: const Text("RSVP"),
                                    )
                                  ])),
                        ]));
                  },
                )),
                Row(
                  children: [
                    const SizedBox(width: 8.0),
                    Expanded(child: Consumer<CurrentState>(
                        builder: (context, currentState, child) {
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(60)),
                        onPressed: () {
                          // Validate returns true if the form is valid, or false otherwise.
                          Navigator.of(context).pop();
                        },
                        child: const Text("Close"),
                      );
                    }))
                  ],
                ),
              ],
            );
          })),
    );
  }
}
