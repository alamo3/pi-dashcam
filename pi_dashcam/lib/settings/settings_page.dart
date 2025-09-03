import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pi_dashcam/settings/settings_manager.dart';
import 'package:http/http.dart' as http;

class SettingsMenu extends StatefulWidget {
  const SettingsMenu({super.key});

  @override
  State<SettingsMenu> createState() => _SettingsMenuState();
}

class _SettingsMenuState extends State<SettingsMenu> {

  final _controller = TextEditingController();

  bool is_ip_valid = false;

  int num_cameras = 0;

  String host_ip = "";

  final _ipRegex = RegExp(r'^((25[0-5]|(2[0-4]|1\d|[1-9]|)\d)\.?\b){4}$');
  final _hostRegex = RegExp(r'^([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$');

  String? _validateHostOrIP(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a host or IP address';
    }
    if (_ipRegex.hasMatch(value) || _hostRegex.hasMatch(value)) {
      return null; // valid
    }
    return 'Invalid IP address or hostname';
  }

  Future<Map<String,dynamic>> fetchData() async {
    try {
      final response = await Future.value(http.get(
          Uri.parse("http://$host_ip:5000/camera_count"))).timeout(Duration(seconds: 10)) ;

      if (response.statusCode == 200) {
        // Request successful, parse the JSON response
        final Map<String, dynamic> data = json.decode(response.body);

        return data;
      }
      else {
        // Request failed
        return {};
      }
    }catch(e)
    {
      return {};
    }
  }

  @override
  void initState()
  {
    super.initState();
    SettingsManager().fetch_camera_count().then((int count)
    {
      setState(() {
        num_cameras = count;
      });

    });

    SettingsManager().get_pi_address().then((String? ip){

      if(ip != null)
      {
        setState(() {
          host_ip = ip;
          _controller.text = ip;
          is_ip_valid = true;
        });
      }

    });

  }


  @override
  Widget build(BuildContext context) {
    return Center(
      child:Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 20),
            TextFormField(
              controller: _controller,
              decoration: InputDecoration(
                  labelText: 'Enter IP or Hostname',
                  border: OutlineInputBorder()
              ),
              validator: _validateHostOrIP,
              autovalidateMode: AutovalidateMode.always,
              onChanged: (val){
                bool isValid = _validateHostOrIP(val) == null;
                setState(() {
                  is_ip_valid = isValid;
                  host_ip = val;
                });
              },
            ),
            SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(onPressed: (){
                  if(!is_ip_valid)
                  {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please enter a valid IP or Hostname'),
                            duration: Duration(seconds: 4))
                    );
                  }
                  else
                  {
                    fetchData().then((Map<String,dynamic> res){
                      if(res.isEmpty || res['status'] != 'ok')
                      {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Unable to connect to server'),
                                duration: Duration(seconds: 4))
                        );
                        setState(() {
                          num_cameras = 0;
                          SettingsManager().set_camera_count(num_cameras);
                        });
                      }
                      else
                      {
                        setState(() {
                          num_cameras = res['cameras'];
                        });
                      }
                    });
                  }
                }, child: Text('Test Connection')),
                Text('Cameras detected: $num_cameras')
              ],
            )
            ,
            ElevatedButton(onPressed: (){
              if(!is_ip_valid)
              {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please enter a valid IP or Hostname'),
                        duration: Duration(seconds: 4))
                );
              }
              else
              {
                  SettingsManager().set_camera_count(num_cameras).then((bool status){
                    if(status)
                    {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Camera count saved'),
                              duration: Duration(seconds: 2))
                      );
                    }
                    else
                    {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Unable to save camera count'),
                              duration: Duration(seconds: 2))
                      );
                    }
                  });
                  SettingsManager().set_pi_address(host_ip).then((bool status){
                    if(status)
                    {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Host successfully saved'),
                              duration: Duration(seconds: 2))
                      );
                    }
                    else
                    {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Unable to save host'),
                              duration: Duration(seconds: 2))
                      );
                    }

                  });
              }
            }, child: Text('Save'))
          ],
        ),
      )

    );
  }
}
