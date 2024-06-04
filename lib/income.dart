import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For JSON processing
import 'package:intl/intl.dart'; // For date formatting, ensure 'intl' is added to your dependencies

class IncomeScreen extends StatefulWidget {
  @override
  _IncomeScreenState createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen> {
  bool _isLoading = true;
  List<BarChartGroupData> _incomeGroups = [];
  List<Map<String, dynamic>> _incomeEntries = []; // Store fetched data
  Map<int, String> _monthYearLabels = {}; // Store month-year labels for the x-axis

  @override
  void initState() {
    super.initState();
    _fetchIncomeData();
  }

  Future<void> _fetchIncomeData() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.56.1:3000/income'));
      if (response.statusCode == 200) {
        final List<dynamic> fetchedData = json.decode(response.body);
        setState(() {
          _isLoading = false;
          _incomeEntries = List<Map<String, dynamic>>.from(fetchedData);
          _incomeGroups = _processIncomeData(fetchedData);
        });
      } else {
        // Handle server error
        print('Server error: ${response.body}');
      }
    } catch (e) {
      // Handle any errors
      print('Error fetching income data on trying for second time: $e');
    }
  }

  List<BarChartGroupData> _processIncomeData(List<dynamic> incomeData) {
    final List<BarChartGroupData> groups = [];
    for (int i = 0; i < incomeData.length; i++) {
      final entry = incomeData[i];
      final double amount = (entry['amount'] as num).toDouble();
      final date = DateTime.parse(entry['date']);
      final String monthYear = DateFormat('MM-yy').format(date); // Formats date as 'MM-yy'
// Store the label
      _monthYearLabels[i] = monthYear;
      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [BarChartRodData(y: amount, colors: [Colors.lightBlue])],
          // showingTooltipIndicators: [0],
        ),
      );
    }
    return groups;
  }
  void _showAddIncomeSheet(BuildContext context) {
    final _amountController = TextEditingController();
    final _dateController = TextEditingController();
    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: 'Amount'),
              ),
              TextField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: 'Date',
                  hintText: 'YYYY-MM-DD',
                ),
                keyboardType: TextInputType.datetime,
                onTap: () async {
                  // Prevent the keyboard from appearing when the date picker is open
                  FocusScope.of(context).requestFocus(new FocusNode());
                  // Show the date picker
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null) {
                    // Format and set the date in the text field
                    _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
                  }
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                child: Text('Add Entry'),
                onPressed: () {
                  // Validate inputs and add the new income entry
                  _addIncomeEntry(_amountController.text, _dateController.text);
                  // Clear the text fields
                  _amountController.clear();
                  _dateController.clear();
                  // Dismiss the bottom sheet
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }
// Method to process adding a new income entry

  Future<void> _addIncomeEntry(String amountStr, String dateStr) async {
    final double? amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      _showErrorMessage('Please enter a valid amount.');
      return;
    }

    final DateTime? date = DateTime.tryParse(dateStr);
    if (date == null) {
      _showErrorMessage('Please enter a valid date.');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://192.168.56.1:3000/add-income'), // Change to your server's IP and endpoint
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'amount': amount, 'date': dateStr}),
      );

      if (response.statusCode == 201) {
        // If the server did create a new resource...
        print('Income entry added: ${response.body}');
        // You might want to refresh the income list or show a confirmation message
        _fetchIncomeData(); // Fetch income data again to update the list
      } else {
        // If the server did not create a new resource...
        _showErrorMessage('Failed to add income entry: ${response.body}');
      }
    } catch (e) {
      _showErrorMessage('Error sending income data: $e');
    }
  }


  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Income Summary')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              // child: Text('Summary', style: Theme.of(context).textTheme.headline6),
            ),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: _incomeGroups,
                  titlesData: FlTitlesData(
                    bottomTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22, // Space for titles
                      getTitles: (value) {
                        return _monthYearLabels[value.toInt()] ?? '';
                      },
                      margin: 10,
                    ),
                    // Define left titles, top titles, and right titles if necessary
                  ),
                  // Add alignment, border, grid, and other configurations
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Income Details',
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
            ListView.builder(
              shrinkWrap: true, // Needed to use ListView.builder inside SingleChildScrollView
              physics: NeverScrollableScrollPhysics(), // Ensures the ListView doesn't scroll separately
              itemCount: _incomeEntries.length,
              itemBuilder: (context, index) {
                final entry = _incomeEntries[index];
                return Card( // Wrap each ListTile in a Card for better visuals
                  elevation: 1.0,
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: ListTile(
                    leading: Icon(Icons.monetization_on, color: Colors.green),
                    title: Text('₹${entry['amount'].toStringAsFixed(2)}'), // Assuming the amount is in INR
                    subtitle: Text(DateFormat('dd MMM, yyyy').format(DateTime.parse(entry['date']))),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {
                      // Handle the tap if necessary, perhaps to edit the entry
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddIncomeSheet(context),
        child: Icon(Icons.add),
        tooltip: 'Add Income',
      ),
    );
  }
}