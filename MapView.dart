import 'package:flutter/material.dart';
import 'package:flutter_app_acasa/widgets/toasts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'dart:math' show cos, sqrt, asin;

class MapView extends StatefulWidget {
  double startLat,startLong,endLat,endLong;
  var apiKey;
  var directionsApiKey;
  String _distanceBetweenLocations = "0.0";
  String getDistance() => _distanceBetweenLocations;

  MapView({@required this.startLat,@required this.startLong, @required this.endLat,@required this.endLong, @required this.apiKey,@required this.directionsApiKey});

  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  // Initial location of the Map view
  CameraPosition _initialLocation = CameraPosition(target: LatLng(0.0, 0.0));
  Position startCoordinates;
  Position destinationCoordinates;

  // For controlling the view of the Map
  GoogleMapController mapController;
  // final Geolocator _geolocator = Geolocator();
  // For storing the current position
  Position _currentPosition;

  Set<Marker> markers = {};
// Object for PolylinePoints
  PolylinePoints polylinePoints;

// List of coordinates to join
  List<LatLng> polylineCoordinates = [];

// Map storing polylines created by connecting
// two points
  Map<PolylineId, Polyline> polylines = {};

  double _placeDistance = 0.0;
  @override
  void dispose() {
    super.dispose();
    polylines = _currentPosition = destinationCoordinates =startCoordinates = markers = widget.startLong = widget.startLat = widget.endLong = widget.endLat = null;
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    startCoordinates = Position(latitude: widget.startLat, longitude: widget.startLong);
    destinationCoordinates = Position(latitude: widget.endLat, longitude: widget.endLong);
    // Start Location Marker
    Marker startMarker = Marker(
      markerId: MarkerId('$startCoordinates'),
      position: LatLng(
        startCoordinates.latitude,
        startCoordinates.longitude,
      ),
      infoWindow: InfoWindow(
        title: 'Start',
        snippet: "starting location",
      ),
      icon: BitmapDescriptor.defaultMarker,
    );

// Destination Location Marker
    Marker destinationMarker = Marker(
      markerId: MarkerId('$destinationCoordinates'),
      position: LatLng(
        destinationCoordinates.latitude,
        destinationCoordinates.longitude,
      ),
      infoWindow: InfoWindow(
        title: 'Destination',
        snippet: "destination location",
      ),
      icon: BitmapDescriptor.defaultMarker,
    );
    // Add the markers to the list
    markers.add(startMarker);
    markers.add(destinationMarker);

    _createPolylines(startCoordinates, destinationCoordinates);


  }


  @override
  Widget build(BuildContext context) {
    return Container(
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            GoogleMap(
              initialCameraPosition: _initialLocation,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapType: MapType.normal,
              zoomGesturesEnabled: true,
              markers: markers != null ? Set<Marker>.from(markers) : null,
              zoomControlsEnabled: false,
              polylines: Set<Polyline>.of(polylines.values),
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
            ),

            // Design for current location button

            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ClipOval(
                      child: Material(
                        color: Colors.blueGrey, // button color
                        child: InkWell(
                          splashColor: Colors.red, // inkwell color
                          child: SizedBox(
                            width: 25,
                            height: 25,
                            child: Icon(Icons.my_location,color: Colors.white,),
                          ),
                          onTap: () {
                            // on button tap
                            _getCurrentLocation();
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 10,),

                    GestureDetector(
                      onTap: (){
                        zoomIn();
                      },
                      child: Container(
                        color: Colors.white,
                        child: Icon(Icons.zoom_in),
                      ),
                    ),
                    // SizedBox(height: 10,),
                    GestureDetector(
                      onTap: (){
                        zoomOut();
                      },
                      child: Container(
                        color: Colors.white,
                        child: Icon(Icons.zoom_out),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

  }
  zoomIn(){
    // Zoom In action
    mapController.animateCamera(
      CameraUpdate.zoomIn(),
    );
  }
  zoomOut(){
    // Zoom Out action
    mapController.animateCamera(
      CameraUpdate.zoomOut(),
    );
  }
  moveToNewPosition(_currentPosition){
    // Move camera to the specified latitude & longitude
    mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            // Will be fetching in the next step
            _currentPosition.latitude,
            _currentPosition.longitude,
          ),
          zoom: 18.0,
        ),
      ),
    );
  }


  // Method for retrieving the current location
  _getCurrentLocation() async {
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) async {
      setState(() {
        // Store the position in the variable
        _currentPosition = position;

        print('CURRENT POS: $_currentPosition');

        // For moving the camera to current location
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(widget.startLat,widget.startLong),//LatLng(position.latitude, position.longitude),
              zoom: 8.0,

            ),
          ),
        );
      });
    }).catchError((e) {
      print(e);
    });
  }
  // Create the polylines for showing the route between two places

  _createPolylines(Position start, Position destination) async {
    // Initializing PolylinePoints
    polylinePoints = PolylinePoints();

    // Generating the list of coordinates to be used for
    // drawing the polylines
    PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
      widget.directionsApiKey, // Google Maps API Key
      PointLatLng(start.latitude, start.longitude),
      PointLatLng(destination.latitude, destination.longitude),
      optimizeWaypoints: true
    );

    // Adding the coordinates to the list
    if (result.points.isNotEmpty) {
      result.points.forEach((PointLatLng point) {
        polylineCoordinates.add(LatLng(point.latitude, point.longitude));
      });
    }

    // Defining an ID
    PolylineId id = PolylineId('poly');

    // Initializing Polyline
    Polyline polyline = Polyline(
      polylineId: id,
      color: Colors.blue,
      points: polylineCoordinates,
      width: 5,
    );

    // Adding the polyline to the map
    // setState(() {
      polylines[id] = polyline;
      print("PLOYLINE DRAWN :::::::::::" + polyline.points.toString());
    // });

    _getDistance();
  }
  ///////////////////////////////////////////////////////////////////////
  //                    Calculating the distance now
  ///////////////////////////////////////////////////////////////////////
  _getDistance() {
    if(polylineCoordinates.length == 0){
      double distanceInMeters = Geolocator.distanceBetween(
        widget.startLat,
        widget.startLong,
        widget.endLat,
        widget.endLong,
      );
      widget._distanceBetweenLocations = (distanceInMeters / 1000).toStringAsFixed(2);
    }
    for (int i = 0; i < polylineCoordinates.length - 1; i++) {
      _placeDistance += _coordinateDistance(
        polylineCoordinates[i].latitude,
        polylineCoordinates[i].longitude,
        polylineCoordinates[i + 1].latitude,
        polylineCoordinates[i + 1].longitude,
      );
    }

    widget._distanceBetweenLocations = _placeDistance.toStringAsFixed(2);
  }
  double _coordinateDistance(lat1, lon1, lat2, lon2) {
    var p = 0.017453292519943295;
    var c = cos;
    var a = 0.5 -
        c((lat2 - lat1) * p) / 2 +
        c(lat1 * p) * c(lat2 * p) * (1 - c((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }
}
