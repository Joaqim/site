#!/usr/bin/env bash

# Adapted from https://gitlab.com/mplanchard/mplanchard.gitlab.io/-/blob/master/Makefile?ref_type=heads#L63

read -rp "Post Title: " TITLE
if [[ ${TITLE// /} == "" ]]; then
  echo -e "No title provided."
  exit 1
fi
SLUG=$(echo -n "$TITLE" |
  sed --regexp-extended 's/[  ]+/-/g' |
  sed 's/[(),.!:]//g' |
  awk '{ printf tolower($0) }' |
  jq --slurp --raw-input --raw-output '@uri') # urlencode
DATE=$(date --iso-8601)
FNAME="${DATE}-${SLUG}.md"
FPATH="posts/${FNAME}"
if [[ -e $FPATH ]]; then
  echo "$FPATH" already exists!
  exit 1
fi
{
  echo "---"
  echo "draft: true"
  echo "title: $TITLE"
  echo "slug: $SLUG"
  echo "created: $DATE"
  echo "updated: $DATE"
  echo "tags:"
  echo "summary:"
  echo "---"
} >>"$FPATH"
echo "Created new post in $FPATH"
