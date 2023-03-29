(:import ./util :export true)

(defn verify-one-commit
  "verify a commit using the allowed_signers files from it's parent trees"
  [commit]
  # Verify a commit using the allowed_signers from its parent
  )

(defn verify-commit
  "verify commit while ensuring an up-to-date allowed_signers file is used"
  [commit])

(defn generate-allowed-signers
  "generate the allowed_signers file using a previously set trust anchor"
  [repo]
  )

(defn trust
  "set trust anchor"
  [repo commit])
