import 'package:flutter/material.dart';

import 'scenes.dart';

void main() => runApp(const CeffloVendorApp());

const ink = Color(0xFF0B0D0E),
    graphite = Color(0xFF24282B),
    soft = Color(0xFFF3F3F0),
    line = Color(0xFFE8E8E4),
    lime = Color(0xFFC7F000),
    muted = Color(0xFF6D7274);

class CeffloVendorApp extends StatelessWidget {
  const CeffloVendorApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Cefflo Vendor',
    builder: (context, child) => ColoredBox(
      color: const Color(0xFFE9E9E5),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: ClipRect(child: child ?? const SizedBox.shrink()),
        ),
      ),
    ),
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(seedColor: lime, surface: Colors.white),
      dividerColor: line,
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: ink, fontSize: 14),
        titleLarge: TextStyle(
          color: ink,
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: -.7,
        ),
        titleMedium: TextStyle(
          color: ink,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    home: const PrototypeShell(),
  );
}

class PrototypeShell extends StatefulWidget {
  const PrototypeShell({super.key});
  @override
  State<PrototypeShell> createState() => _PrototypeShellState();
}

class _PrototypeShellState extends State<PrototypeShell> {
  String current = 'V-11';
  final history = <String>[];
  static const roots = {'V-11', 'V-12', 'V-16', 'V-20', 'V-46'};
  void open(String id) {
    if (id == current) return;
    setState(() {
      history.add(current);
      current = id;
    });
  }

  void back() =>
      setState(() => current = history.isEmpty ? 'V-11' : history.removeLast());
  void showIndex() => showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => SceneIndex(
      open: (id) {
        Navigator.pop(context);
        open(id);
      },
    ),
  );
  @override
  Widget build(BuildContext context) {
    final s = sceneById(current),
        root = roots.contains(current),
        plain = {
          SceneKind.entry,
          SceneKind.auth,
          SceneKind.setup,
          SceneKind.today,
        }.contains(s.kind);
    return PopScope(
      canPop: root,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !root) back();
      },
      child: Scaffold(
        appBar: plain
            ? null
            : CeffloHeader(
                scene: s,
                back: root ? null : back,
                index: showIndex,
              ),
        body: SafeArea(
          bottom: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (c, a) => FadeTransition(
              opacity: a,
              child: SlideTransition(
                position: Tween(begin: const Offset(.025, 0), end: Offset.zero)
                    .animate(
                      CurvedAnimation(parent: a, curve: Curves.easeOutCubic),
                    ),
                child: c,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey(current),
              child: SceneView(scene: s, open: open, index: showIndex),
            ),
          ),
        ),
        bottomNavigationBar: root
            ? CeffloBottomNav(current: current, open: open)
            : null,
        floatingActionButton: root
            ? FloatingActionButton.small(
                heroTag: 'scenes',
                onPressed: showIndex,
                backgroundColor: Colors.white,
                foregroundColor: ink,
                tooltip: 'Open all 60 scenes',
                child: const Icon(Icons.grid_view_rounded),
              )
            : null,
      ),
    );
  }
}

class CeffloHeader extends StatelessWidget implements PreferredSizeWidget {
  const CeffloHeader({
    super.key,
    required this.scene,
    this.back,
    required this.index,
  });
  final Scene scene;
  final VoidCallback? back, index;
  @override
  Size get preferredSize => const Size.fromHeight(66);
  @override
  Widget build(BuildContext context) => AppBar(
    surfaceTintColor: Colors.white,
    backgroundColor: Colors.white,
    scrolledUnderElevation: .5,
    leading: back == null
        ? null
        : IconButton(
            onPressed: back,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
    titleSpacing: back == null ? 20 : 0,
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          scene.id,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: muted,
          ),
        ),
        Text(
          scene.title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -.4,
          ),
        ),
      ],
    ),
    actions: [
      TextButton.icon(
        onPressed: index,
        icon: const Icon(Icons.grid_view_rounded, size: 15),
        label: const Text('60 scenes'),
        style: TextButton.styleFrom(
          foregroundColor: ink,
          textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        ),
      ),
      const SizedBox(width: 8),
    ],
  );
}

class CeffloBottomNav extends StatelessWidget {
  const CeffloBottomNav({super.key, required this.current, required this.open});
  final String current;
  final ValueChanged<String> open;
  static const items = [
    ('V-11', 'Today', Icons.bolt_outlined),
    ('V-12', 'Orders', Icons.inventory_2_outlined),
    ('V-16', 'Zones', Icons.grid_view_outlined),
    ('V-20', 'Riders', Icons.pedal_bike_outlined),
    ('V-46', 'Menu', Icons.menu_rounded),
  ];
  @override
  Widget build(BuildContext context) => NavigationBar(
    height: 62,
    indicatorColor: Colors.transparent,
    backgroundColor: Colors.white,
    selectedIndex: items.indexWhere((e) => e.$1 == current),
    onDestinationSelected: (i) => open(items[i].$1),
    destinations: items
        .map(
          (e) => NavigationDestination(
            icon: Icon(e.$3, size: 21),
            selectedIcon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(e.$3, size: 21),
                const Positioned(
                  bottom: -7,
                  left: 7,
                  child: CircleAvatar(radius: 2, backgroundColor: lime),
                ),
              ],
            ),
            label: e.$2,
          ),
        )
        .toList(),
  );
}

