#!/bin/bash

# Prompt the user to choose between artists, labels, or both
echo "What would you like to download?"
echo "1. Artists (beatport_links_artists.txt)"
echo "2. Labels (beatport_links_labels.txt)"
echo "3. All (artists + labels) [default]"
read -rp "Choose an option (1, 2, or 3): " CHOICE

# Define the radar file(s) based on user input
if [[ "$CHOICE" == "1" ]]; then
  RADAR_FILES=("beatport_links_artists.txt")
  DATE_PARAM="new_release_date"
elif [[ "$CHOICE" == "2" ]]; then
  RADAR_FILES=("beatport_links_labels.txt")
  DATE_PARAM="publish_date"
else
  # Default to both files if choice is 3 or empty
  RADAR_FILES=("beatport_links_artists.txt" "beatport_links_labels.txt")
  # Use the appropriate date param for each file later
  DATE_PARAM=""
fi

# Check if the downloader exists
if [ ! -f "beatportdl-linux-amd64" ]; then
  echo "Error: beatportdl-linux-amd64 not found in the current directory."
  exit 1
fi

# Prompt the user for target date or custom date
echo "Do you want to use the target date (6 days ago) or enter a custom date?"
echo "1. Use target date (default)"
echo "2. Enter custom date"
read -rp "Choose an option (1 or 2): " CHOICE

# Determine the date based on user input
if [[ "$CHOICE" == "2" ]]; then
  read -rp "Enter custom date (format: YYYY-MM-DD): " CUSTOM_DATE
  if ! date -d "$CUSTOM_DATE" &>/dev/null; then
    echo "Error: Invalid date. Please use a valid format (YYYY-MM-DD)."
    exit 1
  fi
  TARGET_DATE="$CUSTOM_DATE"
else
  TARGET_DATE=$(date -d "6 days ago" "+%Y-%m-%d")
fi

# Display the selected date
echo "Using date: $TARGET_DATE"

# Define the download file
DOWNLOAD_FILE="download.txt"

# Clear or create the download file
> "$DOWNLOAD_FILE"

# Process each radar file
for FILE in "${RADAR_FILES[@]}"; do
  if [ ! -f "$FILE" ]; then
    echo "Warning: $FILE does not exist. Skipping."
    continue
  fi

  # Determine date param based on file type
  if [[ "$FILE" == *artists* ]]; then
    FILE_DATE_PARAM="new_release_date"
  else
    FILE_DATE_PARAM="publish_date"
  fi

  while IFS= read -r URL; do
    if [[ -z "$URL" || ! "$URL" =~ ^https?:// ]]; then
      echo "Skipping invalid URL: $URL"
      continue
    fi

    MODIFIED_URL="${URL}/?${FILE_DATE_PARAM}=${TARGET_DATE}:"
    echo "Adding to download list: $MODIFIED_URL"
    echo "$MODIFIED_URL" >> "$DOWNLOAD_FILE"
  done < "$FILE"
done

# Use the downloader with the download file
echo "Downloading releases from the generated list..."
if ./beatportdl-linux-amd64 "$DOWNLOAD_FILE"; then
  echo "Download completed successfully."
else
  echo "Error: Download failed. Please check the logs."
  exit 1
fi

echo "Release scraper script completed."
