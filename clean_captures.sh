#!/bin/bash

echo "Cleaning up capture files..."

# Remove all files in the captures directory
if [ -d "data/captures" ]; then
    rm -rf data/captures/*
    echo "All capture files removed."
else
    echo "No captures directory found, nothing to clean."
fi

echo "Done." 