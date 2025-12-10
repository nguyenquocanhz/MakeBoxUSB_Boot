🛠️ USB TOOL PRO - FULLSTACK EDITION
====================================

**USB TOOL PRO** là bộ công cụ All-in-One gọn nhẹ, viết bằng **PowerShell** và **Batch Script**, giúp kỹ thuật viên tự động hóa quy trình đóng gói phần mềm, triển khai USB cứu hộ và tạo USB Boot đa năng.

🚀 Tính năng chính
------------------

1.  **Đóng gói (Pack):**
    
    *   Nén thư mục phần mềm thành file .bin (thực chất là 7z Ultra).
        
    *   Hỗ trợ đặt mật khẩu và mã hóa tên file (Encrypt Header).
        
    *   Tối ưu hóa đa luồng (Multi-threading).
        
2.  **Triển khai Dữ liệu (Deploy Data):**
    
    *   Tự động Format USB sang chuẩn **ExFAT** (để chứa file > 4GB).
        
    *   Bung nén file .bin (hoặc .iso) vào USB.
        
    *   Thích hợp để làm USB chứa bộ cài Software, Game, Office...
        
3.  **Tạo USB Boot Đa năng (Multiboot):**
    
    *   Tự động chia USB/HDD thành **2 phân vùng**:
        
        *   **PART 1 (BOOT):** FAT32, Set Active (Chuẩn UEFI & Legacy).
            
        *   **PART 2 (DATA):** NTFS (Chứa dữ liệu lớn an toàn).
            
    *   Tự động bung file ISO (Windows, Hiren, DLC Boot...) vào phân vùng Boot.
        
    *   **\[Độc quyền\]** Tự động nạp Bootloader **GRUB4DOS** (MBR & PBR) bằng BOOTICE.
        
4.  **Cơ chế thông minh:**
    
    *   Tự động tải **7-Zip** và **BOOTICE** nếu máy chưa có (Portable).
        
    *   Hỗ trợ kéo thả file (Drag & Drop) hoặc Auto-scan file cùng thư mục.
        
    *   Bảo vệ ổ đĩa hệ thống: Tự động loại trừ ổ C: và ổ chứa Windows để tránh xóa nhầm.
        

📋 Yêu cầu hệ thống
-------------------

*   **Hệ điều hành:** Windows 10, Windows 11 (Khuyên dùng). Windows 7 (Hạn chế một số lệnh PowerShell).
    
*   **Quyền hạn:** Bắt buộc chạy dưới quyền **Administrator**.
    
*   **Kết nối mạng:** Cần internet ở lần chạy đầu tiên để tải Core Tools (7-Zip, Bootice).
    

📖 Hướng dẫn sử dụng
--------------------

Bạn có thể chọn dùng phiên bản **PowerShell** (Khuyên dùng - Giao diện đẹp, nhiều tính năng) hoặc **CMD** (Cho máy cấu hình thấp/WinPE).

### Cách 1: Sử dụng phiên bản PowerShell (.ps1)

Đây là phiên bản đầy đủ tính năng nhất (Auto Scan file, File Dialog, Check ổ đĩa an toàn).

1.  Chuột phải vào file USB\_Tool\_Pro.ps1.
    
2.  Chọn **Run with PowerShell**.
    
    *   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
        
3.  Chọn chức năng từ Menu (1-4).
    

### Cách 2: Sử dụng phiên bản Batch (.cmd)

Dành cho môi trường WinPE hoặc máy không chạy được PowerShell script.

1.  Chuột phải vào file USB\_Tool\_Pro.cmd.
    
2.  Chọn **Run as Administrator**.
    
3.  Làm theo hướng dẫn trên màn hình Console.
    

💡 Chi tiết các chức năng
-------------------------

### \[1\] Đóng gói Folder -> File .BIN

*   **Mục đích:** Sao lưu folder phần mềm portable của bạn thành 1 file duy nhất để dễ copy.
    
*   **Thao tác:** Kéo thả Folder cần nén vào cửa sổ Tool -> Nhập tên file đầu ra -> Đặt mật khẩu (nếu cần).
    

### \[2\] Chép File .BIN -> USB Data

*   **Mục đích:** Tạo USB chứa dữ liệu thuần túy (không Boot).
    
*   **Thao tác:** Chọn file nguồn -> Chọn USB đích -> Tool sẽ Format ExFAT và bung nén.
    

### \[3\] Tạo USB Boot 2 Phân vùng

*   **Mục đích:** Làm USB cài Win hoặc Cứu hộ chuyên nghiệp.
    
*   **Cấu trúc:**
    
    *   Phân vùng BOOT (FAT32) sẽ bị ẩn trên các bản Windows cũ để tránh virus.
        
    *   Phân vùng DATA (NTFS) hiện ra để bạn chép dữ liệu.
        
*   **Thao tác:** Chọn file ISO (ví dụ: Anhdv\_Boot.iso) -> Chọn ổ đích (cẩn thận chọn đúng Disk Number) -> Xác nhận Format -> Chọn "Y" để nạp GRUB4DOS.
    

⚠️ Những lưu ý quan trọng
-------------------------

1.  **Dữ liệu:** Các chức năng \[2\] và \[3\] đều **XÓA SẠCH** dữ liệu trên ổ đĩa đích. Hãy backup trước khi làm.
    
2.  **Đường dẫn file:** Tool hỗ trợ đường dẫn có dấu cách và tiếng Việt. Tuy nhiên, hạn chế các ký tự quá đặc biệt như ! @ # $ % trong tên file ISO.
    
3.  **An toàn:** Tool đã tích hợp bộ lọc chặn chọn ổ C:. Tuy nhiên, hãy luôn nhìn kỹ **Tên ổ đĩa** và **Dung lượng** ở bước xác nhận cuối cùng (Confirm YES).
    

🛠️ Cấu trúc thư mục
--------------------

Sau khi chạy lần đầu, tool sẽ tự tạo cấu trúc như sau:
```   
USB_Tool_Pro/
├── USB_Tool_Pro.ps1
└── Tools/
      ├── 7z.exe      
      ── 7z.dll
      └── BOOTICE.exe
```

_Dev by: Fullstack Colleague_
