import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserDetailsPage extends StatefulWidget {
  const UserDetailsPage({super.key});

  @override
  State<UserDetailsPage> createState() => _UserDetailsPageState();
}

class _UserDetailsPageState extends State<UserDetailsPage> {
  final _auth = FirebaseAuth.instance;

  Future<void> _showInfo(String title, String message) async {
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showChangeEmailDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return _ChangeEmailDialog(
          currentEmail: _auth.currentUser?.email ?? '',
          onUpdate: (newEmail) async {
            final trimmed = newEmail.trim();
            if (trimmed.isEmpty) {
              await showDialog<void>(
                context: dialogContext,
                builder: (_) => const AlertDialog(
                  title: Text('Validation Error'),
                  content: Text('Please enter a valid email address.'),
                ),
              );
              return;
            }

            try {
              await _auth.currentUser!.verifyBeforeUpdateEmail(trimmed);
              if (!mounted) return;

              await _showInfo(
                'Success',
                'A verification email has been sent. You will be logged out after confirming.',
              );

              await _auth.signOut();
            } on FirebaseAuthException catch (e) {
              final msg = e.message ?? e.code;
              await _showInfo('Error', msg);
            } catch (e) {
              await _showInfo('Error', e.toString());
            }
          },
        );
      },
    );
  }

  Future<void> _handleChangePassword() async {
    final email = _auth.currentUser?.email;
    if (email == null || email.isEmpty) {
      await _showInfo('Error', 'No email found for the current user.');
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      await _showInfo('Success', 'The reset link has been sent to your email.');
    } on FirebaseAuthException catch (e) {
      final msg = e.message ?? e.code;
      await _showInfo('Error', msg);
    } catch (e) {
      await _showInfo('Error', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Account details')),
      body: Container(
        color: const Color(0xFFF7F7F7),
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _InfoRow(
                  label: 'Email:',
                  value: user?.email ?? '',
                  valueColor: const Color(0xFF007BFF),
                ),
                const SizedBox(height: 20),
                _InfoRow(
                  label: 'Display name:',
                  value: user?.displayName ?? '',
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007BFF),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _showChangeEmailDialog,
                    child: const Text(
                      'Change Email',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007BFF),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _handleChangePassword,
                    child: const Text(
                      'Change Password',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF555555),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            softWrap: true,
            style: TextStyle(fontSize: 16, color: valueColor),
          ),
        ),
      ],
    );
  }
}

class _ChangeEmailDialog extends StatefulWidget {
  final String currentEmail;
  final Future<void> Function(String newEmail) onUpdate;

  const _ChangeEmailDialog({
    required this.currentEmail,
    required this.onUpdate,
  });

  @override
  State<_ChangeEmailDialog> createState() => _ChangeEmailDialogState();
}

class _ChangeEmailDialogState extends State<_ChangeEmailDialog> {
  late final TextEditingController _controller;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true,
      child: AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        insetPadding: const EdgeInsets.fromLTRB(24, 24, 24, 64),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text(
          'Change Email',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Updating your email will log you out.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFFD9534F),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                height: 52,
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(
                    hintText: 'Enter new email address',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) async {
                    if (_submitting) return;
                    setState(() => _submitting = true);
                    await widget.onUpdate(_controller.text);
                    if (!mounted) return;
                    setState(() => _submitting = false);
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _submitting ? null : () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF333333), fontSize: 16),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF007BFF),
            ),
            onPressed: _submitting
                ? null
                : () async {
                    setState(() => _submitting = true);
                    await widget.onUpdate(_controller.text);
                    if (!mounted) return;
                    setState(() => _submitting = false);
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
            child: Text(
              _submitting ? 'Updating…' : 'Update',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
