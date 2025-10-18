# Coding Convention: 

- **Dấu ngoặc nhọn(Braces): Luôn sử dung dấu ngoặc nhọn {} cho các khối lệnh, ngay cả khi chỉ có một câu lệnh**
    - **Ví dụ:**
        if (condition) {
        doSomething();
        }   
- **Đặt tên:** Có ý nghĩa với biến, hàm, class. Với hàm sử dụng camelCase, biến sử dụng snake_case, và Class sử dụng PascalCase. Với hàng số sử dụng SCREAMING_SNAKE_CASE
- **Khi xây dựng Class cần tối ưu hóa phạm vi:** Chỉ để lộ những gì cần thiết trong public, Sử dụng private và protected cho dữ liệu và hàm nội bộ.
ụng std::unique_ptr hoặc std::shared_ptr thay vì con trỏ thô (raw_pointers). Ngoài ra luôn kiểm tra việc giải phóng tài nguyên trong destructor. Không sử dụng new/delete trực tiếp trừ khi cần thiết.
- **Sử dụng git commit message rõ ràng**
    - **Ví dụ:** add user authentication module:
    - Implement login functionality
    - Check OTP
- **Khi viết hàm nên tối ưu hóa không quá dài. Để dễ bảo trì. Ưu tiên các hàm có thể tái sử dụng**