class SceneView extends StatelessWidget {
  const SceneView({
    super.key,
    required this.scene,
    required this.open,
    required this.index,
  });
  final Scene scene;
  final ValueChanged<String> open;
  final VoidCallback index;
  @override
  Widget build(BuildContext context) => switch (scene.kind) {
    SceneKind.entry => EntryScene(scene: scene, open: open),
    SceneKind.auth => AuthScene(scene: scene, open: open),
    SceneKind.setup => SetupScene(scene: scene, open: open),
    SceneKind.today => TodayScene(open: open, index: index),
    SceneKind.orders => OrdersScene(open: open),
    SceneKind.orderDetail => OrderDetail(open: open),
    SceneKind.zones => ZonesScene(open: open),
    SceneKind.zoneDetail => ZonePlan(open: open),
    SceneKind.dispatch => DispatchScene(open: open),
    SceneKind.run => const RunScene(),
    SceneKind.riders => RidersScene(open: open),
    SceneKind.riderDetail => const RiderDetail(),
    SceneKind.products => ProductsScene(open: open),
    SceneKind.product => ProductScene(scene: scene, open: open),
    SceneKind.storefront => const StorefrontScene(),
    SceneKind.hold => HoldScene(scene: scene),
    SceneKind.form => FormScene(scene: scene, open: open),
    SceneKind.list => ListScene(scene: scene, open: open),
    SceneKind.settings => SettingsScene(scene: scene),
    SceneKind.support => SupportScene(scene: scene),
    SceneKind.legal => LegalScene(scene: scene),
  };
}

class PagePad extends StatelessWidget {
  const PagePad({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
    child: child,
  );
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.3,
        color: muted,
      ),
    ),
  );
}

class Intro extends StatelessWidget {
  const Intro(this.scene, {super.key});
  final Scene scene;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Eyebrow(scene.group),
      Text(scene.title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 7),
      Text(scene.subtitle, style: const TextStyle(color: muted, height: 1.5)),
      const SizedBox(height: 20),
    ],
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onTap});
  final String title;
  final String? action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        if (action != null)
          TextButton(
            onPressed: onTap,
            child: Text(
              action!,
              style: const TextStyle(
                color: ink,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    ),
  );
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.text, {super.key, this.live = false});
  final String text;
  final bool live;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    decoration: BoxDecoration(
      color: live ? lime : const Color(0xFFEDEDEB),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: .5,
        color: ink,
      ),
    ),
  );
}

class ListRow extends StatelessWidget {
  const ListRow({
    super.key,
    required this.title,
    required this.subtitle,
    this.status,
    this.live = false,
    this.icon = Icons.circle_outlined,
    this.onTap,
  });
  final String title, subtitle;
  final String? status;
  final bool live;
  final IconData icon;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      constraints: const BoxConstraints(minHeight: 66),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: line)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              border: Border.all(color: line),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: muted),
                ),
              ],
            ),
          ),
          if (status != null) StatusPill(status!, live: live),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, size: 19, color: Colors.grey),
        ],
      ),
    ),
  );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(
    this.label, {
    super.key,
    required this.onTap,
    this.signal = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool signal;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 50,
    child: FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: signal ? lime : ink,
        foregroundColor: signal ? ink : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    ),
  );
}

class SearchBox extends StatelessWidget {
  const SearchBox({super.key});
  @override
  Widget build(BuildContext context) => TextField(
    decoration: InputDecoration(
      hintText: 'Search',
      prefixIcon: const Icon(Icons.search_rounded, size: 20),
      filled: true,
      fillColor: soft,
      border: OutlineInputBorder(
        borderSide: const BorderSide(color: line),
        borderRadius: BorderRadius.circular(13),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: line),
        borderRadius: BorderRadius.circular(13),
      ),
    ),
  );
}

class Tabs extends StatelessWidget {
  const Tabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChange,
  });
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChange;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: List.generate(
        labels.length,
        (i) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(labels[i]),
            selected: i == index,
            onSelected: (_) => onChange(i),
            selectedColor: ink,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: i == index ? Colors.white : ink,
              fontWeight: FontWeight.w700,
            ),
            side: const BorderSide(color: line),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    ),
  );
}

