#!/bin/bash
#
# requires:
#  bash
#
set -e
set -o pipefail
#set -x

. ./config
. ./functions

function result_issue_close() {
  local assignee=$1 title_pattern=$2
  local issue_number

  issue_number=$(get_issue_number ${assignee} "open" ${title_pattern})
  if [ -z "${issue_number}" ]; then
    echo "Not found issue: ${assignee} ${title_pattern}"
    return
  fi

  curl \
    -i \
    -X PATCH \
    -H "Authorization: token ${GITHUB_TOKEN}"  \
    --data @- \
    ${BASE_URI}/repos/${OWNER}/${REPO}/issues/${issue_number} <<-EOS
	{
	"state": "closed"
	}
	EOS
}

function result_issue_close_debug() {
  local assignee=$1 title_pattern=$2
  local issue_number

  issue_number=$(get_issue_number ${assignee} "open" ${title_pattern})
  if [ -z "${issue_number}" ]; then
    echo "Not found issue: ${assignee} ${title_pattern}"
    return
  fi

echo ${assignee}
echo  curl \
    -i \
    -X PATCH \
    -H "Authorization: token ${GITHUB_TOKEN}"  \
    --data @- \
    ${BASE_URI}/repos/${OWNER}/${REPO}/issues/${issue_number} <<-EOS
	{
	"state": "closed"
	}
	EOS
}

function u_days_fmt() {
  local days=${1}
  date -d "${days} days" +'%m\/%d\(%a\)'
}

function get_title_pattern() {
  local begin_date=${1} end_date=${2}
  echo "$(u_days_fmt ${begin_date})"\.\."$(u_days_fmt ${end_date})"
}


### Main ###
# arguments checking
# milestone checking
if [ $# -ne 1 ] && [ $# -ne 4 ] ; then
    echo "Error: Few or more arguments."
    echo "Usage: $0 GITHUB_TOKEN [OWNER REPO MILESTONE_NAME]"
    exit 1
fi

GITHUB_TOKEN=$1

OWNER=${2:-$OWNER}
if [ -z "$OWNER" ]; then
    echo "Error: No owner was set."
    echo "Usage: $0 GITHUB_TOKEN [OWNER REPO MILESTONE_NAME]"
    exit 1
fi
REPO=${3:-$REPO}
if [ -z "$REPO" ]; then
    echo "Error: No repo was set."
    echo "Usage: $0 GITHUB_TOKEN [OWNER REPO MILESTONE_NAME]"
    exit 1
fi
MILESTONE_NAME=${4:-$MILESTONE_NAME}
if [ -z "$MILESTONE_NAME" ]; then
    echo "Error: No milestone name was set."
    echo "Usage: $0 GITHUB_TOKEN [OWNER REPO MILESTONE_NAME]"
    exit 1
fi

MILESTONE_NUMBER=$(get_milestone_number "${MILESTONE_NAME}")
if [ -z "$MILESTONE_NUMBER" ]; then
    echo "Error: No milestone was found (${MILESTONE_NAME})."
    echo "Usage: $0 GITHUB_TOKEN [OWNER REPO MILESTONE_NAME]"
    exit 1
fi

# days params
cur_u=$(date +%u) # 1..7
mon_u="$((-6 - ${cur_u}))"
fri_u="$((${mon_u} + 4))"

# result issue cration
title_pattern=$(get_title_pattern ${mon_u} ${fri_u})
echo $DEBUG
for m in ${MEMBERS}
do
  if [ "$DEBUG" = "true" ]; then
    result_issue_close_debug ${m} ${title_pattern}
  else
    result_issue_close ${m} ${title_pattern}
  fi
done
