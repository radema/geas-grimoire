#!/usr/bin/env bash
# state.sh — read/update the ticket-loop state file (single source of truth across turns).
# State lives at <repo-root>/.claude/ticket-loop/<story>.json ; requires jq.
# Usage:
#   state.sh init <story> <branch> <base> <review_effort> [max_parallel=3]
#   state.sh add-ticket <story> <ticket> <deps-comma-separated|-> <complexity XS|S|M|L>
#   state.sh build-trails <story>        # group tickets into dependency chains; prints the trail table
#   state.sh get <story>                 # print full state
#   state.sh frontier <story>            # pending trails whose trail-deps are all merged (one id per line)
#   state.sh running <story>             # count of trails in building|reviewing|merging
#   state.sh can-dispatch <story>        # exit 0 + next trail id if running < max_parallel and frontier non-empty
#   state.sh set-ticket <story> <ticket> <status> [sha]
#   state.sh set-trail <story> <trail> <field> <value>   # status|worktree|branch|agent|model|agent_id|review|reason|attempts
#   state.sh summary <story>             # one LOOP: line for the /goal evaluator
set -euo pipefail

dir="$(git rev-parse --show-toplevel)/.claude/ticket-loop"
cmd="${1:?usage: state.sh init|add-ticket|build-trails|get|frontier|running|can-dispatch|set-ticket|set-trail|summary ...}"
story="${2:?missing story key}"
file="$dir/$story.json"
TRAIL_MAX_LEN=4

save() { jq "$1" "$file" > "$file.tmp" && mv "$file.tmp" "$file"; }

