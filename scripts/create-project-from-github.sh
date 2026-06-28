#!/usr/bin/env bash

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

read -rp "Project Title: " TITLE
if [[ ${TITLE// /} == "" ]]; then
  echo -e "No title provided."
  exit 1
fi

REPO_ID="${REPO#*/}"
FNAME="$REPO_ID.md"
FPATH="projects/${FNAME}"
if [[ -e $FPATH ]]; then
  echo "$FPATH" already exists!
  exit 1
fi
CREATION_DATE="$(get-first-github-commit-date "$REPO")"
{
  echo "---"
  echo "title: $TITLE"
  echo "id: $REPO_ID"
  echo "repository: https://github.com/$REPO"
  echo "license: "
  echo "created: $CREATION_DATE"
  echo "status: "
  echo "---"
} >>"$FPATH"
echo "Created new project in $FPATH"
