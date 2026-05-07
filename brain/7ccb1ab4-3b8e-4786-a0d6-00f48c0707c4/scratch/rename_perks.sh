#!/bin/zsh

ASSETS_DIR="/Users/yakupsuda/YakupSuda_Projeler/Block-Jack/Block-Jack/Assets.xcassets"

# Map numbers to meaningful names
declare -A mapping
mapping[1]="perk_momentum"
mapping[2]="perk_glass_cannon"
mapping[3]="perk_overkill"
mapping[4]="perk_last_stand"
mapping[5]="perk_safe_house"
mapping[6]="perk_blue_pill"
mapping[7]="perk_static_charge"
mapping[8]="perk_midas_touch"
mapping[9]="perk_clockwork"
mapping[10]="perk_phantom_siphon"
mapping[11]="perk_vampiric_core"
mapping[12]="perk_tactical_lens"
mapping[13]="perk_recycler"
mapping[14]="perk_wide_load"
mapping[15]="perk_lucky_clover"
mapping[16]="perk_double_down"
mapping[17]="perk_chain_pulse"
mapping[18]="perk_sculptor"
mapping[19]="perk_lead_pill"
mapping[20]="perk_heavy_duty"

for num in ${(k)mapping}; do
    old_name="$num"
    new_name="${mapping[$num]}"
    
    old_dir="${ASSETS_DIR}/${old_name}.imageset"
    new_dir="${ASSETS_DIR}/${new_name}.imageset"
    
    if [ -d "$old_dir" ]; then
        echo "Renaming $old_name to $new_name..."
        
        # Rename the directory
        mv "$old_dir" "$new_dir"
        
        # Rename the file inside
        if [ -f "${new_dir}/${old_name}.png" ]; then
            mv "${new_dir}/${old_name}.png" "${new_dir}/${new_name}.png"
        fi
        
        # Update Contents.json
        cat <<EOF > "${new_dir}/Contents.json"
{
  "images" : [
    {
      "filename" : "${new_name}.png",
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
    else
        echo "Warning: $old_dir not found."
    fi
done

echo "Renaming complete!"
