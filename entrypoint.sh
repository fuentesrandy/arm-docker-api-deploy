#!/bin/bash
# entrypoint.sh

# Optional: Add any setup logic here
echo "Starting the container..."

echo "Starting SSH server..."
service ssh start

# Run the .NET application
echo "Running the .NET application..."
exec dotnet /app/ARM-Docker-Api-Deploy.dll

# The 'exec' command replaces the shell with the .NET app, ensuring that the app gets signal handling correctly
