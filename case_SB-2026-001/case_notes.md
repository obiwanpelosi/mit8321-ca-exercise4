# Investigation logbook: Case SB-2026-001

- Investigator: Feyi Abioye
- Course: MIT8321 Forensics and Ethical Hacking, CA Lab Exercise 4
- System examined: VM securebank-lab (securebank-lab), SecureBank Cyber Fortress containers
- Lab source: github.com/frederickottache-sketch/secure-cyber-fortress (commit 03870ad)
- Time zone used: UTC

## Scope
Evidence collection and preservation only, on the isolated securebank-lab VM
and its six Docker containers. No real, public or third-party system is touched.

## Log (UTC time | action | result)
2026-11-01T13:15:46Z | Case opened, case folder created | OK
2026-11-01T14:16:44Z | Fetched SecureBank login page with curl from inside the VM (S06) | HTTP 200, login form shown
2026-11-01T14:16:44Z | Login as jane with wrong password (attempt 1 of 3), curl POST /login | Login failed. Try again
2026-11-01T14:16:46Z | Login as jane with wrong password (attempt 2 of 3), curl POST /login | Login failed. Try again
2026-11-01T14:16:48Z | Login as jane with wrong password (attempt 3 of 3), curl POST /login | Login failed. Try again
2026-11-01T14:16:50Z | Login as jane with correct password from db_init.sql | Welcome jane! View Accounts
2026-11-01T14:16:56Z | Login as john (password from db_init.sql), session cookie kept | Welcome john! View Accounts
2026-11-01T14:16:58Z | Opened /accounts as john | HTTP 200, accounts page shown
2026-11-01T14:17:00Z | Signed out john by discarding session cookie (app has no logout route) | Session ended client-side
2026-11-01T14:17:10Z | Note: /accounts was requested twice at 14:16:58Z (status check + page display), so two ACCOUNT_VIEW lines for john are expected | Clarification
2026-11-01T14:17:10Z | Started lecturer Phase 1 script: docker exec kali-attacker bash /scripts/attack.sh (targets securebank-app only) | Running
2026-11-01T14:17:28Z | Finished lecturer Phase 1 script (exit code 0) | See securebank.log and evidence/attack_timeline.txt
2026-11-01T14:18:00Z | Checked app log with tail (S07): LOGIN_FAILED x3 then LOGIN_SUCCESS for jane, john LOGIN_SUCCESS + ACCOUNT_VIEW, attack events from 172.18.0.7 | OK
2026-11-01T14:18:16Z | Saved collect_evidence.sh from GUIDE.md Step 4 unchanged (SHA-256 5d3ccf3b...1e03) | OK
2026-11-01T14:20:37Z | Ran collect_evidence.sh (S08): 24 items collected, hashed, registered, sealed read-only and archived | OK
2026-11-01T14:21:42Z | Reviewed case folder, evidence register, hashes.txt and chain of custody (S09a-S09d) | 24 items, all evidence files read-only
2026-11-01T14:21:56Z | Hashes verified, write-protection and tamper test done | All OK
2026-11-01T14:21:56Z | Note: tamper test needed chmod u+w on the /tmp working copy only (cp keeps the read-only mode); original evidence untouched, hash 81f65a71...d34cc unchanged (S10) | Deviation recorded
2026-11-01T14:38:30Z | Case package transferred to Mac and re-verified (S11): package SHA-256 f43cef12...195ecf matched in VM and on Mac | All OK
