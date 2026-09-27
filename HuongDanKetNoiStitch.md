# 🎨 HƯỚNG DẪN KẾT NỐI VÀ SỬ DỤNG MCP STITCH DỰ ÁN SCRUMFLOW

> **Dành cho các thành viên nhóm phát triển ScrumFlow:**  
> Tài liệu này hướng dẫn cách truy cập trực tiếp vào dự án thiết kế UI của ScrumFlow trên Google Stitch, đồng thời cấu hình tích hợp **MCP Stitch** vào Antigravity IDE trên máy cá nhân để đồng bộ thiết kế, mã nguồn và hệ thống Design System.

---

## 1. 📌 Thông Tin Dự Án Trên Stitch

* **Tên dự án:** `ScrumFlow Agile Management UI`
* **Project ID:** `13855995422081675146`
* **Đường dẫn xem trực tiếp trên Web:**  
  👉 **[https://stitch.withgoogle.com/projects/13855995422081675146](https://stitch.withgoogle.com/projects/13855995422081675146)**
* **Hệ thống thiết kế (Design System):** `Kinetic Sprint` (Xem chi tiết tại tệp [design.md](file:///d:/ThuMucOE/BTVN/LTDD%20BTVN/Scrumflow/design.md) trong thư mục gốc của repo).
* **Số lượng màn hình đã thiết kế:** 24 màn hình hoàn chỉnh (Mobile UI cho Auth, Project Dashboard, Backlog, Sprint Kanban, Task Detail, Daily Stand-up, v.v.).

---

## 2. ⚙️ Cấu Hình MCP Stitch Vào Antigravity IDE Của Thành Viên

Sau khi cấu hình, AI trợ lý trong IDE của bạn sẽ có thể trực tiếp đọc các màn hình, trích xuất mã Flutter và đồng bộ giao diện theo chuẩn thiết kế của dự án.

### Bước 1: Mở tệp cấu hình MCP trên máy của bạn
Đường dẫn tệp cấu hình trên hệ điều hành Windows:
```text
C:\Users\<TÊN_USER_CỦA_BẠN>\.gemini\config\mcp_config.json
```
*(Nếu chưa có thư mục `.gemini\config` hoặc file `mcp_config.json`, hãy tự tạo mới)*

### Bước 2: Thêm cấu hình kết nối Stitch
Mở tệp `mcp_config.json` và thêm cấu hình server `stitch` dưới đây vào trong block `"mcpServers"`:

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

> **Lưu ý bảo mật:** API Key trên chỉ dùng nội bộ trong nhóm phát triển dự án môn học ScrumFlow để kết nối vào MCP Stitch của Google.

### Bước 3: Khởi động lại IDE
1. Tắt Antigravity IDE và mở lại (hoặc bấm `Ctrl + Shift + P` chọn **Developer: Reload Window**).
2. Kiểm tra biểu tượng MCP ở góc dưới hoặc menu **Options (...) > MCP Servers**: `stitch` hiển thị trạng thái màu xanh (**Connected/Active**).

---

## 3. 🛠️ Cách AI Trong IDE Của Bạn Sử Dụng MCP Stitch

Khi đã kết nối thành công, bạn chỉ cần ra lệnh cho AI trong khung chat, ví dụ:
* *"Hãy đọc màn hình Backlog từ dự án Stitch 13855995422081675146 và chuyển thành Flutter Widget"*
* *"Hãy tra cứu Design System trong tệp design.md và áp dụng bảng màu Kinetic Sprint vào theme của app"*
* *"Lấy danh sách các màn hình trong dự án Stitch ScrumFlow"*

AI sẽ tự động gọi các tool MCP tương ứng (`get_project`, `get_screen`, `generate_screen_from_text`, `apply_design_system`) để làm việc với đúng dự án thiết kế này.

---

## 4. 📐 Tham Chiếu Bảng Màu & Typography Chuẩn Của Dự Án

* **Màu chủ đạo (Primary Indigo):** `#4F46E5`
* **Màu phụ (Secondary Sky):** `#0EA5E9`
* **Nền Canvas:** `#F8FAFC` (Surface: `#FFFFFF`)
* **Thẻ trạng thái Agile:**
  * **To Do:** Chữ `#475569`, Nền `#F1F5F9`, Viền `#E2E8F0`
  * **In Progress:** Chữ `#B45309`, Nền `#FEF3C7`, Viền `#FDE68A`
  * **Done:** Chữ `#047857`, Nền `#D1FAE5`, Viền `#A7F3D0`
* **Phông chữ:** `Plus Jakarta Sans` (Tiêu đề), `Inter` (Nội dung), `JetBrains Mono` (Mã số task / Story points).

*Mọi thắc mắc về thiết kế, vui lòng tham khảo chi tiết tại tệp `design.md` trong repo.*
