using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Migrations.Internal;
using PaymentService.Application.Services;
using PaymentService.Domain.Interfaces;
using PaymentService.Infrastructure.Data;
using PaymentService.Infrastructure.Repositories;
using PaymentService.WebAPI.BackgroundServices;
using Shared.Middleware;
using Shared.RabbitMQ;
using Stripe;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// Database
builder.Services.AddDbContext<PaymentDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("DefaultConnection")));

builder.Services.AddHostedService<PaymentEventConsumer>();

// Stripe konfiguracija
StripeConfiguration.ApiKey = builder.Configuration["StripeSettings:SecretKey"];

// Repositories
builder.Services.AddScoped<IParkingPaymentRepository, ParkingPaymentRepository>();
builder.Services.AddScoped<IViolationPaymentRepository, ViolationPaymentRepository>();
builder.Services.AddScoped<IReservationPaymentRepository, ReservationPaymentRepository>();

// Services
builder.Services.AddScoped<ParkingPaymentService>();
builder.Services.AddScoped<ViolationPaymentService>();
builder.Services.AddScoped<StripeService>();
builder.Services.AddScoped<ReservationPaymentService>();

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


var app = builder.Build();
app.UseMiddleware<ExceptionHandlingMiddleware>();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

//app.UseHttpsRedirection();

app.UseCors("AllowAll");
app.UseAuthorization();
app.MapControllers();

// Auto - migrate pri startu
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<PaymentDbContext>();
    db.Database.Migrate();
}

app.Run();