# Title         : functions.jq
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : 01.home/00.core/configs/development/jq/functions.jq
# ----------------------------------------------------------------------------
# Custom jq functions library for common JSON processing tasks

# --- Array Utilities ---------------------------------------------------------

# Flatten nested arrays recursively
def flatten_deep:
  if type == "array" then
    map(flatten_deep) | add
  else
    .
  end;

# Get unique items by a specific key
def unique_by_key(key):
  group_by(key) | map(.[0]);

# Remove duplicates from array
def unique:
  sort | group_by(.) | map(.[0]);

# Chunk array into groups of specified size
def chunk(size):
  if length <= size then
    [.]
  else
    [.[0:size]] + (.[size:] | chunk(size))
  end;

# --- Object Utilities --------------------------------------------------------

# Safely get nested value with null fallback
def safe_get(path):
  try (getpath(path)) catch null;

# Deep merge two objects
def deep_merge(other):
  . as $item |
  other |
  to_entries |
  reduce .[] as $entry ($item;
    if ($entry.value | type) == "object" and (.[$entry.key] | type) == "object" then
      .[$entry.key] = (.[$entry.key] | deep_merge($entry.value))
    else
      .[$entry.key] = $entry.value
    end
  );

# Remove empty values (null, "", [])
def filter_empty:
  if type == "object" then
    with_entries(select(.value != null and .value != "" and .value != []))
  elif type == "array" then
    map(select(. != null and . != "" and . != []))
  else
    .
  end;

# Rename object keys
def rename_keys(mapping):
  with_entries(
    if mapping[.key] then
      .key = mapping[.key]
    else
      .
    end
  );

# --- String Utilities --------------------------------------------------------

# Convert string to slug format
def slugify:
  ascii_downcase |
  gsub("[^a-z0-9]+"; "-") |
  gsub("^-+|-+$"; "");

# Capitalize first letter of each word
def title_case:
  split(" ") |
  map(.[0:1] | ascii_upcase) + (.[1:] | ascii_downcase) |
  join(" ");

# Extract domain from URL
def extract_domain:
  if test("^https?://") then
    gsub("^https?://"; "") |
    gsub("/.*$"; "") |
    gsub(":.*$"; "")
  else
    .
  end;

# --- Date and Time Utilities -------------------------------------------------

# Convert Unix timestamp to ISO date string
def timestamp_to_iso:
  if type == "number" then
    strftime("%Y-%m-%dT%H:%M:%SZ")
  else
    .
  end;

# Convert Unix timestamp to readable date
def timestamp_to_date:
  if type == "number" then
    strftime("%Y-%m-%d %H:%M:%S")
  else
    .
  end;

# Convert ISO date string to Unix timestamp
def iso_to_timestamp:
  if type == "string" then
    strptime("%Y-%m-%dT%H:%M:%SZ") | mktime
  else
    .
  end;

# Get current timestamp
def now:
  now;

# --- CSV Utilities -----------------------------------------------------------

# Convert array of objects to CSV format
def to_csv:
  if type == "array" and length > 0 then
    (.[0] | keys_unsorted) as $headers |
    [$headers] + map([.[$headers[]]]) |
    map(@csv) |
    join("\n")
  else
    empty
  end;

# Convert CSV string to array of objects
def from_csv:
  split("\n") |
  map(split(",")) |
  .[0] as $headers |
  .[1:] |
  map(. as $row |
    reduce range(0; $headers|length) as $i ({};
      .[$headers[$i]] = $row[$i]
    )
  );

# --- Validation Utilities ----------------------------------------------------

# Check if value is email format
def is_email:
  type == "string" and test("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$");

# Check if value is URL format
def is_url:
  type == "string" and test("^https?://[^\\s/$.?#].[^\\s]*$");

# Check if value is UUID format
def is_uuid:
  type == "string" and test("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$");

# Check if object has required keys
def has_keys(keys):
  keys as $required |
  (. | keys) as $actual |
  ($required - $actual) | length == 0;

# --- Math Utilities ----------------------------------------------------------

# Calculate percentage
def percentage(total):
  if total > 0 then
    (. / total) * 100
  else
    0
  end;

# Round to specified decimal places
def round_to(places):
  . * (10 | pow(places)) | round | . / (10 | pow(places));

# Calculate average of array
def average:
  if length > 0 then
    add / length
  else
    0
  end;

# --- Development Utilities ---------------------------------------------------

# Pretty print with custom indentation
def pretty(indent):
  tostring | fromjson | tojsonstream | 
  if indent then
    gsub("^"; "  " * indent)
  else
    .
  end;

# Debug print with label
def debug(label):
  . as $value |
  (label + ": " + ($value | tostring)) | debug |
  $value;

# Measure execution time (conceptual - jq doesn't have real timing)
def time_it(label):
  . as $input |
  now as $start |
  $input |
  now as $end |
  (label + " took: " + (($end - $start) | tostring) + "s") | debug;