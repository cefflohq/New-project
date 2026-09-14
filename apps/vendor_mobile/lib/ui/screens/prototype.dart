import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../shell.dart';
import '../widgets.dart';

Widget _icon(BuildContext context, IconData icon, {Color? color}) =>
    Icon(icon, size: Sizes.icon, color: color ?? context.c.iconColor);

class UiPrototypeScreen extends StatelessWidget {
  const UiPrototypeScreen({super.key, required this.spec});

  final RouteSpec spec;

  @override
  Widget build(BuildContext context) => switch (spec.route) {
    VRoute.riderRegistrationLink => const _InviteLinkScreen(kind: 'Rider'),
    VRoute.helperRegistrationLink => const _InviteLinkScreen(
      kind: 'Team member',
    ),
    VRoute.storefront => const _StorefrontScreen(),
    VRoute.storefrontPreview => const _StorefrontPreviewScreen(),
    VRoute.branding => const _BrandingScreen(),
    VRoute.businessProfile => const _BusinessProfileScreen(),
    VRoute.businessInformation => const _BusinessInformationScreen(),
    VRoute.businessAddress => const _BusinessAddressScreen(),
    VRoute.businessHours => const _BusinessHoursScreen(),
    VRoute.deliverySettings => const _ComingSoonScreen(
      title: 'Delivery settings',
      message: 'Reserved for a later approved delivery settings pass.',
    ),
    VRoute.profile => const _ProfileScreen(),
    VRoute.editProfile => const _EditProfileScreen(),
    VRoute.security => const _SecurityScreen(),
    VRoute.changePassword => const _ChangePasswordScreen(),
    VRoute.notificationSettings => const _NotificationPreferencesScreen(),
    VRoute.language => const _LanguageScreen(),
    VRoute.appearance => const _AppearanceScreen(),
    VRoute.subscription => const _SubscriptionScreen(),
    VRoute.choosePlan => const _ChoosePlanScreen(),
    VRoute.subscriptionCheckout => const _CheckoutScreen(),
    VRoute.paymentSuccess => const _PaymentSuccessScreen(),
    VRoute.subscriptionDetails => const _SubscriptionDetailsScreen(),
    VRoute.helpSupport => const _HelpSupportScreen(),
    VRoute.faq => const _FaqScreen(),
    VRoute.contactSupport => const _ContactSupportScreen(),
    VRoute.privacyPolicy => const _PolicyScreen(title: 'Privacy Policy'),
    VRoute.termsOfService => const _PolicyScreen(title: 'Terms of Service'),
    VRoute.about => const _AboutScreen(),
    VRoute.notificationInbox => const _NotificationInboxScreen(),
    _ => _ComingSoonScreen(
      title: spec.title,
      message: '${spec.id} is in the approved inventory.',
    ),
  };
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.kicker, required this.title, this.subtitle});
  final String kicker;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF102344), Color(0xFF1453B7), Color(0xFF12213E)],
      ),
      borderRadius: BorderRadius.circular(Sizes.cardRadius),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          kicker.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: .6),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: .8,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 23,
            height: 1.12,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .78),
              fontSize: 13.5,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: 14),
        Container(
          width: 34,
          height: 4,
          decoration: BoxDecoration(
            color: CefColors.accent,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ],
    ),
  );
}

