# 🦴 BITHOG — Bitbucket Secret Leak Scanner 🔐

Automated, stealthy, and efficient secret scanner for Bitbucket workspaces — powered by OAuth + TruffleHog.


⸻

⚡ Overview

BITHOG is a lightweight Bitbucket secret scanner designed for red-teamers, DevSecOps, and bug-bounty researchers.
It uses Bitbucket OAuth authentication and TruffleHog’s verification engine to discover exposed credentials, API keys, and tokens across your entire workspace — and outputs a clean, readable text report.

No unnecessary logs. No false noise. Just verified secrets 🕵️‍♂️.

⸻

🧩 Features

	•	🔑 OAuth-based authentication — no app passwords required.
  
	•	🧠 Automatic repository enumeration — scans all repos in your workspace.
  
	•	🧹 Cleans TruffleHog noise — only verified findings are shown.
  
	•	📄 Plain-text reports — easy to share and archive.
  
	•	💻 macOS-compatible — works perfectly on Bash 3.2+ (default macOS shell).
  
	•	🛡️ Read-only scanning — safe for production environments.

⸻

🧰 Requirements

	•	bash (≥ 3.2 — built into macOS)
  
	•	trufflehog
  
	•	jq
  
	•	curl

Install prerequisites on macOS:
```
brew install jq
brew install trufflesecurity/trufflehog/trufflehog
```

⸻

🚀 Usage
```
chmod +x bithog.sh
./bithog.sh
```
When prompted:

	1.	Enter your Bitbucket workspace (e.g., secasure or kullaisec).
  
	2.	The script will authenticate using the built-in OAuth keys.
  
	3.	It automatically scans all repos and saves results under:

bitbucket_scan_<workspace>_<timestamp>/


⸻

📊 Example Output
```
========== [Repository: api-service] ==========
✅ Found verified result 🐷🔑
Detector Type: AWS
Decoder Type: PLAIN
Raw result: AKIA...
File: src/config/aws_keys.py
Line: 12

==================== Scan Summary ====================
Total Repositories Scanned: 5
api-service : 1 findings
web-frontend : 0 findings
-------------------------------------------------------
Scan completed at: Tue Oct 7 11:24:52 IST 2025

```
⸻

🧠 How It Works

1.	Uses Bitbucket OAuth client credentials to obtain an access token. refer: https://id.atlassian.com/manage-profile/security/api-tokens
   
2.	Calls the Bitbucket REST API to list all repositories.
   
3.	Runs TruffleHog on each repo via HTTPS (token-based auth).
   
4.	Filters noisy logs and aggregates verified secrets into a text report.

⸻

🔒 Security Notes

	•	Keep your CLIENT_ID and CLIENT_SECRET private.
	•	Revoke or rotate OAuth credentials regularly.
	•	BITHOG only performs read-only operations — safe for internal and cloud environments.
	•	Always review findings manually before disclosure or remediation.

⸻

👨‍💻 About the Author

Developed by Kullai Metikala 
Focused on building automation frameworks for secret scanning, recon, and security testing.

📫 Contact: metikalakullai.gtl@gmail.com

⸻

🧾 License

Released under the MIT License.
You are free to use, modify, and distribute this project with attribution.
