import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:qr/qr.dart';

import '../../core/app_state.dart';
import '../../core/routes.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
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
          const SizedBox(height: 2),
          Text(title, style: text.titleMedium?.copyWith(color: Colors.white)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: text.bodyMedium?.copyWith(color: muted)),
          ],
          const SizedBox(height: Gap.sm),
          Container(
            width: 28,
            height: 3,
            decoration: BoxDecoration(
              color: CefColors.ceffloMustard,
              borderRadius: BorderRadius.circular(Sizes.buttonRadius),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact intro at the top of a grouped settings page: a CEFFLO Blue
/// [IconTile] beside a section title and its supporting line.
class _GroupedIntro extends StatelessWidget {
  const _GroupedIntro({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.xs, 0, 0, Gap.xl),
      child: Row(
        children: [
          IconTile(icon),
          const SizedBox(width: Gap.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleMedium),
                const SizedBox(height: 2),
                Text(subtitle, style: text.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Business
// ---------------------------------------------------------------------------

class _BusinessProfileScreen extends StatelessWidget {
  const _BusinessProfileScreen();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final text = Theme.of(context).textTheme;
    final name = app.business?.name ?? 'Kopi Kita';
    // Archetype F: compact identity + stats card, grouped rows, then the
    // store panel -- all inside the first viewport.
    return PageBody(
      grouped: true,
      children: [
        CefCard(
          padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.sm),
          child: Column(
            children: [
              Row(
                children: [
                  CefAvatar(name, size: 48),
                  const SizedBox(width: Gap.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: text.titleMedium),
                        Text(
                          'A better delivery day. Today.',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Gap.sm),
                  CefButton(
                    'Edit',
                    secondary: true,
                    compact: true,
                    icon: LucideIcons.pencil,
                    onTap: () => app.go(VRoute.businessInformation),
                  ),
                ],
              ),
              const SizedBox(height: Gap.md),
              Divider(height: 1, color: context.c.border),
              const KpiStrip(
                items: [
                  KpiItem('24', 'Products', icon: LucideIcons.package),
                  KpiItem('128', 'Orders', icon: LucideIcons.shoppingCart),
                  KpiItem('4.8', 'Rating', icon: LucideIcons.star),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.lg),
        CefListGroup(
          label: 'Business',
          children: [
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
          ],
        ),
        const _HeroPanel(
          kicker: 'Your store is ready',
          title: 'Keep your business information up to date.',
        ),
      ],
    );
  }
}

class _BusinessInformationScreen extends StatelessWidget {
  const _BusinessInformationScreen();

  @override
  Widget build(BuildContext context) => PageBody(
    bottom: CefButton('Save Changes', onTap: () {}),
    // Archetype G (multi-section form).
    children: [
      const _EditableAvatar(name: 'Kopi Kita'),
      const SectionHeading(
        'Business details',
        icon: LucideIcons.store,
        subtitle: 'How customers and riders see your business.',
      ),
      const CefField(
        label: 'Business Name',
        initialValue: 'Kopi Kita',
        prefixIcon: LucideIcons.store,
      ),
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
      const CefField(
        label: 'Short Description',
        initialValue: 'Handcrafted coffee and light bites, delivered fresh across Kuala Lumpur.',
        maxLines: 3,
        maxLength: 160,
      ),
      const SectionHeading(
        'Contact',
        icon: LucideIcons.phone,
        subtitle: 'Where customers and riders can reach you.',
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
        prefixIcon: LucideIcons.mail,
        keyboardType: TextInputType.emailAddress,
      ),
    ],
  );
}

class _BusinessAddressScreen extends StatelessWidget {
  const _BusinessAddressScreen();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    // Archetype G (multi-section form).
    return PageBody(
      bottom: CefButton('Save Address', onTap: () {}),
      children: [
        const CefSearchField(hint: 'Search or enter your address'),
        const SizedBox(height: Gap.md),
        Container(
          height: 210,
          decoration: BoxDecoration(
            color: c.grouped,
            borderRadius: BorderRadius.circular(Sizes.cardRadius),
            border: Border.all(color: c.border),
          ),
          child: Stack(
            children: [
              const Center(
                child: Icon(
                  LucideIcons.mapPin,
                  size: 52,
                  color: CefColors.brand,
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
                    size: Sizes.icon,
                    color: c.iconColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SectionHeading(
          'Address details',
          icon: LucideIcons.mapPin,
          subtitle: 'Store address and service area',
        ),
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
    // Archetype G (form).
    return PageBody(
      bottom: CefButton('Save Hours', onTap: () {}),
      children: [
        const SectionHeading(
          'Operating Hours',
          icon: LucideIcons.clock3,
          subtitle: 'Let your customers know when your business is open.',
        ),
        for (final day in days)
          _BusinessHourRow(
            day: day,
            enabled: day != 'Sunday',
            close: day == 'Friday' || day == 'Saturday' ? '21:00' : '20:00',
          ),
        const SizedBox(height: Gap.sm),
        CefActionRow(
          icon: LucideIcons.copy,
          label: "Apply Monday's hours to all days",
          chevron: false,
          onTap: () {},
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Account
// ---------------------------------------------------------------------------

class _EditProfileScreen extends StatelessWidget {
  const _EditProfileScreen();

  @override
  Widget build(BuildContext context) => PageBody(
    bottom: CefButton('Save Changes', onTap: () {}),
    // Archetype G (multi-section form).
    children: [
      const _EditableAvatar(name: 'Yusuf Sazali'),
      const SectionHeading(
        'Personal details',
        icon: LucideIcons.user,
        subtitle: 'Your name and phone number.',
      ),
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
      const SectionHeading(
        'Account',
        icon: LucideIcons.briefcase,
        subtitle: 'Sign-in email and role.',
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
    ],
  );
}

class _SecurityScreen extends StatelessWidget {
  const _SecurityScreen();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    // Archetype F: compact intro, one group, then the security panel.
    return PageBody(
      grouped: true,
      children: [
        const _GroupedIntro(
          icon: LucideIcons.shield,
          title: 'Keep your account safe',
          subtitle:
              'Manage your security settings and protect your business data.',
        ),
        CefListGroup(
          label: 'Sign-in & access',
          children: [
            CefListRow(
              title: 'Password',
              subtitle: 'Update your password regularly',
              subtitleMaxLines: 2,
              icon: LucideIcons.lock,
              onTap: () => app.go(VRoute.changePassword),
            ),
            CefListRow(
              title: 'Biometric Login',
              subtitle: 'Use Face ID or Touch ID',
              subtitleMaxLines: 2,
              icon: LucideIcons.fingerprint,
              trailing: CefSwitch(value: true, onChanged: (_) {}),
            ),
            // Unavailable feature: no switch or on/off state, just an honest
            // "Coming soon" subtitle on a non-tappable row.
            const CefListRow(
              title: 'Two-Factor Authentication',
              subtitle: 'Coming soon',
              subtitleMaxLines: 2,
              icon: LucideIcons.smartphone,
            ),
            CefListRow(
              title: 'Active Sessions',
              subtitle: 'Manage your logged in devices',
              subtitleMaxLines: 2,
              icon: LucideIcons.laptop,
              onTap: () {},
            ),
          ],
        ),
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
    bottom: CefButton(
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
    // Archetype G (form).
    children: [
      const SectionHeading(
        'Set a new password',
        icon: LucideIcons.lock,
        subtitle: 'Use a strong password to keep your account secure.',
      ),
      const CefField(
        label: 'Current Password',
        hint: 'Enter current password',
        prefixIcon: LucideIcons.lock,
        obscureText: true,
      ),
      const CefField(
        label: 'New Password',
        hint: 'Enter new password',
        prefixIcon: LucideIcons.keyRound,
        obscureText: true,
      ),
      const _Requirement('Minimum 8 characters'),
      const _Requirement('Include at least one letter and one number'),
      const _Requirement(r'Include one special character (e.g. ! @ # $)'),
      const SizedBox(height: Gap.md),
      const CefField(
        label: 'Confirm New Password',
        hint: 'Confirm new password',
        prefixIcon: LucideIcons.keyRound,
        obscureText: true,
      ),
    ],
  );
}

class _NotificationPreferencesScreen extends StatelessWidget {
  const _NotificationPreferencesScreen();

  @override
  Widget build(BuildContext context) {
    Widget toggle(String title, String subtitle, IconData icon, bool on) =>
        CefListRow(
          title: title,
          subtitle: subtitle,
          subtitleMaxLines: 2,
          icon: icon,
          trailing: CefSwitch(value: on, onChanged: (_) {}),
        );
    // Archetype F: one group per section, switches trailing.
    return PageBody(
      grouped: true,
      children: [
        const _GroupedIntro(
          icon: LucideIcons.bell,
          title: 'Stay in the loop',
          subtitle: 'Get notified about what matters to your business.',
        ),
        CefListGroup(
          label: 'Orders',
          children: [
            toggle(
              'New Orders',
              'Get notified about new orders.',
              LucideIcons.bellRing,
              true,
            ),
            toggle(
              'Order Updates',
              'Status and delivery updates.',
              LucideIcons.packageCheck,
              true,
            ),
          ],
        ),
        CefListGroup(
          label: 'Delivery & runs',
          children: [
            toggle(
              'Run Updates',
              'When runs are dispatched or done.',
              LucideIcons.truck,
              true,
            ),
            toggle(
              'Delivery Issues',
              'Get notified about delivery issues.',
              LucideIcons.triangleAlert,
              true,
            ),
          ],
        ),
        CefListGroup(
          label: 'Riders & team',
          children: [
            toggle(
              'Rider Updates',
              'When riders go online/offline.',
              LucideIcons.users,
              true,
            ),
            toggle(
              'Team Activity',
              'New team members or role changes.',
              LucideIcons.userPlus,
              false,
            ),
          ],
        ),
        CefListGroup(
          label: 'Account & system',
          children: [
            toggle(
              'Important Updates',
              'Account, billing and system announcements.',
              LucideIcons.settings,
              true,
            ),
          ],
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
    // Archetype F: radio rows in one group.
    return PageBody(
      bottom: CefButton('Confirm', onTap: () {}),
      grouped: true,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Gap.xs, 0, 0, Gap.lg),
          child: Text(
            'Choose the language used throughout the Vendor app.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        CefListGroup(
          label: 'App language',
          children: [
            for (final lang in langs)
              CefListRow(
                title: lang.$1,
                subtitle: lang.$2,
                icon: LucideIcons.languages,
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
          ],
        ),
      ],
    );
  }
}

class _AppearanceScreen extends StatelessWidget {
  const _AppearanceScreen();

  @override
  Widget build(BuildContext context) => PageBody(
    // Archetype F: compact intro, the upcoming options as one group.
    grouped: true,
    children: [
      const _GroupedIntro(
        icon: LucideIcons.penLine,
        title: 'Coming Soon',
        subtitle: 'Appearance settings will be available in a future update.',
      ),
      const CefListGroup(
        label: 'More ways to make it yours.',
        children: [
          CefListRow(
            title: 'Theme Options',
            subtitle: 'Light, dark and system theme.',
            subtitleMaxLines: 2,
            icon: LucideIcons.sun,
          ),
          CefListRow(
            title: 'App Appearance',
            subtitle: 'Customize colours and style.',
            subtitleMaxLines: 2,
            icon: LucideIcons.palette,
          ),
          CefListRow(
            title: 'Display Preferences',
            subtitle: 'Adjust display settings to your liking.',
            subtitleMaxLines: 2,
            icon: LucideIcons.slidersHorizontal,
          ),
        ],
      ),
      Text(
        'Same operations. A brighter experience ahead.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ],
  );
}

/// Profile photo placeholder on a form: the standard initials avatar with a
/// camera badge signalling the photo can be changed.
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

// ---------------------------------------------------------------------------
// Support & information
// ---------------------------------------------------------------------------

class _HelpSupportScreen extends StatelessWidget {
  const _HelpSupportScreen();

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    // Archetype F: hero, search, support tiles, grouped topics.
    return PageBody(
      grouped: true,
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
        const SizedBox(height: Gap.xl),
        const CefListGroup(
          label: 'Popular Topics',
          children: [
            CefListRow(
              title: 'Account & Security',
              subtitle: 'Login, profile, security settings',
              subtitleMaxLines: 2,
              icon: LucideIcons.circleUserRound,
            ),
            CefListRow(
              title: 'Orders & Delivery',
              subtitle: 'Order management, delivery issues',
              subtitleMaxLines: 2,
              icon: LucideIcons.truck,
            ),
            CefListRow(
              title: 'Riders & Team',
              subtitle: 'Rider invites, approvals, team access',
              subtitleMaxLines: 2,
              icon: LucideIcons.users,
            ),
            CefListRow(
              title: 'Subscription & Billing',
              subtitle: 'Plans, payments, invoices',
              subtitleMaxLines: 2,
              icon: LucideIcons.calendarDays,
            ),
            CefListRow(
              title: 'App Guides',
              subtitle: 'Step-by-step tutorials',
              subtitleMaxLines: 2,
              icon: LucideIcons.bookOpen,
            ),
          ],
        ),
      ],
    );
  }
}

class _FaqScreen extends StatelessWidget {
  const _FaqScreen();

  @override
  Widget build(BuildContext context) => PageBody(
    // Archetype F, same language as Help & Support.
    grouped: true,
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
      const SizedBox(height: Gap.xl),
      const CefListGroup(
        label: 'Browse topics',
        children: [
          CefListRow(
            title: 'Getting Started',
            subtitle: 'Set up your account and business',
            icon: LucideIcons.bookOpen,
          ),
          CefListRow(
            title: 'Orders & Delivery',
            subtitle: 'Manage orders, runs and zones',
            icon: LucideIcons.truck,
          ),
          CefListRow(
            title: 'Zones & Riders',
            subtitle: 'Coverage, riders and dispatch',
            icon: LucideIcons.users,
          ),
          CefListRow(
            title: 'Account',
            subtitle: 'Profile, security and settings',
            icon: LucideIcons.bookOpen,
          ),
          CefListRow(
            title: 'Subscription & Billing',
            subtitle: 'Plans, payments and invoices',
            icon: LucideIcons.calendarDays,
          ),
        ],
      ),
      CefListGroup(
        label: 'Popular Questions',
        children: [
          for (final question in const [
            'How do I create a delivery zone?',
            'How do I add a rider?',
            'Can I change my plan later?',
            'How does route optimization work?',
            'Where can my customers track their orders?',
          ])
            CefListRow(title: question, icon: LucideIcons.circleHelp),
          CefListRow(
            title: 'View all',
            icon: LucideIcons.list,
            onTap: () =>
                showNotWiredYetSnackBar(context, 'Viewing all questions'),
          ),
        ],
      ),
    ],
  );
}

class _ContactSupportScreen extends StatelessWidget {
  const _ContactSupportScreen();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final c = context.c;
    // Archetype G (multi-section form).
    return PageBody(
      children: [
        Text('We’re here to help.', style: text.bodyMedium),
        const SectionHeading(
          'Get in touch',
          icon: LucideIcons.messageCircle,
          subtitle:
              'Tell us about your issue and our team will get back to you.',
        ),
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
          maxLength: 500,
        ),
        const SectionHeading(
          'Add Screenshots (Optional)',
          icon: LucideIcons.image,
          subtitle: 'PNG, JPG up to 10MB each',
        ),
        Container(
          height: 104,
          width: double.infinity,
          decoration: BoxDecoration(
            color: c.grouped,
            borderRadius: BorderRadius.circular(Sizes.cardRadius),
            border: Border.all(color: c.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.imagePlus, size: 28, color: c.iconColor),
              const SizedBox(height: Gap.sm),
              Text('Tap to attach images', style: text.titleSmall),
            ],
          ),
        ),
        const SectionHeading(
          'Contact',
          icon: LucideIcons.mail,
          subtitle: 'Where we will reply to you.',
        ),
        const CefField(
          label: 'Contact Email',
          initialValue: 'yusuf@kopikita.my',
          prefixIcon: LucideIcons.mail,
          keyboardType: TextInputType.emailAddress,
        ),
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
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final privacy = title == 'Privacy Policy';
    // Document on the white surface.
    return PageBody(
      children: [
        SectionHeading(
          'Trust & Transparency',
          icon: privacy ? LucideIcons.shieldCheck : LucideIcons.fileText,
          subtitle: privacy
              ? 'We’re committed to protecting your data and your privacy.'
              : 'The terms that guide your use of Cefflo.',
        ),
        Text('Last updated: 12 Sep 2026', style: text.bodySmall),
        const SizedBox(height: Gap.lg),
        Divider(height: 1, color: context.c.border),
        const SectionHeading('On this page'),
        Text(
          privacy
              ? '1.  Introduction\n2.  Information We Collect\n3.  How We Use Your Information\n4.  Data Sharing\n5.  Data Security\n6.  Your Rights\n7.  Cookies and Tracking Technologies\n8.  Changes to This Policy\n9.  Contact Us'
              : '1.  Acceptance of Terms\n2.  Account Responsibilities\n3.  Acceptable Use\n4.  Subscription and Billing\n5.  Intellectual Property\n6.  Service Availability\n7.  Limitation of Liability\n8.  Changes to These Terms\n9.  Contact Us',
          style: text.bodyMedium?.copyWith(height: 1.6),
        ),
        SectionHeading(privacy ? '1. Introduction' : '1. Acceptance of Terms'),
        Text(
          privacy
              ? 'Cefflo (“we”, “us” or “our”) values your privacy. This policy explains how we collect, use, disclose and safeguard your information when you use our services.'
              : 'By accessing or using Cefflo, you agree to these terms and to use the service responsibly in accordance with applicable laws.',
          style: text.bodyMedium,
        ),
        SectionHeading(
          privacy ? '2. Information We Collect' : '2. Account Responsibilities',
        ),
        Text(
          privacy
              ? 'We collect information that you provide directly to us, together with limited operational data needed to deliver and improve the service.'
              : 'You are responsible for maintaining accurate account information and protecting access to your account.',
          style: text.bodyMedium,
        ),
      ],
    );
  }
}

class _AboutScreen extends StatelessWidget {
  const _AboutScreen();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // Archetype F: identity block, grouped information rows.
    return PageBody(
      grouped: true,
      children: [
        const Center(child: CefAvatar('Cefflo', size: 84)),
        const SizedBox(height: Gap.md),
        Text('Cefflo', textAlign: TextAlign.center, style: text.titleMedium),
        const SizedBox(height: Gap.xs),
        Text(
          'More orders. Less work. A smoother delivery day.',
          textAlign: TextAlign.center,
          style: text.bodyMedium,
        ),
        const SizedBox(height: Gap.xxl),
        const CefListGroup(
          label: 'Our purpose',
          children: [
            CefListRow(
              title: 'Operate Today. Grow Tomorrow.',
              subtitle: 'A local same-day delivery operating system built for businesses.',
              subtitleMaxLines: 2,
              icon: LucideIcons.target,
            ),
          ],
        ),
        CefListGroup(
          label: 'App information',
          children: [
            CefListRow(
              title: 'Version',
              icon: LucideIcons.smartphone,
              trailing: Text('1.0.0', style: text.bodyMedium),
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
          ],
        ),
        Text(
          '© 2026 Cefflo. All rights reserved.',
          textAlign: TextAlign.center,
          style: text.bodySmall,
        ),
      ],
    );
  }
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
        IconTile(icon),
        const SizedBox(height: Gap.md),
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

/// X-01 — Notification centre. Unread entries carry a blue dot and a bold
/// title; read ones step back. Tap opens (marks read); swipe left deletes
/// (with Undo), swipe right toggles read; the row's overflow menu does the
/// same. Mark all / Clear all live in the header menu.
class _NotificationInboxScreen extends StatelessWidget {
  const _NotificationInboxScreen();

  static IconData _icon(NotificationKind kind) => switch (kind) {
    NotificationKind.attention => LucideIcons.triangleAlert,
    NotificationKind.order => LucideIcons.package,
    NotificationKind.rider => LucideIcons.users,
    NotificationKind.system => LucideIcons.info,
  };

  static void _delete(BuildContext context, AppNotification n) {
    final app = AppScope.read(context);
    final undo = app.deleteNotification(n.id);
    if (undo == null) return;
    showCefToast(
      context,
      'Notification deleted',
      actionLabel: 'Undo',
      onAction: () => app.restoreNotification(undo),
    );
  }

  static void _showRowOptions(BuildContext context, AppNotification n) {
    final app = AppScope.read(context);
    showListSheet(
      context,
      title: n.title,
      children: [
        CefListRow(
          title: n.read ? 'Mark as unread' : 'Mark as read',
          icon: n.read ? LucideIcons.mail : LucideIcons.mailOpen,
          showChevron: false,
          onTap: () {
            Navigator.of(context).pop();
            app.setNotificationRead(n.id, read: !n.read);
          },
        ),
        CefListRow(
          title: 'Delete',
          icon: LucideIcons.trash2,
          showChevron: false,
          onTap: () {
            Navigator.of(context).pop();
            _delete(context, n);
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final c = context.c;
    final items = app.notifications;
    if (items.isEmpty) {
      return const PageBody(
        children: [StateBlock.empty("You're all caught up.")],
      );
    }
    Widget swipeBackground(Color color, IconData icon, Alignment align) =>
        Container(
          color: color,
          alignment: align,
          padding: const EdgeInsets.symmetric(horizontal: Gap.xl),
          child: Icon(icon, color: Colors.white, size: Sizes.icon),
        );
    return PageBody(
      children: [
        for (final n in items)
          Dismissible(
            key: ValueKey(n.id),
            background: swipeBackground(
              CefColors.brand,
              n.read ? LucideIcons.mail : LucideIcons.mailOpen,
              Alignment.centerLeft,
            ),
            secondaryBackground: swipeBackground(
              c.attention,
              LucideIcons.trash2,
              Alignment.centerRight,
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                app.setNotificationRead(n.id, read: !n.read);
                return false;
              }
              return true;
            },
            onDismissed: (_) => _delete(context, n),
            child: CefListRow(
              title: n.title,
              subtitle: '${n.body}\n${n.timeLabel}',
              subtitleMaxLines: 2,
              leading: Stack(
                clipBehavior: Clip.none,
                children: [
                  IconTile(_icon(n.kind)),
                  if (!n.read)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: CefColors.brand,
                          shape: BoxShape.circle,
                          border: Border.all(color: c.card, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              emphasis: !n.read,
              trailing: IconAction(
                icon: LucideIcons.ellipsis,
                tooltip: 'Notification options',
                onTap: () => _showRowOptions(context, n),
              ),
              showChevron: false,
              onTap: () => app.setNotificationRead(n.id, read: true),
            ),
          ),
      ],
    );
  }
}

/// V-22 / V-25 — Rider/Team invitation link. Vendor shares a trusted-link
/// invitation; it never collects the invitee's profile directly.
class _InviteLinkScreen extends StatelessWidget {
  const _InviteLinkScreen({required this.kind});
  final String kind;

  String get _scanLabel =>
      '$kind${kind.endsWith('s') ? '' : 's'} can scan this code';

  void _copyLink(BuildContext context, String link) {
    Clipboard.setData(ClipboardData(text: link));
    showCefToast(context, 'Link copied');
  }

  /// Compact, centred modal over a dimmed page: the real QR code for
  /// [link], nothing expanded inline on the page itself.
  void _showQrModal(BuildContext context, String link) {
    final text = Theme.of(context).textTheme;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: context.c.card,
        insetPadding: const EdgeInsets.symmetric(horizontal: Gap.xxxl),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Sizes.cardRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Gap.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Scan to join', style: text.titleMedium),
              const SizedBox(height: Gap.xs),
              Text(
                _scanLabel,
                textAlign: TextAlign.center,
                style: text.bodySmall,
              ),
              const SizedBox(height: Gap.lg),
              _QrCode(data: link, size: 200),
              const SizedBox(height: Gap.md),
              Text(
                link,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall,
              ),
              const SizedBox(height: Gap.lg),
              CefButton(
                'Done',
                secondary: true,
                onTap: () => Navigator.of(dialogContext).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final text = Theme.of(context).textTheme;
    final rider = kind == 'Rider';
    final link = 'https://cefflo.app/${rider ? 'team' : 'join'}/AB3K9D';
    // Compact archetype G: intro, the link on the hero surface, QR, share
    // channels and the pending-review note all fit the first viewport; Share
    // Invite is pinned.
    return PageBody(
      bottom: CefButton(
        'Share Invite',
        icon: LucideIcons.share,
        onTap: () => _copyLink(context, link),
      ),
      children: [
        Row(
          children: [
            const IconTile(LucideIcons.userPlus),
            const SizedBox(width: Gap.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rider
                        ? 'Invite riders to your business'
                        : 'Invite a team member',
                    style: text.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rider
                        ? 'Share this link so they can join your team and '
                              'complete their profile, vehicle and documents.'
                        : 'Share this link so they can help run deliveries '
                              'and manage orders.',
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Gap.md),
        HeroSurface(
          padding: const EdgeInsets.all(Gap.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(
                    LucideIcons.link,
                    size: Sizes.icon,
                    color: Colors.white,
                  ),
                  const SizedBox(width: Gap.sm),
                  Text(
                    'Invitation link',
                    style: text.titleSmall?.copyWith(color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: Gap.sm),
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
            ],
          ),
        ),
        const SizedBox(height: Gap.sm),
        CefActionRow(
          icon: LucideIcons.qrCode,
          label: 'Show QR code',
          subtitle: _scanLabel,
          onTap: () => _showQrModal(context, link),
        ),
        const SizedBox(height: Gap.sm),
        CefCard(
          padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, Gap.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.share2,
                    size: Sizes.icon,
                    color: c.iconColor,
                  ),
                  const SizedBox(width: Gap.sm),
                  Text('Share via', style: text.titleSmall),
                ],
              ),
              const SizedBox(height: Gap.md),
              Row(
                children: [
                  _ShareChannel.glyph(
                    glyph: const WhatsAppGlyph(),
                    label: 'WhatsApp',
                    onTap: () => _copyLink(context, link),
                  ),
                  _ShareChannel(
                    icon: LucideIcons.send,
                    label: 'Telegram',
                    onTap: () => _copyLink(context, link),
                  ),
                  _ShareChannel(
                    icon: LucideIcons.messageSquare,
                    label: 'SMS',
                    onTap: () => _copyLink(context, link),
                  ),
                  _ShareChannel(
                    icon: LucideIcons.ellipsis,
                    label: 'More',
                    onTap: () => _copyLink(context, link),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: Gap.sm),
        Container(
          padding: const EdgeInsets.all(Gap.md),
          decoration: BoxDecoration(
            color: CefColors.brandTint,
            borderRadius: BorderRadius.circular(Sizes.inputRadius),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.info, size: Sizes.icon, color: c.iconColor),
              const SizedBox(width: Gap.sm),
              Expanded(
                child: Text(
                  rider
                      ? 'Invited riders appear in your Riders list as '
                            'Pending Review once they complete registration.'
                      : 'Invited team members appear in your Team list once '
                            'they accept and complete registration.',
                  style: text.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A scannable QR code for [data], painted module by module in the text
/// colour on white with the standard quiet zone.
class _QrCode extends StatelessWidget {
  const _QrCode({required this.data, required this.size});
  final String data;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(
      painter: _QrPainter(
        QrImage(
          QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.M),
        ),
        context.c.textPrimary,
      ),
    ),
  );
}

class _QrPainter extends CustomPainter {
  _QrPainter(this.image, this.color);
  final QrImage image;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const quiet = 2; // modules of white border
    final count = image.moduleCount;
    final cell = size.width / (count + quiet * 2);
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    final paint = Paint()..color = color;
    for (var y = 0; y < count; y++) {
      for (var x = 0; x < count; x++) {
        if (!image.isDark(y, x)) continue;
        canvas.drawRect(
          Rect.fromLTWH(
            (x + quiet) * cell,
            (y + quiet) * cell,
            cell + .5,
            cell + .5,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_QrPainter old) =>
      old.image != image || old.color != color;
}

/// Share target: the standard neutral [IconTile] with a caption -- no
/// third-party brand colours (D-48: only navigation icons are coloured).
class _ShareChannel extends StatelessWidget {
  const _ShareChannel({required this.label, required this.onTap, this.icon})
    : glyph = null;
  const _ShareChannel.glyph({
    required this.label,
    required this.onTap,
    required Widget this.glyph,
  }) : icon = null;
  final IconData? icon;
  final Widget? glyph;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        glyph == null
            ? IconTile(icon!, onTap: onTap)
            : IconTile.glyph(glyph!, onTap: onTap),
        const SizedBox(height: Gap.xs),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, style: Theme.of(context).textTheme.labelSmall),
        ),
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
        'Back to Settings',
        secondary: true,
        onTap: () => AppScope.read(context).resetTo(VRoute.settings),
      ),
    ],
  );
}
