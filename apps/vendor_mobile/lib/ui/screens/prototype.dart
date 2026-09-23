import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/app_state.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../shell.dart';
import '../widgets.dart';

class UiPrototypeScreen extends StatelessWidget {
  const UiPrototypeScreen({super.key, required this.spec});

  final RouteSpec spec;

  @override
  Widget build(BuildContext context) => switch (spec.route) {
    VRoute.riderRegistrationLink => const _InviteLinkScreen(kind: 'Rider'),
    VRoute.helperRegistrationLink => const _InviteLinkScreen(
      kind: 'Team member',
    ),
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

/// Kicker / title / subtitle composition on the one [HeroSurface].
class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.kicker, required this.title, this.subtitle});
  final String kicker;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Colors.white.withValues(alpha: .72);
    return HeroSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kicker,
            style: text.bodySmall?.copyWith(
              color: muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Gap.xs),
          Text(title, style: text.headlineSmall?.copyWith(color: Colors.white)),
          if (subtitle != null) ...[
            const SizedBox(height: Gap.xs),
            Text(subtitle!, style: text.bodyMedium?.copyWith(color: muted)),
          ],
          const SizedBox(height: Gap.md),
          Container(
            width: 28,
            height: 3,
            decoration: BoxDecoration(
              color: CefColors.accent,
              borderRadius: BorderRadius.circular(Sizes.buttonRadius),
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessProfileScreen extends StatelessWidget {
  const _BusinessProfileScreen();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final name = app.business?.name ?? 'Kopi Kita';
    return PageBody(
      children: [
        CefCard(
          child: Column(
            children: [
              Row(
                children: [
                  CefAvatar(name, size: 56),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
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
              const SizedBox(height: Gap.lg),
              Divider(height: 1, color: context.c.border),
              const SizedBox(height: Gap.md),
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
        CefListRow(
          title: 'Business Information',
          subtitle: 'Name, contact, description',
          icon: LucideIcons.fileText,
          onTap: () => app.go(VRoute.businessInformation),
        ),
        CefListRow(
          title: 'Business Address',
          subtitle: 'Store address and service area',
          icon: LucideIcons.mapPin,
          onTap: () => app.go(VRoute.businessAddress),
        ),
        CefListRow(
          title: 'Business Hours',
          subtitle: 'Set your operating hours',
          icon: LucideIcons.clock,
          onTap: () => app.go(VRoute.businessHours),
        ),
        const SizedBox(height: Gap.xl),
        const _HeroPanel(
          kicker: 'Your store is ready',
          title: 'Keep your business information up to date.',
          subtitle: 'A cleaner profile helps every delivery run smoothly.',
        ),
      ],
    );
  }
}

/// Right-aligned character count shown under a multi-line field.
class _CharCount extends StatelessWidget {
  const _CharCount(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Gap.sm),
    child: Text(
      text,
      textAlign: TextAlign.right,
      style: Theme.of(context).textTheme.bodySmall,
    ),
  );
}

class _BusinessInformationScreen extends StatelessWidget {
  const _BusinessInformationScreen();

  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      const _EditableAvatar(name: 'Kopi Kita'),
      const SizedBox(height: Gap.xl),
      const CefField(label: 'Business Name', initialValue: 'Kopi Kita'),
      const CefField(
        label: 'Tagline (Optional)',
        initialValue: 'A better delivery day. Today.',
      ),
      const CefField(
        label: 'Business Type',
        initialValue: 'Food & Beverage',
        prefixIcon: LucideIcons.package,
        suffixIcon: LucideIcons.chevronDown,
      ),
      const _SplitFields(
        leftLabel: 'Code',
        left: '+60',
        rightLabel: 'Contact Phone',
        right: '12 345 6789',
        keyboardType: TextInputType.phone,
      ),
      const CefField(
        label: 'Business Email',
        initialValue: 'hello@kopikita.my',
        keyboardType: TextInputType.emailAddress,
      ),
      const CefField(
        label: 'Short Description',
        initialValue: 'Handcrafted coffee and light bites, delivered fresh across Kuala Lumpur.',
        maxLines: 3,
      ),
      const _CharCount('72/160'),
      CefButton('Save Changes', secondary: true, onTap: () {}),
    ],
  );
}

class _BusinessAddressScreen extends StatelessWidget {
  const _BusinessAddressScreen();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return PageBody(
      children: [
        const CefSearchField(hint: 'Search or enter your address'),
        const SizedBox(height: Gap.md),
        Container(
          height: 210,
          decoration: BoxDecoration(
            color: c.subtle,
            borderRadius: BorderRadius.circular(Sizes.cardRadius),
            border: Border.all(color: c.border),
          ),
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
                right: Gap.md,
                bottom: Gap.md,
                child: Container(
                  width: Sizes.tapTarget,
                  height: Sizes.tapTarget,
                  decoration: BoxDecoration(
                    color: c.card,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.border),
                  ),
                  child: Icon(
                    LucideIcons.locateFixed,
                    size: 20,
                    color: c.iconColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.lg),
        const CefField(
          label: 'Address Line 1',
          initialValue: 'No. 12, Jalan Damai 3',
        ),
        const CefField(
          label: 'Address Line 2 (Optional)',
          initialValue: 'Taman Melati',
        ),
        const _SplitFields(
          leftLabel: 'Postcode',
          left: '53100',
          rightLabel: 'City',
          right: 'Kuala Lumpur',
        ),
        const CefField(
          label: 'State',
          initialValue: 'Wilayah Persekutuan Kuala Lumpur',
          suffixIcon: LucideIcons.chevronDown,
        ),
        const SizedBox(height: Gap.sm),
        CefButton('Save Address', secondary: true, onTap: () {}),
      ],
    );
  }
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
          subtitle: 'Let your customers know when your business is open.',
        ),
        const SizedBox(height: Gap.xl),
        for (final day in days)
          _BusinessHourRow(
            day: day,
            enabled: day != 'Sunday',
            close: day == 'Friday' || day == 'Saturday' ? '21:00' : '20:00',
          ),
        const SizedBox(height: Gap.sm),
        CefListRow(
          title: 'Apply to all days',
          subtitle: "Use Monday's hours for all days",
          icon: LucideIcons.copy,
          trailing: SizedBox(
            width: 96,
            child: CefButton('Apply', secondary: true, onTap: () {}),
          ),
        ),
        const SizedBox(height: Gap.xl),
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
        const _EditableAvatar(name: 'Yusuf Sazali'),
        const SizedBox(height: Gap.md),
        Text(
          'Yusuf Sazali',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 2),
        Text(
          'yusuf@kopikita.my',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: Gap.md),
        CefListRow(
          title: app.business?.name ?? 'Kopi Kita',
          subtitle: 'Owner',
          icon: LucideIcons.store,
          onTap: () => app.go(VRoute.businessProfile),
        ),
        CefListRow(
          title: 'Personal Information',
          subtitle: 'Name, phone, email',
          icon: LucideIcons.user,
          onTap: () => app.go(VRoute.editProfile),
        ),
        CefListRow(
          title: 'Security',
          subtitle: 'Password, biometric & 2FA',
          icon: LucideIcons.lock,
          onTap: () => app.go(VRoute.security),
        ),
        CefListRow(
          title: 'Language',
          subtitle: 'English',
          icon: LucideIcons.languages,
          onTap: () => app.go(VRoute.language),
        ),
        CefListRow(
          title: 'Notifications',
          subtitle: 'Manage preferences',
          icon: LucideIcons.bell,
          onTap: () => app.go(VRoute.notificationSettings),
        ),
        CefListRow(
          title: 'Help & Support',
          subtitle: 'Get help or contact support',
          icon: LucideIcons.circleHelp,
          onTap: () => app.go(VRoute.helpSupport),
        ),
        const SizedBox(height: Gap.xxl),
        CefButton(
          'Log Out',
          destructive: true,
          icon: LucideIcons.logOut,
          onTap: () {},
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
      const _EditableAvatar(name: 'Yusuf Sazali'),
      const SizedBox(height: Gap.xl),
      const CefField(
        label: 'Full Name',
        initialValue: 'Yusuf Sazali',
        prefixIcon: LucideIcons.user,
      ),
      const _SplitFields(
        leftLabel: 'Code',
        left: '+60',
        rightLabel: 'Phone Number',
        right: '12 345 6789',
        keyboardType: TextInputType.phone,
      ),
      const CefField(
        label: 'Email Address',
        initialValue: 'yusuf@kopikita.my',
        prefixIcon: LucideIcons.mail,
        enabled: false,
        helperText:
            'Email cannot be changed. Please contact support if needed.',
      ),
      const CefField(
        label: 'Role',
        initialValue: 'Owner',
        prefixIcon: LucideIcons.briefcase,
        enabled: false,
        helperText: 'Managed by your business.',
      ),
      const SizedBox(height: Gap.md),
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
              'Manage your security settings and protect your business data.',
        ),
        const SizedBox(height: Gap.lg),
        CefListRow(
          title: 'Password',
          subtitle: 'Update your password regularly',
          icon: LucideIcons.lock,
          onTap: () => app.go(VRoute.changePassword),
        ),
        CefListRow(
          title: 'Biometric Login',
          subtitle: 'Use Face ID or Touch ID',
          icon: LucideIcons.fingerprint,
          trailing: CefSwitch(value: true, onChanged: (_) {}),
        ),
        // Unavailable feature: no switch or on/off state, just an honest
        // "Coming soon" subtitle on a non-tappable row.
        const CefListRow(
          title: 'Two-Factor Authentication',
          subtitle: 'Coming soon',
          icon: LucideIcons.smartphone,
        ),
        CefListRow(
          title: 'Active Sessions',
          subtitle: 'Manage your logged in devices',
          icon: LucideIcons.laptop,
          onTap: () {},
        ),
        const SizedBox(height: Gap.xl),
        const _HeroPanel(
          kicker: 'Your security is important',
          title:
              'These settings help keep your account and business data safe.',
        ),
        const SizedBox(height: Gap.md),
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
        subtitle: 'Use a strong password to keep your account secure.',
      ),
      const SizedBox(height: Gap.xl),
      const CefField(
        label: 'Current Password',
        hint: 'Enter current password',
        prefixIcon: LucideIcons.lock,
        obscureText: true,
      ),
      const CefField(
        label: 'New Password',
        hint: 'Enter new password',
        prefixIcon: LucideIcons.lock,
        obscureText: true,
      ),
      const _Requirement('Minimum 8 characters'),
      const _Requirement('Include at least one letter and one number'),
      const _Requirement(r'Include one special character (e.g. ! @ # $)'),
      const SizedBox(height: Gap.md),
      const CefField(
        label: 'Confirm New Password',
        hint: 'Confirm new password',
        prefixIcon: LucideIcons.lock,
        obscureText: true,
      ),
      const SizedBox(height: Gap.md),
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
      ('New Orders', 'Get notified about new orders.'),
      ('Order Updates', 'Status and delivery updates.'),
      ('Run Updates', 'When runs are dispatched or done.'),
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
        const SectionHeading('Orders'),
        for (final row in rows.take(2))
          CefListRow(
            title: row.$1,
            subtitle: row.$2,
            icon: LucideIcons.bell,
            trailing: CefSwitch(
              value: row.$1 != 'Team Activity',
              onChanged: (_) {},
            ),
          ),
        const SectionHeading('Delivery & runs'),
        for (final row in rows.skip(2).take(2))
          CefListRow(
            title: row.$1,
            subtitle: row.$2,
            icon: row.$1 == 'Run Updates'
                ? LucideIcons.truck
                : LucideIcons.triangleAlert,
            trailing: CefSwitch(value: true, onChanged: (_) {}),
          ),
        const SectionHeading('Riders & team'),
        for (final row in rows.skip(4).take(2))
          CefListRow(
            title: row.$1,
            subtitle: row.$2,
            icon: row.$1 == 'Rider Updates'
                ? LucideIcons.users
                : LucideIcons.userPlus,
            trailing: CefSwitch(
              value: row.$1 != 'Team Activity',
              onChanged: (_) {},
            ),
          ),
        const SectionHeading('Account & system'),
        CefListRow(
          title: rows.last.$1,
          subtitle: rows.last.$2,
          icon: LucideIcons.settings,
          trailing: CefSwitch(value: true, onChanged: (_) {}),
        ),
        const SizedBox(height: Gap.md),
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
        Text(
          'Choose the language used throughout the Vendor app.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SectionHeading('App language'),
        for (final lang in langs)
          CefListRow(
            title: lang.$1,
            subtitle: lang.$2,
            showChevron: false,
            trailing: lang.$1 == 'English'
                ? Icon(
                    LucideIcons.circleDot,
                    size: Sizes.icon,
                    color: context.c.info,
                  )
                : Icon(
                    LucideIcons.circle,
                    size: Sizes.icon,
                    color: context.c.textSecondary,
                  ),
            onTap: () => app.setLocale(lang.$1),
          ),
        const SizedBox(height: Gap.xxl),
        CefButton('Confirm', onTap: () {}),
      ],
    );
  }
}

