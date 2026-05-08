import os

target_folder = "shader_lib"

if os.path.exists(target_folder):
    print("Copy and paste this into your pubspec.yaml under 'shaders:':\n")
    for root, dirs, files in os.walk(target_folder):
        for file in files:
            if file.endswith((".vert", ".frag")):
                # Get the relative path for pubspec
                rel_path = os.path.relpath(os.path.join(root, file), ".").replace("\\", "/")
                print(f"    - {rel_path}")
else:
    print(f"Folder '{target_folder}' not found.")
