#!/bin/bash
#Grabbing the top 250 hits from HybridAnalysis, looking for interesting tags, then downloading 40 random samples for analysis (because API rate limits)

# Grabs system date for finding closest API search matches
DATE=$(date +%s)

# File where hashes to be downloaded is stored
GRAB='~/ha_interesting.txt'

# File where hashes are stored temporarily to be manipulated 
TMP='~/ha_tmp.txt'

# Enter your HA API key here
API='APIKEYHERE'

# User Agent needed to retrieve results from HA
USERAGENT='Falcon Sandbox'

# Output from API query
ACCEPTFILE='accept: application/json'

# Clear output files before beginning
>"$TMP"
>"$GRAB"

# TEST API CALL 
#curl -X GET "https://www.hybrid-analysis.com/api/v2/feed/latest?_timestamp=1562699136960" -H  "accept: application/json" -H  "user-agent: Falcon Sandbox" -H  "api-key: "

# Use the HybridAnalysis API to get the top 250 entries from the last 24hrs, then use jq to filter for any hits that are marked as ''interesting': true' and pipe out to the grab file
curl -X GET "https://www.hybrid-analysis.com/api/v2/feed/latest?_timestamp="$DATE"" -H ""$ACCEPTFILE"" -H "user-agent: "$USERAGENT"" -H "api-key: "$API"" |  jq '.data[] | select(.interesting == true) | .sha256' -r  > "$GRAB"

# Shuffle the non-malicious lines and send them to the temporary file 
shuf "$GRAB" > "$TMP"

# Shuffle the temporary file again, print only the hash lines, then return the top 40 results to the hash download file
sort -R "$TMP" | awk '{print $1}' | head -n 40 > "$GRAB"

# Read all interesting hashes and download the samples from Hybrid Analysis
while read line; do
	curl -X GET "https://www.hybrid-analysis.com/api/v2/overview/"$line"/sample?_timestamp="$DATE"" -H "accept: application/gzip" -H "user-agent: "$USERAGENT"" -H "api-key: "$API"" > ha_interesting_"$line"
	sleep 24s
done < "$GRAB"
