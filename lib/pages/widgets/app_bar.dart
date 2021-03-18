import 'package:flutter/material.dart';
import 'package:latlong/latlong.dart';

import '../maps/stop_map.dart';

class AppBarWidget extends StatelessWidget with PreferredSizeWidget {
  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) => AppBar(
        backgroundColor: Colors.blueGrey[800],
        title: Text(
          'BusLnk',
          // style: TextStyle(
          //   color: Colors.white,
          // ),
        ),
        actions: [
          ModalRoute.of(context).settings.name == '/map' ||
                  ModalRoute.of(context).settings.name == '/stop'
              ? Container()
              : IconButton(
                  icon: Icon(
                    Icons.map_rounded,
                  ),
                  onPressed: () async {
                    await Navigator.pushNamed(
                      context,
                      '/map',
                      arguments: StopsMapArguments(
                        LatLng(
                          -41.276825,
                          174.777969,
                        ),
                        true,
                      ),
                    );
                  },
                ),
          ModalRoute.of(context).settings.name == '/'
              ? Container()
              : IconButton(
                  icon: Icon(
                    Icons.home_rounded,
                  ),
                  onPressed: () {
                    Navigator.popUntil(
                      context,
                      ModalRoute.withName(Navigator.defaultRouteName),
                    );
                  },
                )
        ],
      );
}