case "$cmd" in
  init)
    mkdir -p "$dir/briefs" "$dir/gates" "$dir/wt"
    jq -n --arg story "$story" --arg branch "${3:?branch}" --arg base "${4:?base}" \
          --arg effort "${5:-medium}" --argjson par "${6:-3}" --arg wt "$dir/wt" \
          '{story:$story, branch:$branch, base:$base, review_effort:$effort, max_parallel:$par,
            worktree_root:$wt, created:(now|todate), tickets:[], trails:[]}' > "$file"
    echo "$file"
    ;;
  add-ticket)
    ticket="${3:?ticket}"; deps="${4:--}"; cx="${5:?complexity XS|S|M|L}"
    case "$cx" in XS|S|M|L) ;; *) echo "bad complexity '$cx'" >&2; exit 1;; esac
    [ "$deps" = "-" ] && depsjson='[]' || depsjson="$(printf '%s' "$deps" | jq -R 'split(",") | map(gsub("^\\s+|\\s+$";"")) | map(select(length>0))')"
    st=pending; [ "$cx" = L ] && st=needs-split
    jq --arg t "$ticket" --argjson d "$depsjson" --arg c "$cx" --arg s "$st" \
       '.tickets += [{key:$t, deps:$d, complexity:$c, trail:null, status:$s, sha:null, fail_count:0}]' \
       "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    ;;
  build-trails)
    # Chain rule: extend a trail from ticket X to its dependent Y only when Y's sole dep is X and X's
    # sole dependent is Y. L tickets are excluded (needs-split) and break chains. Max length TRAIL_MAX_LEN.
    save "$(cat <<JQ
      (.tickets | map(select(.status != "needs-split" and .status != "done" and .status != "skipped" and .status != "gate"))) as \$live |
      (\$live | map(.key)) as \$keys |
      def dependents(\$k): [ \$live[] | select(.deps | index(\$k) != null) | .key ];
      def deps_of(\$k): [ \$live[] | select(.key==\$k) | .deps[] | select(. as \$d | \$keys | index(\$d) != null) ];
      def rank(\$c): {"XS":0,"S":1,"M":2,"L":3}[\$c];
      def cx_of(\$k): (\$live[] | select(.key==\$k) | .complexity);
      # a ticket continues a trail only if it has exactly one dep and that dep has exactly one dependent
      def is_start(\$k): (deps_of(\$k)) as \$d | if (\$d|length) != 1 then true else (dependents(\$d[0]) | length) != 1 end;
      def chain(\$k; \$n): if \$n >= $TRAIL_MAX_LEN then [\$k] else
        (dependents(\$k)) as \$d |
        if (\$d|length)==1 and ((deps_of(\$d[0])|length)==1) then [\$k] + chain(\$d[0]; \$n+1) else [\$k] end end;
      ([ \$live[] | .key | select(is_start(.)) ] | to_entries | map({id:("t"+((.key+1)|tostring)), tickets: chain(.value; 1)})) as \$trails |
      def trail_of(\$k): (\$trails[] | select(.tickets | index(\$k) != null) | .id);
      .trails = [ \$trails[] | . as \$t |
          {id:.id, tickets:.tickets,
           deps: ([ deps_of(.tickets[0])[] | trail_of(.) ] | unique | map(select(. != \$t.id))),
           complexity: ([ .tickets[] | cx_of(.) ] | max_by(rank(.))),
           status:"pending", worktree:null, branch:null, agent:null, model:null, agent_id:null, attempts:0, review:null, reason:null} ]
      | .tickets |= map(if .status=="needs-split" then . else .trail = (trail_of(.key) // null) end)
JQ
)"
    jq -r '.trails[] | "\(.id)\t\(.complexity)\tdeps=\(.deps|join(",")|if .=="" then "-" else . end)\t\(.tickets|join(" > "))"' "$file"
    jq -r '.tickets[] | select(.status=="needs-split") | "needs-split\t\(.key)\t(L — split before dispatch)"' "$file"
    ;;
  get) jq . "$file" ;;
  frontier)
    jq -r '(.trails | map(select(.status=="merged") | .id)) as $ok |
      [ .trails[] | select(.status=="pending") | select(all(.deps[]; . as $d | $ok | index($d) != null)) ]
      | .[] | .id' "$file"
    ;;
  running)
    jq -r '[.trails[] | select(.status=="building" or .status=="reviewing" or .status=="merging")] | length' "$file"
    ;;
  can-dispatch)
    running=$(jq -r '[.trails[] | select(.status=="building" or .status=="reviewing" or .status=="merging")] | length' "$file")
    cap=$(jq -r '.max_parallel' "$file")
    [ "$running" -lt "$cap" ] || { echo "cap reached ($running/$cap)" >&2; exit 1; }
    # order: most dependents first, then longest, then id
    next=$(jq -r '(.trails | map(select(.status=="merged") | .id)) as $ok | .trails as $all |
      [ .trails[] | select(.status=="pending") | select(all(.deps[]; . as $d | $ok | index($d) != null)) ]
      | map(. + {nd: (. as $t | [ $all[] | select(.deps | index($t.id) != null) ] | length)})
      | sort_by([-.nd, -(.tickets|length), .id]) | (first // empty) | .id' "$file")
    [ -n "$next" ] || { echo "frontier empty" >&2; exit 1; }
    echo "$next"
    ;;
  set-ticket)
    ticket="${3:?ticket}"; status="${4:?status}"; sha="${5:-}"
    jq --arg t "$ticket" --arg s "$status" --arg sha "$sha" \
       '.tickets |= map(if .key==$t then
           .status=$s
           | (if $sha != "" then .sha=$sha else . end)
           | (if $s=="blocked" then .fail_count+=1 else . end)
         else . end)' \
       "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    ;;
  set-trail)
    trail="${3:?trail id}"; field="${4:?field}"; value="${5:?value}"
    case "$field" in
      status|worktree|branch|agent|model|agent_id|review|reason) vjson=$(jq -cn --arg v "$value" '$v') ;;
      attempts) vjson="$value" ;;
      *) echo "unknown field '$field'" >&2; exit 1 ;;
    esac
    save ".trails |= map(if .id==\"$trail\" then .$field=$vjson else . end)"
    ;;
  summary)
    jq -r '"LOOP: trails merged=\([.trails[]|select(.status=="merged")]|length)/\(.trails|length) running=\([.trails[]|select(.status=="building" or .status=="reviewing" or .status=="merging")]|length)/\(.max_parallel) blocked=\([.trails[]|select(.status=="blocked")]|length) needs-split=\([.tickets[]|select(.status=="needs-split")]|length)"' "$file"
    ;;
  *)
    echo "unknown command '$cmd'" >&2; exit 1
    ;;
esac
