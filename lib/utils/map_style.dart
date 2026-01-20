// Helper that provides a stylized Google Maps JSON string
// Use with `GoogleMapController.setMapStyle(...)` when integrating maps
const String appMapStyle = '''
[
  {
    "featureType": "all",
    "elementType": "geometry",
    "stylers": [
      {"color": "#fff7f4"}
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      {"color": "#ffd9cc"}
    ]
  },
  {
    "featureType": "poi.business",
    "elementType": "labels.text.fill",
    "stylers": [
      {"color": "#b85a3a"}
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {"color": "#e9f6ff"}
    ]
  }
]
''';

String getAppMapStyle() => appMapStyle;
