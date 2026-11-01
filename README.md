# MIT8321 CA: Lab Exercise 4, Evidence Collection and Preservation

Case SB-2026-001, SecureBank Cyber Fortress lab. Investigator: Feyi Abioye.

- `case_SB-2026-001/scripts/collect_evidence.sh`: collection, hashing, register and custody script
- `case_SB-2026-001/evidence/`: collected evidence (read-only, SHA-256 in `hashes.txt`)
- `case_SB-2026-001/evidence_register.csv` and `chain_of_custody.csv`
- `screenshots/`: S01 to S12, referenced in the report
- `report/`: final PDF report

Verify the evidence: `cd case_SB-2026-001/evidence && shasum -a 256 -c ../hashes.txt`

Lab source: github.com/frederickottache-sketch/secure-cyber-fortress (commit 03870ad).
All testing was confined to an isolated local VM.
