
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pi_dashcam/settings/settings_manager.dart';
import 'package:pi_dashcam/live_view/video_tile.dart';
import 'package:provider/provider.dart';



class LiveView extends StatefulWidget {
  const LiveView({super.key});

  @override
  State<LiveView> createState() => _LiveViewState();
}

class _LiveViewState extends State<LiveView> {

  int? _num_of_streams_avail;
  String host_ip = "";

  @override
  void initState(){

    super.initState();
    SettingsManager().fetch_camera_count().then((int count)
    {
      setState(() {
        _num_of_streams_avail = count;
      });

    });

    SettingsManager().get_pi_address().then((String? ip){
      host_ip = ip ?? "";
    });
  }

  Future<void> _startAndOpenStream(BuildContext context, int cameraId) async {


      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoStreamPage(ip: host_ip,cameraId: cameraId),
        ),
      );


  }

  Widget cameraAvailableWidget(BuildContext context, int numCameras)
  {
    return Center(
      child: Column(
        children: [
          for(int i = 0; i < numCameras; i++)
              VideoTile(cameraId: i, onTap: () => _startAndOpenStream(context, i))
        ],
      ),
    );
  }

  Widget cameraStreamSelectionWidget(BuildContext context, int numCameras)
  {
    switch(numCameras)
    {
      case 1:
      case 2:
      case 3:
      case 4:
        {
          return cameraAvailableWidget(context, numCameras);
        }

      default:
      {
        return Text('No cameras available!');
      }

    }
  }

  @override
  Widget build(BuildContext context) {
    final numCameras = context.watch<SettingsManager>().cam_count;
    final _ = context.watch<SettingsManager>().pi_address;
    return Center(
      child: cameraStreamSelectionWidget(context, numCameras)
    );
  }
}
