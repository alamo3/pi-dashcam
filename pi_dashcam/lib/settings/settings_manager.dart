import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SettingsManager extends ChangeNotifier
{

  static final SettingsManager _settingsManager = SettingsManager._internal();

  factory SettingsManager() => _settingsManager;

  SettingsManager._internal();

  static const String _camera_count = 'camera_count';
  static const String _timestampKey = 'camera_cache_time';
  static const String _pi_address = 'pi_address';

  int cam_count = 0;
  String pi_address = "";

  Future<int> fetch_camera_count() async
  {
    final prefs = await SharedPreferences.getInstance();

    final cachedCount = prefs.getInt(_camera_count);

    if(cachedCount != null)
    {
      return cachedCount;
    }

    return 0;
  }

  Future<bool> set_camera_count(int num_cameras) async
  {
    final prefs = await SharedPreferences.getInstance();
    bool success = await prefs.setInt(_camera_count, num_cameras);

    if(success)
    {
      cam_count = num_cameras;
      notifyListeners();
    }
    return success;
  }

  Future<bool> set_pi_address(String address) async
  {
    final prefs = await SharedPreferences.getInstance();
    bool success = await prefs.setString(_pi_address, address);

    if(success)
    {
      pi_address = address;
      notifyListeners();
    }

    return success;
  }

  Future<String?> get_pi_address() async
  {
    final prefs = await SharedPreferences.getInstance();
    final cacheIp = prefs.getString(_pi_address);

    return cacheIp;
  }

  Future<void> delete_cached_preferences() async
  {
    final prefs = await SharedPreferences.getInstance();

    prefs.remove(_camera_count);
    prefs.remove(_pi_address);

    notifyListeners();
  }

}