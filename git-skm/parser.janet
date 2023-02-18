(def commit-grammar (peg/compile
  ~{:main (replace (* "tree " (capture :object-id) "\n"
                      :parents
                      "author " :person "\n"
                      "committer " :person "\n"
                      (opt (* (capture :gpgsig)))
                      "\n"
                      (capture (to -1)))
                    ,(fn [& args]
                       (if (= (length args) 6)
                         {:tree (args 0) :parents (args 1) :author (args 2) :committer (args 3) :gpgsig (args 4) :message (args 5)}
                         {:tree (args 0) :parents (args 1) :author (args 2) :committer (args 3) :message (args 4)})))
    :parents (replace (any (* "parent " (capture :object-id) "\n"))
                      ,(fn [& x] x))
    :object-id (repeat 40 :w)
    :person (replace (* (capture (to (* " " :email))) " " :email " " :timestamp)
                     ,|{:name $0 :email $1 :timestamp $2})
    :email (* "<" (* (capture (any (* (not ">") 1))) ">"))
    :timestamp (replace (* (capture :unix-time) " " (capture :offset))
                        ,|{:time $0 :offset $1})
    :unix-time (repeat 10 :d)
    :offset (* (+ "+" "-") (repeat 4 :d))
    :gpgsig (+ (* "gpgsig -----BEGIN SSH SIGNATURE-----" (thru "-----END SSH SIGNATURE-----\n"))
               (* "gpgsig -----BEGIN PGP SIGNATURE-----" (thru "-----END PGP SIGNATURE-----\n \n")))
    }))

(defn parse-commit [commit]
  (peg/match commit-grammar commit))

(defn render-commit [parsed-commit])
