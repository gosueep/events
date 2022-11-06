class EventInfo {
  int event;
  String name;
  String description;
  int numberProximity;
  double latitude;
  double longitude;
  DateTime startTime;
  DateTime endTime;
  bool haveRsvp = false;

  EventInfo(
      {required this.event,
      required this.name,
      required this.description,
      required this.numberProximity,
      required this.latitude,
      required this.longitude,
      required this.startTime,
      required this.endTime});
}

class PersonInfo {
  String name;
  double latitude;
  double longitude;

  PersonInfo({
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}
