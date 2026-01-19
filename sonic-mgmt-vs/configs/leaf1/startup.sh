#!/bin/bash

# Copy minigraph file into the SONiC container's filesystem
# This is needed because the mounted files are not accessible via SSH due to chroot

if [ -f /etc/sonic/minigraph.xml ]; then
    echo "Minigraph file found at /etc/sonic/minigraph.xml"
    # File is already mounted, no need to copy
else
    echo "Minigraph file not found, attempting to copy from mounted location"
    # Try to copy from the mounted location
    if [ -f /host/etc/sonic/minigraph.xml ]; then
        cp /host/etc/sonic/minigraph.xml /etc/sonic/minigraph.xml
        echo "Copied minigraph from /host/etc/sonic/minigraph.xml"
    else
        echo "Warning: Could not find minigraph file"
    fi
fi

# Verify the file exists
if [ -f /etc/sonic/minigraph.xml ]; then
    echo "Minigraph file is accessible at /etc/sonic/minigraph.xml"
    ls -la /etc/sonic/minigraph.xml
else
    echo "Error: Minigraph file is not accessible"
fi

