import 'package:dio/dio.dart';

class DistanceCalculator {
  double distanceInMiles;
  String travelTime;

  DistanceCalculator._(this.travelTime, this.distanceInMiles);

  static Future<DistanceCalculator> getDistance(double fromLat, double fromLong,
      double toLat, double toLong, String apiKey) async {
    String url =
        "https://maps.googleapis.com/maps/api/distancematrix/json?units=imperial&origins=$fromLat,$fromLong&destinations=$toLat,$toLong&key=$apiKey";
    Dio dio = new Dio();
    Response response = await dio.get(url);

    if (response.statusCode == 200) {
      Map<String, dynamic> map = response.data; //json.decode(response.data);
      List distances = map['rows'].first['elements'];
      double totalDistance = 0;
      String travelTime;
      for (var distance in distances) {
        String distanceString = distance['distance']['text'];
        travelTime = distance['duration']['text'];
        totalDistance += double.parse(distanceString.split(' ').first);
      }
      return DistanceCalculator._(travelTime, totalDistance);
    }
    return null;
  }
}
