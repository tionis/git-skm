(import spork/sh)
(import spork/path)

(defn get-git-dir [&opt repo]
  (default repo (os/cwd))
  (def opts @[])
  (if repo (array/concat opts ["-C" repo]))
  (if (dyn :git-dir)
    (dyn :git-dir)
    (let [git-dir (path/join repo (sh/exec-slurp "git" ;opts "rev-parse" "--git-dir"))]
      (setdyn :git-dir git-dir)
      git-dir)))

(defn get-repo-top-level [&opt repo]
  (default repo (os/cwd))
  (def opts @[])
  (if repo (array/concat opts ["-C" repo]))
  (if (dyn :repo-top-level)
    (dyn :repo-top-level)
    (let [repo-top-level (sh/exec-slurp "git" ;opts "rev-parse" "--show-toplevel")]
      (setdyn :repo-top-level repo-top-level)
      repo-top-level)))

(defn get-allowed-signers-absolute-path [&opt repo]
  (default repo (os/cwd))
  (def opts @[])
  (if repo (array/concat opts ["-C" repo]))
  (if (dyn :allowed-signers-absolute-path)
    (dyn :allowed-signers-absolute-path)
    (try
      (let [allowed-signers-absolute-path (sh/exec-slurp "git" ;opts "config" "--local" "skm.allowedSignersFile")]
        (let [stat (os/stat allowed-signers-absolute-path)]
          (if (or (not stat) (not= (stat :mode) :file))
            (error "allowedSignersFile does not exist or is not a file")))
        (setdyn :allowed-signers-absolute-path allowed-signers-absolute-path))
      ([err]
       (do
          (setdyn :allowed-signers-absolute-path (path/join (get-repo-top-level) ".allowed_signers"))
          (sh/exec-slurp "git" ;opts "config" "--local" "skm.allowedSignersFile" (dyn :allowed-signers-absolute-path)))))))

(defn get-allowed-signers-relative-path [&opt repo]
  (default repo (os/cwd))
  (if (dyn :allowed-signers-relative-path)
    (dyn :allowed-signers-relative-path)
    (path/relpath (get-repo-top-level repo) (get-allowed-signers-absolute-path repo))))
