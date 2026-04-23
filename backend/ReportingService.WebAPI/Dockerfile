FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY ["ReportingService.WebAPI/ReportingService.WebAPI.csproj", "ReportingService.WebAPI/"]
COPY ["ReportingService.Application/ReportingService.Application.csproj", "ReportingService.Application/"]
COPY ["ReportingService.Domain/ReportingService.Domain.csproj", "ReportingService.Domain/"]
COPY ["ReportingService.Infrastructure/ReportingService.Infrastructure.csproj", "ReportingService.Infrastructure/"]
COPY ["Shared/Shared.csproj", "Shared/"]

RUN dotnet restore "ReportingService.WebAPI/ReportingService.WebAPI.csproj"

COPY . .
RUN dotnet build "ReportingService.WebAPI/ReportingService.WebAPI.csproj" -c Release -o /app/build
RUN dotnet publish "ReportingService.WebAPI/ReportingService.WebAPI.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "ReportingService.WebAPI.dll"]