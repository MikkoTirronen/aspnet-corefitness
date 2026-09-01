FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS base
WORKDIR /app
EXPOSE 8080

RUN apt-get update \
    && apt-get install -y --no-install-recommends libgssapi-krb5-2 \
    && rm -rf /var/lib/apt/lists/*

FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /source

# Install Node.js/npm for Tailwind
RUN apt-get update \
    && apt-get install -y nodejs npm \
    && rm -rf /var/lib/apt/lists/*

# Copy project files and restore .NET dependencies
COPY ["src/Presentation.WebApp/Presentation.WebApp.csproj", "src/Presentation.WebApp/"]
COPY ["src/Application/Application.csproj", "src/Application/"]
COPY ["src/Infrastructure/Infrastructure.csproj", "src/Infrastructure/"]
COPY ["src/Domain/Domain.csproj", "src/Domain/"]

RUN dotnet restore "src/Presentation.WebApp/Presentation.WebApp.csproj"

# Copy complete repository
COPY . .

WORKDIR /source/src/Presentation.WebApp

# Install Linux-compatible npm dependencies
RUN rm -rf node_modules \
    && npm ci \
    && npm install @tailwindcss/oxide-linux-x64-gnu --no-save

WORKDIR /source

RUN dotnet publish "src/Presentation.WebApp/Presentation.WebApp.csproj" \
    -c Release \
    -o /app/publish \
    /p:UseAppHost=false

FROM base AS final
WORKDIR /app

COPY --from=build /app/publish .

ENTRYPOINT ["dotnet", "Presentation.WebApp.dll"]