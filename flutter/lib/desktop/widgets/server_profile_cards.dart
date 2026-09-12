import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:get/get.dart';

import '../../models/server_profiles_model.dart';
import 'server_profile_dialog.dart';

class ServerProfileSidebarCards extends StatefulWidget {
  const ServerProfileSidebarCards({Key? key}) : super(key: key);

  @override
  State<ServerProfileSidebarCards> createState() =>
      _ServerProfileSidebarCardsState();
}

class _ServerProfileSidebarCardsState extends State<ServerProfileSidebarCards> {
  @override
  void initState() {
    super.initState();
    serverProfilesModel.syncActiveProfile();
    // Test active or all profiles on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      serverProfilesModel.checkAllStatuses();
    });
  }

  Color _getStatusColor(ServerProfileStatus status) {
    switch (status) {
      case ServerProfileStatus.online:
        return const Color.fromARGB(255, 50, 190, 166);
      case ServerProfileStatus.offline:
        return const Color.fromARGB(255, 224, 79, 95);
      case ServerProfileStatus.checking:
        return Colors.amber;
      case ServerProfileStatus.unknown:
        return Colors.grey;
    }
  }

  String _getStatusTooltip(ServerProfileStatus status) {
    switch (status) {
      case ServerProfileStatus.online:
        return 'Online / ON';
      case ServerProfileStatus.offline:
        return 'Offline / OFF';
      case ServerProfileStatus.checking:
        return 'Checking...';
      case ServerProfileStatus.unknown:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(left: 20, right: 11, top: 12, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Servers',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color:
                      theme.textTheme.titleLarge?.color?.withValues(alpha: 0.8),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(
                    () => IconButton(
                      icon: serverProfilesModel.isCheckingAll.value
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh, size: 16),
                      tooltip: 'Refresh status',
                      splashRadius: 14,
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 22, minHeight: 22),
                      onPressed: serverProfilesModel.isCheckingAll.value
                          ? null
                          : () => serverProfilesModel.checkAllStatuses(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 18),
                    tooltip: 'Add Server',
                    splashRadius: 14,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 22, minHeight: 22),
                    onPressed: () => showAddOrEditServerProfileDialog(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Obx(
            () {
              final profiles = serverProfilesModel.profiles;
              final activeId = serverProfilesModel.activeProfileId.value;

              return Column(
                children: profiles.map((p) {
                  final isActive = p.id == activeId;

                  return Obx(() {
                    final status = p.status.value;
                    final statusColor = _getStatusColor(status);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: isActive
                            ? (isDark
                                ? MyTheme.accent.withValues(alpha: 0.18)
                                : MyTheme.accent.withValues(alpha: 0.1))
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.04)
                                : Colors.black.withValues(alpha: 0.03)),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isActive
                              ? MyTheme.accent
                              : Colors.grey.withValues(alpha: 0.25),
                          width: isActive ? 1.5 : 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            if (!isActive) {
                              serverProfilesModel.selectProfile(p);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 7),
                            child: Row(
                              children: [
                                Tooltip(
                                  message: _getStatusTooltip(status),
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: statusColor,
                                      boxShadow: [
                                        BoxShadow(
                                          color: statusColor.withValues(
                                              alpha: 0.5),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 9),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.name,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: isActive
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isActive
                                              ? (isDark
                                                  ? Colors.white
                                                  : MyTheme.accent)
                                              : theme
                                                  .textTheme.bodyMedium?.color,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        p.isDefault
                                            ? 'Official Server'
                                            : (p.idServer.isNotEmpty
                                                ? p.idServer
                                                : p.relayServer),
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: theme
                                              .textTheme.bodySmall?.color
                                              ?.withValues(alpha: 0.7),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                if (isActive)
                                  const Icon(
                                    Icons.check_circle,
                                    size: 15,
                                    color: MyTheme.accent,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  });
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ServerProfilesSettingsSection extends StatelessWidget {
  const ServerProfilesSettingsSection({Key? key}) : super(key: key);

  Color _getStatusColor(ServerProfileStatus status) {
    switch (status) {
      case ServerProfileStatus.online:
        return const Color.fromARGB(255, 50, 190, 166);
      case ServerProfileStatus.offline:
        return const Color.fromARGB(255, 224, 79, 95);
      case ServerProfileStatus.checking:
        return Colors.amber;
      case ServerProfileStatus.unknown:
        return Colors.grey;
    }
  }

  String _getStatusText(ServerProfileStatus status) {
    switch (status) {
      case ServerProfileStatus.online:
        return 'ON / Online';
      case ServerProfileStatus.offline:
        return 'OFF / Offline';
      case ServerProfileStatus.checking:
        return 'Checking...';
      case ServerProfileStatus.unknown:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Server Profiles',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              Row(
                children: [
                  Obx(
                    () => OutlinedButton.icon(
                      icon: serverProfilesModel.isCheckingAll.value
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh, size: 16),
                      label: Text(translate('Refresh Status')),
                      onPressed: serverProfilesModel.isCheckingAll.value
                          ? null
                          : () => serverProfilesModel.checkAllStatuses(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: Text(translate('Add Server')),
                    onPressed: () => showAddOrEditServerProfileDialog(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            final profiles = serverProfilesModel.profiles;
            final activeId = serverProfilesModel.activeProfileId.value;

            if (profiles.isEmpty) {
              return Text(
                'No server profiles configured',
                style: TextStyle(color: theme.hintColor),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: profiles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final p = profiles[index];
                final isActive = p.id == activeId;

                return Obx(() {
                  final status = p.status.value;
                  final statusColor = _getStatusColor(status);
                  final statusText = _getStatusText(status);

                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: isActive
                          ? (isDark
                              ? MyTheme.accent.withValues(alpha: 0.12)
                              : MyTheme.accent.withValues(alpha: 0.08))
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.03)
                              : Colors.black.withValues(alpha: 0.02)),
                      border: Border.all(
                        color: isActive
                            ? MyTheme.accent
                            : Colors.grey.withValues(alpha: 0.25),
                        width: isActive ? 1.5 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: statusColor,
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withValues(alpha: 0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                              )
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    p.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isActive ? MyTheme.accent : null,
                                    ),
                                  ),
                                  if (isActive) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: MyTheme.accent,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'Active',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(width: 10),
                                  Text(
                                    statusText,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                p.isDefault
                                    ? 'Default official RustDesk servers'
                                    : 'ID: ${p.idServer.isEmpty ? "-" : p.idServer}  |  Relay: ${p.relayServer.isEmpty ? "-" : p.relayServer}  |  Key: ${p.key.isEmpty ? "None" : (p.key.length > 8 ? "${p.key.substring(0, 8)}..." : p.key)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.textTheme.bodySmall?.color
                                      ?.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isActive)
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                ),
                                onPressed: () {
                                  serverProfilesModel.selectProfile(p);
                                },
                                child: Text(translate('Activate')),
                              ),
                            if (!p.isDefault) ...[
                              const SizedBox(width: 6),
                              IconButton(
                                icon: const Icon(Icons.edit, size: 18),
                                tooltip: translate('Edit'),
                                splashRadius: 16,
                                onPressed: () =>
                                    showAddOrEditServerProfileDialog(
                                        profile: p),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 18, color: Colors.redAccent),
                                tooltip: translate('Delete'),
                                splashRadius: 16,
                                onPressed: () {
                                  serverProfilesModel.deleteProfile(p.id);
                                },
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                });
              },
            );
          }),
        ],
      ),
    );
  }
}