class TodayScene extends StatelessWidget {
  const TodayScene({super.key, required this.open, required this.index});
  final ValueChanged<String> open;
  final VoidCallback index;
  static Widget metric(String n, String label) => Expanded(
    child: Container(
      margin: const EdgeInsets.only(right: 7),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: graphite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            n,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Color(0xFFBFC2C1), fontSize: 11),
          ),
        ],
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: line)),
        ),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'FRIDAY · 4 SEP',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.search_rounded),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none_rounded),
            ),
            IconButton(
              onPressed: index,
              icon: const Icon(Icons.grid_view_rounded),
            ),
          ],
        ),
      ),
      Expanded(
        child: PagePad(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: ink,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Orders today',
                            style: TextStyle(color: Color(0xFFD6D7D5)),
                          ),
                        ),
                        StatusPill('LIVE', live: true),
                      ],
                    ),
                    const Text(
                      '42',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -2,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        metric('18', 'Ready'),
                        metric('16', 'Ongoing'),
                        metric('8', 'Done'),
                      ],
                    ),
                  ],
                ),
              ),
              SectionTitle(
                'Need attention',
                action: 'See All ›',
                onTap: () => open('V-12'),
              ),
              InkWell(
                onTap: () => open('V-12'),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: soft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: lime,
                        foregroundColor: ink,
                        child: Text(
                          '2',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Orders need action',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '1 unassigned · 1 delayed',
                              style: TextStyle(color: muted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              SectionTitle(
                'Recent deliveries',
                action: 'See All ›',
                onTap: () => open('V-16'),
              ),
              ListRow(
                title: 'Zone North',
                subtitle: 'Amir · 7 deliveries',
                status: 'On route',
                live: true,
                onTap: () => open('V-19'),
              ),
              ListRow(
                title: 'Zone Central',
                subtitle: 'Hafiz · 5 deliveries',
                status: 'Completed',
                onTap: () => open('V-19'),
              ),
              ListRow(
                title: 'Zone South',
                subtitle: 'Aiman · 4 deliveries',
                status: 'Ready',
                live: true,
                onTap: () => open('V-17'),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class OrdersScene extends StatefulWidget {
  const OrdersScene({super.key, required this.open});
  final ValueChanged<String> open;
  @override
  State<OrdersScene> createState() => _OrdersSceneState();
}

class _OrdersSceneState extends State<OrdersScene> {
  int tab = 0;
  @override
  Widget build(BuildContext context) => PagePad(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('ORDERS'),
        const Text(
          'Orders',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        const SearchBox(),
        const SizedBox(height: 14),
        Tabs(
          labels: const ['All', 'Ready', 'Ongoing', 'Done'],
          index: tab,
          onChange: (i) => setState(() => tab = i),
        ),
        const SizedBox(height: 10),
        ListRow(
          title: '#CF-1048',
          subtitle: 'Taman Melati · 3 items',
          status: 'Ready',
          live: true,
          onTap: () => widget.open('V-13'),
        ),
        ListRow(
          title: '#CF-1047',
          subtitle: 'Setapak · 2 items',
          status: 'Ready',
          live: true,
          onTap: () => widget.open('V-13'),
        ),
        ListRow(
          title: '#CF-1046',
          subtitle: 'Wangsa Maju · 4 items',
          status: 'Ongoing',
          live: true,
          onTap: () => widget.open('V-13'),
        ),
        ListRow(
          title: '#CF-1045',
          subtitle: 'Gombak · 1 item',
          status: 'Done',
          onTap: () => widget.open('V-13'),
        ),
        const SizedBox(height: 18),
        PrimaryButton('Create New Order', onTap: () => widget.open('V-14')),
      ],
    ),
  );
}

class OrderDetail extends StatelessWidget {
  const OrderDetail({super.key, required this.open});
  final ValueChanged<String> open;
  @override
  Widget build(BuildContext context) => PagePad(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('ORDER · #CF-1048'),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Taman Melati',
                style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800),
              ),
            ),
            SizedBox(width: 8),
            StatusPill('Ready', live: true),
          ],
        ),
        const SizedBox(height: 20),
        const InfoBlock('Customer', 'Nur Aina', '012-345 6789'),
        const InfoBlock(
          'Delivery',
          '12 Jalan Melati 3',
          'Kuala Lumpur · Leave at guardhouse',
        ),
        const SectionTitle('Items'),
        const LineItem('Nasi Lemak Ayam', '2 × RM12.00'),
        const LineItem('Iced Matcha Latte', '1 × RM9.50'),
        const SectionTitle('Order activity'),
        const ListRow(
          title: 'Order approved',
          subtitle: '09:42 · Sarah',
          icon: Icons.check_rounded,
        ),
        const ListRow(
          title: 'Ready for planning',
          subtitle: 'Zone North · 10:05',
          icon: Icons.route_outlined,
        ),
        const SizedBox(height: 18),
        PrimaryButton('Edit Order', onTap: () => open('V-15')),
      ],
    ),
  );
}

class InfoBlock extends StatelessWidget {
  const InfoBlock(this.label, this.title, this.detail, {super.key});
  final String label, title, detail;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: soft,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            color: muted,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 3),
        Text(detail, style: const TextStyle(color: muted, fontSize: 12)),
      ],
    ),
  );
}

