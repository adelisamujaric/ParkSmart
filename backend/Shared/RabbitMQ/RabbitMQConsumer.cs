using Microsoft.Extensions.Logging;
using RabbitMQ.Client;
using RabbitMQ.Client.Events;
using System.Text;
using System.Text.Json;

namespace Shared.RabbitMQ
{
    public class RabbitMQConsumer : IAsyncDisposable
    {
        private readonly IConnection _connection;
        private readonly IChannel _channel;
        private readonly ILogger? _logger;

        private RabbitMQConsumer(IConnection connection, IChannel channel, ILogger? logger = null)
        {
            _connection = connection;
            _channel = channel;
            _logger = logger;
        }

        public static async Task<RabbitMQConsumer> CreateAsync(string hostName = "localhost", ILogger? logger = null)
        {
            var factory = new ConnectionFactory { HostName = hostName };
            IConnection connection = null;
            int retries = 10;
            int delaySeconds = 5;

            for (int i = 0; i < retries; i++)
            {
                try
                {
                    connection = await factory.CreateConnectionAsync();
                    break;
                }
                catch (Exception ex)
                {
                    logger?.LogWarning(ex, "RabbitMQ connection attempt {Attempt}/{Total} failed", i + 1, retries);
                    if (i == retries - 1) throw;
                    await Task.Delay(TimeSpan.FromSeconds(delaySeconds));
                }
            }

            var channel = await connection.CreateChannelAsync();
            return new RabbitMQConsumer(connection, channel, logger);
        }

        public async Task SubscribeAsync<T>(string queueName, Func<T, Task> handler)
        {
            await _channel.QueueDeclareAsync(
                queue: queueName,
                durable: true,
                exclusive: false,
                autoDelete: false,
                arguments: null);

            var consumer = new AsyncEventingBasicConsumer(_channel);
            consumer.ReceivedAsync += async (model, ea) =>
            {
                int maxRetries = 4;
                int delayMs = 1000; // počinje sa 1s

                for (int attempt = 1; attempt <= maxRetries; attempt++)
                {
                    try
                    {
                        var body = ea.Body.ToArray();
                        var json = Encoding.UTF8.GetString(body);
                        var message = JsonSerializer.Deserialize<T>(json);
                        if (message != null)
                            await handler(message);

                        await _channel.BasicAckAsync(ea.DeliveryTag, false);
                        return; // uspješno, izlazi iz petlje
                    }
                    catch (Exception ex)
                    {
                        if (attempt == maxRetries)
                        {
                            // Sve ponovne pokušaje iscrpili — loguj i ack da ne blokira queue
                            _logger?.LogError(ex,
                                "RabbitMQ consumer failed after {MaxRetries} attempts on queue {Queue}. Message will be acknowledged.",
                                maxRetries, queueName);
                            await _channel.BasicAckAsync(ea.DeliveryTag, false);
                        }
                        else
                        {
                            // Exponential backoff: 1s -> 2s -> 4s -> 8s
                            _logger?.LogWarning(ex,
                                "RabbitMQ consumer error on queue {Queue}, attempt {Attempt}/{MaxRetries}. Retrying in {Delay}ms.",
                                queueName, attempt, maxRetries, delayMs);
                            await Task.Delay(delayMs);
                            delayMs *= 2; // exponential backoff
                        }
                    }
                }
            };

            await _channel.BasicConsumeAsync(
                queue: queueName,
                autoAck: false,
                consumer: consumer);
        }

        public async ValueTask DisposeAsync()
        {
            await _channel.CloseAsync();
            await _connection.CloseAsync();
        }
    }
}