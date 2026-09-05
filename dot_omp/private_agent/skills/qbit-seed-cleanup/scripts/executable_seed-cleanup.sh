#!/bin/bash
# Select and optionally remove eligible qBittorrent jobs without deleting their files.

set -euo pipefail

PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export PATH

readonly MEDIA_ENV="/Users/alex/homelab/scripts/media-env.sh"
readonly TAG_SYNC="/Users/alex/homelab/scripts/qbit-tracker-tags.sh"
readonly QBIT_CONTAINER="qbittorrent"

mode="${1:-preview}"
days="${2:-10}"

if [[ "$mode" != "preview" && "$mode" != "apply" ]]; then
  echo "Usage: $0 [preview|apply] [minimum-private-seed-days]" >&2
  exit 2
fi

if [[ ! "$days" =~ ^[0-9]+$ ]] || (( days < 1 )); then
  echo "minimum-private-seed-days must be a positive integer" >&2
  exit 2
fi

source "$MEDIA_ENV"

cookie_file=$(mktemp -t qbit-seed-cleanup.XXXXXX)
torrents_file=$(mktemp -t qbit-seed-cleanup-torrents.XXXXXX)
selection_file=$(mktemp -t qbit-seed-cleanup-selection.XXXXXX)
verified_file=$(mktemp -t qbit-seed-cleanup-verified.XXXXXX)
radarr_history_file=$(mktemp -t qbit-seed-cleanup-radarr-history.XXXXXX)
cleanup() {
  test ! -e "$cookie_file" || unlink "$cookie_file"
  test ! -e "$torrents_file" || unlink "$torrents_file"
  test ! -e "$selection_file" || unlink "$selection_file"
  test ! -e "$verified_file" || unlink "$verified_file"
  test ! -e "$radarr_history_file" || unlink "$radarr_history_file"
}
trap cleanup EXIT

qbit_login() {
  local response
  response=$(/usr/bin/curl -fsS -c "$cookie_file" -X POST \
    "$QBIT_URL/api/v2/auth/login" \
    -H "Referer: $QBIT_URL" \
    --data-urlencode "username=$QBIT_USER" \
    --data-urlencode "password=$QBIT_PASS")

  if [[ "$response" != "Ok." ]]; then
    echo "qBittorrent authentication failed" >&2
    return 1
  fi
}

fetch_torrents() {
  /usr/bin/curl -fsS -b "$cookie_file" \
    -H "Referer: $QBIT_URL" \
    "$QBIT_URL/api/v2/torrents/info"
}

