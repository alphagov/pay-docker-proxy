#!/usr/bin/env ash
set -euo pipefail

echo 'Doing auth'

ECR_URL="${ECR_URL:-}"
ECR_TOKEN="${ECR_TOKEN:-}"

AUTOMATED_AUTH="false"

if [ -z "${ECR_URL}" ] || [ -z "${ECR_TOKEN}" ]; then
  AUTOMATED_AUTH="true"
fi

if [ "${AUTOMATED_AUTH}" = "true" ]; then
  # Set up auth
  aws_output="$(aws ecr get-login --no-include-email --region eu-west-1)"

  ECR_URL="$(echo "$aws_output" | awk '{print $7}')"

  # ECR token is base64(AWS:aws-output)
  # - We get the token (from previously)
  # - Prepend AWS (the "username" and separate by a colon)
  # - Base64 encode
  ecr_basic_auth="$(echo "$aws_output" | awk '{print $6}')"
  ecr_basic_auth="$(echo "AWS:$ecr_basic_auth" | base64 | tr -d '[:space:]')"
  ECR_TOKEN="$ecr_basic_auth"
fi

export ECR_URL ECR_TOKEN
# shellcheck disable=SC2016
envsubst '$ECR_URL $ECR_TOKEN' < /app/nginx.conf.tpl > /app/nginx.conf

if [ "${AUTOMATED_AUTH}" = "true" ]; then
  echo "Requeued do_auth asynchronously with a sleep of 3600"
  ash -c 'sleep 3600; /app/do_auth.sh' &
fi

pgrep nginx && \
  echo 'Reloading nginx' && \
  nginx -c /app/nginx.conf -s reload

echo 'Done auth'
