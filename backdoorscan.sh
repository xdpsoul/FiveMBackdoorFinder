#!/bin/bash

################################################ IGNORE ################################################

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

CRITICAL_COUNT=0
HIGH_COUNT=0
MEDIUM_COUNT=0
FOUND_ITEMS=()

################################################ IGNORE ################################################

############################################# CONFIGURATION ############################################

SCAN_PATH="/var/lib/pterodactyl/volumes/2312628e-b975-42cf-b3cf-0dc0b3a35b5a/"

BASE_PATH="ESXLegacy_696C1C.base"

FULL_SCAN_PATH="${SCAN_PATH}txData/${BASE_PATH}/resources/"

REPORT_FILE="lunashield_report_$(date +%m%d_%H%M%S).txt"

############################################# CONFIGURATION ############################################

clear
echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║                    ╦  ╦ ╦╔╗╔╔═╗╔═╗╦ ╦╦╔═╗╦  ╔╦╗                   ║"
echo "║                    ║  ║ ║║║║╠═╣╚═╗╠═╣║║╣ ║   ║║                   ║"
echo "║                    ╩═╝╚═╝╝╚╝╩ ╩╚═╝╩ ╩╩╚═╝╩═╝═╩╝                   ║"
echo "║                                                                   ║"
echo "║                 Advanced Malware Detection System                 ║"
echo "║                            by Soul <3                             ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

echo "╦  ╦ ╦╔╗╔╔═╗╔═╗╦ ╦╦╔═╗╦  ╔╦╗" > "$REPORT_FILE"
echo "║  ║ ║║║║╠═╣╚═╗╠═╣║║╣ ║   ║║" >> "$REPORT_FILE"
echo "╩═╝╚═╝╝╚╝╩ ╩╚═╝╩ ╩╩╚═╝╩═╝═╩╝" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"
echo "Path: $SCAN_PATH" >> "$REPORT_FILE"
echo ""

show_loading() {
    echo -e "${CYAN}Configuration:${NC}"
    echo -e "${BLUE}Path: ${YELLOW}$SCAN_PATH${NC}"
    echo ""
    
    echo -e "${CYAN}Initializing scan${NC}"
    sleep 1.5
    echo -e "${GREEN}✅ Done${NC}"
    echo ""
    
    echo -e "${CYAN}Checking for Miaus malware patterns${NC}"
    sleep 1.7
    echo -e "${GREEN}✅ Done${NC}"
    echo ""
    
    echo -e "${CYAN}Checking for Cipher/Blum backdoor patterns${NC}"
    sleep 1.6
    echo -e "${GREEN}✅ Done${NC}"
    echo ""
    
    echo -e "${CYAN}Analyzing suspicious code patterns${NC}"
    sleep 1.8
    echo -e "${GREEN}✅ Done${NC}"
    echo ""
    
    echo -e "${CYAN}Scanning for hidden files${NC}"
    sleep 1.4
    echo -e "${GREEN}✅ Done${NC}"
    echo ""
    
    echo -e "${CYAN}Generating report${NC}"
    echo ""
    
    sleep 0.5
}

