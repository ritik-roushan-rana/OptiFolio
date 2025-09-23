### Step 1: Initialize the Project

1. **Create a new directory for your project**:
   ```bash
   mkdir flutter-backend
   cd flutter-backend
   ```

2. **Initialize a new Node.js project**:
   ```bash
   npm init -y
   ```

3. **Install the required dependencies**:
   ```bash
   npm install express mongoose cors dotenv body-parser
   ```

### Step 2: Project Structure

Create the following directory structure:

```
flutter-backend
├── src
│   ├── models
│   │   └── insightModel.js
│   ├── controllers
│   │   └── insightController.js
│   ├── routes
│   │   └── insightRoutes.js
│   └── app.js
├── .env
└── package.json
```

### Step 3: MongoDB Connection Setup

Create a `.env` file in the root directory and add your MongoDB connection string:

```
MONGODB_URI=<your_mongodb_connection_string>
```

### Step 4: Create the Mongoose Model

Create the `insightModel.js` file in the `models` directory:

```javascript
// src/models/insightModel.js
const mongoose = require('mongoose');

const insightSchema = new mongoose.Schema({
    title: { type: String, required: true },
    description: { type: String, required: true },
    createdAt: { type: Date, default: Date.now }
});

module.exports = mongoose.model('Insight', insightSchema);
```

### Step 5: Create the Controller

Create the `insightController.js` file in the `controllers` directory:

```javascript
// src/controllers/insightController.js
const Insight = require('../models/insightModel');

// Get all insights
exports.getAllInsights = async (req, res) => {
    try {
        const insights = await Insight.find();
        res.json(insights);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Get a single insight by ID
exports.getInsightById = async (req, res) => {
    try {
        const insight = await Insight.findById(req.params.id);
        if (!insight) return res.status(404).json({ message: 'Insight not found' });
        res.json(insight);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// Create a new insight
exports.createInsight = async (req, res) => {
    const insight = new Insight(req.body);
    try {
        const savedInsight = await insight.save();
        res.status(201).json(savedInsight);
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
};

// Update an existing insight by ID
exports.updateInsight = async (req, res) => {
    try {
        const updatedInsight = await Insight.findByIdAndUpdate(req.params.id, req.body, { new: true });
        if (!updatedInsight) return res.status(404).json({ message: 'Insight not found' });
        res.json(updatedInsight);
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
};

// Delete an insight by ID
exports.deleteInsight = async (req, res) => {
    try {
        const deletedInsight = await Insight.findByIdAndDelete(req.params.id);
        if (!deletedInsight) return res.status(404).json({ message: 'Insight not found' });
        res.json({ message: 'Insight deleted' });
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};
```

### Step 6: Create the Routes

Create the `insightRoutes.js` file in the `routes` directory:

```javascript
// src/routes/insightRoutes.js
const express = require('express');
const router = express.Router();
const insightController = require('../controllers/insightController');

router.get('/', insightController.getAllInsights);
router.get('/:id', insightController.getInsightById);
router.post('/', insightController.createInsight);
router.put('/:id', insightController.updateInsight);
router.delete('/:id', insightController.deleteInsight);

module.exports = router;
```

### Step 7: Set Up the Express Application

Create the `app.js` file in the `src` directory:

```javascript
// src/app.js
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bodyParser = require('body-parser');
const dotenv = require('dotenv');
const insightRoutes = require('./routes/insightRoutes');

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// MongoDB connection
mongoose.connect(process.env.MONGODB_URI, { useNewUrlParser: true, useUnifiedTopology: true })
    .then(() => console.log('MongoDB connected'))
    .catch(err => console.error('MongoDB connection error:', err));

// Routes
app.use('/api/insights', insightRoutes);

// Test route
app.get('/api/test', (req, res) => {
    res.send('Server is running!');
});

// Start the server
app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
});
```

### Step 8: Running the Application

1. **Start the server**:
   ```bash
   npm start
   ```

2. **Verify the server is running**:
   Open your browser or use a tool like Postman to navigate to `http://localhost:3000/api/test`. You should see the message "Server is running!".

### Step 9: Testing the API

You can now test the CRUD operations using Postman or any other API testing tool:

- **GET** `/api/insights` - Retrieve all insights
- **GET** `/api/insights/:id` - Retrieve a single insight by ID
- **POST** `/api/insights` - Create a new insight (send JSON body)
- **PUT** `/api/insights/:id` - Update an existing insight by ID (send JSON body)
- **DELETE** `/api/insights/:id` - Delete an insight by ID

### Conclusion

You have successfully set up a Node.js and Express backend with MongoDB, including Mongoose models, CRUD REST API routes, and middleware for CORS and JSON body parsing. You can now expand this project by adding more models, routes, and features as needed.