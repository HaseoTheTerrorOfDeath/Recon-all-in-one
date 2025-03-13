# Recon Script

This script automates various information gathering steps to efficiently and effectively perform domain reconnaissance (recon). It integrates several popular security tools like `subfinder`, `amass`, `nmap`, `ffuf`, `sqlmap`, and others to perform subdomain discovery, port analysis, screenshot capturing, vulnerability identification, and more.

## Features

- **Subdomain Discovery**: Uses tools like `subfinder`, `assetfinder`, `amass`, and `sublist3r` to gather subdomains from a target domain.
- **Active Subdomain Check**: Uses `httpx` to check if the discovered subdomains are active.
- **Screenshot Capturing**: Captures screenshots of the active subdomain pages using `aquatone`.
- **Port Scanning**: Scans open ports on active subdomains using `masscan` and `nmap`.
- **Hidden Directory and File Discovery**: Performs directory and file fuzzing using `ffuf`.
- **Extracting Old URLs**: Uses `waybackurls` to gather old URLs from archived pages.
- **Vulnerability Testing**: Tests for XSS and SQL Injection vulnerabilities with `dalfox` and `sqlmap`, and identifies technologies and frameworks with `whatweb` and `wappalyzer`.
- **Known Vulnerability Testing**: Uses `nuclei` to check for specific vulnerabilities based on templates.

## Requirements

This script requires several tools to be installed. The script automatically checks if these tools are installed and attempts to install them if not. The tools include:

- `subfinder`
- `assetfinder`
- `amass`
- `httpx`
- `aquatone`
- `masscan`
- `nmap`
- `ffuf`
- `waybackurls`
- `gf`
- `dalfox`
- `sqlmap`
- `sublist3r`
- `whatweb`
- `wappalyzer`
- `nuclei`

## How to Use

1. Clone this repository:

   ```bash
   git clone https://github.com/user/recon-repository.git
   cd recon-repository
   
2. Make the script executable:
  
   ```bash
   chmod +x recon_script.sh
   
3. Run the script with a domain or a file containing domains:
  
   ```bash
   ./recon_script.sh <domain> or <file.txt>

4. Results will be saved in directories organized by target, under /root/recon/.

# Example Usage

   This will perform the full recon process for the domain example.com and save the results in the directory /root/recon/example.com/.
   
   ```bash
   ./recon_script.sh <domain> or <file.txt>
