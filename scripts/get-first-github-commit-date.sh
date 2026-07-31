#!/usr/bin/env bash

# Adapted from: https://stackoverflow.com/a/76264351

if [[ -n $1 ]]; then
  REPO="$1"
else
  read -rp "Repository (owner/repo): " REPO
fi

if [[ ${REPO// /} == "" ]]; then
  echo "No repository provided."
  exit 1
fi

if [[ ! $REPO =~ ^[^/]+/[^/]+$ ]]; then
  echo "Invalid repository format. Expected: owner/repo"
  exit 1
fi

URL="https://api.github.com/repos/$REPO/commits"
H=" -H \"Accept: application/vnd.github+json\" \
  -H \"X-GitHub-Api-Version: 2022-11-28\""

response=$(curl -s -L --include "$H" "$URL" | awk 'NR > 1')

# Split the output into header and json
header=$(echo "$response" | awk 'BEGIN{RS="\r\n";ORS="\r\n"} /^[a-zA-Z0-9-]+:/')
commits=$(echo "$response" | awk '!/^[a-zA-Z0-9-]+:/')

# If paginated, get last page
if [[ $header == *"link"* ]]; then
  # Extract the last page value
  link_line=$(echo "$header" | grep -i "^link:")
  last_page=$(echo "$link_line" | sed -n 's/.*page=\([0-9]\+\)[^0-9].*rel="last".*/\1/p')

  # Get last-page commits
  commits=$(curl -s -L "$H" "$URL?page=$last_page")
fi

# Print first commit
commit_date="$(echo "$commits" | jq --raw-output '.[-1].commit.author.date')"
echo "${commit_date%T*}"
