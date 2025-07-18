import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SettingsManager
{

  static final SettingsManager _settingsManager = SettingsManager._internal();

  factory SettingsManager() => _settingsManager;

  SettingsManager._internal();

  static const String _camera_count = 'camera_count';
  static const String _timestampKey = 'camera_cache_time';
  static const String _pi_address = 'pi_address';

  Future<int> fetch_camera_count() async
  {
    final prefs = await SharedPreferences.getInstance();


    final cachedCount = prefs.getInt(_camera_count);

    if(cachedCount != null)
    {
      return cachedCount;
    }

    return -1;
  }

  Future<bool> set_camera_count(int num_cameras) async
  {
    final prefs = await SharedPreferences.getInstance();
    bool success = await prefs.setInt(_camera_count, num_cameras);

    return success;
  }

  Future<bool> set_pi_address(String address) async
  {
    final prefs = await SharedPreferences.getInstance();
    bool success = await prefs.setString(_pi_address, address);

    return success;
  }

  Future<void> delete_cached_preferences() async
  {
    final prefs = await SharedPreferences.getInstance();

    prefs.remove(_camera_count);
    prefs.remove(_pi_address);
  }

}