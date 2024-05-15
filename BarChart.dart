import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class _BarChart extends StatelessWidget {
  const _BarChart();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: fetchData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final data = snapshot.data as List<Map<String, dynamic>>;
        return BarChart(
          BarChartData(
            barTouchData: barTouchData,
            titlesData: titlesData,
            borderData: borderData,
            barGroups: generateBarGroups(data),
            gridData: const FlGridData(show:true),
            alignment: BarChartAlignment.spaceAround,
            maxY: calculateMaxY(data),
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> fetchData() async {
    final querySnapshot = await FirebaseFirestore.instance.collection('Visite').get();

    // Print the query snapshot to see if it's retrieved successfully
    print('Query Snapshot: $querySnapshot');

    // Map to store department-wise counts
    Map<String, int> departmentCounts = {};

    querySnapshot.docs.forEach((doc) {
      final data = doc.data();
      final nomDepartement = data['nom_departement'] as String;
      final verifications = (data['Vérification'] as List<dynamic>?) ?? [];

      // Count occurrences of 'etat' being 'nonok' for the specific 'nom_departement'
      int countNonOk = verifications
          .where((verification) => verification['etat'] == 'nonok' && verification['type'] != null)
          .length;

      // Update department-wise count
      departmentCounts[nomDepartement] = (departmentCounts[nomDepartement] ?? 0) + countNonOk;
    });

    // Print department-wise counts for debugging
    departmentCounts.forEach((department, count) {
      print('Department: $department, Count Non-OK: $count');
    });

    // Convert department-wise counts to the required format
    List<Map<String, dynamic>> result = departmentCounts.entries.map((entry) {
      return {
        'nom_departement': entry.key,
        'count_nonok': entry.value,
      };
    }).toList();

    return result;
  }

  List<BarChartGroupData> generateBarGroups(List<Map<String, dynamic>> data) {
    final Map<String, int> nonOkCounts = {};

    data.forEach((document) {
      final nomDepartement = document['nom_departement'] as String;
      final countNonOk = document['count_nonok'] as int;
      nonOkCounts.putIfAbsent(nomDepartement, () => countNonOk);
    });

    return nonOkCounts.entries.map((entry) {
      final nomDepartement = entry.key;
      final countNonOk = entry.value;

      return BarChartGroupData(
        x: nonOkCounts.keys.toList().indexOf(nomDepartement),
        barRods: [
          BarChartRodData(
            toY: countNonOk.toDouble(),
            color: Colors.cyan, // Replace with your desired color
          ),
        ],
        showingTooltipIndicators: [0],
      );
    }).toList();
  }

  double calculateMaxY(List<Map<String, dynamic>> data) {
    final List<int> counts = data.map((document) => document['count_nonok'] as int).toList();
    return counts.isNotEmpty
        ? counts.reduce((a, b) => a > b ? a : b).toDouble()
        : 0;
  }
}

  BarTouchData get barTouchData => BarTouchData(
    enabled:false,
    touchTooltipData: BarTouchTooltipData(
      getTooltipColor: (group) => Colors.transparent,
      tooltipPadding: EdgeInsets.zero,
      tooltipMargin:2,
      getTooltipItem: (
          BarChartGroupData group,
          int groupIndex,
          BarChartRodData rod,
          int rodIndex,
          ) {
        return BarTooltipItem(
          rod.toY.round().toString(),
          const TextStyle(
            color: Colors.cyan, // Replace with your desired color
            fontWeight: FontWeight.bold,
          ),
        );
      },
    ),
  );

Widget getTitles(double value, TitleMeta meta) {
  final intValue = value.toInt();
  final style = TextStyle(
    color: Colors.blue[900], // Example color
    fontWeight: FontWeight.bold,
    fontSize: 14,
  );
  String text = 'Dep $intValue';
  return SideTitleWidget(
    axisSide: meta.axisSide,
    space: 4,
    child: Text(text, style: style),
  );
}


FlTitlesData get titlesData => FlTitlesData(
    show: true,
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 30,
        getTitlesWidget: getTitles,
      ),
    ),
    leftTitles: const AxisTitles(
      sideTitles: SideTitles(showTitles: true),
    ),
    topTitles: const AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),
    rightTitles: const AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),
  );

  FlBorderData get borderData => FlBorderData(
    show: false,
  );

class BarChartSample3 extends StatefulWidget {
  const BarChartSample3() ;

  @override
  State<StatefulWidget> createState() => BarChartSample3State();
}

class BarChartSample3State extends State<BarChartSample3> {
  @override
  Widget build(BuildContext context) {
    return const AspectRatio(
      aspectRatio: 1.3,
      child: _BarChart(),
    );
  }
}
