# 🤖 HƯỚNG DẪN TỰ ĐỘNG CẤU HÌNH MCP STITCH CHO AI AGENT & THÀNH VIÊN NHÓM

> **Dành cho Thành viên nhóm:** Khi đưa tài liệu này vào khung chat của Antigravity IDE (hoặc AI IDE bất kỳ), bạn chỉ cần gõ:  
> **"Hãy đọc tệp @HuongDanKetNoiStitch.md và tự động cấu hình MCP Stitch cho máy của tôi."**  
> AI Agent sẽ tự động đọc tài liệu, xác định hệ điều hành, tìm tệp cấu hình và kích hoạt kết nối mà bạn không cần phải thao tác thủ công.

---

## 🧭 [AGENT PLAYBOOK] — DÀNH RIÊNG CHO AI CODING ASSISTANT TỰ THỰC THI

*Kính gửi AI Agent đang đọc tệp này: Hãy thực hiện tuần tự các bước sau đây để cấu hình MCP Stitch cho người dùng:*

### Bước 1: Xác định hệ điều hành & Đường dẫn tệp cấu hình MCP
1. Xác định thư mục User Home của máy hiện tại:
   - **Windows:** `%USERPROFILE%` (ví dụ `C:\Users\<username>`)
   - **macOS / Linux:** `$HOME` (ví dụ `/Users/<username>` hoặc `/home/<username>`)
2. Đường dẫn chuẩn của tệp cấu hình Antigravity MCP:
   - **Windows:** `<USERPROFILE>\.gemini\config\mcp_config.json`
   - **macOS / Linux:** `<HOME>/.gemini/config/mcp_config.json`
   *(Nếu IDE sử dụng đường dẫn cấu hình MCP workspace cục bộ `.agents/mcp_config.json`, hãy kiểm tra và hỗ trợ cả hai).*

### Bước 2: Đọc và sáp nhập (Merge) cấu hình
1. Kiểm tra xem thư mục `<HOME>/.gemini/config` đã tồn tại chưa; nếu chưa, hãy tự động tạo thư mục.
2. Đọc nội dung tệp `mcp_config.json` hiện có (nếu đã có).  
   **LƯU Ý:** Không được ghi đè làm mất các MCP servers khác người dùng đã cài sẵn.
3. Thêm cấu hình server `stitch` vào khối `"mcpServers"` như sau:

```json
{
  "mcpServers": {
    "stitch": {
      "serverUrl": "https://stitch.googleapis.com/mcp",
      "headers": {
        "X-Goog-Api-Key": "<YOUR_STITCH_API_KEY_LIEN_HE_TRUONG_NHOM>"
      }
    }
  }
}
```

*(Nếu người dùng đã có API Key riêng hoặc Trưởng nhóm đã cấp, hãy đưa vào trường `X-Goog-Api-Key`).*

### Bước 3: Ghi tệp và thông báo cho người dùng
1. Lưu lại tệp `mcp_config.json` với định dạng JSON chuẩn thụt lề 2 spaces.
2. Nhắc người dùng reload IDE (`Ctrl + Shift + P` -> `Developer: Reload Window` hoặc khởi động lại IDE) để kích hoạt MCP Stitch.

---

## 📌 THÔNG TIN DỰ ÁN STITCH CỦA SCRUMFLOW

AI Agent và thành viên nhóm sử dụng các thông số sau để truy vấn màn hình:

* **Tên dự án Stitch:** `ScrumFlow Agile Management UI`
* **Project ID:** `13855995422081675146`
* **URL xem trực tiếp trên Trình duyệt:**  
  👉 **[https://stitch.withgoogle.com/projects/13855995422081675146](https://stitch.withgoogle.com/projects/13855995422081675146)**
* **Hệ thống thiết kế (Design System):** `Kinetic Sprint`  
  *(Đã có sẵn tài liệu tokens chi tiết tại tệp [`design.md`](file:///design.md) trong thư mục gốc dự án).*

---

## 📱 DANH SÁCH MÃ MÀN HÌNH CHÍNH (SCREEN IDs) ĐÃ THIẾT KẾ

AI Agent có thể dùng tool `get_screen` với Project ID `13855995422081675146` và các Screen ID dưới đây để trích xuất UI Flutter:

| Phân hệ chức năng | Tên màn hình trên Stitch | Screen ID |
| :--- | :--- | :--- |
| **Auth** | Login Screen (Biometric & Google SSO) | `559e21e64ff244dfaa94b81c2fe823c9` |
| **Auth** | Register Screen (Password Requirements) | `a6534d0811b74d6f85d26391d4ffbc69` |
| **Dashboard** | Project List & Sprint Overview (Home) | `7c01429a21b242b7a6d96742b4b72457` |
| **Project** | Project Detail & Agile Workspace | `9bc91ee85e68431f862d77be2ba621a5` |
| **Project** | Create New Project Modal / Form | `0ebafc75a8b74f0bb48e0ae9187ad4d5` |
| **Members** | Project Members & Role Management (RBAC) | `38cc496c7457404f97a8e5229c7f7943` |
| **Backlog** | Product Backlog & Story Prioritization | `4188683411114a35bfcdb07d57845f92` |
| **Backlog** | User Story Detail & Acceptance Criteria | `c5885a0d0fe0473a8027426cc4daaa72` |
| **Sprint** | Sprint Planning & Kanban Board (Sprint 2) | `4c71e21b8b804561845bb38ec30113ce` |

---

## 🛠️ CÁC CÂU LỆNH MẪU ĐỂ RA LỆNH CHO AI AGENT SAU KHI CÀI ĐẶT

Khi MCP Stitch đã kết nối thành công, thành viên chỉ cần nhắn trong chat:

1. *"Liệt kê tất cả các màn hình trong dự án Stitch ScrumFlow"* -> Agent gọi `list_screens(projectId: "13855995422081675146")`.
2. *"Đọc chi tiết màn hình Product Backlog trên Stitch và đối chiếu với widget trong lib/presentation/backlog"* -> Agent gọi `get_screen` và so khớp giao diện.
3. *"Tạo widget mới dựa trên màn hình Sprint Planning từ Stitch"* -> Agent tự động đọc mã HTML/CSS từ Stitch và chuyển sang Flutter code chuẩn BLoC & Kinetic Sprint.

