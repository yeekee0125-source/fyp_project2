import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserInsightsPage extends StatefulWidget {
  final String userName;
  const UserInsightsPage({super.key, required this.userName});

  @override
  State<UserInsightsPage> createState() => _UserInsightsPageState();
}

class _UserInsightsPageState extends State<UserInsightsPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  late String userId;

  Map<String, int> preferenceData = {};
  final List<Color> chartColors = [
    Colors.orange,
    Colors.deepOrange,
    Colors.amber,
    Colors.redAccent,
    Colors.brown,
    Colors.green,
    Colors.purple,
  ];

  int totalLikes = 0;
  int totalComments = 0;
  int totalSaves = 0;
  int recipeCount = 0;
  int videoCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    userId = supabase.auth.currentUser!.id;
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    try {
      final List likesData = await supabase.from('likes').select('id').eq('user_id', userId);
      final List commentsData = await supabase.from('comments').select('id').eq('user_id', userId);
      final List savesData = await supabase.from('saves').select('id').eq('user_id', userId);

      final List recipesData = await supabase.from('recipes').select('id').eq('user_id', userId);
      final List videosData = await supabase.from('videos').select('id').eq('user_id', userId);

      final userData = await supabase
          .from('users')
          .select('preferences')
          .eq('id', userId)
          .single();

      Map<String, int> prefCount = {};
      if (userData['preferences'] != null) {
        String prefs = userData['preferences'];
        // If preferences are comma-separated (e.g., "Vegan, Keto, Spicy"), we split them
        List<String> prefsList = prefs.split(',').map((e) => e.trim()).toList();

        for (var p in prefsList) {
          if (p.isNotEmpty) {
            prefCount[p] = (prefCount[p] ?? 0) + 1;
          }
        }
      }

      if (mounted) {
        setState(() {
          totalLikes = likesData.length;
          totalComments = commentsData.length;
          totalSaves = savesData.length;
          recipeCount = recipesData.length;
          videoCount = videosData.length;
          preferenceData = prefCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Insight Fetch Error: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBE6),
      appBar: AppBar(
        title: Text("Hello, ${widget.userName}", style: const TextStyle(color: Colors.brown)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.brown),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Insights", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 25),

            _buildChartCard(
              title: "Interaction Source",
              child: Row(
                children: [
                  Expanded(flex: 2, child: _buildPieChartLegend()),
                  Expanded(flex: 3, child: _buildPieChart()),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _buildChartCard(
              title: "Dietary Preferences",
              child: preferenceData.isEmpty
                  ? const Center(child: Text("No preferences selected"))
                  : Column(
                children: [
                  SizedBox(height: 220, child: _buildPreferenceChart()),
                  const SizedBox(height: 15),
                  _buildPreferenceLegend(),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _buildChartCard(
              title: "Content Distribution",
              child: Column(
                children: [
                  const Text("Recipes vs. Video Tutorials", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 20),
                  SizedBox(height: 200, child: _buildBarChart()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    double total = (totalLikes + totalComments + totalSaves).toDouble();
    if (total == 0) return const Center(child: Text("No data yet"));
    return SizedBox(
      height: 140,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 30,
          sections: [
            PieChartSectionData(value: totalLikes.toDouble(), color: Colors.orange, radius: 40, showTitle: false),
            PieChartSectionData(value: totalComments.toDouble(), color: Colors.yellow, radius: 40, showTitle: false),
            PieChartSectionData(value: totalSaves.toDouble(), color: Colors.redAccent, radius: 40, showTitle: false),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart() {
    return BarChart(
      BarChartData(
        maxY: (recipeCount > videoCount ? recipeCount : videoCount).toDouble() + 2,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const Text("Recipes", style: TextStyle(fontSize: 10));
                if (value == 1) return const Text("Videos", style: TextStyle(fontSize: 10));
                return const Text("");
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: recipeCount.toDouble(), color: Colors.brown, width: 40)]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: videoCount.toDouble(), color: Colors.orange, width: 40)]),
        ],
      ),
    );
  }

  Widget _buildPreferenceChart() {
    final total = preferenceData.values.fold(0, (a, b) => a + b);
    if (total == 0) return const Center(child: Text("No preference data"));
    int index = 0;
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 35,
        sections: preferenceData.entries.map((entry) {
          final percent = (entry.value / total) * 100;
          final section = PieChartSectionData(
            color: chartColors[index % chartColors.length],
            value: entry.value.toDouble(),
            title: "${percent.toStringAsFixed(0)}%",
            radius: 55,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          );
          index++;
          return section;
        }).toList(),
      ),
    );
  }

  Widget _buildPreferenceLegend() {
    int index = 0;
    final total = preferenceData.values.fold(0, (a, b) => a + b);
    return Column(
      children: preferenceData.entries.map((entry) {
        final percent = total == 0 ? 0 : (entry.value / total) * 100;
        final color = chartColors[index % chartColors.length];
        index++;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Text(entry.key, style: const TextStyle(fontSize: 13)),
              const Spacer(),
              Text("${percent.toStringAsFixed(0)}%", style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPieChartLegend() {
    int total = totalLikes + totalComments + totalSaves;
    String getPercent(int val) => total == 0 ? "0%" : "${((val / total) * 100).toStringAsFixed(0)}%";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _legendItem("Likes", Colors.orange, getPercent(totalLikes)),
        _legendItem("Comments", Colors.yellow, getPercent(totalComments)),
        _legendItem("Saves", Colors.redAccent, getPercent(totalSaves)),
      ],
    );
  }

  Widget _legendItem(String label, Color color, String percent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
          const Spacer(),
          Text(percent, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildChartCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown)),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}