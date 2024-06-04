import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'expense.dart';
import 'income.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onExpenditurePressed;
  final VoidCallback onIncomePressed;

  const HomeScreen({Key? key, required this.onExpenditurePressed, required this.onIncomePressed}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  List<PieChartSectionData> _expenseSections = [];
  List<BarChartGroupData> _incomeGroups = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    // Replace with your Node.js backend endpoints
    final expenseResponse = await http.get(Uri.parse('http://192.168.56.1:3000/expense'));
    final incomeResponse = await http.get(Uri.parse('http://192.168.56.1:3000/income'));

    if (expenseResponse.statusCode == 200 && incomeResponse.statusCode == 200) {
      final expenseData = json.decode(expenseResponse.body);
      final incomeData = json.decode(incomeResponse.body);

      setState(() {
        _isLoading = false;
        _expenseSections = _parseExpenseData(expenseData);
        _incomeGroups = _parseIncomeData(incomeData);
      });
    } else {
      // Handle the error; perhaps show an alert to the user
    }
  }


  List<PieChartSectionData> _parseExpenseData(List<dynamic> expenseData) {
    final List<PieChartSectionData> sections = [];
    for (var data in expenseData) {
      final categoryIndex = expenseData.indexOf(data);
      final color = Colors.primaries[categoryIndex % Colors.primaries.length];

      final section = PieChartSectionData(
        color: color,
        value: (data['amount'] as num).toDouble(),
        title: '${data['amount']}',
        radius: 50, // You can adjust the radius for the design
        titleStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: const Color(0xffffffff),
        ),
      );
      sections.add(section);
    }
    return sections;
  }

  List<BarChartGroupData> _parseIncomeData(List<dynamic> incomeData) {
    final List<BarChartGroupData> groups = [];
    int index = 0;

    for (var data in incomeData) {
      final group = BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            y: (data['amount'] as num).toDouble(), // Updated parameter name from toY to y
            colors: [Colors.lightBlueAccent], // colors is now a list
            borderRadius: BorderRadius.circular(4),
          ),
        ],
        // showingTooltipIndicators: [0],
      );
      groups.add(group);
      index++;
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: widget.onExpenditurePressed,
                child: const Text('Expenditure', style: TextStyle(fontSize: 24)),
              ),
            ),
          ),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(sections: _expenseSections),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: widget.onIncomePressed,
                child: const Text('Income', style: TextStyle(fontSize: 24)),
              ),
            ),
          ),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(barGroups: _incomeGroups),
            ),
          ),
        ],
      ),
    );
  }
}
