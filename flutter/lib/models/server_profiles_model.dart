import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../common.dart';
import 'platform_model.dart';
import 'state_model.dart';

const kOptionServerProfiles = 'server-profiles-v1';
const kOptionActiveProfileId = 'active-server-profile-id';

enum ServerProfileStatus {
  unknown,
  checking,
  online,
  offline,
}

class ServerProfile {
  final String id;
  String name;
  String idServer;
  String relayServer;
  String apiServer;
  String key;
  final bool isDefault;
  final Rx<ServerProfileStatus> status;

  ServerProfile({
    required this.id,
    required this.name,
    this.idServer = '',
    this.relayServer = '',
    this.apiServer = '',
    this.key = '',
    this.isDefault = false,
    ServerProfileStatus initialStatus = ServerProfileStatus.unknown,
  }) : status = initialStatus.obs;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'idServer': idServer,
        'relayServer': relayServer,
        'apiServer': apiServer,
        'key': key,
        'isDefault': isDefault,
      };

  factory ServerProfile.fromJson(Map<String, dynamic> json) {
    return ServerProfile(
      id: json['id'] as String? ?? const Uuid().v4(),
      name: json['name'] as String? ?? 'Server',
      idServer: json['idServer'] as String? ?? '',
      relayServer: json['relayServer'] as String? ?? '',
      apiServer: json['apiServer'] as String? ?? '',
      key: json['key'] as String? ?? '',
      isDefault: json['isDefault'] as bool? ?? false,
    );
  }

  ServerProfile copyWith({
    String? name,
    String? idServer,
    String? relayServer,
    String? apiServer,
    String? key,
  }) {
    return ServerProfile(
      id: id,
      name: name ?? this.name,
      idServer: idServer ?? this.idServer,
      relayServer: relayServer ?? this.relayServer,
      apiServer: apiServer ?? this.apiServer,
      key: key ?? this.key,
      isDefault: isDefault,
      initialStatus: status.value,
    );
  }
}

class ServerProfilesModel extends ChangeNotifier {
  static final ServerProfilesModel _instance = ServerProfilesModel._internal();
  factory ServerProfilesModel() => _instance;

  final RxList<ServerProfile> profiles = <ServerProfile>[].obs;
  final RxString activeProfileId = ''.obs;
  final RxBool isCheckingAll = false.obs;

  ServerProfilesModel._internal() {
    loadProfiles();
  }

  static ServerProfile get defaultPublicProfile => ServerProfile(
        id: 'default_public_server',
        name: 'Public / Official',
        idServer: '',
        relayServer: '',
        apiServer: '',
        key: '',
        isDefault: true,
      );

  void loadProfiles() {
    try {
      final jsonStr = bind.mainGetLocalOption(key: kOptionServerProfiles);
      final List<ServerProfile> loaded = [];

      if (jsonStr.isNotEmpty) {
        final decoded = jsonDecode(jsonStr);
        if (decoded is List) {
          for (var item in decoded) {
            if (item is Map<String, dynamic>) {
              loaded.add(ServerProfile.fromJson(item));
            }
          }
        }
      }

      // Ensure default public profile is present at index 0
      final hasDefault =
          loaded.any((p) => p.isDefault || p.id == defaultPublicProfile.id);
      if (!hasDefault) {
        loaded.insert(0, defaultPublicProfile);
      }

      profiles.assignAll(loaded);
      syncActiveProfile();
    } catch (e) {
      debugPrint('Error loading server profiles: $e');
      profiles.assignAll([defaultPublicProfile]);
      activeProfileId.value = defaultPublicProfile.id;
    }
  }

  void saveProfiles() {
    try {
      final list = profiles.map((p) => p.toJson()).toList();
      bind.mainSetLocalOption(
        key: kOptionServerProfiles,
        value: jsonEncode(list),
      );
    } catch (e) {
      debugPrint('Error saving server profiles: $e');
    }
  }

