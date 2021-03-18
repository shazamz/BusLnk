import 'package:dio/dio.dart';
import 'package:dio_http_cache/dio_http_cache.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong/latlong.dart';

import '../../constants/config.dart';
import '../../helpers/requests.dart';
import '../stop/stop.dart';
import '../widgets/app_bar.dart';
import '../widgets/page_loading_dots.dart';

class StopsMapArguments {
  final LatLng location;
  final bool isMap;

  StopsMapArguments(
    this.location,
    this.isMap,
  );
}

// Create a stateful widget
class StopsMapWidget extends StatefulWidget {
  final StopsMapArguments arguments;

  const StopsMapWidget(this.arguments);

  @override
  State<StopsMapWidget> createState() => StopsMapWidgetState();
}

class StopsMapWidgetState extends State<StopsMapWidget>
    with TickerProviderStateMixin {
  final GlobalKey _scaffoldkey = GlobalKey();
  final PopupController _popupController = PopupController();
  List stops = [];
  bool isLoading = false;
  List<Marker> listMarkers = [];
  Map<Marker, Map<String, dynamic>> mapMarkers = {};

  @override
  void initState() {
    super.initState();
    Dio().interceptors.add(
          DioCacheManager(
            CacheConfig(
              baseUrl: 'https://api.opendata.metlink.org.nz',
              defaultRequestMethod: 'GET',
            ),
          ).interceptor,
        );
    fetchStopList();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void fetchStopList() async {
    setState(() {
      isLoading = true;
    });

    var stopData = await getRequestCache(
      '$openApiBaseUrl/stops',
    );
    setState(() {
      stops = stopData;
      stops.forEach((stop) {
        var marker = Marker(
          width: 100,
          height: 100,
          point: LatLng(
            stop['stop_lat'],
            stop['stop_lon'],
          ),
          builder: (ctx) => Icon(
            Icons.directions_bus_rounded,
            color: Colors.blueGrey[800],
            size: 40,
          ),
        );
        mapMarkers[marker] = stop;
        listMarkers.add(marker);
      });
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        key: _scaffoldkey,
        appBar: AppBarWidget(),
        body: getBody(),
      );

  Widget getBody() {
    if (isLoading || stops.isEmpty || listMarkers.isEmpty) {
      return JumpingDotsProgressIndicator();
    }
    return FlutterMap(
      options: MapOptions(
        center: widget.arguments.location,
        zoom: widget.arguments.isMap ? 12 : 17,
        minZoom: 0,
        maxZoom: 19,
        interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        plugins: [
          MarkerClusterPlugin(),
        ],
      ),
      layers: [
        TileLayerOptions(
          // https://maps.wikimedia.org/osm-intl/{z}/{x}/{y}.png
          // https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png
          urlTemplate: 'https://maps.wikimedia.org/osm-intl/{z}/{x}/{y}.png',
          subdomains: [
            'a',
            'b',
            'c',
          ],
        ),
        MarkerClusterLayerOptions(
          maxClusterRadius: 200,
          disableClusteringAtZoom: 16,
          animationsOptions: AnimationsOptions(
            zoom: Duration(
              milliseconds: 200,
            ),
          ),
          size: Size(
            60,
            60,
          ),
          fitBoundsOptions: FitBoundsOptions(
            maxZoom: 19,
            padding: EdgeInsets.all(50),
          ),
          anchor: AnchorPos.align(
            AnchorAlign.center,
          ),
          markers: mapMarkers.keys.toList(),
          polygonOptions: PolygonOptions(
            borderColor: Colors.blueGrey[800],
            color: Colors.blueGrey[300],
            borderStrokeWidth: 3,
          ),
          popupOptions: PopupOptions(
            popupController: _popupController,
            popupBuilder: (_, marker) => Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              width: 200,
              height: 100,
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(
                    color: Colors.blueGrey[300],
                  ),
                ),
                color: Colors.white,
                child: ListTile(
                  trailing: IconButton(
                    icon: Icon(
                      Icons.open_in_browser_rounded,
                      color: Colors.blueGrey[800],
                    ),
                    onPressed: () async {
                      var stop = mapMarkers[marker];
                      await Navigator.pushNamed(
                        _scaffoldkey.currentContext,
                        '/stop',
                        arguments: StopArguments(
                          stop['stop_name'],
                          stop['stop_code'],
                        ),
                      );
                    },
                  ),
                  title: Text(
                    '${mapMarkers[marker]['stop_name']}',
                    style: TextStyle(
                      color: Color(0xff699b2c),
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    '${mapMarkers[marker]['stop_code']}',
                    style: TextStyle(
                      color: Colors.blueGrey[800],
                    ),
                  ),
                ),
              ),
            ),
          ),
          builder: (context, markers) => FloatingActionButton(
            heroTag: 'stop_hero_tag_${markers.length.toString()}',
            onPressed: null,
            backgroundColor: Colors.blueGrey[800],
            child: Text(
              markers.length.toString(),
            ),
          ),
        ),
      ],
    );
  }
}