class _AppearanceScreen extends StatelessWidget {
  const _AppearanceScreen();

  @override
  Widget build(BuildContext context) => const PageBody(
    children: [
      _RoundIconHeader(
        icon: LucideIcons.penLine,
        title: 'Coming Soon',
        subtitle: 'Appearance settings will be available in a future update.',
      ),
      SizedBox(height: Gap.xl),
      _HeroPanel(
        kicker: 'Same operations. A brighter experience ahead.',
        title: 'More ways to make it yours.',
      ),
      SizedBox(height: Gap.md),
      CefListRow(
        title: 'Theme Options',
        subtitle: 'Light, dark and system theme.',
        icon: LucideIcons.sun,
      ),
      CefListRow(
        title: 'App Appearance',
        subtitle: 'Customize colours and style.',
        icon: LucideIcons.palette,
      ),
      CefListRow(
        title: 'Display Preferences',
        subtitle: 'Adjust display settings to your liking.',
        icon: LucideIcons.slidersHorizontal,
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
      Icon(
        icon,
        size: 20,
        color: accent ? CefColors.accent : context.c.iconColor,
      ),
      const SizedBox(height: Gap.xs),
      Text(value, style: Theme.of(context).textTheme.titleSmall),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

/// Profile photo placeholder: the standard initials avatar with a camera
/// badge signalling the photo can be changed.
class _EditableAvatar extends StatelessWidget {
  const _EditableAvatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CefAvatar(name, size: 84),
          Positioned(
            right: -Gap.xs,
            bottom: 0,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: c.card,
                shape: BoxShape.circle,
                border: Border.all(color: c.border),
              ),
              child: Icon(LucideIcons.camera, size: 16, color: c.iconColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// Two labelled fields side by side (e.g. country code + number,
/// postcode + city) at a 2:4 split.
class _SplitFields extends StatelessWidget {
  const _SplitFields({
    required this.leftLabel,
    required this.left,
    required this.rightLabel,
    required this.right,
    this.keyboardType,
  });
  final String leftLabel, left, rightLabel, right;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        flex: 2,
        child: CefField(
          label: leftLabel,
          initialValue: left,
          keyboardType: keyboardType,
        ),
      ),
      const SizedBox(width: Gap.md),
      Expanded(
        flex: 4,
        child: CefField(
          label: rightLabel,
          initialValue: right,
          keyboardType: keyboardType,
        ),
      ),
    ],
  );
}

/// Compact icon disc + heading + supporting line that introduces a list or
/// form inside a page body.
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
      Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: context.c.subtle,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 26, color: CefColors.navy),
      ),
      const SizedBox(height: Gap.sm),
      Text(
        title,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: Gap.xs),
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
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // Day label, switch and separator share the field's control height so
    // they line up with the CefFields (which carry their own bottom gap).
    Widget control(Widget child, {double? width}) => SizedBox(
      width: width,
      height: Sizes.controlHeight,
      child: Align(alignment: Alignment.centerLeft, child: child),
    );
    final dayLabel = Text(
      day,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: text.titleSmall,
    );
    final toggle = CefSwitch(value: enabled, onChanged: (_) {});
    final times = [
      const Expanded(child: CefField(initialValue: '08:00')),
      control(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gap.xs),
          child: Text('–', style: text.bodyMedium),
        ),
      ),
      Expanded(child: CefField(initialValue: close)),
    ];
    final closed = Text('Closed', style: text.bodyMedium);
    return LayoutBuilder(
      builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        // One line needs the day label (~92 * scale), switch + separator
        // (~77) and two time fields (28 padding + ~44 * scale text each);
        // with less room (narrow phone, large text) the times drop below.
        final inline = constraints.maxWidth >= 133 + 180 * scale;
        if (inline) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              control(dayLabel, width: 92 * scale),
              control(toggle),
              const SizedBox(width: Gap.sm),
              if (enabled)
                ...times
              else
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: Gap.md),
                    child: control(closed),
                  ),
                ),
            ],
          );
        }
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: control(dayLabel)),
                if (!enabled) ...[closed, const SizedBox(width: Gap.md)],
                toggle,
              ],
            ),
            if (enabled)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: times)
            else
              const SizedBox(height: Gap.sm),
          ],
        );
      },
    );
  }
}

