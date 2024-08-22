# Base stage using Debian for runtime
FROM debian:bookworm AS base

# Install dependencies for running .NET applications (curl and other necessary packages)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    apt-transport-https \
    gnupg \
    && apt-get install -y --no-install-recommends dialog \
    && apt-get install -y --no-install-recommends openssh-server \
    && echo "root:Docker!" | chpasswd \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* 

# Install the .NET runtime
RUN curl -sSL https://dotnet.microsoft.com/download/dotnet/scripts/v1/dotnet-install.sh | bash /dev/stdin --channel 8.0 --install-dir /usr/share/dotnet \
    && ln -s /usr/share/dotnet/dotnet /usr/bin/dotnet


COPY sshd_config /etc/ssh/

WORKDIR /app
EXPOSE 8080 
EXPOSE 8081
EXPOSE 2222

# Copy the entrypoint script to the container
COPY entrypoint.sh ./

# Ensure the entrypoint script is executable
RUN chmod u+x ./entrypoint.sh

# Build stage to compile the .NET project
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["ARM-Docker-Api-Deploy.csproj", "."]
RUN dotnet restore "./ARM-Docker-Api-Deploy.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "./ARM-Docker-Api-Deploy.csproj" -c $BUILD_CONFIGURATION -o /app/build

# Publish stage to produce optimized output
FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./ARM-Docker-Api-Deploy.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

# Final stage using Debian to run the application
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT [ "./entrypoint.sh" ] 