class LineItem extends StatelessWidget {
  const LineItem(this.name, this.value, {super.key});
  final String name, value;
  @override
  Widget build(BuildContext context) => Container(
    height: 52,
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: line)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(name),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

class ZonesScene extends StatefulWidget {
  const ZonesScene({super.key, required this.open});
  final ValueChanged<String> open;
  @override
  State<ZonesScene> createState() => _ZonesSceneState();
}

class _ZonesSceneState extends State<ZonesScene> {
  int tab = 0;
  @override
  Widget build(BuildContext context) => PagePad(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('TODAY · DELIVERY OPERATIONS'),
        const Text(
          'Zones',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        Tabs(
          labels: const ['Ready', 'Ongoing', 'Completed'],
          index: tab,
          onChange: (i) => setState(() => tab = i),
        ),
        const SizedBox(height: 12),
        ListRow(
          title: 'Zone North',
          subtitle: '12 orders · 2 riders',
          status: tab == 1
              ? 'Ongoing'
              : tab == 2
              ? 'Completed'
              : 'Ready',
          live: tab < 2,
          onTap: () => widget.open(tab == 1 ? 'V-19' : 'V-17'),
        ),
        ListRow(
          title: 'Zone South',
          subtitle: '8 orders · 2 riders',
          status: tab == 2 ? 'Completed' : 'Ready',
          live: tab < 2,
          onTap: () => widget.open('V-17'),
        ),
        ListRow(
          title: 'Zone Central',
          subtitle: '9 orders · 1 rider',
          status: tab == 2 ? 'Completed' : 'Ongoing',
          live: tab < 2,
          onTap: () => widget.open('V-19'),
        ),
      ],
    ),
  );
}

class ZonePlan extends StatelessWidget {
  const ZonePlan({super.key, required this.open});
  final ValueChanged<String> open;
  @override
  Widget build(BuildContext context) => PagePad(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('ZONE NORTH'),
        const Text(
          'Delivery Plan',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          '12 orders · 2 riders · No blocking conflicts',
          style: TextStyle(color: muted),
        ),
        const SectionTitle('Suggested runs'),
        const InfoBlock(
          'RUN 01',
          'Amir · Motorcycle',
          '7 deliveries · Ready to dispatch',
        ),
        const InfoBlock(
          'RUN 02',
          'Hafiz · Car',
          '5 deliveries · Ready to dispatch',
        ),
        const SizedBox(height: 18),
        PrimaryButton('Review Plan', signal: true, onTap: () => open('V-18')),
      ],
    ),
  );
}

class DispatchScene extends StatelessWidget {
  const DispatchScene({super.key, required this.open});
  final ValueChanged<String> open;
  @override
  Widget build(BuildContext context) => PagePad(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('PLAN REVIEW'),
        const Text(
          'Review & Dispatch',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 18),
        const InfoBlock('ZONE', 'Zone North', '12 orders · 2 planned runs'),
        const InfoBlock(
          'RUN 01',
          'Amir · Motorcycle',
          '7 stops · Capacity checked',
        ),
        const InfoBlock('RUN 02', 'Hafiz · Car', '5 stops · Capacity checked'),
        const SizedBox(height: 18),
        PrimaryButton('Dispatch Plan', signal: true, onTap: () => open('V-19')),
        const SizedBox(height: 10),
        const Text(
          'Prototype only · No dispatch request is sent.',
          style: TextStyle(fontSize: 11, color: muted),
        ),
      ],
    ),
  );
}

class RunScene extends StatelessWidget {
  const RunScene({super.key});
  @override
  Widget build(BuildContext context) => PagePad(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('ZONE NORTH · RUN 01'),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Active Run',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
            ),
            SizedBox(width: 8),
            StatusPill('On route', live: true),
          ],
        ),
        const SizedBox(height: 15),
        const LinearProgressIndicator(
          value: .43,
          minHeight: 5,
          color: lime,
          backgroundColor: line,
        ),
        const SizedBox(height: 7),
        const Text(
          '3 of 7 stops completed',
          style: TextStyle(color: muted, fontSize: 12),
        ),
        const SectionTitle('Stops'),
        const ListRow(
          title: '01 · Taman Melati',
          subtitle: 'Delivered · 10:32',
          status: 'Done',
        ),
        const ListRow(
          title: '02 · Setapak',
          subtitle: 'Rider on the way',
          status: 'Active',
          live: true,
        ),
        const ListRow(
          title: '03 · Wangsa Maju',
          subtitle: 'Upcoming',
          status: 'Next',
        ),
      ],
    ),
  );
}

class RidersScene extends StatelessWidget {
  const RidersScene({super.key, required this.open});
  final ValueChanged<String> open;
  @override
  Widget build(BuildContext context) => PagePad(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('WORKFORCE'),
        const Text(
          'Riders',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const SearchBox(),
        const SizedBox(height: 12),
        ListRow(
          title: 'Amir',
          subtitle: 'Motorcycle · RUN 01',
          status: 'On delivery',
          live: true,
          icon: Icons.pedal_bike_outlined,
          onTap: () => open('V-21'),
        ),
        ListRow(
          title: 'Hafiz',
          subtitle: 'Car · No active run',
          status: 'Available',
          live: true,
          icon: Icons.directions_car_outlined,
          onTap: () => open('V-21'),
        ),
        ListRow(
          title: 'Aiman',
          subtitle: 'Motorcycle · No active run',
          status: 'Available',
          live: true,
          icon: Icons.pedal_bike_outlined,
          onTap: () => open('V-21'),
        ),
        const ListRow(
          title: 'Farid',
          subtitle: 'Van · Last seen yesterday',
          status: 'Offline',
          icon: Icons.airport_shuttle_outlined,
        ),
        const SizedBox(height: 18),
        PrimaryButton('Invite Rider', onTap: () => open('V-22')),
      ],
    ),
  );
}

