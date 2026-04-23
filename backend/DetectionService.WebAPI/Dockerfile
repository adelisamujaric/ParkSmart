FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY ["DetectionService.WebAPI/DetectionService.WebAPI.csproj", "DetectionService.WebAPI/"]
COPY ["DetectionService.Application/DetectionService.Application.csproj", "DetectionService.Application/"]
COPY ["DetectionService.Domain/DetectionService.Domain.csproj", "DetectionService.Domain/"]
COPY ["DetectionService.Infrastructure/DetectionService.Infrastructure.csproj", "DetectionService.Infrastructure/"]
COPY ["Shared/Shared.csproj", "Shared/"]

RUN dotnet restore "DetectionService.WebAPI/DetectionService.WebAPI.csproj"

COPY . .
RUN dotnet build "DetectionService.WebAPI/DetectionService.WebAPI.csproj" -c Release -o /app/build
RUN dotnet publish "DetectionService.WebAPI/DetectionService.WebAPI.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "DetectionService.WebAPI.dll"]