verify_primary_import() {
  local category="$1"
  local content_path="$2"

  docker exec "$QBIT_CONTAINER" test -e "$content_path" || return 1

  case "$category" in
    radarr)
      # Radarr imports one primary movie. Bundled featurettes and shorts are not
      # library failures, so verify the largest media payload rather than extras.
      docker exec "$QBIT_CONTAINER" sh -c '
        rows=$(find "$1" -type f -size +100M \
          \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.m4v" \
             -o -iname "*.avi" -o -iname "*.ts" -o -iname "*.m2ts" \) \
          -exec stat -c "%s %h" {} \; 2>/dev/null) || exit 1
        [ -n "$rows" ] || exit 1
        links=$(printf "%s\n" "$rows" | sort -nr | head -n 1 | awk "{print \$2}")
        [ -n "$links" ] && [ "$links" -ge 2 ]
      ' sh "$content_path"
      ;;
    sonarr|tv-sonarr)
      # Sonarr season packs may include featurettes or bonus specials which are
      # intentionally outside the requested season. Verify every primary episode.
      docker exec "$QBIT_CONTAINER" sh -c '
        links=$(find "$1" -type f -size +100M \
          \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.m4v" \
             -o -iname "*.avi" -o -iname "*.ts" -o -iname "*.m2ts" \) \
          ! -path "$1/Featurettes/*" ! -path "$1/Specials/*" \
          ! -path "$1/Extras/*" ! -path "$1/Sample/*" ! -path "$1/Samples/*" \
          -exec stat -c "%h" {} \; 2>/dev/null) || exit 1
        [ -n "$links" ] || exit 1
        for count in $links; do
          [ "$count" -ge 2 ] || exit 1
        done
      ' sh "$content_path"
      ;;
    *)
      # Unknown import owners retain the original strict all-media behavior.
      docker exec "$QBIT_CONTAINER" sh -c '
        links=$(find "$1" -type f -size +100M \
          \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.m4v" \
             -o -iname "*.avi" -o -iname "*.ts" -o -iname "*.m2ts" \) \
          -exec stat -c "%h" {} \; 2>/dev/null) || exit 1
        [ -n "$links" ] || exit 1
        for count in $links; do
          [ "$count" -ge 2 ] || exit 1
        done
      ' sh "$content_path"
      ;;
  esac
}

radarr_history_loaded=false
load_radarr_history() {
  if [[ "$radarr_history_loaded" == "true" ]]; then
    return 0
  fi

  /usr/bin/curl -fsS -G "${RADARR_URL%/}/api/v3/history" \
    -H "X-Api-Key: $RADARR_KEY" \
    --data-urlencode "page=1" \
    --data-urlencode "pageSize=1000" \
    --data-urlencode "sortKey=date" \
    --data-urlencode "sortDirection=descending" > "$radarr_history_file"
  jq -e '.records | type == "array"' "$radarr_history_file" >/dev/null
  radarr_history_loaded=true
}

verify_radarr_superseded() {
  local hash="$1"
  local category="$2"
  local content_path="$3"
  local source_suffix lowercase_hash grabbed_movie_id movie_id
  local import_row imported_file_id imported_path import_date
  local deletion_count current_row current_file_id current_path current_links

  [[ "$category" == "radarr" ]] || return 1
  docker exec "$QBIT_CONTAINER" test -e "$content_path" || return 1
  load_radarr_history || return 1

  source_suffix="${content_path#/data-movies}"
  lowercase_hash=$(printf "%s" "$hash" | tr "[:upper:]" "[:lower:]")
  grabbed_movie_id=$(jq -r --arg hash "$lowercase_hash" '
    [
      .records[]
      | select(.eventType == "grabbed")
      | select(((.data.torrentInfoHash // "") | ascii_downcase) == $hash)
      | .movieId
    ] | first // empty
  ' "$radarr_history_file")

  import_row=$(jq -r --arg source_suffix "$source_suffix" '
    def media_suffix:
      sub("^/data-(movies|tv)"; "")
      | sub("^/data"; "");
    [
      .records[]
      | select(.eventType == "downloadFolderImported")
      | ((.data.droppedPath // "") | media_suffix) as $dropped
      | select($dropped == $source_suffix or ($dropped | startswith($source_suffix + "/")))
    ]
    | sort_by(.date)
    | last
    | [.movieId, (.data.fileId // ""), (.data.importedPath // ""), .date]
    | @tsv
  ' "$radarr_history_file")
  IFS=$'\t' read -r movie_id imported_file_id imported_path import_date <<< "$import_row"
  [[ "$movie_id" =~ ^[0-9]+$ ]] || return 1
  [[ "$imported_file_id" =~ ^[0-9]+$ ]] || return 1
  [[ -n "$imported_path" && -n "$import_date" ]] || return 1
  if [[ -n "$grabbed_movie_id" && "$grabbed_movie_id" != "$movie_id" ]]; then
    return 1
  fi

  deletion_count=$(jq -r \
    --argjson movie_id "$movie_id" \
    --arg imported_path "$imported_path" \
    --arg import_date "$import_date" '
      def media_suffix:
        sub("^/data-(movies|tv)"; "")
        | sub("^/data"; "");
      [
        .records[]
        | select(.movieId == $movie_id and .eventType == "movieFileDeleted")
        | select(
            ((.sourceTitle // "") | media_suffix)
            == ($imported_path | media_suffix)
          )
        | select(.date >= $import_date)
        | select((.data.reason // "") == "Upgrade" or (.data.reason // "") == "Manual")
      ] | length
    ' "$radarr_history_file")
  (( deletion_count > 0 )) || return 1

  current_row=$(/usr/bin/curl -fsS "${RADARR_URL%/}/api/v3/movie/$movie_id" \
    -H "X-Api-Key: $RADARR_KEY" \
    | jq -r '
        select(.hasFile == true)
        | [(.movieFile.id // ""), ((.path // "") + "/" + (.movieFile.relativePath // ""))]
        | @tsv
      ')
  IFS=$'\t' read -r current_file_id current_path <<< "$current_row"
  [[ "$current_file_id" =~ ^[0-9]+$ ]] || return 1
  [[ "$current_file_id" != "$imported_file_id" && -n "$current_path" ]] || return 1
  docker exec radarr test -f "$current_path" || return 1
  current_links=$(docker exec radarr stat -c "%h" "$current_path")
  [[ "$current_links" =~ ^[0-9]+$ ]] && (( current_links >= 2 ))
}

# Keep provider identity current before making any cleanup decision.
"$TAG_SYNC" sync >/dev/null
qbit_login
fetch_torrents > "$torrents_file"

jq --argjson minimum_seconds "$((days * 86400))" --argjson days "$days" '
  def tag_list: ((.tags // "") | split(",") | map(ltrimstr(" ")));
  def provider:
    (tag_list) as $tags
    | if ($tags | index("tracker-torrentleech")) then "torrentleech"
      elif ($tags | index("tracker-avistaz")) then "avistaz"
      elif ($tags | index("tracker-public")) then "public"
      elif ($tags | index("tracker-private-other")) then "private-other"
      else "unclassified"
      end;
  def completed:
    (.progress == 1)
    and (.completion_on > 0)
    and (.amount_left == 0)
    and (.state as $state
      | (["uploading", "stalledUP", "pausedUP", "queuedUP", "forcedUP", "stoppedUP"]
        | index($state)) != null);
  def summary($provider; $reason): {
    name,
    hash,
    tracker_provider: $provider,
    category,
    state,
    ratio,
    seeding_time,
    seed_days: (((.seeding_time // 0) / 86400) * 100 | round / 100),
    content_path,
    reason: $reason
  };

  [ .[] | . + {resolved_provider: provider, is_completed: completed} ] as $all
  | {
      policy: {
        public: "all completed",
        private_providers: ["avistaz", "torrentleech"],
        minimum_private_seed_days: $days,
        delete_files: false
      },
      candidates: [
        $all[]
        | select(.is_completed)
        | select(
            (.resolved_provider == "public")
            or ((.resolved_provider == "torrentleech" or .resolved_provider == "avistaz")
              and ((.seeding_time // 0) >= $minimum_seconds))
          )
        | summary(.resolved_provider;
            if .resolved_provider == "public" then "completed public torrent"
            else "completed approved private torrent meeting seed-time threshold"
            end)
      ] | sort_by(.tracker_provider, .name),
      review: [
        $all[]
        | select(.is_completed)
        | if (.resolved_provider == "private-other" or .resolved_provider == "unclassified") then
            summary(.resolved_provider; "excluded: provider is outside the approved private-tracker scope")
          elif ((.resolved_provider == "torrentleech" or .resolved_provider == "avistaz")
            and ((.seeding_time // 0) < $minimum_seconds)) then
            summary(.resolved_provider; "excluded: private torrent has not met the seed-time threshold")
          else empty
          end
      ] | sort_by(.tracker_provider, .name)
    }
  | .candidate_count = (.candidates | length)
  | .review_count = (.review | length)
' "$torrents_file" > "$selection_file"

# A completed qBit job can still be waiting for an *arr import. Keep only candidates
# whose primary media payloads are hardlinked into the library.
primary_verified_hashes=""
superseded_verified_hashes=""
while IFS=$'\t' read -r hash category content_path; do
  if verify_primary_import "$category" "$content_path"; then
    primary_verified_hashes="${primary_verified_hashes}${primary_verified_hashes:+|}${hash}"
  elif verify_radarr_superseded "$hash" "$category" "$content_path"; then
    superseded_verified_hashes="${superseded_verified_hashes}${superseded_verified_hashes:+|}${hash}"
  fi
done < <(jq -r '.candidates[] | [.hash, .category, .content_path] | @tsv' "$selection_file")

jq \
  --arg primary_verified_hashes "$primary_verified_hashes" \
  --arg superseded_verified_hashes "$superseded_verified_hashes" '
  ($primary_verified_hashes | split("|") | map(select(length > 0))) as $primary_verified
  | ($superseded_verified_hashes | split("|") | map(select(length > 0))) as $superseded_verified
  | ($primary_verified + $superseded_verified) as $verified
  | .candidates as $original_candidates
  | .candidates = [
      $original_candidates[]
      | .hash as $hash
      | select($verified | index($hash))
      | . + {
          library_import_verified: true,
          library_verification_method:
            (if ($primary_verified | index($hash)) then "primary-media-hardlinks"
             else "radarr-superseded-with-hardlinked-replacement"
             end)
        }
    ]
  | .review += [
      $original_candidates[]
      | .hash as $hash
      | select(($verified | index($hash)) == null)
      | .reason = "excluded: primary media is neither hardlinked nor proven superseded with a hardlinked replacement"
      | . + {library_import_verified: false}
    ]
  | .candidates |= sort_by(.tracker_provider, .name)
  | .review |= sort_by(.tracker_provider, .name)
  | .candidate_count = (.candidates | length)
  | .review_count = (.review | length)
' "$selection_file" > "$verified_file"
cp "$verified_file" "$selection_file"

jq . "$selection_file"

if [[ "$mode" == "preview" ]]; then
  exit 0
fi

candidate_count=$(jq -r '.candidate_count' "$selection_file")
if (( candidate_count == 0 )); then
  echo '{"apply_status":"no eligible torrents; nothing removed"}'
  exit 0
fi

# Abort the whole batch if any source path is absent before deletion.
while IFS=$'\t' read -r hash category content_path verification_method; do
  verified=false
  case "$verification_method" in
    primary-media-hardlinks)
      verify_primary_import "$category" "$content_path" && verified=true
      ;;
    radarr-superseded-with-hardlinked-replacement)
      verify_radarr_superseded "$hash" "$category" "$content_path" && verified=true
      ;;
  esac
  if [[ -z "$content_path" || "$verified" != "true" ]]; then
    echo "Refusing apply: source or verified library hardlink is missing for $hash: $content_path" >&2
    exit 1
  fi
done < <(jq -r '.candidates[] | [.hash, .category, .content_path, .library_verification_method] | @tsv' "$selection_file")

hashes=$(jq -r '[.candidates[].hash] | join("|")' "$selection_file")
/usr/bin/curl -fsS -b "$cookie_file" -X POST \
  -H "Referer: $QBIT_URL" \
  "$QBIT_URL/api/v2/torrents/delete" \
  --data-urlencode "hashes=$hashes" \
  --data-urlencode "deleteFiles=false"

remaining=$(fetch_torrents | jq -r --arg hashes "$hashes" '
  ($hashes | split("|")) as $targets
  | [.[] | select(.hash as $hash | $targets | index($hash))] | length
')
if (( remaining != 0 )); then
  echo "qBittorrent still reports $remaining targeted jobs after deletion" >&2
  exit 1
fi

# deleteFiles=false must retain the payload; verify every resolved source path.
retained=0
while IFS=$'\t' read -r hash content_path; do
  if ! docker exec "$QBIT_CONTAINER" test -e "$content_path"; then
    echo "Retention verification failed for $hash: $content_path" >&2
    exit 1
  fi
  retained=$((retained + 1))
done < <(jq -r '.candidates[] | [.hash, .content_path] | @tsv' "$selection_file")

jq -n \
  --argjson removed "$candidate_count" \
  --argjson retained "$retained" \
  '{apply_status: "complete", removed_jobs: $removed, retained_content_paths: $retained, delete_files: false}'
