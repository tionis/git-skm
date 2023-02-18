(declare-project
  :name "git-skm"
  :description "git simple key management - manages ssh keys for git repos"
  :dependencies ["https://github.com/janet-lang/spork"]
  :author "tionis.dev"
  :license "MIT"
  :url "https://tasadar.net/tionis/git-skm"
  :repo "git+https://tasadar.net/tionis/git-skm")

(declare-source
  :source ["git-skm"])

(declare-executable
  :name "git-skm"
  :entry "git-skm/cli.janet"
  :install true)