class _Requirement extends StatelessWidget {
  const _Requirement(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: Gap.xs),
    child: Row(
      children: [
        Icon(LucideIcons.circle, size: 14, color: context.c.textSecondary),
        const SizedBox(width: Gap.sm),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    ),
  );
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
        CefSearchField(
          hint: 'Search for help, articles or topics...',
          onFilter: () {},
        ),
        const SizedBox(height: Gap.md),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
          CefListRow(title: row.$1, subtitle: row.$2, icon: row.$3),
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
      CefSearchField(
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
        CefListRow(
          title: row.$1,
          subtitle: row.$2,
          icon: row.$1 == 'Orders & Delivery'
              ? LucideIcons.truck
              : row.$1 == 'Zones & Riders'
              ? LucideIcons.users
              : row.$1 == 'Subscription & Billing'
              ? LucideIcons.calendarDays
              : LucideIcons.bookOpen,
        ),
      SectionHeading(
        'Popular Questions',
        trailing: TextButton(
          onPressed: () =>
              showNotWiredYetSnackBar(context, 'Viewing all questions'),
          child: const Text('View All'),
        ),
      ),
      for (final question in const [
        'How do I create a delivery zone?',
        'How do I add a rider?',
        'Can I change my plan later?',
        'How does route optimization work?',
        'Where can my customers track their orders?',
      ])
        CefListRow(title: question),
    ],
  );
}