class _BusinessProfileScreen extends StatelessWidget {
  const _BusinessProfileScreen();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return PageBody(
      children: [
        CefCard(
          child: Column(
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 38,
                    backgroundColor: Color(0xFF2D13A5),
                    child: Text(
                      'KK',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.business?.name ?? 'Kopi Kita',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'A better delivery day. Today.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 96,
                    child: CefButton(
                      'Edit',
                      secondary: true,
                      onTap: () => app.go(VRoute.businessInformation),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 14),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MiniStat(
                    icon: LucideIcons.package,
                    value: '24',
                    label: 'Products',
                  ),
                  _MiniStat(
                    icon: LucideIcons.shoppingCart,
                    value: '128',
                    label: 'Orders',
                  ),
                  _MiniStat(
                    icon: LucideIcons.star,
                    value: '4.8',
                    label: 'Rating',
                    accent: true,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SectionHeading('Business'),
        FlatListRow(
          title: 'Business Information',
          subtitle: 'Name, contact, description',
          leading: _icon(context, LucideIcons.fileText),
          onTap: () => app.go(VRoute.businessInformation),
        ),
        FlatListRow(
          title: 'Business Address',
          subtitle: 'Store address and service area',
          leading: _icon(context, LucideIcons.mapPin),
          onTap: () => app.go(VRoute.businessAddress),
        ),
        FlatListRow(
          title: 'Business Hours',
          subtitle: 'Set your operating hours',
          leading: _icon(context, LucideIcons.clock),
          onTap: () => app.go(VRoute.businessHours),
        ),
        const SizedBox(height: Gap.md),
        const _HeroPanel(
          kicker: 'Your store is ready',
          title: 'Keep your business information up to date.',
          subtitle: 'A cleaner profile helps every delivery run smoothly.',
        ),
      ],
    );
  }
}

class _BusinessInformationScreen extends StatelessWidget {
  const _BusinessInformationScreen();

  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      const _EditableAvatar(label: 'RUMA\nLIVING'),
      const SizedBox(height: 18),
      const _PrototypeField(label: 'Business Name', value: 'RUMA Living'),
      const _PrototypeField(
        label: 'Tagline (Optional)',
        value: 'A Better Home. Today.',
      ),
      const _PrototypeField(
        label: 'Business Type',
        value: 'Home & Living',
        icon: LucideIcons.package,
        trailing: LucideIcons.chevronDown,
      ),
      const _SplitFields(
        left: '+60',
        right: '12 345 6789',
        label: 'Contact Phone',
      ),
      const _PrototypeField(
        label: 'Business Email',
        value: 'hello@rumaliving.my',
      ),
      const _PrototypeField(
        label: 'Short Description',
        value: 'Modern home essentials for a more comfortable everyday life.',
        lines: 2,
      ),
      const Align(
        alignment: Alignment.centerRight,
        child: Text(
          '53/160',
          style: TextStyle(fontSize: 12, color: Color(0xFF666C80)),
        ),
      ),
      const SizedBox(height: 12),
      CefButton('Save Changes', secondary: true, onTap: () {}),
    ],
  );
}

class _BusinessAddressScreen extends StatelessWidget {
  const _BusinessAddressScreen();

  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      const SearchBarField(hint: 'Search or enter your address'),
      const SizedBox(height: Gap.md),
      Container(
        height: 210,
        decoration: BoxDecoration(
          color: const Color(0xFFEAF0F4),
          borderRadius: BorderRadius.circular(Sizes.cardRadius),
          border: Border.all(color: context.c.border),
        ),
        child: Center(
          child: Stack(
            children: [
              const Center(
                child: Icon(
                  LucideIcons.mapPin,
                  size: 52,
                  color: CefColors.navy,
                ),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(
                    LucideIcons.locateFixed,
                    color: context.c.iconColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: Gap.md),
      const _PrototypeField(
        label: 'Address Line 1',
        value: 'No. 12, Jalan Damai 3',
      ),
      const _PrototypeField(
        label: 'Address Line 2 (Optional)',
        value: 'Taman Melati',
      ),
      const _SplitFields(
        left: '53100',
        right: 'Kuala Lumpur',
        label: 'Postcode                              City',
      ),
      const _PrototypeField(
        label: 'State',
        value: 'Wilayah Persekutuan Kuala Lumpur',
        trailing: LucideIcons.chevronDown,
      ),
      CefButton('Save Address', secondary: true, onTap: () {}),
    ],
  );
}

class _BusinessHoursScreen extends StatelessWidget {
  const _BusinessHoursScreen();

  @override
  Widget build(BuildContext context) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return PageBody(
      children: [
        const _RoundIconHeader(
          icon: LucideIcons.clock3,
          title: 'Operating Hours',
          subtitle: 'Let your customers know when\nyour business is open.',
        ),
        const SizedBox(height: 12),
        for (final day in days)
          _BusinessHourRow(
            day: day,
            enabled: day != 'Sunday',
            close: day == 'Friday' || day == 'Saturday' ? '21:00' : '20:00',
          ),
        const Divider(height: 28),
        const _ActionRowPrototype(
          icon: LucideIcons.copy,
          title: 'Apply to all days',
          subtitle: "Use Monday's hours for all days",
          action: 'Apply',
        ),
        const SizedBox(height: 18),
        CefButton('Save Hours', onTap: () {}),
      ],
    );
  }
}

class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return PageBody(
      children: [
        const _EditableAvatar(label: 'YS'),
        const SizedBox(height: Gap.md),
        Center(
          child: Text(
            'Yusuf Sazali',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Center(
          child: Text(
            'yusuf@kopikita.my',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        FlatListRow(
          title: app.business?.name ?? 'Kopi Kita',
          subtitle: 'Owner',
          leading: _icon(context, LucideIcons.store),
          onTap: () => app.go(VRoute.businessProfile),
        ),
        FlatListRow(
          title: 'Personal Information',
          subtitle: 'Name, phone, email',
          leading: _icon(context, LucideIcons.user),
          onTap: () => app.go(VRoute.editProfile),
        ),
        FlatListRow(
          title: 'Security',
          subtitle: 'Password, biometric & 2FA',
          leading: _icon(context, LucideIcons.lock),
          onTap: () => app.go(VRoute.security),
        ),
        FlatListRow(
          title: 'Language',
          subtitle: 'English',
          leading: _icon(context, LucideIcons.languages),
          onTap: () => app.go(VRoute.language),
        ),
        FlatListRow(
          title: 'Notifications',
          subtitle: 'Manage preferences',
          leading: _icon(context, LucideIcons.bell),
          onTap: () => app.go(VRoute.notificationSettings),
        ),
        FlatListRow(
          title: 'Help & Support',
          subtitle: 'Get help or contact support',
          leading: _icon(context, LucideIcons.circleHelp),
          onTap: () => app.go(VRoute.helpSupport),
        ),
        const SizedBox(height: Gap.md),
        Center(
          child: SizedBox(
            width: 132,
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(LucideIcons.logOut, size: 18),
              label: const Text('Log Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFD73C2B),
                side: const BorderSide(color: Color(0xFFD73C2B)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EditProfileScreen extends StatelessWidget {
  const _EditProfileScreen();

  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      const _EditableAvatar(label: 'YS'),
      const SizedBox(height: 20),
      const _PrototypeField(
        label: 'Full Name',
        value: 'Yusuf Sazali',
        icon: LucideIcons.user,
      ),
      const _SplitFields(
        left: '+60',
        right: '12 345 6789',
        label: 'Phone Number',
      ),
      const _PrototypeField(
        label: 'Email Address',
        value: 'yusuf@rumaliving.my',
        icon: LucideIcons.mail,
        disabled: true,
      ),
      const Text(
        'Email cannot be changed. Please contact support if needed.',
        style: TextStyle(fontSize: 11.5, color: Color(0xFF7A8194)),
      ),
      const SizedBox(height: 14),
      const _PrototypeField(
        label: 'Role',
        value: 'Owner',
        icon: LucideIcons.briefcase,
        disabled: true,
      ),
      const Text(
        'Managed by your business.',
        style: TextStyle(fontSize: 11.5, color: Color(0xFF7A8194)),
      ),
      const SizedBox(height: 24),
      CefButton('Save Changes', onTap: () {}),
    ],
  );
}

class _SecurityScreen extends StatelessWidget {
  const _SecurityScreen();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return PageBody(
      children: [
        const _RoundIconHeader(
          icon: LucideIcons.shield,
          title: 'Keep your account safe',
          subtitle:
              'Manage your security settings and\nprotect your business data.',
        ),
        const SizedBox(height: 14),
        FlatListRow(
          title: 'Password',
          subtitle: 'Update your password regularly',
          leading: _icon(context, LucideIcons.lock),
          onTap: () => app.go(VRoute.changePassword),
        ),
        FlatListRow(
          title: 'Biometric Login',
          subtitle: 'Use Face ID or Touch ID',
          leading: _icon(context, LucideIcons.fingerprint),
          trailing: CefSwitch(value: true, onChanged: (_) {}),
        ),
        FlatListRow(
          title: 'Two-Factor Authentication',
          subtitle: 'Coming soon',
          leading: _icon(context, LucideIcons.smartphone),
          trailing: const StatusChip('Off'),
        ),
        FlatListRow(
          title: 'Active Sessions',
          subtitle: 'Manage your logged in devices',
          leading: _icon(context, LucideIcons.laptop),
          onTap: () {},
        ),
        const SizedBox(height: Gap.md),
        const _HeroPanel(
          kicker: 'Your security is important',
          title:
              'These settings help keep your account and business data safe.',
        ),
      ],
    );
  }
}

class _ChangePasswordScreen extends StatelessWidget {
  const _ChangePasswordScreen();

  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      const _RoundIconHeader(
        icon: LucideIcons.lock,
        title: 'Set a new password',
        subtitle: 'Use a strong password to keep\nyour account secure.',
      ),
      const SizedBox(height: 18),
      const _PrototypeField(
        label: 'Current Password',
        value: 'Enter current password',
        icon: LucideIcons.lock,
        trailing: LucideIcons.eyeOff,
      ),
      const _PrototypeField(
        label: 'New Password',
        value: 'Enter new password',
        icon: LucideIcons.lock,
        trailing: LucideIcons.eye,
      ),
      const _Requirement('Minimum 8 characters'),
      const _Requirement('Include at least one letter and one number'),
      const _Requirement(r'Include one special character (e.g. ! @ # $)'),
      const SizedBox(height: 14),
      const _PrototypeField(
        label: 'Confirm New Password',
        value: 'Confirm new password',
        icon: LucideIcons.lock,
        trailing: LucideIcons.eyeOff,
      ),
      const SizedBox(height: 24),
      CefButton(
        'Update Password',
        onTap: () => runAsyncFeedback(
          context,
          action: () async {},
          processingTitle: 'Processing...',
          processingSubtitle: 'Updating your password',
          successTitle: 'Successful',
          successSubtitle: 'Your password has been updated successfully.',
        ),
      ),
    ],
  );
}

class _NotificationPreferencesScreen extends StatelessWidget {
  const _NotificationPreferencesScreen();

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('New Orders', 'Get notified when new orders come in.'),
      ('Order Updates', 'Status changes and delivery progress.'),
      ('Run Updates', 'When runs are dispatched or completed.'),
      ('Delivery Issues', 'Get notified about delivery issues.'),
      ('Rider Updates', 'When riders go online/offline.'),
      ('Team Activity', 'New team members or role changes.'),
      ('Important Updates', 'Account, billing and system announcements.'),
    ];
    return PageBody(
      children: [
        const _RoundIconHeader(
          icon: LucideIcons.bell,
          title: 'Stay in the loop',
          subtitle: 'Get notified about what matters to your business.',
        ),
        const _PreferenceLabel('ORDERS'),
        for (final row in rows.take(2))
          FlatListRow(
            title: row.$1,
            subtitle: row.$2,
            leading: _icon(context, LucideIcons.bell),
            trailing: CefSwitch(
              value: row.$1 != 'Team Activity',
              onChanged: (_) {},
            ),
          ),
        const _PreferenceLabel('DELIVERY & RUNS'),
        for (final row in rows.skip(2).take(2))
          FlatListRow(
            title: row.$1,
            subtitle: row.$2,
            leading: _icon(
              context,
              row.$1 == 'Run Updates'
                  ? LucideIcons.truck
                  : LucideIcons.triangleAlert,
            ),
            trailing: CefSwitch(value: true, onChanged: (_) {}),
          ),
        const _PreferenceLabel('RIDERS & TEAM'),
        for (final row in rows.skip(4).take(2))
          FlatListRow(
            title: row.$1,
            subtitle: row.$2,
            leading: _icon(
              context,
              row.$1 == 'Rider Updates'
                  ? LucideIcons.users
                  : LucideIcons.userPlus,
            ),
            trailing: CefSwitch(
              value: row.$1 != 'Team Activity',
              onChanged: (_) {},
            ),
          ),
        const _PreferenceLabel('ACCOUNT & SYSTEM'),
        FlatListRow(
          title: rows.last.$1,
          subtitle: rows.last.$2,
          leading: _icon(context, LucideIcons.settings),
          trailing: CefSwitch(value: true, onChanged: (_) {}),
        ),
      ],
    );
  }
}

class _LanguageScreen extends StatelessWidget {
  const _LanguageScreen();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    const langs = [
      ('English', 'Default language'),
      ('Bahasa Melayu', 'Bahasa utama anda'),
      ('中文（简体）', '简体中文'),
      ('தமிழ்', 'உங்கள் விருப்ப மொழி'),
    ];
    return PageBody(
      children: [
        Opacity(
          opacity: .45,
          child: const _HeroPanel(
            kicker: 'Your app, your way',
            title: 'Simple settings for a smoother experience.',
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: cefCardShadow(Brightness.light),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFABB2C2),
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Select Language',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              for (final lang in langs)
                FlatListRow(
                  title: lang.$1,
                  subtitle: lang.$2,
                  trailing: lang.$1 == 'English'
                      ? Icon(LucideIcons.circleDot, color: context.c.info)
                      : Icon(
                          LucideIcons.circle,
                          color: context.c.textSecondary,
                        ),
                  onTap: () => app.setLocale(lang.$1),
                ),
              const SizedBox(height: 14),
              CefButton('Confirm', onTap: () {}),
            ],
          ),
        ),
      ],
    );
  }
}

class _AppearanceScreen extends StatelessWidget {
  const _AppearanceScreen();

  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      const _RoundIconHeader(
        icon: LucideIcons.penLine,
        title: 'Coming Soon',
        subtitle: 'Appearance settings will be available\nin a future update.',
      ),
      const SizedBox(height: 20),
      const _HeroPanel(
        kicker: 'Same operations. A brighter experience ahead.',
        title: 'More ways\nto make it yours.',
      ),
      const SizedBox(height: 16),
      FlatListRow(
        title: 'Theme Options',
        subtitle: 'Light, dark and system theme.',
        leading: _icon(context, LucideIcons.sun),
      ),
      FlatListRow(
        title: 'App Appearance',
        subtitle: 'Customize colours and style.',
        leading: _icon(context, LucideIcons.palette),
      ),
      FlatListRow(
        title: 'Display Preferences',
        subtitle: 'Adjust display settings to your liking.',
        leading: _icon(context, LucideIcons.slidersHorizontal),
      ),
    ],
  );
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
    this.accent = false,
  });
  final IconData icon;
  final String value;
  final String label;
  final bool accent;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, size: 20, color: accent ? CefColors.accent : CefColors.navy),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10.5),
      ),
    ],
  );
}