scan() {
    local pattern="$1"
    local desc="$2"
    local severity="$3"
    local ext="$4"
    local scan_results=""
    
    if [ "$ext" == "js" ]; then
        scan_results=$(grep -rln "$pattern" "$SCAN_PATH" --include="*.js" 2>/dev/null | grep -v node_modules | grep -v '.min.js')
    elif [ "$ext" == "lua" ]; then
        scan_results=$(grep -rln "$pattern" "$SCAN_PATH" --include="*.lua" 2>/dev/null | grep -v node_modules)
    else
        scan_results=$(grep -rln "$pattern" "$SCAN_PATH" --include="*.lua" --include="*.js" 2>/dev/null | grep -v node_modules | grep -v '.min.js')
    fi
    
    if [ -n "$scan_results" ]; then
        count=$(echo "$scan_results" | wc -l)
        case $severity in
            "CRITICAL") 
                CRITICAL_COUNT=$((CRITICAL_COUNT + count))
                FOUND_ITEMS+=("CRITICAL|$desc|$count")
                ;;
            "HIGH") 
                HIGH_COUNT=$((HIGH_COUNT + count))
                FOUND_ITEMS+=("HIGH|$desc|$count")
                ;;
            "MEDIUM") 
                MEDIUM_COUNT=$((MEDIUM_COUNT + count))
                FOUND_ITEMS+=("MEDIUM|$desc|$count")
                ;;
        esac
        echo "" >> "$REPORT_FILE"
        echo "[$severity] $desc" >> "$REPORT_FILE"
        echo "$scan_results" >> "$REPORT_FILE"
        
        if [ "$desc" == "Blum Panel NEW" ]; then
            echo "$scan_results" | while read file; do
                if [ -f "$file" ]; then
                    if [[ "$file" == *"/system_resources/"* ]]; then
                        folder_to_delete=$(echo "$file" | grep -o '.*/system_resources/[^/]*' | head -1)
                        
                        echo -e "${RED}🔍 ATTEMPTING TO DELETE FOLDER: ${YELLOW}$folder_to_delete${NC}"
                        
                        if [ -d "$folder_to_delete" ]; then
                            echo -e "${RED}🗑️  DELETING FOLDER: ${YELLOW}$folder_to_delete${NC}"
                            rm -rf "$folder_to_delete"
                            if [ ! -d "$folder_to_delete" ]; then
                                echo -e "${GREEN}✅ SUCCESSFULLY DELETED FOLDER: ${YELLOW}$folder_to_delete${NC}"
                                FOUND_ITEMS+=("DELETED|FOLDER: $folder_to_delete|1")
                            else
                                echo -e "${RED}❌ FAILED TO DELETE FOLDER: ${YELLOW}$folder_to_delete${NC}"
                            fi
                        else
                            echo -e "${YELLOW}⚠️  DIRECTORY NOT FOUND: ${YELLOW}$folder_to_delete${NC}"
                        fi
                    else
                        echo -e "${YELLOW}📁 IN $BASE_PATH - DELETING FILE: ${YELLOW}$file${NC}"
                        rm -f "$file"
                        if [ ! -f "$file" ]; then
                            echo -e "${GREEN}✅ SUCCESSFULLY DELETED FILE: ${YELLOW}$file${NC}"
                            FOUND_ITEMS+=("DELETED|FILE: $file|1")
                        else
                            echo -e "${RED}❌ FAILED TO DELETE FILE: ${YELLOW}$file${NC}"
                        fi
                    fi
                fi
            done
        fi
    fi
}

scan_blum_xor() {
    local desc="Blum Panel NEW - XOR Backdoor"
    local severity="CRITICAL"
    
    local scan_results=$(find "$SCAN_PATH" -type f -name "*.js" 2>/dev/null | while read file; do
        if head -n 1 "$file" 2>/dev/null | grep -q "(function(){const [a-z][a-z0-9]*=[0-9]*;function [a-z][a-z0-9]*(a,k){"; then
            echo "$file"
        fi
    done)
    
    if [ -n "$scan_results" ]; then
        count=$(echo "$scan_results" | wc -l)
        CRITICAL_COUNT=$((CRITICAL_COUNT + count))
        FOUND_ITEMS+=("CRITICAL|$desc|$count")
        
        echo "$scan_results" | while read file; do
            rm -f "$file"
            if [ ! -f "$file" ]; then
                echo -e "${GREEN}✅ DELETED: $file${NC}"
                FOUND_ITEMS+=("DELETED|FILE: $file|1")
            else
                echo -e "${RED}❌ ERROR: $file${NC}"
            fi
        done
    else
        echo -e "${RED}❌ NOTHING FOUND${NC}"
        
        find "$SCAN_PATH" -type f -name "*.js" 2>/dev/null | head -5 | while read f; do
            echo -e "${CYAN}FILE: $f${NC}"
            echo -e "FIRST LINE:"
            head -n 1 "$f" 2>/dev/null | cut -c 1-100
            echo ""
        done
    fi
}

show_loading
scan_blum_xor

