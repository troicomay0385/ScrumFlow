const express = require("express");
const https = require("https");

const router = express.Router();

// ── Fallback tasks khi Gemini không khả dụng ──────────────────────────────────
function buildFallback(title) {
  return {
    source: "fallback",
    tasks: [
      {
        title: `Phân tích yêu cầu: ${title}`.slice(0, 80),
        description: "Xác định rõ ràng phạm vi, điều kiện chấp nhận và các ràng buộc kỹ thuật.",
        estimateHours: 2,
        role: "BA / PO",
      },
      {
        title: "Thiết kế UI / UX",
        description: "Tạo wireframe hoặc mockup cho giao diện liên quan.",
        estimateHours: 3,
        role: "Designer",
      },
      {
        title: "Cài đặt backend / API",
        description: "Xây dựng endpoint và logic xử lý phía server.",
        estimateHours: 4,
        role: "Backend Dev",
      },
      {
        title: "Cài đặt frontend",
        description: "Tích hợp UI với API, xử lý trạng thái loading/error.",
        estimateHours: 4,
        role: "Frontend Dev",
      },
      {
        title: "Viết test & kiểm thử",
        description: "Unit test, integration test và kiểm tra thủ công theo acceptance criteria.",
        estimateHours: 2,
        role: "QA / Dev",
      },
    ],
  };
}

// ── Gọi Gemini REST API ────────────────────────────────────────────────────────
function callGemini(apiKey, model, body) {
  return new Promise((resolve, reject) => {
    const payload = JSON.stringify(body);
    const path = `/v1beta/models/${model}:generateContent?key=${apiKey}`;

    const options = {
      hostname: "generativelanguage.googleapis.com",
      port: 443,
      path,
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Content-Length": Buffer.byteLength(payload),
      },
    };

    const req = https.request(options, (res) => {
      let data = "";
      res.on("data", (chunk) => { data += chunk; });
      res.on("end", () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          reject(new Error("Invalid JSON from Gemini"));
        }
      });
    });

    req.on("error", reject);

    // Timeout 20 giây
    req.setTimeout(20000, () => {
      req.destroy(new Error("Gemini request timed out"));
    });

    req.write(payload);
    req.end();
  });
}

// ── POST /split-story ─────────────────────────────────────────────────────────
router.post("/split-story", async (req, res) => {
  const { title = "", description = "", maxTasks = 6 } = req.body;

  if (!title.trim()) {
    return res.status(400).json({ error: "title is required" });
  }

  const apiKey = process.env.GEMINI_API_KEY;
  const model = process.env.GEMINI_MODEL || "gemini-2.0-flash";

  if (!apiKey) {
    console.warn("[AI] GEMINI_API_KEY chưa được cấu hình — trả fallback");
    return res.json(buildFallback(title));
  }

  const prompt = `Bạn là một Scrum Master chuyên nghiệp.
Hãy tách User Story sau thành tối đa ${maxTasks} task cụ thể, khả thi.

User Story Title: ${title}
User Story Description: ${description || "(không có mô tả)"}

Trả về KẾT QUẢ THUẦN JSON (không markdown, không giải thích), theo đúng cấu trúc:
{
  "source": "ai",
  "tasks": [
    {
      "title": "Tên task ngắn gọn (≤ 80 ký tự)",
      "description": "Mô tả chi tiết việc cần làm",
      "estimateHours": <số nguyên từ 1 đến 16>,
      "role": "Vai trò thực hiện (vd: Frontend Dev, Backend Dev, QA, Designer, BA)"
    }
  ]
}`;

  try {
    const geminiRes = await callGemini(apiKey, model, {
      contents: [{ parts: [{ text: prompt }] }],
      generationConfig: { temperature: 0.4, maxOutputTokens: 1024 },
    });

    // Lấy text từ response
    const rawText =
      geminiRes?.candidates?.[0]?.content?.parts?.[0]?.text ?? "";

    // Strip markdown code fences nếu có
    const jsonText = rawText
      .replace(/^```json\s*/i, "")
      .replace(/^```\s*/i, "")
      .replace(/```$/i, "")
      .trim();

    const parsed = JSON.parse(jsonText);

    // Validate tối thiểu
    if (!Array.isArray(parsed.tasks) || parsed.tasks.length === 0) {
      throw new Error("Empty tasks array from Gemini");
    }

    return res.json({ source: "ai", tasks: parsed.tasks });
  } catch (err) {
    console.error("[AI] Lỗi gọi Gemini:", err.message);
    return res.json(buildFallback(title));
  }
});

module.exports = router;