class _EditableAvatar extends StatelessWidget {
  const _EditableAvatar({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Center(
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 50,
          backgroundColor: CefColors.navy,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
        const Positioned(
          right: -3,
          bottom: 2,
          child: CircleAvatar(
            radius: 17,
            backgroundColor: Colors.white,
            child: Icon(LucideIcons.camera, size: 18, color: CefColors.navy),
          ),
        ),
      ],
    ),
  );
}

class _PrototypeField extends StatelessWidget {
  const _PrototypeField({
    required this.label,
    required this.value,
    this.icon,
    this.trailing,
    this.lines = 1,
    this.disabled = false,
  });
  final String label;
  final String value;
  final IconData? icon;
  final IconData? trailing;
  final int lines;
  final bool disabled;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            color: CefColors.navy,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          constraints: BoxConstraints(minHeight: lines > 1 ? 62 : 48),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          decoration: BoxDecoration(
            color: disabled ? const Color(0xFFF0F1F5) : const Color(0xFFF8F9FB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFDDE1EA)),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: CefColors.navy),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  value,
                  maxLines: lines,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: disabled ? const Color(0xFF8A90A0) : CefColors.navy,
                  ),
                ),
              ),
              if (trailing != null)
                Icon(trailing, size: 18, color: CefColors.navy),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SplitFields extends StatelessWidget {
  const _SplitFields({
    required this.left,
    required this.right,
    required this.label,
  });
  final String left;
  final String right;
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 13),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            color: CefColors.navy,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(flex: 2, child: _FieldBox(left)),
            const SizedBox(width: 10),
            Expanded(flex: 4, child: _FieldBox(right)),
          ],
        ),
      ],
    ),
  );
}