class _ContactSupportScreen extends StatelessWidget {
  const _ContactSupportScreen();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return PageBody(
      children: [
        const _HeroPanel(
          kicker: 'We’re here to help',
          title: 'Get in touch',
          subtitle:
              'Tell us about your issue and our team will get back to you.',
        ),
        const SizedBox(height: Gap.xl),
        const CefField(
          label: 'Issue Category',
          hint: 'Select a category',
          suffixIcon: LucideIcons.chevronDown,
        ),
        const CefField(label: 'Subject', hint: 'Briefly describe your issue'),
        const CefField(
          label: 'Message',
          hint: 'Tell us more about your issue...',
          maxLines: 4,
        ),
        const _CharCount('0/500'),
        Text('Add Screenshots (Optional)', style: text.labelLarge),
        const SizedBox(height: Gap.sm),
        CefCard(
          child: Column(
            children: [
              Icon(
                LucideIcons.image,
                size: Sizes.icon,
                color: context.c.iconColor,
              ),
              const SizedBox(height: Gap.sm),
              Text('Tap to attach images', style: text.titleSmall),
              const SizedBox(height: 2),
              Text('PNG, JPG up to 10MB each', style: text.bodySmall),
            ],
          ),
        ),
        const SizedBox(height: Gap.lg),
        const CefField(
          label: 'Contact Email',
          initialValue: 'yusuf@kopikita.my',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: Gap.sm),
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
          style: text.bodySmall,
        ),
      ],
    );
  }
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
        'Last updated: 12 Sep 2026',
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
      const SizedBox(height: Gap.md),
      const Center(child: CefAvatar('Cefflo', size: 84)),
      const SizedBox(height: Gap.md),
      Text(
        'Cefflo',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: Gap.xs),
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
      CefListRow(
        title: 'Version',
        icon: LucideIcons.smartphone,
        trailing: Text('1.0.0', style: Theme.of(context).textTheme.bodyMedium),
      ),
      const CefListRow(
        title: 'Privacy Policy',
        subtitle: 'Read policy',
        icon: LucideIcons.shieldCheck,
      ),
      const CefListRow(
        title: 'Terms of Service',
        subtitle: 'Read terms',
        icon: LucideIcons.fileText,
      ),
      const SizedBox(height: Gap.section),
      Text(
        '© 2026 Cefflo. All rights reserved.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
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
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: Sizes.icon, color: context.c.info),
        const SizedBox(height: Gap.sm),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );
}