class RiderDetail extends StatelessWidget {
  const RiderDetail({super.key});
  @override
  Widget build(BuildContext context) => PagePad(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('RIDER'),
        const Text(
          'Amir Rahman',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const StatusPill('On delivery', live: true),
        const SizedBox(height: 18),
        const InfoBlock('VEHICLE', 'Motorcycle', 'WXY 2381'),
        const InfoBlock(
          'CURRENT RUN',
          'RUN 01 · Zone North',
          '7 deliveries · 3 completed',
        ),
        const InfoBlock(
          'CAPACITY',
          '5 active orders',
          'Prototype value · No live telemetry',
        ),
        const SectionTitle('Today'),
        const ListRow(
          title: '7 assigned',
          subtitle: '3 completed · 4 remaining',
          icon: Icons.route_outlined,
        ),
      ],
    ),
  );
}

final menuMap = <String, List<(String, String, String, IconData)>>{
  'V-23': [
    ('Sarah Lim', 'Owner · Active', 'V-24', Icons.person_outline),
    ('Daniel Tan', 'Operator · Active', 'V-24', Icons.person_outline),
    (
      'Invite team member',
      'Trusted invitation flow',
      'V-25',
      Icons.person_add_alt_1_outlined,
    ),
  ],
  'V-26': [
    (
      'Coverage area',
      '12 km radius · Kuala Lumpur',
      'V-27',
      Icons.radar_outlined,
    ),
    (
      'Zone configuration',
      '3 reusable zones',
      'V-28',
      Icons.grid_view_outlined,
    ),
  ],
  'V-28': [
    ('Zone North', 'Enabled · Priority 1', 'V-30', Icons.grid_3x3_outlined),
    ('Zone Central', 'Enabled · Priority 2', 'V-30', Icons.grid_3x3_outlined),
    (
      'Create zone',
      'Add a reusable delivery zone',
      'V-29',
      Icons.add_box_outlined,
    ),
  ],
  'V-31': [
    (
      'View storefront',
      'Customer-facing preview',
      'V-32',
      Icons.phone_android_outlined,
    ),
    (
      'Appearance & branding',
      'Theme and identity',
      'V-33',
      Icons.palette_outlined,
    ),
    (
      'Products',
      'Active and hidden catalogue',
      'V-34',
      Icons.inventory_2_outlined,
    ),
  ],
  'V-37': [
    (
      'Business information',
      'Kopi Mak Long',
      'V-38',
      Icons.storefront_outlined,
    ),
    (
      'Business address',
      'Setapak, Kuala Lumpur',
      'V-39',
      Icons.location_on_outlined,
    ),
    ('Business hours', 'Open today · 9am–8pm', 'V-40', Icons.schedule_outlined),
    (
      'Delivery settings',
      'Reconciliation hold',
      'V-41',
      Icons.local_shipping_outlined,
    ),
  ],
  'V-42': [
    ('Personal details', 'Sarah Lim · Owner', 'V-43', Icons.person_outline),
  ],
  'V-44': [
    (
      'Change password',
      'Authenticated security flow',
      'V-45',
      Icons.lock_outline,
    ),
  ],
  'V-46': [
    ('Team', 'People and access', 'V-23', Icons.groups_outlined),
    (
      'Service Area',
      'Coverage and configured zones',
      'V-26',
      Icons.radar_outlined,
    ),
    (
      'Storefront / Appearance',
      'Branding and products',
      'V-31',
      Icons.storefront_outlined,
    ),
    (
      'Business Profile',
      'Identity and operating details',
      'V-37',
      Icons.business_outlined,
    ),
    ('Profile', 'Personal account', 'V-42', Icons.person_outline),
    (
      'Security',
      'Password and account security',
      'V-44',
      Icons.security_outlined,
    ),
    (
      'Notifications',
      'Operational preferences',
      'V-47',
      Icons.notifications_none_rounded,
    ),
    ('Language', 'English', 'V-48', Icons.language_outlined),
    ('Appearance', 'System', 'V-49', Icons.contrast_outlined),
    ('Help & Support', 'Guidance and contact', 'V-55', Icons.help_outline),
    (
      'About Cefflo',
      'Version 0.1 Flutter prototype',
      'V-60',
      Icons.info_outline,
    ),
  ],
};

