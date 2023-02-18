(import spork/sh)
(import spork/path)

(defn get-repo-root []
  (if (dyn :repo-root)
    (dyn :repo-root)
    (let [repo-root (sh/exec-slurp "git" "rev-parse" "--git-dir")]
      (setdyn :repo-root repo-root)
      repo-root)))

(defn get-repo-top-level []
  (if (dyn :repo-top-level)
    (dyn :repo-top-level)
    (let [repo-top-level (sh/exec-slurp "git" "rev-parse" "--show-toplevel")]
      (setdyn :repo-top-level repo-top-level)
      repo-top-level)))

(defn get-allowed-signers-absolute-path []
  (if (dyn :allowed-signers-absolute-path)
    (dyn :allowed-signers-absolute-path)
    (try
      (let [allowed-signers-absolute-path (sh/exec-slurp "git" "config" "--local" "skm.allowedSignersFile")]
        (let [stat (os/stat allowed-signers-absolute-path)]
          (if (or (not stat) (not= (stat :mode) :file))
            (error "allowedSignersFile does not exist or is not a file")))
        (setdyn :allowed-signers-absolute-path allowed-signers-absolute-path))
      ([err]
       (do
          (setdyn :allowed-signers-absolute-path (path/join (get-repo-top-level) ".allowed_signers"))
          (sh/exec-slurp "git" "config" "--local" "skm.allowedSignersFile" (dyn :allowed-signers-absolute-path)))))))

(defn get-allowed-signers-relative-path []
  (if (dyn :allowed-signers-relative-path)
    (dyn :allowed-signers-relative-path)
    (path/relpath (get-repo-top-level) (get-allowed-signers-absolute-path))))
