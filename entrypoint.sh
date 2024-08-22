#!/bin/bash
# entrypoint.sh

# Optional: Add any setup logic here
echo "Starting the container..."

# Optional: Print environment variables for debugging
echo "Environment variables:"
env

# Run the .NET application
echo "Running the .NET application..."
exec dotnet /app/ARM-Docker-Api-Deploy.dll

# The 'exec' command replaces the shell with the .NET app, ensuring that the app gets signal handling correctly
