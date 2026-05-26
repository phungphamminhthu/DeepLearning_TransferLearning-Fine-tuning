import os

for split in ["train", "val"]:
    for label in ["smiling", "not_smiling"]:
        folder = f"dataset/{split}/{label}"
        if os.path.exists(folder):
            print(f"{split}/{label}: {len(os.listdir(folder))}")
        else:
            print(f"{split}/{label}: chưa tồn tại")
