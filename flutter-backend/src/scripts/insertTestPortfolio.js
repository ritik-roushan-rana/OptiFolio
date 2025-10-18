import mongoose from 'mongoose';
import Portfolio from '../models/portfolioModel.js';

async function insertTestPortfolio() {
  try {
    await mongoose.connect('mongodb://localhost:27017/your_database_name', {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });

    const testPortfolio = {
      userId: 'user_id',
      portfolioName: 'Test Portfolio',
      description: 'A test portfolio',
      positions: [],
    };

    await Portfolio.create(testPortfolio);
    console.log('Test document inserted successfully');
  } catch (error) {
    console.error('Error inserting test document:', error);
  } finally {
    await mongoose.disconnect();
  }
}

insertTestPortfolio();