scan 'x=s=>eval' "Miaus - XOR Decoder (x=s=>eval)" "CRITICAL" "js"
scan 'Yz4nEW9,xqeiF1,LyvVH95,kNcQKf,znG1Ldr,_rogDLd' "Blum Panel NEW" "CRITICAL" "js"
scan 'screenshare:startStream' "Blum Panel NEW" "CRITICAL" "lua"
scan 'screenshare:stopStream' "Blum Panel NEW" "CRITICAL" "lua"
scan 'screenshare:webrtcAnswer' "Blum Panel NEW" "CRITICAL" "lua"
scan 'screenshare:webrtcIceCandidate' "Blum Panel NEW" "CRITICAL" "lua"
scan '\x50\x65\x72\x66\x6f\x72\x6d\x48\x74\x74\x70\x52\x65\x71\x75\x65\x73\x74' "Blum Panel NEW" "CRITICAL" "lua"
scan '\\u0075\\u006e\\u0064\\u0065\\u0066\\u0069\\u006e\\u0065\\u0064' "Blum Panel NEW" "CRITICAL" "js"
scan 'function\(\){const [a-z]{10}=[0-9]{3};function [a-z]{9}\(a,k\){var s=[^;]+;for\(var i=0;i<a.length;i++\){s\+=String\.fromCharCode\(a\[i\]\^k\);}return s;}const [a-z]{9}=[^;]+;eval\([a-z]{9}\([a-z]{9},[a-z]{10}\)\);}\(\)\);' "Blum Panel NEW - XOR Decoder" "CRITICAL" "js"
scan '\\x1A\\x40\\x47\\x41\\x47' "Blum Panel NEW" "CRITICAL" "js"
scan 'const k="r4314";' "Blum Panel NEW" "CRITICAL" "js"
scan 'eval(s.replace' "Miaus - eval+replace" "CRITICAL" "js"
scan 'v="\\u00' "Miaus - Unicode Payload" "CRITICAL" "js"
scan "v='\\\\u00" "Miaus - Unicode Payload" "CRITICAL" "js"
scan 'charCodeAt(0)^3' "Miaus - XOR Key 3" "CRITICAL" "js"
scan 'charCodeAt(0) ^ 3' "Miaus - XOR Key 3" "CRITICAL" "js"
scan '9ns1.com' "Miaus - C2 Domain" "CRITICAL" "all"
scan '9ns1' "Miaus - Reference" "CRITICAL" "all"
scan 'zXeHjj' "Miaus - Endpoint" "CRITICAL" "all"
scan 'globalThis.GlobalState' "Miaus - Persistence" "CRITICAL" "js"
scan 'GlobalState\[' "Miaus - Persistence" "HIGH" "js"
scan '"miaus"' "Miaus - Malware Name" "CRITICAL" "all"
scan "'miaus'" "Miaus - Malware Name" "CRITICAL" "all"

scan 'assert(load(d))' "Cipher - Backdoor Loader" "CRITICAL" "lua"
scan 'assert(load(r))' "Cipher - Backdoor Loader" "CRITICAL" "lua"
scan 'pcall(function() assert(load' "Cipher - Protected Loader" "CRITICAL" "lua"
scan 'helpCode' "Cipher - Signature" "CRITICAL" "all"
scan 'Enchanced_Tabs' "Cipher - Variable" "CRITICAL" "lua"
scan 'random_char' "Cipher - Variable" "HIGH" "lua"
scan 'cipher-panel' "Cipher - C2 Domain" "CRITICAL" "all"
scan 'blum-panel' "Blum - C2 Domain" "CRITICAL" "all"
scan 'ciphercheats' "Cipher - Reference" "CRITICAL" "all"
scan 'keyx.club' "Cipher - C2 Domain" "CRITICAL" "all"
scan 'dark-utilities' "Cipher - C2 Domain" "CRITICAL" "all"

scan '\\x50\\x65\\x72\\x66\\x6f\\x72\\x6d' "Hex - PerformHttpRequest" "HIGH" "lua"
scan '\\x61\\x73\\x73\\x65\\x72\\x74' "Hex - assert" "HIGH" "lua"
scan '\\x6c\\x6f\\x61\\x64' "Hex - load" "HIGH" "lua"
scan 'loadstring' "Lua - loadstring()" "HIGH" "lua"
scan 'RunString' "Lua - RunString()" "HIGH" "lua"
scan 'String.fromCharCode(parseInt' "JS - Unicode Decoding" "HIGH" "js"
scan 'fromCharCode' "JS - Char Conversion" "MEDIUM" "js"
scan 'eval(' "JS - eval()" "HIGH" "js"

echo -e "$FULL_SCAN_PATH"
hidden_files=$(find "$FULL_SCAN_PATH" -type f \( -name "*.lua" -o -name "*.js" \) 2>/dev/null)
if [ -n "$hidden_files" ]; then
    echo -e "${YELLOW}📋 Found $(echo "$hidden_files" | wc -l) files${NC}"
    
    echo "$hidden_files" | while read file; do
        if [ -f "$file" ]; then
            first_line=$(head -n 1 "$file" 2>/dev/null | tr -d '\0')
            
            if [[ "$first_line" =~ ^/\*\ \[.*\]\ \*/ ]]; then
                echo -e "${RED}🔴 FOUND FILE WITH PATTERN: ${YELLOW}$file${NC}"
                echo -e "${RED}   └── Pattern: $first_line${NC}"
                echo -e "${RED}   └── 🗑️  DELETING...${NC}"
                
                rm -f "$file"
                if [ ! -f "$file" ]; then
                    echo -e "${GREEN}   └── ✅ DELETED${NC}"
                    CRITICAL_COUNT=$((CRITICAL_COUNT + 1))
                    FOUND_ITEMS+=("CRITICAL|File with /* [*] */ pattern|1")
                    FOUND_ITEMS+=("DELETED|FILE: $file|1")
                else
                    echo -e "${RED}   └── ❌ DELETE FAILED${NC}"
                fi
            fi
        fi
    done
    
    echo "" >> "$REPORT_FILE"
    echo "[CRITICAL] Files with /* [*] */ pattern" >> "$REPORT_FILE"
    echo "$hidden_files" >> "$REPORT_FILE"
    
