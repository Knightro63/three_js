import json
import os

# Configuration
target_folder = "shader_lib"  # Specifically scan only this folder
output_file = "my_shaders.shaderbundle.json"

bundle = {"shaders": []}

# Only proceed if the folder exists
if os.path.exists(target_folder):
    for root, dirs, files in os.walk(target_folder):
        for file in files:
            if file.endswith(".vert") or file.endswith(".frag"):
                # Determine type
                s_type = "vertex" if file.endswith(".vert") else "fragment"
                
                # Create a unique name for Dart (e.g., "mesh_physical_frag")
                s_name = file.replace(".", "_")
                
                # Get path relative to the root where the JSON will be saved
                rel_path = os.path.relpath(os.path.join(root, file), ".").replace("\\", "/")
                
                bundle["shaders"].append({
                    "name": s_name,
                    "type": s_type,
                    "file": rel_path
                })

    with open(output_file, "w") as f:
        json.dump(bundle, f, indent=2)

    print(f"Success! {len(bundle['shaders'])} master shaders from {target_folder} added to {output_file}")
else:
    print(f"Error: Folder '{target_folder}' not found. Please run this script from your main shaders directory.")
