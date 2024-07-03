#!/bin/bash

# Warna ANSI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fungsi untuk menjalankan perintah rollback
run_rollback() {
    cd $HOME/tracks
    sleep 3
    for i in {1..3}
    do
        echo -e "${YELLOW}Running rollback attempt ${i}...${NC}"
        go run cmd/main.go rollback
        sleep 10
    done
}

# Fungsi untuk animasi spinner
spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Menginisialisasi penghitung eror
error_count=0


#fungsi buat nambahin tulisan
display_message() {
    local blue='\033[0;34m'      
    local NC='\033[0m'           
    local red='\033[0;31m'       
    
    echo -e "${blue}"
    echo "   ,--,                                                                    "
    echo ",---.'|                           ,--.                                    "
    echo "|   | :      ,---,              ,--.'|                ,---,.    ,---,      "
    echo ":   : |     '  .' \\         ,--,:  : |       ,---.  ,'  .' |  .'  .' \`    "
    echo "|   ' :    /  ;    '.    ,\`--.'\`|  ' :      /__./|,---.'   |,---.'     \\   "
    echo ";   ; '   :  :       \\   |   :  :  | | ,---.;  ; ||   |   .'|   |  .\`\\  |  "
    echo "'   | |__ :  |   /\\   \\  :   |   \\ | :/___/ \\  | |:   :  |-,:   : |  '  | "
    echo "|   | :.'||  :  ' ;.   : |   : '  '; |\\   ;  \\ ' |:   |  ;/||   ' '  ;  : "
    echo "'   :    ;|  |  ;/  \\   \\'   ' ;.    ; \\   \\  \\: ||   :   .''   | ;  .  | "
    echo "|   |  ./ '  :  | \\  \\ ,'|   | | \\   |  ;   \\  ' .|   |  |-,|   | :  |  ' "
    echo ";   : ;   |  |  '  '--'  '   : |  ; .'   \\   \\   ''   :  ;/|'   : | /  ;  "
    echo "|   ,/    |  :  :        |   | '\`--'      \\   \`  ;|   |    \|   | '\` ,/   "
    echo "'---'     |  | ,'        '   : |           :   \\ ||   :   .';   :  .'     "
    echo "          \`--''          ;   |.'            '---\" |   | ,'  |   ,.'       "
    echo "                         '---'                    \`----'    '---'         "
    echo "                                                                          "
    echo -e "  Monitoring Logs for ${red}Error ${blue}Message........${NC}                            "
    echo -e "${NC}"
}

# Memeriksa log secara terus-menerus
#echo -e "${BLUE}Monitoring Logs for Error msg..${NC}"

display_message
sudo journalctl -u stationd -f --no-hostname -o cat | while IFS= read -r line
do
    # Memeriksa jika baris mengandung kata eror
    if echo "$line" | grep -iq "error"; then
        ((error_count++))
        # Jika ditemukan lebih dari satu eror
        if [ "$error_count" -gt 4 ]; then
            echo -e "${RED}Error berhasil ditemukan...${NC}"
            echo -e "${GREEN}Masuk ke HOME directory${NC}"
            cd $HOME
            sleep 3
            echo -e "${YELLOW}Memberhentikan Stationd${NC}"
            systemctl stop stationd &
            spinner
            spinner
            sleep 120
            echo -e "${GREEN}StationD Telah berhenti${NC}"
            sleep 3
            echo "${GREEN}Memeriksa Pembaruan....."
            cd tracks && git pull 
            sleep 3
            echo "${GREEN}Pembaruan Telah Berhasil..."
            sleep 2
            echo -e "${YELLOW}Memulai Rollback${NC}"
            run_rollback
            sleep 3
            echo -e "${GREEN}Rollback Berhasil dilakukan${NC}"
            sleep 3
            echo -e "${YELLOW}Memulai kembali StationD${NC}"
            systemctl restart stationd &
            spinner
            echo -e "${GREEN}StationD berhasil di Restart${NC}"
            display_message
            #echo -e "${BLUE}Monitoring Logs for Error msg..${NC}"
            # Reset penghitung eror setelah menjalankan langkah-langkah
            error_count=0
        fi
    fi
done