# import gdown
# import zipfile
# import os
# import shutil

# # 1. Kiểm tra file đã tồn tại chưa
# output = "celeba.zip"
# if not os.path.exists(output):
#     url = "https://drive.google.com/uc?id=0B7EVK8r0v71pZjFTYXZWM3FlRnM" # thay FILE_ID bằng ID thật của file CelebA.zip
#     print("Đang tải CelebA từ Google Drive...")
#     gdown.download(url, output, quiet=False, resume=True)
# else:
#     print("File celeba.zip đã tồn tại, bỏ qua bước tải.")

# # 2. Giải nén nếu chưa có thư mục
# extract_dir = "CelebA"
# if not os.path.exists(extract_dir):
#     print("Giải nén CelebA...")
#     with zipfile.ZipFile(output, 'r') as zip_ref:
#         zip_ref.extractall(extract_dir)
# else:
#     print("Thư mục CelebA đã tồn tại, bỏ qua bước giải nén.")

# # 3. Chuẩn bị thư mục train/val
# train_dir = "dataset/train"
# val_dir   = "dataset/val"
# os.makedirs(train_dir, exist_ok=True)
# os.makedirs(val_dir, exist_ok=True)

# # 4. Đọc annotation và chia dữ liệu (ví dụ thuộc tính Smiling)
# anno_dir = os.path.join(extract_dir, "Anno")
# attr_file = os.path.join(anno_dir, "list_attr_celeba.txt")
# eval_file = os.path.join(anno_dir, "list_eval_partition.txt")

# # Đọc thuộc tính Smiling
# attr_dict = {}
# with open(attr_file, "r") as f:
#     lines = f.readlines()[2:]
#     for line in lines:
#         parts = line.strip().split()
#         filename = parts[0]
#         smiling = int(parts[31])  # cột 31 là "Smiling"
#         attr_dict[filename] = smiling

# # Đọc file chia train/val/test
# with open(eval_file, "r") as f:
#     for line in f:
#         filename, partition = line.strip().split()
#         partition = int(partition)

#         src = os.path.join(extract_dir, "Img/img_align_celeba", filename)
#         if not os.path.exists(src):
#             continue

#         label = "smiling" if attr_dict[filename] == 1 else "not_smiling"

#         if partition == 0:  # train
#             dst = os.path.join(train_dir, label)
#         elif partition == 1:  # val
#             dst = os.path.join(val_dir, label)
#         else:
#             continue

#         os.makedirs(dst, exist_ok=True)
#         shutil.copy(src, dst)

# print("CelebA đã được chia thành train/val theo thuộc tính Smiling.")

import gdown
import zipfile
import os
import shutil

# ==========================
# 1. Tải CelebA từ Google Drive
# ==========================
output = "celeba.zip"
if not os.path.exists(output):
    url = "https://drive.google.com/uc?id=0B7EVK8r0v71pZjFTYXZWM3FlRnM"
    print("📥 Đang tải CelebA từ Google Drive...")
    gdown.download(url, output, quiet=False, resume=True)
else:
    print("✅ File celeba.zip đã tồn tại, bỏ qua bước tải.")

# ==========================
# 2. Giải nén nếu chưa có thư mục
# ==========================
extract_dir = "CelebA"
if not os.path.exists(extract_dir):
    print("📦 Giải nén CelebA...")
    with zipfile.ZipFile(output, 'r') as zip_ref:
        zip_ref.extractall(extract_dir)
else:
    print("✅ Thư mục CelebA đã tồn tại, bỏ qua bước giải nén.")

# ==========================
# 3. Chuẩn bị thư mục train/val
# ==========================
train_dir = "dataset/train"
val_dir   = "dataset/val"
os.makedirs(train_dir, exist_ok=True)
os.makedirs(val_dir, exist_ok=True)

# ==========================
# 4. Đọc annotation và chia dữ liệu
# ==========================
anno_dir = os.path.join(extract_dir, "Anno")
attr_file = os.path.join(anno_dir, "list_attr_celeba.txt")
eval_file = os.path.join(anno_dir, "list_eval_partition.txt")

# Đọc thuộc tính Smiling
attr_dict = {}
with open(attr_file, "r") as f:
    lines = f.readlines()[2:]  # bỏ header
    for line in lines:
        parts = line.strip().split()
        filename = parts[0]
        smiling = int(parts[31])  # cột 31 là "Smiling"
        attr_dict[filename] = smiling

# Đọc file chia train/val/test
img_dir = os.path.join(extract_dir, "Img/img_align_celeba")
with open(eval_file, "r") as f:
    for line in f:
        filename, partition = line.strip().split()
        partition = int(partition)

        src = os.path.join(img_dir, filename)
        if not os.path.exists(src):
            continue

        label = "smiling" if attr_dict[filename] == 1 else "not_smiling"

        if partition == 0:  # train
            dst = os.path.join(train_dir, label)
        elif partition == 1:  # val
            dst = os.path.join(val_dir, label)
        else:
            continue  # bỏ qua test

        os.makedirs(dst, exist_ok=True)
        shutil.copy(src, dst)

print("✅ CelebA đã chia thành train/val theo Smiling.")