class ListScene extends StatelessWidget {
  const ListScene({super.key, required this.scene, required this.open});
  final Scene scene;
  final ValueChanged<String> open;
  @override
  Widget build(BuildContext context) {
    final rows = menuMap[scene.id] ?? [];
    return PagePad(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Intro(scene),
          ...rows.map(
            (r) => ListRow(
              title: r.$1,
              subtitle: r.$2,
              icon: r.$4,
              onTap: () => open(r.$3),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductsScene extends StatelessWidget {
  const ProductsScene({super.key, required this.open});
  final ValueChanged<String> open;
  @override
  Widget build(BuildContext context) => PagePad(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('BUSINESS · STOREFRONT'),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Products',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
              ),
            ),
            FilledButton.icon(
              onPressed: () => open('V-36'),
              style: FilledButton.styleFrom(
                backgroundColor: ink,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const SearchBox(),
        const SectionTitle('Food'),
        ListRow(
          title: 'Nasi Lemak Ayam',
          subtitle: 'Coconut rice · RM12.00',
          status: 'Active',
          onTap: () => open('V-35'),
        ),
        ListRow(
          title: 'Mee Kari Special',
          subtitle: 'Rich curry noodles · RM10.00',
          status: 'Active',
          onTap: () => open('V-35'),
        ),
        const SectionTitle('Drinks'),
        ListRow(
          title: 'Iced Matcha Latte',
          subtitle: 'Fresh chilled milk · RM9.50',
          status: 'Active',
          onTap: () => open('V-35'),
        ),
        const SectionTitle('Dessert'),
        ListRow(
          title: 'Pandan Cloud Cake',
          subtitle: 'Coconut cream · RM9.80',
          status: 'Hidden',
          onTap: () => open('V-35'),
        ),
      ],
    ),
  );
}

class ProductScene extends StatelessWidget {
  const ProductScene({super.key, required this.scene, required this.open});
  final Scene scene;
  final ValueChanged<String> open;
  @override
  Widget build(BuildContext context) => PagePad(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Intro(scene),
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: soft,
            border: Border.all(color: line),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Icon(Icons.image_outlined, size: 34, color: muted),
          ),
        ),
        const SizedBox(height: 14),
        const Field('Product name', 'Nasi Lemak Ayam'),
        const Field('Category', 'Food'),
        const Field('Description', 'Coconut rice, sambal and crispy chicken.'),
        const Field('Display price', 'RM12.00'),
        const SettingsToggle(
          title: 'Active',
          subtitle: 'Visible in the working catalogue',
        ),
        const SizedBox(height: 10),
        PrimaryButton(
          'Save Product',
          onTap: () => localFeedback(
            context,
            'Product retained in this local prototype.',
          ),
        ),
        if (scene.id == 'V-35')
          TextButton(
            onPressed: () => localFeedback(context, 'Archive is preview-only.'),
            child: const Text(
              'Archive Product',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
      ],
    ),
  );
}

class FormScene extends StatelessWidget {
  const FormScene({super.key, required this.scene, required this.open});
  final Scene scene;
  final ValueChanged<String> open;
  @override
  Widget build(BuildContext context) {
    final fields = switch (scene.id) {
      'V-07' || 'V-38' => [
        ('Business name', 'Kopi Mak Long'),
        ('Phone', '012-345 6789'),
        ('Description', 'Local favourites, made fresh.'),
      ],
      'V-08' || 'V-39' => [
        ('Address', '12 Jalan Setapak'),
        ('City', 'Kuala Lumpur'),
        ('Postcode', '53300'),
      ],
      'V-09' ||
      'V-27' => [('Operating centre', 'Setapak'), ('Delivery radius', '12 km')],
      'V-14' || 'V-15' => [
        ('Customer name', 'Nur Aina'),
        ('Phone', '012-345 6789'),
        ('Delivery address', 'Taman Melati'),
        ('Delivery notes', 'Leave at guardhouse'),
      ],
      'V-22' => [
        ('Rider email', 'rider@example.com'),
        ('Vehicle', 'Motorcycle'),
      ],
      'V-25' => [
        ('Team member email', 'team@example.com'),
        ('Role', 'Operator'),
      ],
      'V-29' || 'V-30' => [('Zone name', 'Zone North'), ('Priority', '1')],
      'V-43' => [('Full name', 'Sarah Lim'), ('Phone', '012-345 6789')],
      'V-45' => [
        ('Current password', ''),
        ('New password', ''),
        ('Confirm password', ''),
      ],
      'V-57' => [
        ('Subject', 'Operational help'),
        ('Message', 'Describe what you need help with.'),
      ],
      _ => [('Name', 'Example'), ('Details', 'Local prototype value')],
    };
    return PagePad(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Intro(scene),
          ...fields.map((f) => Field(f.$1, f.$2)),
          PrimaryButton(
            scene.next == null ? 'Save' : 'Continue',
            onTap: () => scene.next == null
                ? localFeedback(context, 'Saved locally for prototype review.')
                : open(scene.next!),
          ),
          const SizedBox(height: 10),
          const Text(
            'Prototype only · No data is sent or persisted.',
            style: TextStyle(fontSize: 11, color: muted),
          ),
        ],
      ),
    );
  }
}

class Field extends StatelessWidget {
  const Field(this.label, this.value, {super.key});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      initialValue: value,
      obscureText: label.toLowerCase().contains('password'),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: line),
        ),
      ),
    ),
  );
}

