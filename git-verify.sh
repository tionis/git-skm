#!/bin/bash
die(){
  echo "$1" >&2
  if test -z "$2"; then
    exit 1
  else
    exit "$2"
  fi
}

verify-commit(){
  commit="$1"
  # TODO look up allowed_signers in parent of commit
  # TODO verify commit using the looked up allowed_signers file
}

# Abort if there is no .allowed_signers to check against
if ! test -f ".allowed_signers"; then
  die "No .allowed_signers found!"
fi

# Get last_verified_commit as trust anchor
last_verified_commit="$(git config verify.last_verified_commit)"
if test -z "$last_verified_commit"; then
  die "No last verified commit set, please set it as the root of trust using 'git config verify.last_verified_commit \$COMMIT_HASH'"
fi

# Build array of commits to verify
all_commits="$(git log --pretty=format:%H .allowed_signers)"
commits_to_verify=()
for commit in $all_commits; do
  if ! test "$commit" = "$last_verified_commit"; then
    commits_to_verify+=("$commit")
  else
    found_commit="true"
    break
  fi
done
if ! test "$found_commit" = "true"; then
  die "Could not find last_verified_commit, please ensure it exists in the current history"
fi

# Verify all commits in reverse iterativly
min=0
max=$(( ${#commits_to_verify[@]} -1 ))
while test $min -le $max; do
  commit="${commits_to