  void syncActiveProfile() {
    try {
      final curId =
          bind.mainGetOptionSync(key: 'custom-rendezvous-server').trim();
      final curRelay = bind.mainGetOptionSync(key: 'relay-server').trim();
      final curKey = bind.mainGetOptionSync(key: 'key').trim();

      if (curId.isEmpty && curRelay.isEmpty && curKey.isEmpty) {
        activeProfileId.value = defaultPublicProfile.id;
        final def = profiles.firstWhereOrNull((p) => p.isDefault);
        if (def != null && stateGlobal.svcStatus.value == SvcStatus.ready) {
          def.status.value = ServerProfileStatus.online;
        }
        return;
      }

      final matched = profiles.firstWhereOrNull(
        (p) =>
            !p.isDefault &&
            p.idServer.trim() == curId &&
            p.relayServer.trim() == curRelay &&
            p.key.trim() == curKey,
      );

      if (matched != null) {
        activeProfileId.value = matched.id;
        if (stateGlobal.svcStatus.value == SvcStatus.ready) {
          matched.status.value = ServerProfileStatus.online;
        }
      } else {
        // Active server is not in saved profiles
        final savedActiveId =
            bind.mainGetLocalOption(key: kOptionActiveProfileId);
        if (savedActiveId.isNotEmpty &&
            profiles.any((p) => p.id == savedActiveId)) {
          activeProfileId.value = savedActiveId;
        } else {
          activeProfileId.value = '';
        }
      }
    } catch (e) {
      debugPrint('Error syncing active server profile: $e');
    }
  }

  Future<bool> selectProfile(ServerProfile profile) async {
    final config = ServerConfig(
      idServer: profile.idServer,
      relayServer: profile.relayServer,
      apiServer: profile.apiServer,
      key: profile.key,
    );

    final success = await setServerConfig(null, null, config);
    if (success) {
      activeProfileId.value = profile.id;
      bind.mainSetLocalOption(
        key: kOptionActiveProfileId,
        value: profile.id,
      );
      notifyListeners();
      // Test the selected profile status
      checkProfileStatus(profile);
      showToast(translate('Successful'));
      return true;
    } else {
      showToast(translate('Failed'));
      return false;
    }
  }

  Future<void> checkProfileStatus(ServerProfile profile) async {
    profile.status.value = ServerProfileStatus.checking;
    try {
      if (profile.isDefault) {
        // If it's active and ready, online
        if (activeProfileId.value == profile.id &&
            stateGlobal.svcStatus.value == SvcStatus.ready) {
          profile.status.value = ServerProfileStatus.online;
          return;
        }
        // Test standard public server host
        final res = await bind.mainTestIfValidServer(
          server: 'rs-ny.rustdesk.com',
          testWithProxy: true,
        );
        profile.status.value = res.isEmpty
            ? ServerProfileStatus.online
            : ServerProfileStatus.offline;
      } else {
        final host = profile.idServer.trim().isNotEmpty
            ? profile.idServer.trim()
            : profile.relayServer.trim();

        if (host.isEmpty) {
          profile.status.value = ServerProfileStatus.offline;
          return;
        }

        final res = await bind.mainTestIfValidServer(
          server: host,
          testWithProxy: true,
        );
        profile.status.value = res.isEmpty
            ? ServerProfileStatus.online
            : ServerProfileStatus.offline;
      }
    } catch (e) {
      debugPrint('Failed checking status for ${profile.name}: $e');
      profile.status.value = ServerProfileStatus.offline;
    }
  }

  Future<void> checkAllStatuses() async {
    if (isCheckingAll.value) return;
    isCheckingAll.value = true;
    try {
      final futures = profiles.map((p) => checkProfileStatus(p)).toList();
      await Future.wait(futures);
    } finally {
      isCheckingAll.value = false;
      notifyListeners();
    }
  }

  void addProfile(ServerProfile profile) {
    profiles.add(profile);
    saveProfiles();
    notifyListeners();
    checkProfileStatus(profile);
  }

  void updateProfile(ServerProfile profile) {
    final idx = profiles.indexWhere((p) => p.id == profile.id);
    if (idx != -1) {
      profiles[idx] = profile;
      saveProfiles();
      notifyListeners();
      checkProfileStatus(profile);
      if (activeProfileId.value == profile.id) {
        selectProfile(profile);
      }
    }
  }

  void deleteProfile(String profileId) {
    if (profileId == defaultPublicProfile.id) return;
    profiles.removeWhere((p) => p.id == profileId && !p.isDefault);
    saveProfiles();
    if (activeProfileId.value == profileId) {
      final def =
          profiles.firstWhereOrNull((p) => p.isDefault) ?? defaultPublicProfile;
      selectProfile(def);
    }
    notifyListeners();
  }
}

final serverProfilesModel = ServerProfilesModel();
