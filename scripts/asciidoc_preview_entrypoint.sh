#!/bin/bash

# Define the output directory
OUTPUT_DIR=/workspace/target/docs/html
INPUT_DIR=/workspace/docs

# Ensure the output directory exists
mkdir -p $OUTPUT_DIR

# Function to handle SIGINT and SIGTERM signals
cleanup() {
  echo "Received signal, shutting down..."
  kill -s SIGTERM $WATCH_PID
  exit 0
}

trap 'cleanup' SIGINT SIGTERM

# Check if input directory is correctly mounted
echo "Checking if input directory is correctly mounted..."
if [ -d "$INPUT_DIR" ]; then
  echo "$INPUT_DIR exists."
else
  echo "$INPUT_DIR does not exist."
fi

# Input dir
echo "Checking input directory contents before initial conversion..."
ls -la $INPUT_DIR

# Convert all .adoc files to .html initially
echo "Performing initial conversion of .adoc files to .html..."
find $INPUT_DIR -name "*.adoc" -exec asciidoctor -D $OUTPUT_DIR {} \;
echo "Initial conversion complete."

# Log the files found
echo "Files found for conversion:"
find $INPUT_DIR -name "*.adoc" -print

# Watch and convert .adoc files to .html
echo "Starting inotifywait to monitor input dir ($INPUT_DIR)..."
inotifywait -m -e modify,create,delete -r $INPUT_DIR |
while read path action file; do
  echo "inotifywait detected a change: $path $action $file"
  if [[ "$file" =~ .*\.adoc$ ]]; then
    echo "Change detected: $action $file"
    echo "Converting $path$file to HTML..."
    asciidoctor -D $OUTPUT_DIR "$path$file"
    echo "Conversion complete: $path$file"
  else
    echo "Ignored change: $action $file"
  fi
done &

WATCH_PID=$!

# Start livereloadx to serve the files
cd $OUTPUT_DIR
echo "Starting livereloadx..."
livereloadx -s . -p 4000 &

wait $WATCH_PID