class _NotificationInboxScreen extends StatelessWidget {
  const _NotificationInboxScreen();

  @override
  Widget build(BuildContext context) => const PageBody(
    children: [
      CefListRow(
        title: '3 orders need your action',
        subtitle: 'Review issues before dispatch.',
        icon: LucideIcons.bell,
      ),
      CefListRow(
        title: 'Rider update',
        subtitle: 'Ahmad Razi is online.',
        icon: LucideIcons.users,
      ),
      CefListRow(
        title: 'System update',
        subtitle: 'Everything is operating normally.',
        icon: LucideIcons.info,
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
      backgroundColor: context.c.card,
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
                color: context.c.card,
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
    final c = context.c;
    final text = Theme.of(context).textTheme;
    final link =
        'https://cefflo.app/${kind == 'Rider' ? 'team' : 'join'}/AB3K9D';
    return PageBody(
      children: [
        Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: c.subtle, shape: BoxShape.circle),
            child: const Icon(
              LucideIcons.userPlus,
              size: 26,
              color: CefColors.navy,
            ),
          ),
        ),
        const SizedBox(height: Gap.md),
        Text(
          kind == 'Rider'
              ? 'Invite Riders to Your Business'
              : 'Invite a Team Member',
          textAlign: TextAlign.center,
          style: text.headlineSmall,
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
          style: text.bodyMedium,
        ),
        const SizedBox(height: Gap.section),
        HeroSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.link, size: 18, color: Colors.white),
                  const SizedBox(width: Gap.sm),
                  Expanded(
                    child: Text(
                      'Your Invitation Link',
                      style: text.titleSmall?.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Gap.md),
              Container(
                padding: const EdgeInsets.only(left: Gap.md),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(Sizes.inputRadius),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        link,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodyMedium,
                      ),
                    ),
                    IconAction(
                      icon: LucideIcons.copy,
                      tooltip: 'Copy link',
                      onTap: () => _copyLink(context, link),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Gap.md),
              CefButton(
                'Copy Link',
                secondary: true,
                onTap: () => _copyLink(context, link),
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.cardGap),
        CefListRow(
          title: 'Show QR Code',
          subtitle: '$kind${kind.endsWith('s') ? '' : 's'} can scan this code',
          icon: LucideIcons.qrCode,
          onTap: () => _showQrSheet(context),
        ),
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
              color: c.subtle,
              iconColor: c.textSecondary,
              onTap: () => _copyLink(context, link),
            ),
          ],
        ),
        const SizedBox(height: Gap.section),
        CefCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.info, size: 18, color: c.info),
              const SizedBox(width: Gap.sm),
              Expanded(
                child: Text(
                  kind == 'Rider'
                      ? 'Invited riders will appear in your Riders list '
                            'as Pending Review once they complete their '
                            'registration.'
                      : 'Invited team members will appear in your Team '
                            'list once they accept and complete their '
                            'registration.',
                  style: text.bodySmall,
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

/// Share target disc. Brand colours for WhatsApp / Telegram / SMS are
/// third-party marks; the neutral "More" disc uses tokens.
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
          child: Icon(icon, size: Sizes.icon, color: iconColor ?? Colors.white),
        ),
        const SizedBox(height: Gap.sm),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
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
