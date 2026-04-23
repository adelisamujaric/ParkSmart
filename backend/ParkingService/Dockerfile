FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY ["ParkingService/ParkingService.WebAPI.csproj", "ParkingService/"]
COPY ["ParkingService.Application/ParkingService.Application.csproj", "ParkingService.Application/"]
COPY ["ParkingService.Domain/ParkingService.Domain.csproj", "ParkingService.Domain/"]
COPY ["ParkingService.Infrastructure/ParkingService.Infrastructure.csproj", "ParkingService.Infrastructure/"]
COPY ["Shared/Shared.csproj", "Shared/"]

RUN dotnet restore "ParkingService/ParkingService.WebAPI.csproj"

COPY . .
RUN dotnet build "ParkingService/ParkingService.WebAPI.csproj" -c Release -o /app/build
RUN dotnet publish "ParkingService/ParkingService.WebAPI.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "ParkingService.WebAPI.dll"]