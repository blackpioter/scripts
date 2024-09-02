#!/bin/bash

measure_bootup_time () {
    # Parse input arguments
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --container|-c) container_name="$2"; shift ;;
            --url|-u) url="$2"; shift ;;
            --help|-h) echo "Usage: $0 --container <container_name> --url <url_to_check>"; return 0 ;;
            *) echo "Unknown parameter passed: $1"; return 1 ;;
        esac
        shift
    done

    # Check if both required parameters are provided
    if [ -z "$container_name" ] || [ -z "$url" ]; then
        echo "Error: Both --container and --url parameters are required."
        echo "Usage: $0 --container <container_name> --url <url_to_check>"
        echo "       $0 -c <container_name> -u <url_to_check>"
        return 1
    fi

    # Get the container ID of the specified container
    container_id=$(docker ps | grep "$container_name" | awk '{print $1}')

    if [ -z "$container_id" ]; then
        echo "Error: No running container found with the name $container_name"
        return 1
    fi

    # Get the container start time from Docker
    container_start_time=$(docker inspect --format='{{.State.StartedAt}}' "$container_id" | xargs -I{} date +%s -d {})

    echo "Container '$container_name' started at: $(date -d @$container_start_time)"

    # Poll the specified URL until it returns a 200 status
    while true; do
        # Check if the URL returns 200
        status_code=$(curl -s -o /dev/null -w "%{http_code}" "$url")

        if [ "$status_code" -eq 200 ]; then
            end_time=$(date +%s)
            break
        fi

        sleep 1 # Sleep for a second before retrying
    done

    echo "App in container '$container_name' is up and responding with 200 OK at $url."

    # Calculate the time difference
    bootup_time=$((end_time - container_start_time))

    echo "App bootup time: $bootup_time seconds"
}

# Call the function if the script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    measure_bootup_time "$@"
fi
