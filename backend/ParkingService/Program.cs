using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using ParkingService.Application;
using ParkingService.Domain.Interfaces;
using ParkingService.Infrastructure.Data;
using ParkingService.Infrastructure.Repositories;
using ParkingService.Infrastructure.Services;
using ParkingService.WebAPI.BackgroundServices;
using Shared.Middleware;
using Shared.RabbitMQ;
using System.Text;

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.

builder.Services.AddControllers();
// Learn more about configuring Swagger/OpenAPI at https://aka.ms/aspnetcore/swashbuckle
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "ParkingService API",
        Version = "v1"
    });

    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        In = ParameterLocation.Header,
        Description = "Enter JWT token",
        Name = "Authorization",
        Type = SecuritySchemeType.ApiKey
    });

    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            new string[] {}
        }
    });
});

builder.Services.AddDbContext<ParkingDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection"))); //baza podataka

builder.Services.AddHostedService<ParkingEventConsumer>();
builder.Services.AddHostedService<TicketExpiryChecker>();

builder.Services.AddScoped<IParkingLotRepository, ParkingLotRepository>();
builder.Services.AddScoped<IParkingSpotRepository, ParkingSpotRepository>();
builder.Services.AddScoped<IParkingReservationRepository, ParkingReservationRepository>();
builder.Services.AddScoped<IParkingTicketRepository, ParkingTicketRepository>();
builder.Services.AddScoped<IParkingViolationRepository, ParkingViolationRepository>();
builder.Services.AddScoped<IViolationConfigRepository, ViolationConfigRepository>();

builder.Services.AddScoped<ViolationConfigService>();
builder.Services.AddScoped<ViolationService>();
builder.Services.AddScoped<ParkingTicketService>();
builder.Services.AddScoped<ParkingLotService>();
builder.Services.AddScoped<ParkingSpotService>();
builder.Services.AddScoped<ReservationService>();
builder.Services.AddHostedService<PaymentDeadlineChecker>();
builder.Services.AddMemoryCache(); 

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader());
});

builder.Services.AddHostedService<TicketStatusUpdater>();
builder.Services.AddHostedService<ReservationExpiryChecker>();

builder.Services.AddHttpClient<UserServiceClient>(client =>
{
    client.BaseAddress = new Uri(builder.Configuration["ServiceUrls:UserService"] ?? "http://localhost:5072");
});


var key = Encoding.UTF8.GetBytes(builder.Configuration["JwtSettings:Key"]);

builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(key),
            ValidateIssuer = false,
            ValidateAudience = false
        };
    });

builder.Services.AddSingleton<RabbitMQPublisherSingleton>(sp =>
    new RabbitMQPublisherSingleton(
        builder.Configuration["RabbitMQ:Host"] ?? "localhost"
    ));

builder.Services.AddAuthorization();


var app = builder.Build();
app.UseMiddleware<ExceptionHandlingMiddleware>();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

//app.UseHttpsRedirection();

app.UseCors("AllowAll");

app.UseAuthorization();

app.MapControllers();

// Auto - migrate i seed pri startu
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<ParkingDbContext>();
    db.Database.Migrate();
    SeedData.Initialize(db);
}

app.Run();
