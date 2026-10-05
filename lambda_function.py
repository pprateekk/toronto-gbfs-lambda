import sys
import json
import urllib.request
import gzip
from datetime import datetime, timezone

import os
import boto3

STALE_AFTER_SECONDS = 600 #10mins 

FEEDS = {
    "station_status": "https://tor.publicbikesystem.net/ube/gbfs/v1/en/station_status",
    "station_information": "https://tor.publicbikesystem.net/ube/gbfs/v1/en/station_information",
}
BUCKET = os.environ["BUCKET_NAME"]
s3 = boto3.client("s3")

"""
    check how recently the feed was updated:
    look at the 'last_updated' field in the feed and compare it to the current time
    
    if lambda runs at 10:05 but the last_updated = 10:04:58 => fresh
    if lambda runs at 10:05 but the last_updated = 09:30:00 => stale
"""
def check_freshness(raw_data, feed_name, now):
    data = json.loads(raw_data)
    feed_time = datetime.fromtimestamp(data["last_updated"], tz=timezone.utc)
    age_seconds = (now - feed_time).total_seconds()
    
    if age_seconds > STALE_AFTER_SECONDS:
        print(f"WARNING: {feed_name} looks stale ({age_seconds:.0f}s old)")

def collect(feed_name):
    url = FEEDS[feed_name]

    with urllib.request.urlopen(url, timeout=10) as response:
        raw_data = response.read()

    now = datetime.now(timezone.utc)

    #compress it in gzip to reduce storage and query costs
    compressed = gzip.compress(raw_data)
    key = f"raw/{feed_name}/dt={now:%Y-%m-%d}/{feed_name}_{now:%Y%m%dT%H%M%SZ}.json.gz"
    s3.put_object(Bucket=BUCKET, Key=key, Body=compressed)
    print(f"Uploaded s3://{BUCKET}/{key} ({len(compressed) / 1024:.0f} KB)")

    check_freshness(raw_data, feed_name, now)

    return key

def lambda_handler(event, context):
    feed_name = event.get("feed", "station_status")
    try:
        key = collect(feed_name)
    except Exception as error:
        print(f"ERROR collecting {feed_name}: {error}")
        raise

    return {"saved": key}

if __name__ == "__main__":
    if len(sys.argv) > 1:
        feed_name = sys.argv[1]
    else:
        feed_name = "station_status"
    collect(feed_name)

