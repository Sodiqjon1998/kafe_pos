import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/user.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<AppUser> _users = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiClient().get('/users');
      _users = (res.data as List)
          .map((u) => AppUser.fromJson(u as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = ApiClient.errorMessage(e);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _delete(AppUser user) async {
    final ok = await _confirm('${user.name} ni o\'chirasizmi?');
    if (!ok) return;
    try {
      await ApiClient().delete('/users/${user.id}');
      setState(() => _users.removeWhere((u) => u.id == user.id));
      _snack('O\'chirildi');
    } catch (e) {
      _snack(ApiClient.errorMessage(e), error: true);
    }
  }

  Future<void> _openForm([AppUser? user]) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _UserForm(user: user, onSaved: _load),
    );
  }

  Future<bool> _confirm(String msg) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Tasdiqlash',
                style: TextStyle(color: AppColors.text)),
            content: Text(msg,
                style: const TextStyle(color: AppColors.muted)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Bekor',
                      style: TextStyle(color: AppColors.muted))),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('O\'chirish',
                      style: TextStyle(color: AppColors.danger))),
            ],
          ),
        ) ??
        false;
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.danger : AppColors.success,
    ));
  }

  static const _roleColors = {
    'admin':   AppColors.danger,
    'manager': AppColors.primary,
    'cashier': AppColors.warning,
    'waiter':  AppColors.info,
    'kitchen': AppColors.success,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _openForm(),
        child: const Icon(Icons.add, color: AppColors.white),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!,
                          style: const TextStyle(color: AppColors.danger)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _load,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary),
                          child: const Text('Qayta',
                              style: TextStyle(color: AppColors.white))),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _users.length,
                    itemBuilder: (_, i) {
                      final u = _users[i];
                      final roleColor =
                          _roleColors[u.role] ?? AppColors.muted;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.border.withOpacity(0.5)),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor:
                                roleColor.withOpacity(0.15),
                            child: Text(
                              u.name.isNotEmpty
                                  ? u.name[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                  color: roleColor,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                          title: Text(u.name,
                              style: const TextStyle(
                                  color: AppColors.text,
                                  fontWeight: FontWeight.w600)),
                          subtitle: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: roleColor.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(u.roleLabel,
                                    style: TextStyle(
                                        color: roleColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600)),
                              ),
                              if (u.pin != null) ...[
                                const SizedBox(width: 8),
                                Text('PIN: ${u.pin}',
                                    style: const TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 11)),
                              ],
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!u.isActive)
                                const Padding(
                                  padding: EdgeInsets.only(right: 8),
                                  child: Icon(Icons.block,
                                      color: AppColors.danger, size: 16),
                                ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined,
                                    color: AppColors.muted, size: 20),
                                onPressed: () => _openForm(u),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: AppColors.danger, size: 20),
                                onPressed: () => _delete(u),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}

// ── Xodim formi ──────────────────────────────────────────────────────────────

class _UserForm extends StatefulWidget {
  final AppUser? user;
  final VoidCallback onSaved;

  const _UserForm({this.user, required this.onSaved});

  @override
  State<_UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<_UserForm> {
  final _nameCtrl  = TextEditingController();
  final _pinCtrl   = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  String _role = 'waiter';
  bool _active = true;
  bool _saving = false;

  static const _roles = [
    'admin', 'manager', 'cashier', 'waiter', 'kitchen'
  ];
  static const _roleLabels = {
    'admin': 'Admin', 'manager': 'Menejer', 'cashier': 'Kassir',
    'waiter': 'Ofitsiant', 'kitchen': 'Oshpaz',
  };

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    if (u != null) {
      _nameCtrl.text  = u.name;
      _pinCtrl.text   = u.pin ?? '';
      _emailCtrl.text = u.email ?? '';
      _role   = u.role;
      _active = u.isActive;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _pinCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      _snack('Ism kiritilmagan', error: true);
      return;
    }
    if (_pinCtrl.text.trim().isEmpty && widget.user == null) {
      _snack('PIN kiritilmagan', error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final data = <String, dynamic>{
        'name': _nameCtrl.text.trim(),
        'role': _role,
        if (_pinCtrl.text.isNotEmpty) 'pin': _pinCtrl.text.trim(),
        if (_emailCtrl.text.isNotEmpty) 'email': _emailCtrl.text.trim(),
        if (_passCtrl.text.isNotEmpty) 'password': _passCtrl.text,
        'is_active': _active,
      };

      if (widget.user != null) {
        await ApiClient().put('/users/${widget.user!.id}', data: data);
        _snack('Yangilandi');
      } else {
        await ApiClient().post('/users', data: data);
        _snack('Qo\'shildi');
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _snack(ApiClient.errorMessage(e), error: true);
    } finally {
      setState(() => _saving = false);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? AppColors.danger : AppColors.success,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.user == null
                      ? 'Yangi xodim'
                      : 'Xodimni tahrirlash',
                  style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.muted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _field('Ism *', _nameCtrl, hint: 'Sardor'),
            const SizedBox(height: 12),
            _field('PIN *', _pinCtrl,
                hint: '1234', keyboard: TextInputType.number),
            const SizedBox(height: 12),
            _field('Email', _emailCtrl,
                hint: 'sardor@example.com',
                keyboard: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _field('Parol', _passCtrl,
                hint: widget.user != null
                    ? 'O\'zgartirmaslik uchun bo\'sh qoldiring'
                    : 'Ixtiyoriy',
                obscure: true),
            const SizedBox(height: 16),

            // Rol
            const Text('Rol',
                style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _roles.map((r) {
                final active = r == _role;
                return GestureDetector(
                  onTap: () => setState(() => _role = r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primary
                          : AppColors.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: active
                              ? AppColors.primary
                              : AppColors.border),
                    ),
                    child: Text(
                      _roleLabels[r] ?? r,
                      style: TextStyle(
                        color: active
                            ? AppColors.white
                            : AppColors.muted,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Aktiv
            Row(
              children: [
                const Text('Aktiv',
                    style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600)),
                const Spacer(),
                Switch(
                  value: _active,
                  onChanged: (v) => setState(() => _active = v),
                  activeColor: AppColors.success,
                ),
              ],
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: AppColors.white, strokeWidth: 2))
                    : Text(
                        widget.user == null ? 'Qo\'shish' : 'Saqlash',
                        style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    String? hint,
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          obscureText: obscure,
          style: const TextStyle(color: AppColors.text),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(color: AppColors.border, fontSize: 13),
            filled: true,
            fillColor: AppColors.bg,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }
}
