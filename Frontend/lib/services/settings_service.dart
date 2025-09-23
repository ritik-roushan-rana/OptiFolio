import 'api_client.dart';
import 'auth_service.dart';

class SettingItem {
  final String key;
  final String title;
  final String description;
  final String type;
  bool? valueBool;
  String? valueString;
  final String group;
  final int order;

  SettingItem({
    required this.key,
    required this.title,
    required this.description,
    required this.type,
    this.valueBool,
    this.valueString,
    required this.group,
    required this.order,
  });

  factory SettingItem.fromJson(Map j) => SettingItem(
    key: j['key'],
    title: j['title'] ?? '',
    description: j['description'] ?? '',
    type: j['type'] ?? 'toggle',
    valueBool: j['valueBool'],
    valueString: j['valueString'],
    group: j['group'] ?? 'general',
    order: (j['order'] ?? 0) as int,
  );

  Map<String,dynamic> toJson() => {
    'key': key,
    'title': title,
    'description': description,
    'type': type,
    'valueBool': valueBool,
    'valueString': valueString,
    'group': group,
    'order': order,
  };
}

class SettingsService {
  final ApiClient _api;
  SettingsService(AuthService auth): _api = ApiClient(auth);

  Future<List<SettingItem>> fetch() async {
    final j = await _api.getJson('/api/settings');
    final list = (j['settings'] as List? ?? []);
    return list.map((e) => SettingItem.fromJson(e)).toList()
      ..sort((a,b)=>a.order.compareTo(b.order));
  }

  Future<SettingItem> toggle(String key, bool value) async {
    final j = await _api.patchJson('/api/settings/$key', {'valueBool': value});
    return SettingItem.fromJson(j['setting']);
  }
}