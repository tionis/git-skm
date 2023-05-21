#!/bin/env janet
(use ./init)

(def zero-commit "0000000000000000000000000000000000000000")

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

(defn cli/hooks/pre-receive [args]
  (def excludeExisting ["--not" "--all"])
  (forever
    (def input (string/trimr (file/read :line stdin)))
    (if (= input "") (break))
    (def [oldrev newrev refname] (string/split " " input))
    (printf "%s %s %s" oldrev newrev refname)
    (when (not= newrev zero-commit)
      (def span "")
      (if (= oldrev zero-commit)
        (set span (string/split "\n" (sh/exec-slurp "git" "rev-list" newrev ;excludeExisting)))
        (set span (string/split "\n" (sh/exec-slurp "git" "rev-list" (string oldrev ".." newrev) ;excludeExisting))))
      (each commit span
        (try
          (os/execute ["git" "verify-commit" commit] :px) # TODO this does not update allowed_signers yet
          ([err] (error (string "could not verify signature of commit "
                                commit " due to: " err
                                "\nrejecting push"))))))))

(defn cli/hooks [args]
  (def hook-type (first args))
  (case hook-type
    "pre-receive" (cli/hooks/pre-receive (slice args 1 -1))
    (error "unknown hook-type")))

(defn cli/help []
  (print `simple key management
         available subcommands:
           help - show this help
           generate - generate the allowed_signers file
           verify-commit - verify a specific commit (or HEAD if no commit ref was given)
           hook pre-receive - git hook handling (use in pre-receive hook via git-skm hook pre-receive "$@")
           trust - set trust anchor (this is the last commit hash that you trust)`))

(defn main [_ & args]
  (case (first args)
    "help" (cli/help)
    "verify-commit" (cli/verify-commit (slice args 1 -1))
    "generate" (cli/generate-allowed-signers (slice args 1 -1))
    "hook" (cli/hook (slice args 1 -1))
    "trust" (cli/trust (slice args 1 -1))
    (cli/help)))