class SettingsScene extends StatelessWidget {
  const SettingsScene({super.key, required this.scene});
  final Scene scene;
  @override
  Widget build(BuildContext context) => PagePad(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Intro(scene),
        if (scene.id == 'V-33') const ThemeTiles(),
        if (scene.id == 'V-40')
          ...[
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday',
            'Sunday',
          ].map(
            (d) => SettingsToggle(
              title: d,
              subtitle: d == 'Sunday' ? 'Closed' : '9:00 AM – 8:00 PM',
            ),
          ),
        if (scene.id == 'V-47') ...const [
          SettingsToggle(
            title: 'Order updates',
            subtitle: 'Important order activity',
          ),
          SettingsToggle(
            title: 'Rider updates',
            subtitle: 'Assignment and run activity',
          ),
          SettingsToggle(
            title: 'Exceptions',
            subtitle: 'Issues requiring attention',
          ),
        ],
        if (scene.id == 'V-48')
          ...['English', 'Bahasa Melayu'].map(
            (l) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l),
              trailing: Icon(
                l == 'English'
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
              ),
            ),
          ),
        if (scene.id == 'V-49')
          ...['System', 'Light', 'Dark'].map(
            (l) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l),
              trailing: Icon(
                l == 'System'
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
              ),
            ),
          ),
        if (scene.id == 'V-24') ...const [
          InfoBlock('MEMBER', 'Sarah Lim', 'Owner · Active'),
          SettingsToggle(
            title: 'Operational access',
            subtitle: 'Orders, zones and riders',
          ),
        ],
        if (![
          'V-33',
          'V-40',
          'V-47',
          'V-48',
          'V-49',
          'V-24',
        ].contains(scene.id))
          const SettingsToggle(
            title: 'Enabled',
            subtitle: 'Local prototype setting',
          ),
        const SizedBox(height: 20),
        PrimaryButton(
          'Save Changes',
          onTap: () => localFeedback(
            context,
            'Changes kept only for this preview session.',
          ),
        ),
      ],
    ),
  );
}

class SettingsToggle extends StatefulWidget {
  const SettingsToggle({
    super.key,
    required this.title,
    required this.subtitle,
  });
  final String title, subtitle;
  @override
  State<SettingsToggle> createState() => _SettingsToggleState();
}

class _SettingsToggleState extends State<SettingsToggle> {
  bool value = true;
  @override
  Widget build(BuildContext context) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(
      widget.title,
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
    subtitle: Text(widget.subtitle),
    value: value,
    activeTrackColor: ink,
    activeThumbColor: lime,
    onChanged: (v) => setState(() => value = v),
  );
}

class ThemeTiles extends StatelessWidget {
  const ThemeTiles({super.key});
  @override
  Widget build(BuildContext context) => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: 2,
    mainAxisSpacing: 10,
    crossAxisSpacing: 10,
    childAspectRatio: 1.4,
    children: ['Clean', 'Warm', 'Fresh', 'Midnight']
        .map(
          (t) => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: t == 'Midnight' ? graphite : soft,
              border: Border.all(color: t == 'Clean' ? ink : line),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                t,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: t == 'Midnight' ? Colors.white : ink,
                ),
              ),
            ),
          ),
        )
        .toList(),
  );
}

class StorefrontScene extends StatelessWidget {
  const StorefrontScene({super.key});
  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFFF8F8F5),
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            CircleAvatar(
              backgroundColor: ink,
              foregroundColor: Colors.white,
              child: Text('KM'),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kopi Mak Long',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  'Direct order page · Preview only',
                  style: TextStyle(color: muted, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        const Spacer(),
        Center(
          child: Container(
            width: 220,
            height: 170,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(100),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x16000000),
                  blurRadius: 28,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            child: const Icon(Icons.local_cafe_outlined, size: 86),
          ),
        ),
        const Spacer(),
        const Text(
          'Caramel Macchiato',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'Velvety milk, deep espresso and a soft caramel finish.',
          style: TextStyle(color: muted),
        ),
        const SizedBox(height: 10),
        const Text(
          'RM8.50',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 14),
        PrimaryButton('Preview only · Ordering not connected', onTap: () {}),
      ],
    ),
  );
}

class EntryScene extends StatelessWidget {
  const EntryScene({super.key, required this.scene, required this.open});
  final Scene scene;
  final ValueChanged<String> open;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(28),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 66,
          height: 66,
          decoration: BoxDecoration(
            color: ink,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.bolt_rounded, color: lime, size: 32),
        ),
        const SizedBox(height: 24),
        const Text(
          'CEFFLO VENDOR',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your operation,\nunder control.',
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.5,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'A calm mobile command surface for local delivery operations.',
          style: TextStyle(color: muted, height: 1.5),
        ),
        const SizedBox(height: 30),
        PrimaryButton('Enter Prototype', onTap: () => open(scene.next!)),
      ],
    ),
  );
}