class _FieldBox extends StatelessWidget {
  const _FieldBox(this.value);
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    height: 48,
    padding: const EdgeInsets.symmetric(horizontal: 13),
    alignment: Alignment.centerLeft,
    decoration: BoxDecoration(
      color: const Color(0xFFF8F9FB),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFDDE1EA)),
    ),
    child: Text(
      value,
      style: const TextStyle(fontSize: 13.5, color: CefColors.navy),
    ),
  );
}

class _RoundIconHeader extends StatelessWidget {
  const _RoundIconHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      CircleAvatar(
        radius: 39,
        backgroundColor: const Color(0xFFF1F3F7),
        child: Icon(icon, size: 38, color: CefColors.navy),
      ),
      const SizedBox(height: 12),
      Text(
        title,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 5),
      Text(
        subtitle,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ],
  );
}

class _BusinessHourRow extends StatelessWidget {
  const _BusinessHourRow({
    required this.day,
    required this.enabled,
    required this.close,
  });
  final String day;
  final bool enabled;
  final String close;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 54,
    child: Row(
      children: [
        SizedBox(
          width: 78,
          child: Text(
            day,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
        ),
        Transform.scale(
          scale: .8,
          child: CefSwitch(value: enabled, onChanged: (_) {}),
        ),
        if (enabled) ...[
          const Expanded(child: _FieldBox('08:00')),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text('–'),
          ),
          Expanded(child: _FieldBox(close)),
        ] else
          const Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 10),
              child: Text('Closed', style: TextStyle(color: Color(0xFF7A8194))),
            ),
          ),
      ],
    ),
  );
}

class _ActionRowPrototype extends StatelessWidget {
  const _ActionRowPrototype({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String action;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: CefColors.navy),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
      OutlinedButton(onPressed: () {}, child: Text(action)),
    ],
  );
}

class _Requirement extends StatelessWidget {
  const _Requirement(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        const Icon(LucideIcons.circle, size: 14, color: Color(0xFFB1B7C5)),
        const SizedBox(width: 8),
        Text(text, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class _PreferenceLabel extends StatelessWidget {
  const _PreferenceLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 4),
    child: Text(
      text,
      style: const TextStyle(
        color: Color(0xFF6D7890),
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: .4,
      ),
    ),
  );
}

class _StorefrontScreen extends StatelessWidget {
  const _StorefrontScreen();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return PageBody(
      children: [
        const _HeroPanel(
          kicker: 'Storefront',
          title: 'Your delivery page, kept simple.',
          subtitle: 'Prototype only — live ordering setup comes later.',
        ),
        const SectionHeading('Manage'),
        FlatListRow(
          title: 'Preview storefront',
          subtitle: 'See customer-facing layout',
          leading: _icon(context, LucideIcons.eye),
          onTap: () => app.go(VRoute.storefrontPreview),
        ),
        FlatListRow(
          title: 'Branding',
          subtitle: 'Logo and display style',
          leading: _icon(context, LucideIcons.palette),
          onTap: () => app.go(VRoute.branding),
        ),
        FlatListRow(
          title: 'Products',
          subtitle: 'Manage catalog items',
          leading: _icon(context, LucideIcons.package),
          onTap: () => app.go(VRoute.products),
        ),
      ],
    );
  }
}

