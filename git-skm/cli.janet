#!/bin/env janet
(use ./init)

(defn cli/trust [args]
  (setdyn :repo-path (os/cwd))
  (if (first args)
    (trust (first args))
    (error "no commit hash to trust given")))

(defn cli/generate-allowed-signers [args]
  (setdyn :repo-path (os/cwd))
  (generate-allowed-signers "HEAD"))

(defn cli/verify-commit [args]
  (setdyn :repo-path (os/cwd))
  (if (first args)
    (verify-commit (first args))
    (verify-commit "HEAD")))

(defn cli/help []
  (print `simple key management
         available subcommands:
           help - show this help
           generate - generate the allowed_signers file
           verify-commit - verify a specific commit (or HEAD if no commit ref was given)
           trust - set trust anchor (this is the last commit hash that you trust)`))

(defn main [_ & args]
  (case (first args)
    "help" (cli/help)
    "verify-commit" (cli/verify-commit (slice args 1 -1))
    "generate" (cli/generate-allowed-signers (slice args 1 -1))
    "trust" (cli/trust (slice args 1 -1))
    (cli/help)))
