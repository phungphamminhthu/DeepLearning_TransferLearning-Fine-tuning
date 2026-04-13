import io
import torch
import torch.nn as nn
import torch.nn.functional as F
from torchvision import models, transforms
from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware # <-- MỚI: Import CORS
from PIL import Image

app = FastAPI(title="AI Image Scanner API")

# --- BẮT ĐẦU FIX LỖI CORS CHO WEB ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Mở cửa cho mọi trình duyệt (Chrome, Safari, Edge...)
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
# --- KẾT THÚC FIX LỖI CORS ---

# 1. Khởi tạo lại cấu hình và nạp bộ não
device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
class_names = ['FAKE', 'REAL']

model = models.resnet50()
num_ftrs = model.fc.in_features
model.fc = nn.Sequential(
    nn.Linear(num_ftrs, 512),
    nn.ReLU(),
    nn.Dropout(0.6), # <-- ĐÃ CẬP NHẬT LÊN 0.6 CHO KHỚP VỚI MODEL MỚI TRAIN
    nn.Linear(512, 2)
)

# Nạp file .pth (đảm bảo file ai_image_detector.pth đang nằm cùng thư mục)
model.load_state_dict(torch.load('ai_image_detector.pth', map_location=device))
model.to(device)
model.eval()

preprocess = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
])

# 2. Tạo đường ống (Endpoint) nhận ảnh
@app.post("/predict")
async def predict_image(file: UploadFile = File(...)):
    try:
        # Đọc file ảnh người dùng gửi lên
        contents = await file.read()
        img = Image.open(io.BytesIO(contents)).convert('RGB')
        
        # Tiền xử lý
        img_t = preprocess(img)
        batch_t = torch.unsqueeze(img_t, 0).to(device)
        
        # Phân tích
        with torch.no_grad():
            outputs = model(batch_t)
            probabilities = F.softmax(outputs, dim=1)[0] * 100
            _, predicted_class = torch.max(outputs, 1)
            
        label = class_names[predicted_class.item()]
        confidence = round(probabilities[predicted_class.item()].item(), 2)
        
        # Trả về kết quả JSON cho Mobile/Web App
        return {
            "status": "success",
            "label": label,
            "confidence": confidence
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}
    
    #uvicorn api:app --host 0.0.0.0 --port 8000 --reload