class _StorefrontPreviewScreen extends StatelessWidget {
  const _StorefrontPreviewScreen();

  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      const _HeroPanel(
        kicker: 'Kopi Kita',
        title: 'Order ahead for smoother delivery.',
      ),
      const SectionHeading('Featured items'),
      FlatListRow(
        title: 'Chocolate Cake',
        subtitle: 'RM12.00',
        leading: _icon(context, LucideIcons.cake),
      ),
      FlatListRow(
        title: 'Matcha Latte',
        subtitle: 'RM9.50',
        leading: _icon(context, LucideIcons.coffee),
      ),
      FlatListRow(
        title: 'Croissant',
        subtitle: 'RM7.00',
        leading: _icon(context, LucideIcons.cookie),
      ),
      const SizedBox(height: Gap.section),
      CefButton(
        'Customer ordering is not active',
        secondary: true,
        onTap: () {},
      ),
    ],
  );
}

class _SubscriptionScreen extends StatelessWidget {
  const _SubscriptionScreen();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return PageBody(
      children: [
        const _HeroPanel(
          kicker: 'Plans that grow with you',
          title: 'Choose how you operate.',
          subtitle: 'Simple plans for every stage of your delivery business.',
        ),
        const SectionHeading('Your plan'),
        _PlanCard(
          name: 'Operate',
          price: 'RM2,190',
          description: 'More power to grow your deliveries.',
          active: true,
          onTap: () => app.go(VRoute.subscriptionDetails),
        ),
        const SizedBox(height: Gap.md),
        CefButton('View all plans', onTap: () => app.go(VRoute.choosePlan)),
      ],
    );
  }
}

class _ChoosePlanScreen extends StatelessWidget {
  const _ChoosePlanScreen();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return PageBody(
      children: [
        Text('Choose your plan', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 5),
        Text(
          'Pick the plan that fits your business today.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: Gap.section),
        _PlanCard(
          name: 'Start',
          price: 'RM790',
          description: 'For new businesses starting local delivery.',
          onTap: () => app.go(VRoute.subscriptionCheckout),
        ),
        const SizedBox(height: Gap.md),
        _PlanCard(
          name: 'Operate',
          price: 'RM2,190',
          description: 'For growing businesses with higher volume.',
          recommended: true,
          onTap: () => app.go(VRoute.subscriptionCheckout),
        ),
        const SizedBox(height: Gap.md),
        _PlanCard(
          name: 'Scale',
          price: 'Let’s talk',
          description: 'For larger teams and complex operations.',
          onTap: () {},
        ),
      ],
    );
  }
}

