#!/bin/bash

echo "Select language / Dil seçin:"
echo "1 - Türkçe"
echo "2 - English"
read -p "Seçiminiz / Your choice (1/2): " dilSecimi

if [[ "$dilSecimi" == "2" ]]; then
    LANG=EN
else
    LANG=TR
fi

msg() {
    case "$1" in
        enter_filename)
            [[ "$LANG" == "EN" ]] && echo "Enter Lua file name (e.g. script.lua): " || echo "Lua dosya adı (örnek: script.lua): "
            ;;
        menu_count)
            [[ "$LANG" == "EN" ]] && echo "How many menu options?: " || echo "Kaç adet menü seçeneği olacak?: "
            ;;
        menu_title)
            [[ "$LANG" == "EN" ]] && echo "$2. Menu title (e.g. Freeze Money): " || echo "$2. Menü başlığı (örnek: Parayı dondur): "
            ;;
        search_value)
            [[ "$LANG" == "EN" ]] && echo "[$2. Menu] Value to search: " || echo "[$2. Menü] Aranacak değer: "
            ;;
        type_input)
            [[ "$LANG" == "EN" ]] && echo "[$2. Menu] Type (e.g. Dword, Float): " || echo "[$2. Menü] Tür (örnek: Dword, Float): "
            ;;
        action_prompt)
            if [[ "$LANG" == "EN" ]]; then
                echo "[$2. Menu] What to do with results?"
                echo "1 - Freeze"
                echo "2 - Edit with new value"
                echo "3 - Do nothing"
                echo "4 - Freeze with another value"
            else
                echo "[$2. Menü] Sonuçlara ne yapılsın?"
                echo "1 - Dondur"
                echo "2 - Yeni değer ile değiştir"
                echo "3 - Hiçbir şey yapma"
                echo "4 - Başka bir değer ile dondur"
            fi
            ;;
        invalid_type)
            [[ "$LANG" == "EN" ]] && echo "Invalid type! Valid: ${known_types[*]}" || echo "Geçersiz tür! Geçerli: ${known_types[*]}"
            ;;
        file_created)
            [[ "$LANG" == "EN" ]] && echo "✅ $dosyaAdi successfully created." || echo "✅ $dosyaAdi başarıyla oluşturuldu."
            ;;
        invalid_choice)
            [[ "$LANG" == "EN" ]] && echo "Invalid choice. Please enter 1-4." || echo "Geçersiz seçim. Lütfen 1-4 arası girin."
            ;;
        function_added)
            [[ "$LANG" == "EN" ]] && echo "✅ [$2] function added." || echo "✅ [$2] işlem fonksiyonu eklendi."
            ;;
    esac
}

read -p "$(msg enter_filename)" dosyaAdi
[[ "$dosyaAdi" != *.lua ]] && dosyaAdi="${dosyaAdi}.lua"

read -p "$(msg menu_count)" menuSayisi
if ! [[ "$menuSayisi" =~ ^[1-9][0-9]*$ ]]; then
    echo "Hatalı giriş / Invalid input. Çıkılıyor / Exiting..."
    exit 1
fi

echo "-- Game Guardian Script" > "$dosyaAdi"
echo "" >> "$dosyaAdi"
echo "function menu()" >> "$dosyaAdi"
echo "  local secim = gg.choice({" >> "$dosyaAdi"

declare -a menuIsimleri
declare -a fonksiyonIsimleri

for (( i=1; i<=menuSayisi; i++ ))
do
    while true; do
        read -p "$(msg menu_title $i)" menuBaslik
        [[ -z "$menuBaslik" ]] && echo "Boş bırakılamaz / Cannot be empty." || break
    done
    menuIsimleri+=("$menuBaslik")
    fonksiyonIsimleri+=("islem_$i")
    echo "    \"$menuBaslik\"," >> "$dosyaAdi"
done

echo "    \"Çıkış / Exit\"" >> "$dosyaAdi"
echo "  }, nil, \"Bir seçenek seçin / Select an option\")" >> "$dosyaAdi"
echo "  if secim == nil then return end" >> "$dosyaAdi"

for (( i=1; i<=menuSayisi; i++ ))
do
    echo "  if secim == $i then ${fonksiyonIsimleri[$i-1]}() end" >> "$dosyaAdi"
done

echo "  if secim == $((menuSayisi+1)) then os.exit() end" >> "$dosyaAdi"
echo "end" >> "$dosyaAdi"
echo "" >> "$dosyaAdi"

known_types=("DWORD" "FLOAT" "DOUBLE" "QWORD" "BYTE" "AUTO")

for (( i=1; i<=menuSayisi; i++ ))
do
    echo "function ${fonksiyonIsimleri[$i-1]}()" >> "$dosyaAdi"

    while true; do
        read -p "$(msg search_value $i)" aranacakDeger
        [[ -z "$aranacakDeger" ]] && echo "Boş bırakılamaz / Cannot be empty." || break
    done

    while true; do
        read -p "$(msg type_input $i)" tur
        tur=$(echo "$tur" | tr '[:lower:]' '[:upper:]')
        if [[ " ${known_types[*]} " == *" $tur "* ]]; then break; fi
        msg invalid_type
    done

    echo "  gg.clearResults()" >> "$dosyaAdi"
    echo "  gg.searchNumber(\"$aranacakDeger\", gg.TYPE_$tur)" >> "$dosyaAdi"
    echo "  local results = gg.getResults(100)" >> "$dosyaAdi"

    msg action_prompt $i
    while true; do
        read -p "> " sonucIslem
        case $sonucIslem in
            1)
                echo "  for i,v in ipairs(results) do v.freeze = true end" >> "$dosyaAdi"
                echo "  gg.addListItems(results)" >> "$dosyaAdi"
                echo "  gg.toast(\"$aranacakDeger frozen.\")" >> "$dosyaAdi"
                break ;;
            2)
                read -p "New value / Yeni değer: " yeniDeger
                echo "  gg.editAll(\"$yeniDeger\", gg.TYPE_$tur)" >> "$dosyaAdi"
                echo "  gg.toast(\"$aranacakDeger → $yeniDeger\")" >> "$dosyaAdi"
                break ;;
            3)
                echo "  gg.toast(\"$aranacakDeger found, no action taken.\")" >> "$dosyaAdi"
                break ;;
            4)
                read -p "Value to freeze with: " dondurDeger
                echo "  for i,v in ipairs(results) do v.value = \"$dondurDeger\"; v.freeze = true end" >> "$dosyaAdi"
                echo "  gg.addListItems(results)" >> "$dosyaAdi"
                echo "  gg.toast(\"$aranacakDeger frozen as $dondurDeger\")" >> "$dosyaAdi"
                break ;;
            *)
                msg invalid_choice
                ;;
        esac
    done

    echo "end" >> "$dosyaAdi"
    echo "" >> "$dosyaAdi"
    msg function_added $i
done

echo "while true do" >> "$dosyaAdi"
echo "  if gg.isVisible(true) then" >> "$dosyaAdi"
echo "    gg.setVisible(false)" >> "$dosyaAdi"
echo "    menu()" >> "$dosyaAdi"
echo "  end" >> "$dosyaAdi"
echo "end" >> "$dosyaAdi"

msg file_created