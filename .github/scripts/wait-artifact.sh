#!/usr/bin/env bash
id="$1"
seen=0
for _ in $(seq 1 60); do
  if gh api "repos/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID/artifacts?per_page=100" \
    --paginate --jq '.artifacts[].id' 2>/dev/null | grep -qx "$id"; then
    seen=$((seen + 1))
    if [ "$seen" -ge 3 ]; then
      echo "Artifact $id is listed"
      exit 0
    fi
  else
    seen=0
  fi
  sleep 2
done
echo "::warning::Artifact $id is still not listed, continuing"
exit 0
