const express = require('express');
const mysql = require('mysql');
const cors = require('cors');
const bodyParser = require('body-parser'); // Required to parse POST data
const app = express();


// Enable CORS for your Flutter app
app.use(cors());
app.use(bodyParser.json()); // Support json encoded bodies
app.use(bodyParser.urlencoded({ extended: true })); // Support encoded bodies

// MySQL database connection configuration
const db = mysql.createConnection({
  host: 'localhost',
  port: 3306,
  user: 'root',
  password: 'root',
  database: 'budget',
});
// Connect to the MySQL database
db.connect(err => {
  if (err) {
    console.error('Error connecting to the database: ' + err.stack);
    return;
  }
  console.log('Connected to database with ID: ' + db.threadId);
});

// Endpoint for getting expense data
app.get('/expense', (req, res) => {
  const query = `SELECT date, category, SUM(amount) AS amount FROM expenses GROUP BY category`;
  db.query(query, (err, results) => {
    if (err) {
      res.status(500).send('Server error');
    } else {
      res.json(results.map(row => ({ category: row.category, amount: row.amount, date: row.date})));
    }
  });
});

// Endpoint for getting income data
app.get('/income', (req, res) => {
  console.log('First fetching');
  const query = `SELECT amount, date FROM income ORDER BY date`;
  db.query(query, (err, results) => {
    if (err) {
      res.status(500).send('Server error');
    } else {
      res.json(results.map(row => ({ amount: row.amount, date: row.date })));
    }
  });
  console.log('First income fetching complete');
});

// Endpoint to add a new income entry
app.post('/add-income', (req, res) => {
  const { amount, date } = req.body;
  const query = 'INSERT INTO income (amount, date) VALUES (?, ?)';
  db.query(query, [amount, date], (err, result) => {
    if (err) {
      console.error('Error adding income: ' + err.stack);
      res.status(500).send('Error adding income');
    } else {
      res.status(201).send({ message: 'Income added successfully', id: result.insertId });
    }
  });
});

// POST endpoint to add a new expense
app.post('/add-expense', (req, res) => {
  const { amount, date, category } = req.body;
  const query = 'INSERT INTO expenses (amount, date, category) VALUES (?, ?, ?)';

  db.query(query, [amount, date, category], (err, results) => {
    if (err) {
      console.error('Error adding new expense:', err);
      res.status(500).send('Error adding new expense');
    } else {
      res.status(200).send('Expense added successfully');
    }
  });
});

const port = 3000; // You can choose another port if this one is in use
app.listen(port, () => {
  console.log(`Server is running on http://localhost:${port}`);
});
