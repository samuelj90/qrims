import 'package:flutter/material.dart';

class AdaptiveScaffold extends StatelessWidget {
  final Widget body;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AdaptiveDestination> destinations;

  const AdaptiveScaffold({
    super.key,
    required this.body,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Mobile layout: width < 600
        if (constraints.maxWidth < 600) {
          return Scaffold(
            body: body,
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: selectedIndex,
              onTap: onDestinationSelected,
              type: BottomNavigationBarType.fixed,
              items: destinations
                  .map((d) => BottomNavigationBarItem(
                        icon: d.icon,
                        label: d.label,
                      ))
                  .toList(),
            ),
          );
        }
        
        // Tablet layout: 600 <= width < 1200
        if (constraints.maxWidth < 1200) {
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  labelType: NavigationRailLabelType.selected,
                  destinations: destinations
                      .map((d) => NavigationRailDestination(
                            icon: d.icon,
                            selectedIcon: d.selectedIcon ?? d.icon,
                            label: Text(d.label),
                          ))
                      .toList(),
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: body),
              ],
            ),
          );
        }

        // Desktop/Foldable Expanded Layout: width >= 1200
        return Scaffold(
          body: Row(
            children: [
              Container(
                width: 260,
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      'QRIMS MOBILE',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: ListView.builder(
                        itemCount: destinations.length,
                        itemBuilder: (context, index) {
                          final destination = destinations[index];
                          final isSelected = index == selectedIndex;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            key: ValueKey(destination.label),
                            child: ListTile(
                              leading: IconTheme(
                                data: IconThemeData(
                                  color: isSelected ? Theme.of(context).colorScheme.primary : null,
                                ),
                                child: destination.icon,
                              ),
                              title: Text(
                                destination.label,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Theme.of(context).colorScheme.primary : null,
                                ),
                              ),
                              selected: isSelected,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              onTap: () => onDestinationSelected(index),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const VerticalDivider(thickness: 1, width: 1),
              Expanded(child: body),
            ],
          ),
        );
      },
    );
  }
}

class AdaptiveDestination {
  final String label;
  final Widget icon;
  final Widget? selectedIcon;

  const AdaptiveDestination({
    required this.label,
    required this.icon,
    this.selectedIcon,
  });
}
