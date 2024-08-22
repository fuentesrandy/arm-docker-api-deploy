# Base stage with SSH support
FROM ubuntu:20.04 AS base

# Install dependencies, OpenSSH server, and supervisor
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    openssh-server \
    curl \
    ca-certificates \
    apt-transport-https \
    gnupg \
    supervisor \
    && mkdir -p /run/sshd \
    && echo 'root:Docker!' | chpasswd \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd \
    && echo "export VISIBLE=now" >> /etc/profile \
    && apt-get clean

# Supervisor config for running SSH and .NET app
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Set working directory and expose necessary ports
WORKDIR /app
EXPOSE 80
EXPOSE 2222

# Build stage to compile the .NET project
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["ARM-Docker-Api-Deploy.csproj", "."]
RUN dotnet restore "./ARM-Docker-Api-Deploy.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "./ARM-Docker-Api-Deploy.csproj" -c $BUILD_CONFIGURATION -o /app/build

# Publish stage to publish the .NET project
FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./ARM-Docker-Api-Deploy.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

# Final stage with SSH and .NET app running under supervisor
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

# Copy the entrypoint script (for supervisor)
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set entrypoint to start supervisord (runs both SSH and app)
ENTRYPOINT ["/entrypoint.sh"]
