# Base stage with SSH support
FROM ubuntu:20.04 AS base

# Install dependencies and OpenSSH server
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    openssh-server \
    curl \
    ca-certificates \
    apt-transport-https \
    gnupg \
    && mkdir -p /run/sshd \
    && echo 'root:Docker!' | chpasswd \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd \
    && echo "export VISIBLE=now" >> /etc/profile \
    && apt-get clean

# Set up SSH to run in the background
EXPOSE 22
EXPOSE 2222
CMD service ssh start && tail -f /dev/null

# Set the non-root user and working directory for your app
USER app
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

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

# Final stage with SSH and .NET app running
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

# Entry point to run the .NET application
ENTRYPOINT ["dotnet", "ARM-Docker-Api-Deploy.dll"]
