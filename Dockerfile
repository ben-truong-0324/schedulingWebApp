# Stage 1: Build
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copy project files
COPY ["Src/GroomingWebApp/GroomingWebApp.csproj", "GroomingWebApp/"]
COPY ["Src/Grooming.Core/Grooming.Core.csproj", "Grooming.Core/"]

# Restore based on the web app project
RUN dotnet restore "GroomingWebApp/GroomingWebApp.csproj"

# Copy the entire Src directory and build
COPY Src/ .
WORKDIR "/src/GroomingWebApp"
RUN dotnet publish "GroomingWebApp.csproj" -c Release -o /app/publish

# Stage 2: Final Image (UPDATED TO 10.0)
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app
COPY --from=build /app/publish .

# Cloud Run requirements: Listen on 8080
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

ENTRYPOINT ["dotnet", "GroomingWebApp.dll"]