class _CheckoutScreen extends StatelessWidget {
  const _CheckoutScreen();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return PageBody(
      children: [
        Text('Review & pay', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 5),
        Text(
          'Confirm your plan and payment details.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SectionHeading('Plan summary'),
        const _PlanSummaryCard(),
        const SectionHeading('Payment method'),
        CefCard(
          child: Row(
            children: [
              _icon(context, LucideIcons.creditCard),
              const SizedBox(width: Gap.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Visa ending 4242',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 3),
                    Text('Expires 10/28'),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight),
            ],
          ),
        ),
        const SectionHeading('Billing details'),
        const _PrototypeField(label: 'Business name', value: 'Kopi Kita'),
        const _PrototypeField(
          label: 'Billing email',
          value: 'yusuf@cefflo.com',
        ),
        const SizedBox(height: Gap.sm),
        CefButton('Pay RM2,190', onTap: () => app.go(VRoute.paymentSuccess)),
        const SizedBox(height: Gap.sm),
        Text(
          'Prototype only — no payment will be processed.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _PaymentSuccessScreen extends StatelessWidget {
  const _PaymentSuccessScreen();

  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      const SizedBox(height: 24),
      const Center(child: _SuccessMark()),
      const SizedBox(height: 20),
      Text(
        'Subscription Activated',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 6),
      Text(
        'You’re all set! Your business is now on Operate plan.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: Gap.section),
      const _PlanSummaryCard(active: true),
      const SizedBox(height: Gap.md),
      const _InfoLine(
        icon: LucideIcons.calendarDays,
        label: 'Next renewal date',
        value: '12 Oct 2025',
      ),
      const _InfoLine(
        icon: LucideIcons.fileText,
        label: 'Receipt sent to',
        value: 'yusuf@cefflo.com',
      ),
      const SizedBox(height: 28),
      CefButton(
        'Continue to Cefflo',
        onTap: () => AppScope.read(context).resetTo(VRoute.today),
      ),
    ],
  );
}

class _SubscriptionDetailsScreen extends StatelessWidget {
  const _SubscriptionDetailsScreen();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return PageBody(
      children: [
        const _PlanSummaryCard(active: true),
        const SizedBox(height: Gap.md),
        CefCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(LucideIcons.chartNoAxesColumnIncreasing),
                  SizedBox(width: Gap.sm),
                  Text(
                    'Order Usage',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  Spacer(),
                  Text(
                    '1,240 / 5,000',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: const LinearProgressIndicator(
                  value: .248,
                  minHeight: 10,
                  color: Color(0xFF1672E8),
                  backgroundColor: Color(0xFFE3E8F0),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '3,760 remaining this year',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.md),
        const _InfoLine(
          icon: LucideIcons.clipboardList,
          label: 'Plan Details',
          value: 'View features and limits',
          chevron: true,
        ),
        const _InfoLine(
          icon: LucideIcons.creditCard,
          label: 'Payment Method',
          value: '•••• 4242',
          chevron: true,
        ),
        const _InfoLine(
          icon: LucideIcons.fileText,
          label: 'Billing History',
          value: 'View past invoices',
          chevron: true,
        ),
        const SizedBox(height: Gap.md),
        CefCard(
          child: Row(
            children: [
              _icon(context, LucideIcons.arrowRightLeft),
              const SizedBox(width: Gap.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Need to make changes?',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 3),
                    Text('Upgrade, downgrade or switch plans anytime.'),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight),
            ],
          ),
        ),
        const SizedBox(height: Gap.section),
        CefButton('Change Plan', onTap: () => app.go(VRoute.choosePlan)),
      ],
    );
  }
}

class _HelpSupportScreen extends StatelessWidget {
  const _HelpSupportScreen();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return PageBody(
      children: [
        const _HeroPanel(
          kicker: 'We’re here to help',
          title: 'How can we help?',
        ),
        const SizedBox(height: Gap.md),
        SearchBarField(
          hint: 'Search for help, articles or topics...',
          onFilter: () {},
        ),
        const SizedBox(height: Gap.md),
        Row(
          children: [
            Expanded(
              child: _SupportTile(
                icon: LucideIcons.bookOpen,
                title: 'Help Centre',
                subtitle: 'Browse articles, guides and FAQs',
                onTap: () => app.go(VRoute.faq),
              ),
            ),
            const SizedBox(width: Gap.md),
            Expanded(
              child: _SupportTile(
                icon: LucideIcons.messageCircle,
                title: 'Contact Support',
                subtitle: 'Chat or send a support request',
                onTap: () => app.go(VRoute.contactSupport),
              ),
            ),
          ],
        ),
        const SectionHeading('Popular Topics'),
        for (final row in const [
          (
            'Account & Security',
            'Login, profile, security settings',
            LucideIcons.circleUserRound,
          ),
          (
            'Orders & Delivery',
            'Order management, delivery issues',
            LucideIcons.truck,
          ),
          (
            'Riders & Team',
            'Rider invites, approvals, team access',
            LucideIcons.users,
          ),
          (
            'Subscription & Billing',
            'Plans, payments, invoices',
            LucideIcons.calendarDays,
          ),
          ('App Guides', 'Step-by-step tutorials', LucideIcons.bookOpen),
        ])
          FlatListRow(
            title: row.$1,
            subtitle: row.$2,
            leading: _icon(context, row.$3),
          ),
      ],
    );
  }
}

class _FaqScreen extends StatelessWidget {
  const _FaqScreen();

  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      const _HeroPanel(
        kicker: 'How can we help?',
        title: 'Find answers',
        subtitle: 'Search our help centre or browse topics below.',
      ),
      const SizedBox(height: Gap.md),
      SearchBarField(
        hint: 'Search for help, e.g. zones, riders...',
        onFilter: () {},
      ),
      const SizedBox(height: Gap.md),
      for (final row in const [
        ('Getting Started', 'Set up your account and business'),
        ('Orders & Delivery', 'Manage orders, runs and zones'),
        ('Zones & Riders', 'Coverage, riders and dispatch'),
        ('Account', 'Profile, security and settings'),
        ('Subscription & Billing', 'Plans, payments and invoices'),
      ])
        FlatListRow(
          title: row.$1,
          subtitle: row.$2,
          leading: _icon(
            context,
            row.$1 == 'Orders & Delivery'
                ? LucideIcons.truck
                : row.$1 == 'Zones & Riders'
                ? LucideIcons.users
                : row.$1 == 'Subscription & Billing'
                ? LucideIcons.calendarDays
                : LucideIcons.bookOpen,
          ),
        ),
      SectionHeading(
        'Popular Questions',
        trailing: TextButton(onPressed: () {}, child: const Text('View All')),
      ),
      for (final question in const [
        'How do I create a delivery zone?',
        'How do I add a rider?',
        'Can I change my plan later?',
        'How does route optimization work?',
        'Where can my customers track their orders?',
      ])
        FlatListRow(title: question),
    ],
  );
}

class _ContactSupportScreen extends StatelessWidget {
  const _ContactSupportScreen();

  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      const _HeroPanel(
        kicker: 'We’re here to help',
        title: 'Get in touch',
        subtitle: 'Tell us about your issue and our team will get back to you.',
      ),
      const SizedBox(height: Gap.md),
      const _PrototypeField(
        label: 'Issue Category',
        value: 'Select a category',
        trailing: LucideIcons.chevronDown,
      ),
      const _PrototypeField(
        label: 'Subject',
        value: 'Briefly describe your issue',
      ),
      const _MessageField(),
      Text(
        'Add Screenshots (Optional)',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      const SizedBox(height: 7),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          border: Border.all(color: context.c.border),
          borderRadius: BorderRadius.circular(Sizes.inputRadius),
        ),
        child: const Column(
          children: [
            Icon(LucideIcons.image),
            SizedBox(height: 6),
            Text(
              'Tap to attach images',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            Text('PNG, JPG up to 10MB each'),
          ],
        ),
      ),
      const SizedBox(height: Gap.md),
      const _PrototypeField(label: 'Contact Email', value: 'yusuf@cefflo.com'),
      const SizedBox(height: Gap.md),
      CefButton(
        'Send Request',
        onTap: () => runAsyncFeedback(
          context,
          action: () async {},
          processingTitle: 'Processing...',
          processingSubtitle: 'Sending your request',
          successTitle: 'Successful',
          successSubtitle: 'Your support request has been sent.',
        ),
      ),
      const SizedBox(height: Gap.sm),
      Text(
        'ⓘ Our support team will get back to you as soon as possible.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

class _PolicyScreen extends StatelessWidget {
  const _PolicyScreen({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      _HeroPanel(
        kicker: 'Trust & Transparency',
        title: title,
        subtitle: title == 'Privacy Policy'
            ? 'We’re committed to protecting your data and your privacy.'
            : 'The terms that guide your use of Cefflo.',
      ),
      const SizedBox(height: Gap.sm),
      Text(
        'Last updated: 12 Sep 2025',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: Gap.md),
      CefCard(
        child: Text(
          title == 'Privacy Policy'
              ? 'On this page\n\n1.  Introduction\n2.  Information We Collect\n3.  How We Use Your Information\n4.  Data Sharing\n5.  Data Security\n6.  Your Rights\n7.  Cookies and Tracking Technologies\n8.  Changes to This Policy\n9.  Contact Us'
              : 'On this page\n\n1.  Acceptance of Terms\n2.  Account Responsibilities\n3.  Acceptable Use\n4.  Subscription and Billing\n5.  Intellectual Property\n6.  Service Availability\n7.  Limitation of Liability\n8.  Changes to These Terms\n9.  Contact Us',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
      SectionHeading(
        title == 'Privacy Policy'
            ? '1. Introduction'
            : '1. Acceptance of Terms',
      ),
      Text(
        title == 'Privacy Policy'
            ? 'Cefflo (“we”, “us” or “our”) values your privacy. This policy explains how we collect, use, disclose and safeguard your information when you use our services.'
            : 'By accessing or using Cefflo, you agree to these terms and to use the service responsibly in accordance with applicable laws.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      SectionHeading(
        title == 'Privacy Policy'
            ? '2. Information We Collect'
            : '2. Account Responsibilities',
      ),
      Text(
        title == 'Privacy Policy'
            ? 'We collect information that you provide directly to us, together with limited operational data needed to deliver and improve the service.'
            : 'You are responsible for maintaining accurate account information and protecting access to your account.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    ],
  );
}

class _AboutScreen extends StatelessWidget {
  const _AboutScreen();

  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      const SizedBox(height: 20),
      const Center(
        child: CircleAvatar(
          radius: 42,
          backgroundColor: Color(0xFF102344),
          child: Text(
            'C',
            style: TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
      const SizedBox(height: 15),
      Text(
        'Cefflo',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      const SizedBox(height: 4),
      Text(
        'More orders. Less work. A smoother delivery day.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: Gap.section),
      const _HeroPanel(
        kicker: 'Our purpose',
        title: 'Operate Today. Grow Tomorrow.',
        subtitle:
            'A local same-day delivery operating system built for businesses.',
      ),
      const SectionHeading('App information'),
      const _InfoLine(
        icon: LucideIcons.smartphone,
        label: 'Version',
        value: '1.0.0',
      ),
      const _InfoLine(
        icon: LucideIcons.shieldCheck,
        label: 'Privacy Policy',
        value: 'Read policy',
        chevron: true,
      ),
      const _InfoLine(
        icon: LucideIcons.fileText,
        label: 'Terms of Service',
        value: 'Read terms',
        chevron: true,
      ),
      const SizedBox(height: Gap.section),
      Text(
        '© 2025 Cefflo. All rights reserved.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.name,
    required this.price,
    required this.description,
    required this.onTap,
    this.active = false,
    this.recommended = false,
  });
  final String name, price, description;
  final VoidCallback onTap;
  final bool active, recommended;

  @override
  Widget build(BuildContext context) => CefCard(
    selected: recommended,
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(name, style: Theme.of(context).textTheme.titleLarge),
            if (active || recommended) ...[
              const SizedBox(width: 9),
              Text(
                active ? 'Active' : 'Recommended',
                style: TextStyle(
                  color: active
                      ? const Color(0xFF0F9B51)
                      : const Color(0xFF0A63CE),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const Spacer(),
            Text(price, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          price.startsWith('RM') ? 'Annual Plan · per year' : 'Custom plan',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 13),
        Text(description, style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  );
}

class _PlanSummaryCard extends StatelessWidget {
  const _PlanSummaryCard({this.active = false});
  final bool active;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF102344), Color(0xFF075EC8), Color(0xFF112342)],
      ),
      borderRadius: BorderRadius.circular(Sizes.cardRadius),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Operate',
              style: TextStyle(
                color: Colors.white,
                fontSize: 23,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (active) ...[
              const SizedBox(width: 9),
              const Text(
                'Active',
                style: TextStyle(
                  color: Color(0xFF35D878),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const Spacer(),
            const Text(
              'RM2,190',
              style: TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Text(
              'Annual Plan',
              style: TextStyle(color: Colors.white.withValues(alpha: .8)),
            ),
            const Spacer(),
            Text(
              'per year',
              style: TextStyle(color: Colors.white.withValues(alpha: .8)),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: Text(
                'For growing businesses\nwith higher volume.',
                style: TextStyle(color: Colors.white.withValues(alpha: .85)),
              ),
            ),
            Text(
              'Renews on\n12 Oct 2025',
              textAlign: TextAlign.right,
              style: TextStyle(color: Colors.white.withValues(alpha: .85)),
            ),
          ],
        ),
      ],
    ),
  );
}

class _SuccessMark extends StatelessWidget {
  const _SuccessMark();
  @override
  Widget build(BuildContext context) => Container(
    width: 92,
    height: 92,
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: Color(0xFFF0F8F3),
    ),
    child: const Center(
      child: CircleAvatar(
        radius: 31,
        backgroundColor: Color(0xFF16AD55),
        child: Icon(LucideIcons.check, color: Colors.white, size: 34),
      ),
    ),
  );
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
    this.chevron = false,
  });
  final IconData icon;
  final String label, value;
  final bool chevron;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 13),
    child: Row(
      children: [
        Icon(icon, size: Sizes.icon),
        const SizedBox(width: Gap.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
              if (chevron) ...[
                const SizedBox(height: 3),
                Text(value, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
        if (chevron)
          const Icon(LucideIcons.chevronRight)
        else
          Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
      ],
    ),
  );
}

class _SupportTile extends StatelessWidget {
  const _SupportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => CefCard(
    onTap: onTap,
    child: SizedBox(
      height: 112,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF086BE3)),
          const Spacer(),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );
}

class _MessageField extends StatelessWidget {
  const _MessageField();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Gap.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Message', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 7),
        Container(
          height: 108,
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: context.c.card,
            border: Border.all(color: context.c.border),
            borderRadius: BorderRadius.circular(Sizes.inputRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tell us more about your issue...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: Text(
                  '0/500',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _NotificationInboxScreen extends StatelessWidget {
  const _NotificationInboxScreen();

  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      FlatListRow(
        title: '3 orders need your action',
        subtitle: 'Review issues before dispatch.',
        leading: _icon(context, LucideIcons.bell),
      ),
      FlatListRow(
        title: 'Rider update',
        subtitle: 'Ahmad Razi is online.',
        leading: _icon(context, LucideIcons.users),
      ),
      FlatListRow(
        title: 'System update',
        subtitle: 'Everything is operating normally.',
        leading: _icon(context, LucideIcons.info),
      ),
    ],
  );
}

/// V-22 / V-25 — Rider/Team invitation link. Vendor shares a trusted-link
/// invitation; it never collects the invitee's profile directly.
class _InviteLinkScreen extends StatelessWidget {
  const _InviteLinkScreen({required this.kind});
  final String kind;

  void _copyLink(BuildContext context, String link) {
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Link copied')));
  }

  void _showQrSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(Sizes.cardRadius),
        ),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(Gap.section),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$kind${kind.endsWith('s') ? '' : 's'} can scan this code',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: Gap.section),
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Sizes.cardRadius),
                border: Border.all(color: context.c.border),
              ),
              child: Icon(
                LucideIcons.qrCode,
                size: 140,
                color: context.c.textPrimary,
              ),
            ),
            const SizedBox(height: Gap.section),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final link =
        'https://cefflo.app/${kind == 'Rider' ? 'team' : 'join'}/AB3K9D';
    return PageBody(
      children: [
        Center(
          child: Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFE9EEF7),
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.userPlus, size: 28, color: CefColors.navy),
          ),
        ),
        const SizedBox(height: Gap.md),
        Text(
          kind == 'Rider'
              ? 'Invite Riders to Your Business'
              : 'Invite a Team Member',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: Gap.xs),
        Text(
          kind == 'Rider'
              ? 'Share this link with your riders so they can join your '
                    'team. They\'ll complete their own profile, vehicle and '
                    'documents.'
              : 'Give access to your team so they can help run your '
                    'deliveries, manage orders and more.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: Gap.section),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Gap.cardPadding),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF102344), Color(0xFF1453B7), Color(0xFF12213E)],
            ),
            borderRadius: BorderRadius.circular(Sizes.cardRadius),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.link, size: 18, color: Colors.white),
                  const SizedBox(width: Gap.sm),
                  Text(
                    'Your Invitation Link',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Gap.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(Sizes.inputRadius),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        link,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: Gap.sm),
                    GestureDetector(
                      onTap: () => _copyLink(context, link),
                      child: Icon(
                        LucideIcons.copy,
                        size: 18,
                        color: context.c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Gap.sm),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _copyLink(context, link),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: CefColors.navy,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(Sizes.buttonRadius),
                    ),
                  ),
                  child: const Text(
                    'Copy Link',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.cardGap),
        FlatListRow(
          title: 'Show QR Code',
          subtitle: '$kind${kind.endsWith('s') ? '' : 's'} can scan this code',
          leading: Icon(
            LucideIcons.qrCode,
            size: Sizes.icon,
            color: context.c.info,
          ),
          onTap: () => _showQrSheet(context),
        ),
        const SizedBox(height: Gap.section),
        const SectionHeading('Share via'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ShareChannel(
              icon: LucideIcons.messageCircle,
              label: 'WhatsApp',
              color: const Color(0xFF25D366),
              onTap: () => _copyLink(context, link),
            ),
            _ShareChannel(
              icon: LucideIcons.send,
              label: 'Telegram',
              color: const Color(0xFF29A9EA),
              onTap: () => _copyLink(context, link),
            ),
            _ShareChannel(
              icon: LucideIcons.messageSquare,
              label: 'SMS',
              color: const Color(0xFF34C759),
              onTap: () => _copyLink(context, link),
            ),
            _ShareChannel(
              icon: LucideIcons.ellipsis,
              label: 'More',
              color: const Color(0xFFE9ECF2),
              iconColor: context.c.textSecondary,
              onTap: () => _copyLink(context, link),
            ),
          ],
        ),
        const SizedBox(height: Gap.section),
        CefCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.info, size: 18, color: context.c.info),
              const SizedBox(width: Gap.sm),
              Expanded(
                child: Text(
                  kind == 'Rider'
                      ? 'Invited riders will appear in your Riders list '
                            'once they accept and complete their '
                            'registration.'
                      : 'Invited team members will appear in your Team '
                            'list once they accept and complete their '
                            'registration.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.section),
        CefButton('Share Invite', onTap: () => _copyLink(context, link)),
      ],
    );
  }
}

class _ShareChannel extends StatelessWidget {
  const _ShareChannel({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.iconColor,
  });
  final IconData icon;
  final String label;
  final Color color;
  final Color? iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, size: 22, color: iconColor ?? Colors.white),
        ),
        const SizedBox(height: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

/// V-33 — Branding. Storefront identity only: logo, tagline and an accent
/// colour choice, with a small live preview.
class _BrandingScreen extends StatefulWidget {
  const _BrandingScreen();
  @override
  State<_BrandingScreen> createState() => _BrandingScreenState();
}

class _BrandingScreenState extends State<_BrandingScreen> {
  final tagline = TextEditingController(text: 'A better delivery day. Today.');
  int colorIndex = 0;

  static const _colors = [
    CefColors.navy,
    Color(0xFF0F766E),
    Color(0xFF9333EA),
    Color(0xFFB45309),
    Color(0xFF1D4ED8),
  ];

  @override
  void dispose() {
    tagline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final accent = _colors[colorIndex];
    return PageBody(
      children: [
        _EditableAvatar(
          label: (app.business?.name ?? 'Kopi Kita')
              .substring(0, 2)
              .toUpperCase(),
        ),
        const SizedBox(height: 20),
        _PrototypeField(label: 'Tagline', value: tagline.text),
        Text('Accent Colour', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: Gap.xs),
        Row(
          children: [
            for (final (index, color) in _colors.indexed)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => setState(() => colorIndex = index),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: colorIndex == index
                          ? Border.all(color: Colors.black, width: 2)
                          : null,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: Gap.section),
        const SectionHeading('Live preview'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(Sizes.cardRadius),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white.withValues(alpha: .22),
                child: Text(
                  (app.business?.name ?? 'Kopi Kita').substring(0, 1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: Gap.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.business?.name ?? 'Kopi Kita',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      tagline.text,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .85),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.section),
        CefButton(
          'Save',
          onTap: () => runAsyncFeedback(
            context,
            action: () async {},
            processingTitle: 'Processing...',
            processingSubtitle: 'Saving your branding',
            successTitle: 'Successful',
            successSubtitle: 'Your branding has been updated successfully.',
          ),
        ),
      ],
    );
  }
}

class _ComingSoonScreen extends StatelessWidget {
  const _ComingSoonScreen({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      StateBlock.blocked(message),
      const SizedBox(height: Gap.md),
      CefButton(
        'Back to Menu',
        secondary: true,
        onTap: () => AppScope.read(context).resetTo(VRoute.settings),
      ),
    ],
  );
}
