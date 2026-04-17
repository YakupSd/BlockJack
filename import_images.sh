#!/bin/zsh

ASSETS_DIR="/Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Assets.xcassets"
BRAIN_DIR="/Users/yakupsuda/.gemini/antigravity/brain/af4e501d-7c46-4f42-9324-d692a012cd84"

# Format: name:source_file
images=(
  "cyber_merchant_portrait:cyber_merchant_portrait_1776412086534.png"
  "cyber_mystery_rift:cyber_mystery_rift_1776411027187.png"
  "cyber_battle_arena:cyber_battle_arena_1776411012933.png"
  "cyber_treasure_vault:cyber_treasure_vault_1776410994643.png"
  "cyber_merchant_shop:cyber_merchant_shop_1776410980395.png"
  "cyber_rest_site:cyber_rest_site_1776410960963.png"
)

for item in "${images[@]}"; do
  name="${item%%:*}"
  src_file_name="${item#*:}"
  src_file="${BRAIN_DIR}/${src_file_name}"
  dest_dir="${ASSETS_DIR}/${name}.imageset"
  
  echo "Processing $name ($src_file_name)..."
  
  mkdir -p "$dest_dir"
  cp "$src_file" "${dest_dir}/${name}.png"
  
  cat <<EOF > "${dest_dir}/Contents.json"
{
  "images" : [
    {
      "filename" : "${name}.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "idiom" : "universal",
      "scale" : "2x"
    },
    {
      "idiom" : "universal",
      "scale" : "3x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
EOF
done

echo "Done!"
