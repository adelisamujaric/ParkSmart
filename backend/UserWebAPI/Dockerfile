FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY ["UserWebAPI/UserService.WebAPI.csproj", "UserWebAPI/"]
COPY ["UserServices/UserService.Application.csproj", "UserServices/"]
COPY ["UserModules/UserService.Domain.csproj", "UserModules/"]
COPY ["UserInfrastructure/UserService.Infrastructure.csproj", "UserInfrastructure/"]
COPY ["Shared/Shared.csproj", "Shared/"]

RUN dotnet restore "UserWebAPI/UserService.WebAPI.csproj"

COPY . .
RUN dotnet build "UserWebAPI/UserService.WebAPI.csproj" -c Release -o /app/build
RUN dotnet publish "UserWebAPI/UserService.WebAPI.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "UserService.WebAPI.dll"]