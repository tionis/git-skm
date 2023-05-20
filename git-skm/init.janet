(import ./parser :export true)
(import ./util :export true)
(import spork/sh)
(import spork/path)

(defn git/loud [repo & args] (sh/exec "git" "-C" repo ;args))
(defn git/fail [repo & args] (sh/exec-fail "git" "-C" repo ;args))
(defn git/slurp [repo & args] (sh/exec-slurp "git" "-C" repo ;args))
(defn git/slurp-all [repo & args] (sh/exec-slurp-all "git" "-C" repo ;args))

(defn trust
  "set trust anchor"
  [repo commit]
  (if commit
    (git/fail repo "config" "skm.last-verified-commit" commit)
    (git/fail repo "config" "skm.last-verified-commit")))

(defn get-tmp-dir [] # TODO replace this horrible hack
  (def p (path/join "/tmp" (string/format "%j" (math/floor (* 10000000 (math/random) (os/clock))))))
  (os/mkdir p)
  p)

(defn ssh-verify [data signature allowed-signers &named namespace]
  (default namespace "git")
  (def tmp-dir (get-tmp-dir))
  (def allowed-signers-file (path/join tmp-dir "allowed_signers"))
  (spit allowed-signers-file allowed-signers)
  (def signature-file (path/join tmp-dir "commit.sig"))
  (spit signature-file signature) # TODO hotfix
  (spit (path/join tmp-dir "commit") data)
  (def principal
    (sh/exec-slurp "ssh-keygen" "-Y" "find-principals" "-s" signature-file "-f" allowed-signers-file))
  (def proc (os/spawn ["ssh-keygen"
                       "-Y" "verify"
                       "-f" allowed-signers-file
                       "-n" namespace
                       "-s" signature-file
                       "-I" principal] :p {:in :pipe}))
  (ev/write (proc :in) data)
  (ev/close (proc :in))
  (os/proc-wait proc)
  (if (not= (proc :return-code) 0)
    (error "could not verify commit signature"))
  true)

(defn verify-one-commit
  "verify a commit using the allowed_signers files from it's parent trees"
  [repo commit]
  (def allowed_signers (git/slurp repo "show" (string commit "^:" (util/get-allowed-signers-relative-path)))) # TODO use real plumbing command
  (def parsed-commit (parser/parse-commit (git/slurp repo "cat-file" "-p" commit)))
  (def commit-without-sig (parser/render-commit (put (struct/to-table parsed-commit) :gpgsig nil)))
  (if (not (parsed-commit :gpgsig)) (error "commit not signed"))
  (ssh-verify commit-without-sig (parsed-commit :gpgsig) allowed_signers))

(defn check-allowed-signers
  [repo]
  (def allowed-signers-absolute-path (util/get-allowed-signers-absolute-path repo))
  # TODO throw error if allowed_signers is outside git repo
  # also check that file exists
  (assert (= allowed-signers-absolute-path (path/abspath (util/get-allowed-signers-relative-path)))))

(defn generate-allowed-signers
  "generate the allowed_signers file using a previously set trust anchor"
  [repo commit]
  (def allowed-signers-absolute-path (util/get-allowed-signers-absolute-path repo))
  (var last-verified-commit (git/slurp repo "config" "skm.last-verified-commit"))
  (set last-verified-commit "92ed36577684f7ec5b65a08166445a90d9ad6ffd") # TODO remove this, just for testing
  (if (or (not last-verified-commit) (= last-verified-commit "")) (error "No last verified commit set"))
  (def all_commits (string/split "\n" (git/slurp repo "log" "--pretty=format:%H" (util/get-allowed-signers-relative-path repo))))
  (def commits-to-verify @[])
  (var found_commit false)
  (each commit all_commits
    (when (= commit last-verified-commit)
      (set found_commit true)
      (break))
    (array/push commits-to-verify commit))
  (unless found_commit (error "could not find last-verified-commit in current history"))
  (each commit (reverse commits-to-verify)
    (verify-one-commit repo commit)
    (set last-verified-commit commit))
  (trust repo last-verified-commit)
  (def allowed-signers-cache-file (path/join (util/get-git-dir repo) "allowed_signers"))
  (pp allowed-signers-absolute-path)
  (pp allowed-signers-cache-file)
  (sh/copy-file allowed-signers-absolute-path allowed-signers-cache-file)
  (git/fail repo "config" "gpg.ssh.allowedSignersFile" allowed-signers-cache-file)
  (print "allowed_signers was verified and copied into git_dir"))

(defn verify-commit
  [repo commit]
  (def allowed-signers-cache-file (path/join (util/get-git-dir repo) "allowed_signers"))
  (unless (deep= (slurp allowed-signers-cache-file) (slurp (util/get-allowed-signers-absolute-path repo)))
    (generate-allowed-signers repo (git/slurp repo "rev-parse" commit)))
  (git/loud repo "verify-commit" commit))
