#!/bin/bash

# Define the Availability Domains (ADs) to cycle through.
# These typically correspond to the ADs available in your OCI region (e.g., Frankfurt has AD-1, AD-2, AD-3).
AVAILABILITY_DOMAINS=("1" "2" "3")
CURRENT_AD_INDEX=0

echo "Starting OCI instance provisioning retry loop..."

while true; do
  # Get the current Availability Domain from the array.
  CURRENT_AD=${AVAILABILITY_DOMAINS[$CURRENT_AD_INDEX]}
  echo "$(date '+%Y-%m-%d %H:%M:%S') - Attempting to provision instance in Availability Domain: AD-${CURRENT_AD}..."

  # Execute terraform apply, passing the current AD as a variable.
  # The -auto-approve flag is used for unattended execution.
  terraform apply -var="ad_number=${CURRENT_AD}" -auto-approve

  # Check the exit status of the terraform apply command.
  if [ $? -eq 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - SUCCESS: Instance successfully provisioned in AD-${CURRENT_AD}!"
    break # Exit the loop as provisioning was successful.
  else
    echo "$(date '+%Y-%m-%d %H:%M:%S') - FAILURE: Provisioning in AD-${CURRENT_AD} failed. This AD might be full or another issue occurred."
    echo "       - Switching to the next Availability Domain and retrying after a delay."
    
    # Move to the next Availability Domain in a cyclic manner.
    CURRENT_AD_INDEX=$(( (CURRENT_AD_INDEX + 1) % ${#AVAILABILITY_DOMAINS[@]} ))
    
    # Wait for a specified duration before the next attempt to avoid rate limiting
    # and give OCI a chance to free up resources.
    sleep 30 
  fi
done
