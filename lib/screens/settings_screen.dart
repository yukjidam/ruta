import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';

/// Settings, reached from the top-right of your own profile.
///
/// Dummy/UI-only for now — each row is a placeholder until the
/// corresponding feature (account, preferences, etc.) is wired up.
/// Grouped the way most riders will scan it: account stuff first, then
/// app behavior, then the destructive log-out action on its own at
/// the bottom.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 20, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: AppColors.darkInk),
                  ),
                  const SizedBox(width: 4),
                  Text('Settings', style: AppText.display(size: 20, color: AppColors.darkInk)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  const _SettingsGroupLabel('Account'),
                  _SettingsTile(
                    icon: Icons.person_outline,
                    label: 'Edit profile',
                    onTap: () {},
                  ),
                  const SizedBox(height: 18),
                  const _SettingsGroupLabel('Preferences'),
                  _SettingsTile(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: () {},
                  ),
                  _SettingsTile(
                    icon: Icons.straighten_outlined,
                    label: 'Units',
                    trailingLabel: 'Kilometers',
                    onTap: () {},
                  ),
                  const SizedBox(height: 18),
                  const _SettingsGroupLabel('Support'),
                  _SettingsTile(
                    icon: Icons.info_outline,
                    label: 'About Ruta',
                    onTap: () => showDialog(
                      context: context,
                      builder: (_) => const _AboutRutaDialog(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _SettingsTile(
                    icon: Icons.logout,
                    label: 'Log out',
                    labelColor: AppColors.rust,
                    iconColor: AppColors.rust,
                    showChevron: false,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsGroupLabel extends StatelessWidget {
  final String text;
  const _SettingsGroupLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
      child:
          Text(text, style: AppText.mono(size: 11, color: AppColors.darkInkDim, letterSpacing: 2)),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? trailingLabel;
  final Color? labelColor;
  final Color? iconColor;
  final bool showChevron;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailingLabel,
    this.labelColor,
    this.iconColor,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.paperLine),
        ),
        child: Row(
          children: [
            Icon(icon, size: 19, color: iconColor ?? AppColors.darkInk),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppText.body(
                    size: 13.5, weight: FontWeight.w600, color: labelColor ?? AppColors.darkInk),
              ),
            ),
            if (trailingLabel != null) ...[
              Text(trailingLabel!, style: AppText.mono(size: 11, color: AppColors.darkInkDim)),
              const SizedBox(width: 6),
            ],
            if (showChevron) const Icon(Icons.chevron_right, size: 18, color: AppColors.darkInkDim),
          ],
        ),
      ),
    );
  }
}

/// The "About Ruta" card — same treatment used across the solo-project
/// apps: app icon × maker's avatar, name, version, a short personal
/// note, and a link back to github.com/yukjidam.
class _AboutRutaDialog extends StatelessWidget {
  const _AboutRutaDialog();

  Future<void> _openGithub() async {
    final uri = Uri.parse('https://github.com/yukjidam');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 36, 28, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _AboutAvatar(
                  size: 68,
                  background: Colors.white,
                  border: AppColors.paperLine,
                  child: SvgPicture.asset(
                    'assets/icon/ruta_icon.svg',
                    width: 40,
                    height: 40,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Text('×',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkInkDim)),
                ),
                _AboutAvatar(
                  size: 68,
                  background: AppColors.paper,
                  border: AppColors.paperLine,
                  // Fetched live from GitHub's avatar-redirect URL, so this
                  // always reflects your current profile photo — no manual
                  // asset updates needed when you change your pfp.
                  child: ClipOval(
                    child: Image.network(
                      'https://github.com/yukjidam.png',
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.person, color: AppColors.darkInkDim, size: 30),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Ruta', style: AppText.display(size: 24, color: AppColors.darkInk)),
            const SizedBox(height: 4),
            Text('v1.0.0', style: AppText.mono(size: 12, color: AppColors.darkInkDim)),
            const SizedBox(height: 20),
            Text(
              'Ruta is a solo project — something I built for fun while '
              'job hunting in my post-graduation days. I wanted a reason to '
              'keep building every day, and riding felt like the right '
              'thing to build around: a place to log your rides, keep track '
              'of your bikes, and ride with your crew.',
              textAlign: TextAlign.center,
              style: AppText.body(size: 13.5, color: AppColors.darkInkDim).copyWith(height: 1.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Made with ☕ and probably too much love for tiny UI details.',
              textAlign: TextAlign.center,
              style: AppText.body(size: 12, color: AppColors.darkInkDim)
                  .copyWith(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20),
            const Divider(color: AppColors.paperLine, height: 1),
            const SizedBox(height: 20),
            InkWell(
              onTap: _openGithub,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: AppColors.route),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.code, size: 16, color: AppColors.route),
                    const SizedBox(width: 8),
                    Text('github.com/yukjidam',
                        style: AppText.mono(
                            size: 12.5, weight: FontWeight.w700, color: AppColors.route)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: AppText.body(size: 13, color: AppColors.darkInkDim)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutAvatar extends StatelessWidget {
  final double size;
  final Color background;
  final Color border;
  final Widget child;

  const _AboutAvatar({
    required this.size,
    required this.background,
    required this.border,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 1.5),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }
}
