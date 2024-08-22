#!/bin/bash

# Start the SSH server in the background
service ssh start

# Start the .NET application
dotnet /app/ARM-Docker-Api-Deploy.dll

# Keep the container running (optional if the app is not long-running)
exec "$@"
