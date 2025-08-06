import 'package:flutter/cupertino.dart';
import 'package:pi_dashcam/settings/settings_manager.dart';


class LiveView extends StatefulWidget {
  const LiveView({super.key});

  @override
  State<LiveView> createState() => _LiveViewState();
}

class _LiveViewState extends State<LiveView> {

  int? _num_of_streams_avail;

  @override
  void initState(){

    super.initState();
    SettingsManager().fetch_camera_count().then((int count)
    {
      _num_of_streams_avail = count;
    });

  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: (_num_of_streams_avail != null) ? Text("Cameras loaded! $_num_of_streams_avail") : Placeholder(),
    );
  }
}
