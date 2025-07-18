import 'package:flutter/material.dart';

class SettingsMenu extends StatefulWidget {
  const SettingsMenu({super.key});

  @override
  State<SettingsMenu> createState() => _SettingsMenuState();
}

class _SettingsMenuState extends State<SettingsMenu> {

  final _controller = TextEditingController();

  bool is_ip_valid = false;

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
                });
              },
            ),
            SizedBox(height: 16),
            ElevatedButton(onPressed: (){
              if(!is_ip_valid)
              {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please enter a valid IP or Hostname'),
                  duration: Duration(seconds: 4))
                );
              }
            }, child: Text('Save'))
          ],
        ),
      )

    );
  }
}
