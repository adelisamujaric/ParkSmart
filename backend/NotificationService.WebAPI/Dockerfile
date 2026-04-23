FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY ["NotificationService.WebAPI/NotificationService.WebAPI.csproj", "NotificationService.WebAPI/"]
COPY ["NotificationService.Application/NotificationService.Application.csproj", "NotificationService.Application/"]
COPY ["NotificationService.Domain/NotificationService.Domain.csproj", "NotificationService.Domain/"]
COPY ["NotificationService.Infrastructure/NotificationService.Infrastructure.csproj", "NotificationService.Infrastructure/"]
COPY ["Shared/Shared.csproj", "Shared/"]

RUN dotnet restore "NotificationService.WebAPI/NotificationService.WebAPI.csproj"

COPY . .
RUN dotnet build "NotificationService.WebAPI/NotificationService.WebAPI.csproj" -c Release -o /app/build
RUN dotnet publish "NotificationService.WebAPI/NotificationService.WebAPI.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "NotificationService.WebAPI.dll"]