class AuthScene extends StatelessWidget {
  const AuthScene({super.key, required this.scene, required this.open});
  final Scene scene;
  final ValueChanged<String> open;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: PagePad(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          const Text(
            'CEFFLO VENDOR',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 36),
          Text(
            scene.title,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(scene.subtitle, style: const TextStyle(color: muted)),
          const SizedBox(height: 28),
          if (scene.id != 'V-05') const Field('Email', 'vendor@example.com'),
          if (scene.id == 'V-02') const Field('Password', ''),
          if (scene.id == 'V-03') ...const [
            Field('Business name', 'Kopi Mak Long'),
            Field('Password', ''),
          ],
          if (scene.id == 'V-05') ...const [
            Field('New password', ''),
            Field('Confirm password', ''),
          ],
          PrimaryButton(
            scene.id == 'V-04'
                ? 'Send Recovery Link'
                : scene.id == 'V-05'
                ? 'Reset Password'
                : scene.id == 'V-03'
                ? 'Create Account'
                : 'Sign In',
            onTap: () => open(scene.next!),
          ),
          const SizedBox(height: 12),
          if (scene.id == 'V-02')
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => open('V-04'),
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(color: ink),
                  ),
                ),
                TextButton(
                  onPressed: () => open('V-03'),
                  child: const Text(
                    'Create account',
                    style: TextStyle(color: ink),
                  ),
                ),
              ],
            ),
        ],
      ),
    ),
  );
}

class SetupScene extends StatelessWidget {
  const SetupScene({super.key, required this.scene, required this.open});
  final Scene scene;
  final ValueChanged<String> open;
  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            scene.id == 'V-06' ? 'SETUP · 1 OF 5' : 'SETUP COMPLETE',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
              color: muted,
            ),
          ),
          const SizedBox(height: 22),
          Icon(
            scene.id == 'V-10'
                ? Icons.check_circle_rounded
                : Icons.tune_rounded,
            size: 54,
            color: scene.id == 'V-10' ? lime : ink,
          ),
          const SizedBox(height: 18),
          Text(
            scene.title,
            style: const TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            scene.subtitle,
            style: const TextStyle(color: muted, height: 1.5),
          ),
          const SizedBox(height: 30),
          PrimaryButton(
            scene.id == 'V-10' ? 'Open Workspace' : 'Start Setup',
            onTap: () => open(scene.next!),
          ),
        ],
      ),
    ),
  );
}

class HoldScene extends StatelessWidget {
  const HoldScene({super.key, required this.scene});
  final Scene scene;
  @override
  Widget build(BuildContext context) => PagePad(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: ink,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock_clock_outlined, color: lime, size: 30),
              const SizedBox(height: 24),
              const Text(
                'FOUNDER HOLD',
                style: TextStyle(
                  color: lime,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                scene.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                scene.subtitle,
                style: const TextStyle(color: Color(0xFFBFC2C1), height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'This scene remains visible without simulating an unsupported contract or success state.',
          style: TextStyle(color: muted, height: 1.6),
        ),
      ],
    ),
  );
}

class SupportScene extends StatelessWidget {
  const SupportScene({super.key, required this.scene});
  final Scene scene;
  @override
  Widget build(BuildContext context) => PagePad(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Intro(scene),
        const InfoBlock(
          'SUPPORT',
          'Operational help',
          'Guidance for orders, zones and riders.',
        ),
        ...[
          'Getting started',
          'Managing today’s orders',
          'Preparing a delivery plan',
          'Inviting a rider',
        ].map(
          (q) => ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(q, style: const TextStyle(fontWeight: FontWeight.w700)),
            children: const [
              Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Prototype guidance content. No support request is sent.',
                  style: TextStyle(color: muted),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class LegalScene extends StatelessWidget {
  const LegalScene({super.key, required this.scene});
  final Scene scene;
  @override
  Widget build(BuildContext context) => PagePad(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Intro(scene),
        if (scene.id == 'V-60')
          const InfoBlock(
            'BUILD',
            'Cefflo Vendor Flutter',
            'Prototype 0.1 · Local data only',
          ),
        for (final title in [
          'Purpose',
          'Your responsibilities',
          'Information and security',
        ]) ...[
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 6),
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
          const Text(
            'This is concise prototype copy for structural review. Final legal content remains subject to the approved Cefflo legal source.',
            style: TextStyle(color: muted, height: 1.6),
          ),
        ],
      ],
    ),
  );
}

class SceneIndex extends StatefulWidget {
  const SceneIndex({super.key, required this.open});
  final ValueChanged<String> open;
  @override
  State<SceneIndex> createState() => _SceneIndexState();
}

class _SceneIndexState extends State<SceneIndex> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final filtered = scenes
        .where(
          (s) => ('${s.id} ${s.title} ${s.group}').toLowerCase().contains(
            query.toLowerCase(),
          ),
        )
        .toList();
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: .9,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CEFFLO VENDOR FLUTTER',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                  color: muted,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                '60-scene prototype',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              TextField(
                onChanged: (v) => setState(() => query = v),
                decoration: InputDecoration(
                  hintText: 'Search V-01 to V-60',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: soft,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final s = filtered[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Text(
                        s.id,
                        style: const TextStyle(
                          fontSize: 11,
                          color: muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      title: Text(
                        s.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        s.group,
                        style: const TextStyle(fontSize: 9, letterSpacing: .7),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (s.hold) const StatusPill('HOLD'),
                          const Icon(Icons.chevron_right_rounded, size: 18),
                        ],
                      ),
                      onTap: () => widget.open(s.id),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void localFeedback(BuildContext context, String message) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
