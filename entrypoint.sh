#!/bin/sh

set -e

if [[ -z $GITHUB_BASE_REF ]]; then
  echo "Skipping: This should only run on pull_request.";
  exit 0;
fi

GITHUB_TOKEN=$1
CONFIG_PATH=$2
IGNORE_PATH=$3
TARGET_BRANCH=${GITHUB_BASE_REF}
CURRENT_BRANCH=${GITHUB_HEAD_REF}


echo "${GITHUB_TOKEN}"
echo "${CONFIG_PATH}"
echo "${IGNORE_PATH}"
echo "${TARGET_BRANCH}"
echo "${CURRENT_BRANCH}"
echo "${GITHUB_REPOSITORY}"
echo "----------------------"
echo $(git branch)

git remote set-url origin https://${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}

echo "Getting base branch..."
git config --local remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
git config --local --add remote.origin.fetch "+refs/tags/*:refs/tags/*"
# git fetch origin --tags

git fetch --depth=1 origin ${TARGET_BRANCH}:${TARGET_BRANCH}

echo "Getting changed files..."

echo "Getting head sha..."
HEAD_SHA=$(git rev-parse ${TARGET_BRANCH} || true)
echo ${HEAD_SHA}

echo "Getting diffs..."
FILES=$(git diff --diff-filter=ACM --name-only ${HEAD_SHA} || true)

if [[ ! -z ${FILES} ]]; then
  echo "Filtering files..."
  CHANGED_FILES=$(echo ${FILES} | grep -E ".(js|jsx|ts|tsx)$" || true)
  if [[ -z ${CHANGED_FILES} ]]; then
    echo "Skipping: No files to lint"
    exit 0;
  else
    echo "Running ESLint..."
    if [[ ! -z ${IGNORE_PATH} ]]; then
      eslint --config=${CONFIG_PATH} --ignore-path ${IGNORE_PATH} --max-warnings=0 $(CHANGED_FILES)
    else
      eslint --config=${CONFIG_PATH} --max-warnings=0 $(CHANGED_FILES)
    fi
  fi
fi
