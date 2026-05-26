import os
import shutil

# ==========================
# 1. Sử dụng CelebA từ Drive (đã copy vào /content)
# ==========================
dataset_path = "/content/CelebA"
print("📂 Using local CelebA dataset at", dataset_path)

# ==========================
# 2. Chuẩn bị thư mục train/val
# ==========================
train_dir = "dataset/train"
val_dir   = "dataset/val"
os.makedirs(train_dir, exist_ok=True)
os.makedirs(val_dir, exist_ok=True)

# ==========================
# 3. Đọc annotation và chia dữ liệu
# ==========================
anno_dir = os.path.join(dataset_path, "Anno")
attr_file = os.path.join(anno_dir, "list_attr_celeba.txt")
eval_file = os.path.join(dataset_path, "Eval/list_eval_partition.txt")

# Đọc thuộc tính Smiling
attr_dict = {}
with open(attr_file, "r") as f:
    lines = f.readlines()[2:]  # bỏ header
    for line in lines:
        parts = line.strip().split()
        filename = parts[0]
        smiling = int(parts[31])  # cột 31 là "Smiling"
        attr_dict[filename] = smiling

# ==========================
# 4. Đọc file chia train/val/test
# ==========================
img_dir = "/content/img_align_celeba/img_align_celeba"

copied_count = 0
with open(eval_file, "r") as f:
    for idx, line in enumerate(f, start=1):
        parts = line.strip().split()
        if len(parts) == 2:
            filename, partition = parts[0], int(parts[1])
        else:
            filename = f"{idx:06d}.jpg"
            partition = int(parts[0])

        src = os.path.join(img_dir, filename)
        if not os.path.exists(src):
            print("⚠️ Không tìm thấy:", src)
            continue

        label = "smiling" if attr_dict[filename] == 1 else "not_smiling"

        if partition == 0:  # train
            dst = os.path.join(train_dir, label)
        elif partition == 1:  # val
            dst = os.path.join(val_dir, label)
        else:
            continue  # bỏ qua test

        os.makedirs(dst, exist_ok=True)
        shutil.copy2(src, dst)
        copied_count += 1
        if copied_count <= 20:  # chỉ in log 20 ảnh đầu tiên cho gọn
            print(f"✅ Copy {src} → {dst}")

print(f"🎉 Hoàn tất! Đã copy {copied_count} ảnh vào dataset.")
