# Stage 1: Build
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy the project file from the subfolder to the container
COPY ["groomingScheduler/groomingScheduler.csproj", "groomingScheduler/"]
RUN dotnet restore "groomingScheduler/groomingScheduler.csproj"

# Copy everything else and build
COPY . .
WORKDIR "/src/groomingScheduler"
RUN dotnet publish "groomingScheduler.csproj" -c Release -o /app

# Stage 2: Run
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app .

# Cloud Run requirement: listen on 8080
ENV ASPNETCORE_URLS=http://+:8080
EXPOSE 8080

ENTRYPOINT ["dotnet", "groomingScheduler.dll"]