else
    echo -e "${GREEN}✅ No files found${NC}"
fi

echo -e ""

TOTAL=$((CRITICAL_COUNT + HIGH_COUNT + MEDIUM_COUNT))
echo "" >> "$REPORT_FILE"
echo "=== SCAN SUMMARY ===" >> "$REPORT_FILE"
echo "CRITICAL: $CRITICAL_COUNT" >> "$REPORT_FILE"
echo "HIGH: $HIGH_COUNT" >> "$REPORT_FILE"
echo "MEDIUM: $MEDIUM_COUNT" >> "$REPORT_FILE"
echo "TOTAL DETECTIONS: $TOTAL" >> "$REPORT_FILE"
echo "Scan completed: $(date)" >> "$REPORT_FILE"

clear
echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║                    ╦  ╦ ╦╔╗╔╔═╗╔═╗╦ ╦╦╔═╗╦  ╔╦╗                   ║"
echo "║                    ║  ║ ║║║║╠═╣╚═╗╠═╣║║╣ ║   ║║                   ║"
echo "║                    ╩═╝╚═╝╝╚╝╩ ╩╚═╝╩ ╩╩╚═╝╩═╝═╩╝                   ║"
echo "║                                                                   ║"
echo "║                 Advanced Backdoor Detection System                ║"
echo "║                            by Soul <3                             ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

if [ $TOTAL -eq 0 ]; then
    echo -e "${GREEN}✅ Scan completed successfully!${NC}"
    echo ""
    echo -e "${GREEN}No threats detected in: $SCAN_PATH${NC}"
else
    echo -e "${RED}⚠️  Scan completed with findings!${NC}"
    echo ""
    
    if [ $CRITICAL_COUNT -gt 0 ]; then
        echo -e "${RED}CRITICAL threats found: $CRITICAL_COUNT${NC}"
    fi
    if [ $HIGH_COUNT -gt 0 ]; then
        echo -e "${YELLOW}HIGH threats found: $HIGH_COUNT${NC}"
    fi
    if [ $MEDIUM_COUNT -gt 0 ]; then
        echo -e "${CYAN}MEDIUM threats found: $MEDIUM_COUNT${NC}"
    fi
    
    echo ""
    echo -e "${YELLOW}Total detections: $TOTAL${NC}"
fi

sleep 4
clear
echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════════════╗"
echo "║                    ╦  ╦ ╦╔╗╔╔═╗╔═╗╦ ╦╦╔═╗╦  ╔╦╗                   ║"
echo "║                    ║  ║ ║║║║╠═╣╚═╗╠═╣║║╣ ║   ║║                   ║"
echo "║                    ╩═╝╚═╝╝╚╝╩ ╩╚═╝╩ ╩╩╚═╝╩═╝═╩╝                   ║"
echo "║                                                                   ║"
echo "║                     List of Detected Threats                      ║"
echo "║                            by Soul <3                             ║"
echo "╚═══════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

DELETED_COUNT=0

for item in "${FOUND_ITEMS[@]}"; do
    severity=$(echo "$item" | cut -d'|' -f1)
    desc=$(echo "$item" | cut -d'|' -f2)
    count=$(echo "$item" | cut -d'|' -f3)
    
    if [ "$severity" == "DELETED" ]; then
        echo -e "${RED}🗑️  DELETED FOLDER: ${YELLOW}$desc${NC} ${GREEN}[$count found]${NC}"
        echo -e "${BLUE}   └── Automatically removed${NC}"
        echo -e ""
        DELETED_COUNT=$((DELETED_COUNT + 1))
    elif [ "$severity" == "CRITICAL" ]; then
        echo -e "${RED}⛔ CRITICAL threat: ${YELLOW}$desc${NC} ${GREEN}[$count found]${NC}"
        echo -e "${BLUE}   └── Detected and reported${NC}"
        echo -e ""
    fi
done

if [ $CRITICAL_COUNT -eq 0 ] && [ $DELETED_COUNT -eq 0 ]; then
    echo -e "${GREEN}✅ No threats detected!${NC}"
    echo -e ""
elif [ $DELETED_COUNT -gt 0 ]; then
    echo -e "${GREEN}✅ Successfully deleted $DELETED_COUNT Blum Panel backdoors${NC}"
    echo -e ""
fi

echo ""
echo -e "${BLUE}Full report saved to: ${YELLOW}$REPORT_FILE${NC}"
echo ""