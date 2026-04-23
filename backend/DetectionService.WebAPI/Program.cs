using DetectionService.Application.Services;
using DetectionService.Domain.Interfaces;
using DetectionService.Infrastructure.Data;
using DetectionService.Infrastructure.Repositories;
using DetectionService.Infrastructure.Services;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
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
        Title = "DetectionService API",
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


builder.Services.AddDbContext<DetectionDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection"))); 

builder.Services.AddHttpClient<MLService>();
builder.Services.AddScoped<IDetectionLogRepository, DetectionLogRepository>();
builder.Services.AddScoped<IDroneRepository, DroneRepository>();
builder.Services.AddScoped<ICameraRepository, CameraRepository>();

builder.Services.AddScoped<DetectionAppService>();
builder.Services.AddScoped<DroneAppService>();
builder.Services.AddScoped<CameraAppService>();

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader());
});

builder.Services.AddSingleton<RabbitMQPublisherSingleton>(sp =>
    new RabbitMQPublisherSingleton(
        builder.Configuration["RabbitMQ:Host"] ?? "localhost"
    ));

//-----------------------------------------------------------------------------------------------
// NOTE: DangerousAcceptAnyServerCertificateValidator is used only in development.
// In production, a valid SSL certificate should be used.

builder.Services.AddHttpClient<ParkingServiceClient>(client =>
{
    client.BaseAddress = new Uri(builder.Configuration["ParkingService:BaseUrl"]!);
}).ConfigurePrimaryHttpMessageHandler(() => new HttpClientHandler
{
    ServerCertificateCustomValidationCallback = HttpClientHandler.DangerousAcceptAnyServerCertificateValidator
});
//-----------------------------------------------------------------------------------------------

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

app.UseAuthentication();

app.UseAuthorization();

app.MapControllers();

// Auto - migrate i seed pri startu
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<DetectionDbContext>();
    db.Database.Migrate();
    SeedData.Initialize(db);
}

app.Run();
