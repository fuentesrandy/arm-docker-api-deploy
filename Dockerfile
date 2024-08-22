# See https://aka.ms/customizecontainer to learn how to customize your debug container and how Visual Studio uses this Dockerfile to build your images for faster debugging.

# This stage is used when running from VS in fast mode (Default for Debug configuration)
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
USER app
# Install SSH server
COPY sshd_config /etc/ssh/sshd_config
# Install OpenSSH server
RUN apt-get update \
    && apt-get install -y --no-install-recommends openssh-server \
    && mkdir -p /run/sshd \
    && echo 'root:Docker!' | chpasswd \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd \
    && echo "export VISIBLE=now" >> /etc/profile

WORKDIR /app
EXPOSE 8080
EXPOSE 8081
EXPOSE 2222
EXPOSE 22


# This stage is used to build the service project
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
COPY ["ARM-Docker-Api-Deploy.csproj", "."]
RUN dotnet restore "./ARM-Docker-Api-Deploy.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "./ARM-Docker-Api-Deploy.csproj" -c $BUILD_CONFIGURATION -o /app/build

# This stage is used to publish the service project to be copied to the final stage
FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./ARM-Docker-Api-Deploy.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

# This stage is used in production or when running from VS in regular mode (Default when not using the Debug configuration)
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
CMD service ssh start
ENTRYPOINT ["dotnet", "ARM-Docker-Api-Deploy.dll"]