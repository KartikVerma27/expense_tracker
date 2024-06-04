import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // For JSON processing
import 'package:intl/intl.dart';

class ExpenseScreen extends StatefulWidget {
  @override
  _ExpenseScreenState createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  bool _isLoading = true;
  List<PieChartSectionData> _sections = [];
  Map<String, Color> _categoryColors = {}; // To store category and color pairs for the legend
  List<Map<String, dynamic>> _expenseData = [];
  List<String> categories = ['Groceries', 'Bills', 'Transportation', 'Entertainment', 'Other'];
  String? selectedCategory;
  TextEditingController amountController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController customCategoryController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _fetchExpenseData();

  }

  Future<void> _fetchExpenseData() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.56.1:3000/expense'));
      if (response.statusCode == 200) {
        setState(() {
          _isLoading = false;
          _processExpenseData(json.decode(response.body));
          print(json.decode(response.body));
          _expenseData = List<Map<String, dynamic>>.from(json.decode(response.body));
        });
      } else {
        // Handle server error
        print('Server error: ${response.body}');
      }
    } catch (e) {
      // Handle any errors
      print('Error fetching expense data: $e');
    }
  }

  void _processExpenseData(List<dynamic> expenseData) {
    final List<PieChartSectionData> sections = [];
    final Map<String, Color> categoryColors = {};

    // Assuming each entry in expenseData has 'category' and 'amount'
    for (var data in expenseData) {
      final category = data['category'];
      final amount = data['amount'].toDouble(); // Ensure amount is a double
      final color = Colors.primaries[sections.length % Colors.primaries.length];

      categoryColors[category] = color; // Save the color for the legend

      sections.add(
        PieChartSectionData(
          color: color,
          value: amount,
          title: '$category\n(${amount.toStringAsFixed(2)})',
          showTitle: true,
          radius: 50,
        ),
      );
    }

    setState(() {
      _isLoading = false;
      _sections = sections;
      _categoryColors = categoryColors;
    });
  }
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'not working';
    try {
      final date = DateTime.parse(dateStr);

      return DateFormat('yyyy-MM-dd').format(date);
    } catch (e) {
      print('not working');
      return 'Unknown';
    }
  }
  void _showAddExpenseSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              TextField(
                controller: dateController,
                decoration: InputDecoration(
                  labelText: 'Date',
                  hintText: 'YYYY-MM-DD',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                keyboardType: TextInputType.datetime,
                onTap: () async {
                  // Prevent keyboard from appearing
                  FocusScope.of(context).requestFocus(new FocusNode());
                  // Show Date Picker Here
                  DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    String formattedDate = DateFormat('yyyy-MM-dd').format(pickedDate);
                    dateController.text = formattedDate;
                  }
                },
              ),// ... Amount and Date TextFields ...
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: categories.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == 'Other') {
                    // Prompt user to add a custom category
                    setState(() {
                      selectedCategory = null;
                    });
                  } else {
                    setState(() {
                      selectedCategory = value;
                    });
                  }
                },
                decoration: InputDecoration(labelText: 'Category'),
              ),
              if (selectedCategory == null) // This will show TextField if 'Other' is selected
                TextField(
                  controller: customCategoryController,
                  decoration: InputDecoration(labelText: 'Custom Category'),
                ),
              ElevatedButton(
                child: Text('Add Expense'),
                onPressed: () async {
                  // Close the keyboard if it's open
                  FocusScope.of(context).unfocus();

                  // Validate inputs here and make sure they're not null
                  // Get the values from the controllers
                  final double? amountValue = double.tryParse(amountController.text);
                  final String date = dateController.text.trim();
                  String category = selectedCategory ?? '';

                  // If 'Other' is selected, use the value from the customCategoryController
                  if (category == 'Other') {
                    category = customCategoryController.text.trim();
                  }

                  // Basic validation
                  if (amountValue == null || amountValue <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please enter a valid amount')),
                    );
                    return;
                  }

                  if (date.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please enter a date')),
                    );
                    return;
                  }

                  if (category.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please select a category')),
                    );
                    return;
                  }

                  // Create the expense data
                  final Map<String, dynamic> expenseData = {
                    'amount': amountValue,
                    'date': date,
                    'category': category,
                  };

                  // Send the expense data to the server
                  final response = await http.post(
                    Uri.parse('http://192.168.56.1:3000/add-expense'),
                    headers: {'Content-Type': 'application/json'},
                    body: json.encode(expenseData),
                  );

                  // Handle the response from the server
                  if (response.statusCode == 200) {
                    // If the server returns a successful response, reload the expenses to reflect the new entry
                    _fetchExpenseData();
                  } else {
                    // If the server returns an error response, display an error message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error adding expense')),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Summary'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(sections: _sections),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Wrap(
                children: _categoryColors.keys.map((category) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        color: _categoryColors[category],
                      ),
                      SizedBox(width: 4),
                      Text(category),
                    ],
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: _expenseData.map((expense) {
                  return Card(

                    child: ListTile(
                      leading: Icon(Icons.monetization_on, color: Colors.green),
                      title: Text('${expense['category'] ?? 'Unknown'} - \$${(expense['amount'] as num?)?.toDouble()?.toStringAsFixed(2) ?? '0.00'}'),
                      subtitle: Text('Date: ${_formatDate(expense['date'])}'),

                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),

      ),
          floatingActionButton: FloatingActionButton(
    onPressed: () => _showAddExpenseSheet(context),
    child: Icon(Icons.add),
    tooltip: 'Add Expense'),
    );
  }
}