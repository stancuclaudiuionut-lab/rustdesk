import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/models/server_profiles_model.dart';
import 'package:uuid/uuid.dart';

void showAddOrEditServerProfileDialog({
  ServerProfile? profile,
}) {
  final isEdit = profile != null;
  final nameCtrl = TextEditingController(text: profile?.name ?? '');
  final idCtrl = TextEditingController(text: profile?.idServer ?? '');
  final relayCtrl = TextEditingController(text: profile?.relayServer ?? '');
  final apiCtrl = TextEditingController(text: profile?.apiServer ?? '');
  final keyCtrl = TextEditingController(text: profile?.key ?? '');

  String testStatus = '';
  bool isTesting = false;

  gFFI.dialogManager.show((setState, close, context) {
    void importClipboard() async {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim();
      if (text != null && text.isNotEmpty) {
        try {
          final sc = ServerConfig.decode(text);
          setState(() {
            idCtrl.text = sc.idServer;
            relayCtrl.text = sc.relayServer;
            apiCtrl.text = sc.apiServer;
            keyCtrl.text = sc.key;
            if (nameCtrl.text.trim().isEmpty && sc.idServer.isNotEmpty) {
              nameCtrl.text = sc.idServer;
            }
          });
          showToast(translate('Successful'));
        } catch (_) {
          showToast(translate('Invalid server config'));
        }
      }
    }

    void testConnection() async {
      final host = idCtrl.text.trim().isNotEmpty
          ? idCtrl.text.trim()
          : relayCtrl.text.trim();

      if (host.isEmpty) {
        setState(() {
          testStatus = translate('Please enter server address');
        });
        return;
      }

      setState(() {
        isTesting = true;
        testStatus = '';
      });

      try {
        final res = await bind.mainTestIfValidServer(
          server: host,
          testWithProxy: true,
        );
        setState(() {
          isTesting = false;
          testStatus = res.isEmpty ? '✓ Online' : '✗ ${translate(res)}';
        });
      } catch (e) {
        setState(() {
          isTesting = false;
          testStatus = '✗ $e';
        });
      }
    }

    Widget buildField(String label, TextEditingController controller,
        {bool autofocus = false, String? hint}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: Text(
                label,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SizedBox(
                height: 36,
                child: TextField(
                  controller: controller,
                  autofocus: autofocus,
                  decoration: InputDecoration(
                    hintText: hint,
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return CustomAlertDialog(
      title: Row(
        children: [
          Expanded(
            child: Text(
              isEdit ? 'Edit Server Profile' : 'Add Server Profile',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.paste, size: 20),
            tooltip: translate('Import server config'),
            onPressed: importClipboard,
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 440, maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildField('Profile Name', nameCtrl,
                autofocus: true, hint: 'e.g. Server Birou'),
            buildField(translate('ID Server'), idCtrl,
                hint: 'e.g. id.example.com'),
            buildField(translate('Relay Server'), relayCtrl, hint: 'optional'),
            buildField(translate('API Server'), apiCtrl,
                hint: 'optional: http(s)://...'),
            buildField('Key', keyCtrl, hint: 'optional public key'),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  icon: isTesting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.network_check, size: 16),
                  label: Text(translate('Test Connection')),
                  onPressed: isTesting ? null : testConnection,
                ),
                const SizedBox(width: 12),
                if (testStatus.isNotEmpty)
                  Expanded(
                    child: Text(
                      testStatus,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: testStatus.startsWith('✓')
                            ? Colors.green
                            : Colors.redAccent,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        dialogButton(
          'Cancel',
          onPressed: close,
          isOutline: true,
        ),
        dialogButton(
          'OK',
          onPressed: () {
            final name = nameCtrl.text.trim();
            if (name.isEmpty) {
              showToast('Please enter a profile name');
              return;
            }

            if (isEdit) {
              profile.name = name;
              profile.idServer = idCtrl.text.trim();
              profile.relayServer = relayCtrl.text.trim();
              profile.apiServer = apiCtrl.text.trim();
              profile.key = keyCtrl.text.trim();
              serverProfilesModel.updateProfile(profile);
            } else {
              final newProfile = ServerProfile(
                id: const Uuid().v4(),
                name: name,
                idServer: idCtrl.text.trim(),
                relayServer: relayCtrl.text.trim(),
                apiServer: apiCtrl.text.trim(),
                key: keyCtrl.text.trim(),
              );
              serverProfilesModel.addProfile(newProfile);
            }

            close();
            showToast(translate('Successful'));
          },
        ),
      ],
    );
  });
}
