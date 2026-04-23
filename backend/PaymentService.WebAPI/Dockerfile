FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS base
WORKDIR /app
EXPOSE 8080

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY ["PaymentService.WebAPI/PaymentService.WebAPI.csproj", "PaymentService.WebAPI/"]
COPY ["PaymentService.Application/PaymentService.Application.csproj", "PaymentService.Application/"]
COPY ["PaymentService.Domain/PaymentService.Domain.csproj", "PaymentService.Domain/"]
COPY ["PaymentService.Infrastructure/PaymentService.Infrastructure.csproj", "PaymentService.Infrastructure/"]
COPY ["Shared/Shared.csproj", "Shared/"]

RUN dotnet restore "PaymentService.WebAPI/PaymentService.WebAPI.csproj"

COPY . .
RUN dotnet build "PaymentService.WebAPI/PaymentService.WebAPI.csproj" -c Release -o /app/build
RUN dotnet publish "PaymentService.WebAPI/PaymentService.WebAPI.csproj" -c Release -o /app/publish

FROM base AS final
WORKDIR /app
COPY --from=build /app/publish .
ENTRYPOINT ["dotnet", "PaymentService.WebAPI.dll"]