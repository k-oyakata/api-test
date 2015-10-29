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

function result_issue_new() {
  local mon_u=$1 fri_u=$2 assignee=$3
  local title body

  title="作業実績 (${assignee}): "$(date_range "${mon_u}" "${fri_u}")
  body=$(build_body ${mon_u} ${fri_u})

  curl \
   -i \
   -X POST \
   -H "Authorization: token ${GITHUB_TOKEN}"  \
   --data @- \
   ${BASE_URI}/repos/${OWNER}/${REPO}/issues <<-EOS
	{
	"title": "${title}",
	"body": "${body}",
	"assignee": "${assignee}",
	"milestone": "${MILESTONE_NUMBER}"
	}
	EOS
}

function result_issue_new_debug() {
  local mon_u=$1 fri_u=$2 assignee=$3
  local title body

  title="作業実績 (${assignee}): "$(date_range "${mon_u}" "${fri_u}")
  body=$(build_body ${mon_u} ${fri_u})

  cat <<-EOS
	${BASE_URI}/repos/${OWNER}/${REPO}/issues <<-EOS
	{
	"title": "${title}",
	"body": "${body}",
	"assignee": "${assignee}",
	"milestone": "${MILESTONE_NUMBER}"
	}
	EOS
}

function u_days_fmt() {
  local days=${1}
  date -d "${days} days" +'%m/%d(%a)'
}

function date_range() {
  local begin_date=${1} end_date=${2}
  echo "$(u_days_fmt ${begin_date})".."$(u_days_fmt ${end_date})"
}

function build_body() {
  local mon_u=$1 fri_u=$2
  local body
  
  body="#### The plan for this week"
  for ((d=${mon_u}; d <= ${fri_u}; d++))
  do
    body="${body}\n#### $(u_days_fmt $d)\n"
  done
  echo ${body}
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
if [ "$WEEK" = "this" ]; then
  mon_u="$((1 - ${cur_u}))"
else
  mon_u="$((8 - ${cur_u}))"
fi
fri_u="$((${mon_u} + 4))"

# result issue cration
for m in ${MEMBERS}
do
  if [ "$DEBUG" = "true" ]; then
    result_issue_new_debug ${mon_u} ${fri_u} ${m}
  else
    echo new
    #result_issue_new ${mon_u} ${fri_u} ${m}
  fi
  break
done
