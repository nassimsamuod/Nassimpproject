import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class _LineChart extends StatelessWidget {
  const _LineChart({required this.isShowingMainData, required this.monthlyVisitsData});

  final bool isShowingMainData;
  final Map<String, int> monthlyVisitsData;

  @override
  Widget build(BuildContext context) {
    return LineChart(
      isShowingMainData ? sampleData1 : sampleData2,
      duration: const Duration(milliseconds: 250),
    );
  }

  LineChartData get sampleData1 => LineChartData(
    lineTouchData: lineTouchData1,
    gridData: gridData,
    titlesData: titlesData1,
    borderData: borderData,
    lineBarsData: lineBarsData1,
    minX: 0,
    maxX: monthlyVisitsData.length.toDouble() - 1,
    maxY: monthlyVisitsData.values.reduce((value, element) => value > element ? value : element).toDouble() + 1,
    minY: 0,
  );

  LineChartData get sampleData2 => LineChartData(
    lineTouchData: lineTouchData2,
    gridData: gridData,
    titlesData: titlesData2,
    borderData: borderData,
    lineBarsData: lineBarsData2,
    minX: 0,
    maxX: monthlyVisitsData.length.toDouble() - 1,
    maxY:monthlyVisitsData.values.reduce((value, element) => value > element ? value : element).toDouble() + 1,
    minY: 0,
  );

  LineTouchData get lineTouchData1 => LineTouchData(
    handleBuiltInTouches: true,
    touchTooltipData: LineTouchTooltipData(
      getTooltipColor: (touchedSpot) => Colors.blueGrey.withOpacity(0.8),
    ),
  );

  FlTitlesData get titlesData1 => FlTitlesData(
    bottomTitles: AxisTitles(
      sideTitles: bottomTitles,
    ),
    rightTitles: const AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),
    topTitles: const AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),
    leftTitles: AxisTitles(
      sideTitles: leftTitles(),
    ),
  );

  List<LineChartBarData> get lineBarsData1 => [
    lineChartBarData1_1,
  ];

  LineTouchData get lineTouchData2 => const LineTouchData(
    enabled: false,
  );

  FlTitlesData get titlesData2 => FlTitlesData(
    bottomTitles: AxisTitles(
      sideTitles: bottomTitles,
    ),
    rightTitles: const AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),
    topTitles: const AxisTitles(
      sideTitles: SideTitles(showTitles: false),
    ),
    leftTitles: AxisTitles(
      sideTitles: leftTitles(),
    ),
  );

  List<LineChartBarData> get lineBarsData2 => [
    lineChartBarData2_1,
  ];

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    return Text('${value.toInt()}', style: style, textAlign: TextAlign.center);
  }

  SideTitles leftTitles() => SideTitles(
    getTitlesWidget: leftTitleWidgets,
    showTitles: true,
    interval: 1,
    reservedSize: 40,
  );

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    final monthIndex = value.toInt();
    final frenchMonths = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    final frenchMonth = frenchMonths[monthIndex];
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 13,
    );
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 10,
      child: Text(frenchMonth, style: style),
    );
  }


  SideTitles get bottomTitles => SideTitles(
    showTitles: true,
    reservedSize: 32,
    interval: 1,
    getTitlesWidget: bottomTitleWidgets,
  );

  FlGridData get gridData => const FlGridData(show: true);

  FlBorderData get borderData => FlBorderData(
    show: true,
    border: Border(
      bottom: BorderSide(color: Colors.grey.withOpacity(0.8), width: 4),
      left: const BorderSide(color: Colors.transparent),
      right: const BorderSide(color: Colors.transparent),
      top: const BorderSide(color: Colors.transparent),
    ),
  );

  LineChartBarData get lineChartBarData1_1 => LineChartBarData(
    isCurved: true,
    color: Colors.green.shade50,
    barWidth: 4,
    isStrokeCapRound: true,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(show: true),
    spots: monthlyVisitsData.entries
        .map((entry) => FlSpot(monthlyVisitsData.keys.toList().indexOf(entry.key).toDouble(), entry.value.toDouble()))
        .toList(),
  );

  LineChartBarData get lineChartBarData2_1 => LineChartBarData(
    isCurved: true,
    curveSmoothness:0,
    color: Colors.blue.withOpacity(0.9),
    barWidth: 4,
    isStrokeCapRound: true,
    dotData: const FlDotData(show: false),
    belowBarData: BarAreaData(show: true),
    spots: monthlyVisitsData.entries
        .map((entry) => FlSpot(monthlyVisitsData.keys.toList().indexOf(entry.key).toDouble(), entry.value.toDouble()))
        .toList(),
  );
}

class LineChartSample1 extends StatefulWidget {
  const LineChartSample1({super.key});

  @override
  State<StatefulWidget> createState() => LineChartSample1State();
}

class LineChartSample1State extends State<LineChartSample1> {
  late bool isShowingMainData;
  late Map<String, int> monthlyVisitsData;

  @override
  void initState() {
    super.initState();
    isShowingMainData = true;
    monthlyVisitsData = {}; // Initialize empty data
    fetchMonthlyVisits();
  }

  Future<void> fetchMonthlyVisits() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Visite')
          .orderBy('Date', descending: false)
          .get();

      monthlyVisitsData = {};

      for (DocumentSnapshot doc in querySnapshot.docs) {
        Timestamp visitTimestamp = doc['Date'] as Timestamp;
        DateTime visitDate = visitTimestamp.toDate();

        // Format the month name using DateFormat
        String monthName = DateFormat.MMMM().format(visitDate);

        if (monthlyVisitsData.containsKey(monthName)) {
          monthlyVisitsData[monthName] = monthlyVisitsData[monthName]! + 1;
        } else {
          monthlyVisitsData[monthName] = 1;
        }
      }

      setState(() {});
    } catch (e) {
      // Handle errors
      print('Error fetching data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio:1,
      child: Stack(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[

              const Text(
                'Nombre de visite par mois',
                style: TextStyle(
                  color: Colors.blueGrey,
                  fontSize:20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(
                height: 37,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16, left: 6),
                  child: _LineChart(isShowingMainData: isShowingMainData, monthlyVisitsData: monthlyVisitsData),
                ),
              ),
              const SizedBox(
                height: 10,
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: Colors.blueAccent.withOpacity(isShowingMainData ? 1.0 : 0.5),
            ),
            onPressed: () {
              setState(() {
                isShowingMainData = !isShowingMainData;
              });
            },
          )
        ],
      ),
    );
  }
}
