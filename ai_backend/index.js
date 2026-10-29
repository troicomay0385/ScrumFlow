require("dotenv").config();
const express = require("express");
const cors = require("cors");
const app = express();
app.set("trust proxy", 1); // để lấy đúng IP người dùng khi chạy sau proxy của Render
app.use(express.json({ limit: "100kb" }));

// Giới hạn 20 lượt / 10 phút / IP để không cháy quota Gemini
const hits = new Map();
function rateLimit(req, res, next) {
  const now = Date.now();
  const windowMs = 10 * 60 * 1000;
  const max = 20;
  const recent = (hits.get(req.ip) || []).filter((t) => now - t < windowMs);
  if (recent.length >= max) {
    return res.status(429).json({ error: "Too many requests" });
  }
  recent.push(now);
  hits.set(req.ip, recent);
  next();
}

app.get("/", (_req, res) => res.send("ScrumFlow AI backend is running"));
app.use("/api/ai", rateLimit, require("./routes/aiSplit"));

const port = process.env.PORT || 3000;
app.listen(port, () => console.log(`Listening on ${port}`));