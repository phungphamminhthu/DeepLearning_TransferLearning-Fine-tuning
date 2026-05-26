```text
.
├── TransferLearning&Fine-tuning/  # Thư mục chứa mã nguồn chính
│   ├── .venv/                     # Môi trường ảo (đã chặn git)
│   ├── data/                      # Dữ liệu huấn luyện
│   ├── models/                    # Lưu trữ các file .pth sau khi train
│   ├── train.py                   # Script huấn luyện chính
│   └── evaluate.py                # Script đánh giá mô hình
├── requirements.txt               # Danh sách thư viện cần thiết
└── README.md                      # Hướng dẫn này

# Tạo và kích hoạt môi trường ảo
python -m venv .venv
.venv\Scripts\activate

# Cài đặt thư viện
pip install --upgrade pip
pip install -r ..\requirements.txt

#chạy api
uvicorn api:app --host 0.0.0.0 --port 8000

#xong chạy flutter
flutter run
