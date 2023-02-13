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
