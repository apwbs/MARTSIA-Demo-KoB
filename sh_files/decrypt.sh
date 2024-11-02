#!/bin/sh

# Initialize variables
requester_name=""
message_id=""
slice_id=""
output_folder=""

# Parse command-line arguments
while [ $# -gt 0 ]; do
    key="$1"
    case $key in
        --requester_name|-r) # Set requester name
            requester_name="$2"
            shift # past argument
            shift # past value
            ;;
        -m|--message_id) # Set message ID
            message_id="$2"
            shift # past argument
            shift # past value
            ;;
        -s|--slice_id) # Set slice ID
            slice_id="$2"
            shift # past argument
            shift # past value
            ;;
        -o|--output_folder) # Set output folder
            output_folder="$2"
            shift # past argument
            shift # past value
            ;;
        *) # Handle unknown options
            echo "Unknown option $1"
            exit 1
    esac
done

# Check if requester_name is provided
if [ -z "$requester_name" ]; then
    echo "You need to specify --requester_name!"
    exit 1
fi

# Check if message_id is provided
if [ -z "$message_id" ]; then
    echo "You need to specify --message_id!"
    exit 1
fi

# Check if output_folder exists
if [ -z "$output_folder" ] || [ ! -d "$output_folder" ]; then
    echo "You need to specify a directory for the --output_folder option!"
    exit 1
fi

python3 ../src/client.py -r "$requester_name"

# Validate message_id format and find it if needed
if ! echo "$message_id" | grep -qE '^[0-9]{20}$'; then
    matching_lines=$(grep "$message_id" "../src/.cache")
    if [ $(echo "$matching_lines" | wc -l) -eq 1 ]; then
        message_id=$(echo "$matching_lines" | grep -oP '\b\d+\b')
    fi
fi

# Count the number of slices
count_of_slices=$(ipfs_link=$(python3 -c "import sys; sys.path.append('../src'); from block_int import retrieve_MessageIPFSLink; print(retrieve_MessageIPFSLink(int(sys.argv[1]))[0])" "$message_id") && ipfs cat "$ipfs_link" | python3 -c "import sys, json; data = sys.stdin.read(); print(len(json.loads(data).get('header', [])))")

# Handle slice_id logic
if [ -z "$slice_id" ]; then
    if [ "$count_of_slices" -gt 1 ]; then
    	echo "You need to specify the slice id (--slice_id) since the message_id has $count_of_slices slices!"
    	exit 1
    fi
    python3 ../src/reader.py --message_id "$message_id" \
        --reader_name "$requester_name" --output_folder "$output_folder"
else
    if ! echo "$slice_id" | grep -qE '^[0-9]{20}$'; then
        matching_lines=$(grep "$slice_id" "../src/.cache")
        if [ $(echo "$matching_lines" | wc -l) -eq 1 ]; then
            slice_id=$(echo "$matching_lines" | grep -oP '\b\d+\b')
        fi
    fi
    if [ "$count_of_slices" -eq 1 ]; then
        echo "You do not need to specify the slice id (--slice_id) since the message_id has $count_of_slices slice!"
        exit 1
    fi
    python3 ../src/reader.py --message_id "$message_id" --slice_id "$slice_id" \
        --reader_name "$requester_name" --output_folder "$output_folder"
fi

# Check if the last command was successful
if [ $? -ne 0 ]; then
    echo "Error: python3 command failed!"
else
    echo "✅ Data owner access done"
fi

