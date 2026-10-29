// routes/aiSplit.js
const express = require("express");
const router = express.Router();

const API_KEY = (process.env.GEMINI_API_KEY || "").trim();
const MODEL = (process.env.GEMINI_MODEL || "").trim();

const schema = {
  type: "OBJECT",
  properties: {
    tasks: {
      type: "ARRAY",
      items: {
        type: "OBJECT",
        properties: {
          title: { type: "STRING" },
          description: { type: "STRING" },
          estimateHours: { type: "INTEGER" },
          role: { type: "STRING" },
        },
        required: ["title", "estimateHours"],
      },
    },
  },
  required: ["tasks"],
};

function fallbackTasks(title) {
  return [
    { title: `Phân tích yêu cầu: ${title}`, description: "Làm rõ phạm vi và tiêu chí chấp nhận", estimateHours: 2, role: "BA" },
    { title: `Thiết kế giao diện/API: ${title}`, description: "Thiết kế màn hình và endpoint liên quan", estimateHours: 3, role: "Dev" },
    { title: `Cài đặt chức năng: ${title}`, description: "Viết code backend và frontend", estimateHours: 5, role: "Dev" },
    { title: `Kiểm thử: ${title}`, description: "Viết và chạy test case", estimateHours: 2, role: "Tester" },
  ];
}

// Lấy phần JSON từ chuỗi, kể cả khi có rào ```json hoặc chữ thừa
function extractJson(text) {
  const cleaned = String(text || "").replace(/```json|```/gi, "").trim();
  const start = cleaned.indexOf("{");
  const end = cleaned.lastIndexOf("}");
  if (start === -1 || end === -1 || end <= start) {
    throw new Error(`Không tìm thấy JSON trong nội dung (độ dài ${cleaned.length})`);
  }
  return JSON.parse(cleaned.slice(start, end + 1));
}

async function callGemini(prompt, withThinkingConfig) {
  const startedAt = Date.now();

  const generationConfig = {
    responseMimeType: "application/json",
    responseSchema: schema,
    temperature: 0.3,
    maxOutputTokens: 4096,
  };
  // Giảm thời gian "suy nghĩ" của dòng Gemini 3 để trả lời nhanh hơn
  if (withThinkingConfig) {
    generationConfig.thinkingConfig = { thinkingLevel: "low" };
  }

  const r = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(MODEL)}:generateContent`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json", "x-goog-api-key": API_KEY },
      body: JSON.stringify({
        contents: [{ parts: [{ text: prompt }] }],
        generationConfig,
      }),
      signal: AbortSignal.timeout(20000),
    }
  );

  const raw = await r.text();
  console.log(
    `[ai/split-story] HTTP ${r.status} sau ${Date.now() - startedAt}ms ` +
      `(thinkingConfig=${withThinkingConfig})`
  );

  if (!r.ok) {
    throw new Error(`Gemini HTTP ${r.status}: ${raw.slice(0, 500)}`);
  }
  if (!raw) throw new Error("Gemini trả về body rỗng");

  const data = JSON.parse(raw);
  const cand = data?.candidates?.[0];
  const parts = cand?.content?.parts || [];
  const text = parts
    .filter((p) => !p.thought)
    .map((p) => p.text || "")
    .join("");

  console.log(
    `[ai/split-story] finishReason=${cand?.finishReason} ` +
      `blockReason=${data?.promptFeedback?.blockReason || "none"} textLength=${text.length}`
  );

  if (!text) throw new Error(`Nội dung rỗng: ${raw.slice(0, 500)}`);
  return text;
}

router.post("/split-story", async (req, res) => {
  const { title, description = "", maxTasks = 6 } = req.body || {};
  if (!title || typeof title !== "string") {
    return res.status(400).json({ error: "title is required" });
  }
  const n = Math.min(Math.max(parseInt(maxTasks, 10) || 6, 2), 10);

  const prompt =
    `Bạn là Scrum Master. Tách User Story sau thành tối đa ${n} task nhỏ, ` +
    `mỗi task làm được trong 2-6 giờ, theo thứ tự thực hiện, viết bằng tiếng Việt, ` +
    `không trùng lặp, không thêm phạm vi ngoài story. ` +
    `role chọn một trong: BA, Dev, Tester.\n\n` +
    `Tiêu đề: ${title}\nMô tả: ${description}`;

  try {
    if (!API_KEY) throw new Error("Thiếu biến GEMINI_API_KEY");
    if (!MODEL) throw new Error("Thiếu biến GEMINI_MODEL");

    console.log(`[ai/split-story] model=${MODEL}, keyLength=${API_KEY.length}`);

    let parsed;
    try {
      parsed = extractJson(await callGemini(prompt, true));
    } catch (firstError) {
      console.warn("[ai/split-story] Lần 1 lỗi, thử lại:", firstError.message);
      // Nếu Gemini từ chối tham số thinkingConfig (HTTP 400) thì thử lại không kèm nó
      const keepThinking = !String(firstError.message).includes("HTTP 400");
      parsed = extractJson(await callGemini(prompt, keepThinking));
    }

    const tasks = (parsed.tasks || []).slice(0, n).map((t) => ({
      title: String(t.title || "").slice(0, 200),
      description: String(t.description || "").slice(0, 1000),
      estimateHours: Math.min(Math.max(parseInt(t.estimateHours, 10) || 2, 1), 16),
      role: ["BA", "Dev", "Tester"].includes(t.role) ? t.role : "Dev",
    }));
    if (!tasks.length) throw new Error("AI trả về danh sách rỗng");

    return res.json({ source: "ai", tasks });
  } catch (e) {
    console.error("[ai/split-story] LỖI:", e.message);
    return res.json({ source: "fallback", tasks: fallbackTasks(title) });
  }
});

module.exports = router;