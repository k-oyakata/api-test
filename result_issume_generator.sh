#!/bin/bash
#
# requires:
#  bash
#
set -e
set -o pipefail
#set -x

LANG=C

BASE_URI=https://api.github.com
MILESTONE_NAME='Daily work results'
OWNER=k-oyakata
REPO=result_issue_generator
MEMBERS="
k-oyakata
hansode
unakatsuo
t-iwano
akry
Metallion
triggers
"

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
  # http://developer.github.com/v3/issues/#create-an-issue
  local mon_u=$1 fri_u=$2 assignee=$3
  local title body

  title="作業実績 (${assignee}): "$(date_range "${mon_u}" "${fri_u}")
  body=$(build_body ${mon_u} ${fri_u})

  cat <<-EOS
	{
	"title": "${title}",
	"body": "${body}",
	"assignee": "${assignee}",
	"milestone": "${MILESTONE_NUMBER}"
	}
	EOS
}

function get_milestone_number() {
  local title=$1
  curl \
    -s \
    -H "Authorization: token ${GITHUB_TOKEN}" \
    ${BASE_URI}/repos/${OWNER}/${REPO}/milestones \
  | awk '/"number":/{num=$2};/"title":/ && /'"${title}"'/{printf("%d", num)}'
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
if [ $# -ne 2 ]; then
    echo "Error: Few or more arguments."
    echo "Usage: $0 GITHUB_TOKEN MILESTONE_NAME"
    exit 1
fi

GITHUB_TOKEN=$1
MILESTONE_NAME=${2:-$MILESTONE_NAME}
if [ -z "$MILESTONE_NAME" ]; then
    echo "Error: No milestone name was set."
    echo "Usage: $0 GITHUB_TOKEN MILESTONE_NAME"
    exit 1
fi

MILESTONE_NUMBER=$(get_milestone_number "${MILESTONE_NAME}")
if [ -z "$MILESTONE_NUMBER" ]; then
    echo "Error: No milestone was found (${MILESTONE_NAME})."
    exit 1
fi

# days params
cur_u=$(date +%u) # 1..7
mon_u="$((8 - ${cur_u}))"
fri_u="$((${mon_u} + 4))"

# result issue cration
for m in ${MEMBERS}
do
  result_issue_new ${mon_u} ${fri_u} ${m}
done
