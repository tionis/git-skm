# Simple Git Signatures
SGS helps you sign your commits without relying on knowledge outside of the git repo itself.  
For this an allowed_signers file containing the signing (ssh) keys and their validity period is managed in the git repo itself.  
As this file is only valid when all commits modifying it where signed with an at the time valid key this key registry can be trusted.  

## Rough Outline of Algorithm
1. Look up the last trusted commit hash
2. Look up what commit last modified .allowed_signers
3. If the commit hash of the previous step matched the trusted commit hash the .allowed_signers file can be trusted, if not continue
4. Walk back the previous commits modfying the file until you find one that is trusted (if none is found at the top most commit, throw an error or trust it on first use if the config allows as such)
5. Verify each walked commit and mark it as trusted in reverse order, if any verification fails, throw an error

## Problems
This signing scheme is vulnerable to some git history rewrite attacks as well as forged git commit dates when a key was compromised and revoked.

## Example
As an example this repo has some signed commits managed by itself. The first trusted anchor commit in this repo is `0b89545db211f2197bf6448139497b14748859b2`. Please note that the commit hash is just listed here for demonstration purposes. Normally the trust anchor should be delivered over a verified and trusted independant channel as the README.md could be freely manipulated by an attacker.
