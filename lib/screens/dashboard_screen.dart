// DASHBOARD SCREEN - Phase 2: Grid Layout with Card Sizes
// Supports XL/L/M/S card sizes with automatic row packing

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data_provider.dart';
import '../models/card_config.dart';
import '../widgets/apk_warning_banner.dart';
import '../widgets/dashboard_grid.dart';
import '../widgets/distance_consumption_card.dart';
import '../widgets/costs_overview_card.dart';
import '../widgets/price_tracker_card.dart';
import '../widgets/efficiency_monitor_card.dart';
import '../widgets/cost_per_km_card.dart';
import '../widgets/timeline_heatmap_card.dart';
import '../widgets/card_visibility_selector.dart';
import 'history_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DataProvider>();
    final appColor = provider.themeColor;
    final selectedCar = provider.selectedCar;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    if (selectedCar == null) {
      return const Scaffold(body: Center(child: Text("Selecteer eerst een voertuig.")));
    }

    final visibleCardsList = provider.visibleCards.where((c) => c.isVisible).toList();
    final hasNoVisibleCards = visibleCardsList.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_toTitleCase(selectedCar.name)),
        centerTitle: false,
        titleSpacing: 24,
        elevation: 0,
        backgroundColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, size: 24), 
            onPressed: () => _showHistoryModal(context)
          ),
          if (provider.cars.length > 1)
            IconButton(
              icon: Icon(Icons.directions_car, color: appColor, size: 24), 
              onPressed: () => _showVehicleSelector(context, provider)
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: hasNoVisibleCards
          ? _buildEmptyState(context, provider, appColor)
          : SingleChildScrollView(
              child: Column(
                children: [
                  const ApkWarningBanner(),
                  const SizedBox(height: 24),
                  
                  // Grid layout with size-aware cards
                  DashboardGrid(
                    configs: visibleCardsList,
                    cards: _buildCards(context, visibleCardsList, appColor, isDarkMode),
                  ),
                ],
              ),
            ),
    );
  }
  
  List<Widget> _buildCards(
    BuildContext context,
    List<DashboardCardConfig> configs,
    Color appColor,
    bool isDarkMode,
  ) {
    return configs.map((config) {
      Widget card;
      
      switch (config.id) {
        case 'distance_consumption':
          card = DistanceConsumptionCard(size: config.size);
          break;
          
        case 'costs_overview':
          card = CostsOverviewCard(size: config.size);
          break;
          
        case 'price_tracker':
          card = PriceTrackerCard(appColor: appColor, isDarkMode: isDarkMode);
          break;
          
        case 'efficiency_monitor':
          card = EfficiencyMonitorCard(appColor: appColor, isDarkMode: isDarkMode);
          break;
          
        case 'cost_per_km':
          card = CostPerKmCard(appColor: appColor, isDarkMode: isDarkMode);
          break;
          
        case 'timeline_heatmap':
          card = TimelineHeatmapCard(appColor: appColor, isDarkMode: isDarkMode);
          break;
          
        default:
          card = const SizedBox.shrink();
      }
      
      // Wrap with long-press gesture
      return GestureDetector(
        onLongPress: () => _showCardVisibilitySelector(context),
        child: card,
      );
    }).toList();
  }
  
  Widget _buildEmptyState(BuildContext context, DataProvider provider, Color appColor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const Expanded(child: SizedBox()),
                  
                  Icon(
                    Icons.dashboard_outlined,
                    size: 80,
                    color: Colors.grey.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Geen cards actief',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Voeg cards toe aan je dashboard',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).hintColor.withValues(alpha: 0.7),
                    ),
                  ),
                  
                  const Expanded(child: SizedBox()),
                  
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showCardVisibilitySelector(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Cards Toevoegen'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: appColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCardVisibilitySelector(BuildContext context) {
    final provider = Provider.of<DataProvider>(context, listen: false);
    showCardVisibilitySelector(
      context: context,
      cards: provider.visibleCards,
      onSave: (cards) {
        provider.updateCardVisibility(cards);
      },
    );
  }

  void _showHistoryModal(BuildContext context) {
    showModalBottomSheet(
      context: context, 
      isScrollControlled: true, 
      backgroundColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.9, 
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor, 
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24))
          ), 
          child: const HistoryScreen(isModal: true)
        )
      )
    );
  }

  void _showVehicleSelector(BuildContext context, DataProvider provider) {
    showModalBottomSheet(
      context: context, 
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24))
      ), 
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ListView(
            shrinkWrap: true,
            children: provider.cars.map((c) {
              final isSelected = provider.selectedCar?.id == c.id;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                leading: Icon(Icons.directions_car, color: isSelected ? provider.themeColor : Colors.grey), 
                title: Text(c.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)), 
                trailing: isSelected ? Icon(Icons.check, color: provider.themeColor) : null,
                onTap: () { 
                  provider.selectCar(c); 
                  Navigator.pop(context); 
                }
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}