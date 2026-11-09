# Multi-stage Dockerfile for the Raceway ASP.NET Core 8 MVC app.
# Same structure Visual Studio generates with "Add > Docker Support" (video 13),
# adapted to this project (Race.csproj / Race.dll, .NET 8).

# ---- runtime base image (small, runs as a non-root user) ----
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
USER $APP_UID
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

# ---- build stage ----
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
ARG BUILD_CONFIGURATION=Release
WORKDIR /src
# Copy the project file first so "dotnet restore" is cached until packages change
COPY ["Race.csproj", "."]
RUN dotnet restore "./Race.csproj"
COPY . .
WORKDIR "/src/."
RUN dotnet build "./Race.csproj" -c $BUILD_CONFIGURATION -o /app/build

# ---- publish stage ----
FROM build AS publish
ARG BUILD_CONFIGURATION=Release
RUN dotnet publish "./Race.csproj" -c $BUILD_CONFIGURATION -o /app/publish /p:UseAppHost=false

# ---- final image ----
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .

# Profile pictures are saved under wwwroot/uploads/profiles; the non-root user needs write access.
USER root
RUN mkdir -p /app/wwwroot/uploads/profiles && chown -R $APP_UID /app/wwwroot/uploads
USER $APP_UID

ENV ASPNETCORE_HTTP_PORTS=8080
ENTRYPOINT ["dotnet", "Race.dll"]
