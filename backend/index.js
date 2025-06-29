const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const dotenv = require('dotenv');
dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

// 1. MongoDB 연결 (Atlas에서 복사한 URI로 대체)
mongoose.connect(process.env.MONGODB_URI)
  .then(() => console.log('MongoDB connected'))
  .catch(err => console.log(err));

// 2. 스키마 정의
const fridgeSchema = new mongoose.Schema({
  name: String,
  members: [String], // userId 리스트
  ingredients: [
    {
      id: String,
      name: String,
      quantity: Number,
      expirationDate: String,
      storageType: String
    }
  ],
  cart: [
    {
      id: String,
      name: String,
      quantity: Number
    }
  ]
});
const Fridge = mongoose.model('Fridge', fridgeSchema);

// 3. API 예시

// 냉장고 생성
app.post('/fridges', async (req, res) => {
  const { name, userId } = req.body;
  const fridge = new Fridge({ name, members: [userId], ingredients: [], cart: [] });
  await fridge.save();
  res.json(fridge);
});

// 냉장고 참여
app.post('/fridges/:id/join', async (req, res) => {
  const { userId } = req.body;
  const fridge = await Fridge.findById(req.params.id);
  if (!fridge.members.includes(userId)) {
    fridge.members.push(userId);
    await fridge.save();
  }
  res.json(fridge);
});

// 재료 추가
app.post('/fridges/:id/ingredients', async (req, res) => {
  const { ingredient } = req.body;
  const fridge = await Fridge.findById(req.params.id);
  fridge.ingredients.push(ingredient);
  await fridge.save();
  res.json(fridge.ingredients);
});

// 장바구니 추가
app.post('/fridges/:id/cart', async (req, res) => {
  const { item } = req.body;
  const fridge = await Fridge.findById(req.params.id);
  fridge.cart.push(item);
  await fridge.save();
  res.json(fridge.cart);
});

// 냉장고 정보 조회
app.get('/fridges/:id', async (req, res) => {
  const fridge = await Fridge.findById(req.params.id);
  res.json(fridge);
});

// 서버 시작
app.listen(3000, () => {
  console.log('Server running on http://localhost:3000');
}); 