using RabbitMQ.Client;
using System.Text;
using System.Text.Json;

namespace Shared.RabbitMQ
{
    public class RabbitMQPublisherSingleton : IAsyncDisposable
    {
        private IConnection? _connection;
        private IChannel? _channel;
        private readonly string _hostName;
        private readonly SemaphoreSlim _semaphore = new(1, 1);

        public RabbitMQPublisherSingleton(string hostName = "localhost")
        {
            _hostName = hostName;
        }

        private async Task EnsureConnectedAsync()
        {
            if (_connection != null && _connection.IsOpen) return;

            await _semaphore.WaitAsync();
            try
            {
                if (_connection != null && _connection.IsOpen) return;

                var factory = new ConnectionFactory { HostName = _hostName };
                _connection = await factory.CreateConnectionAsync();
                _channel = await _connection.CreateChannelAsync();
            }
            finally
            {
                _semaphore.Release();
            }
        }

        public async Task PublishAsync<T>(string queueName, T message)
        {
            await EnsureConnectedAsync();

            await _channel!.QueueDeclareAsync(
                queue: queueName,
                durable: true,
                exclusive: false,
                autoDelete: false,
                arguments: null);

            var json = JsonSerializer.Serialize(message);
            var body = Encoding.UTF8.GetBytes(json);

            var properties = new BasicProperties
            {
                Persistent = true
            };

            await _channel.BasicPublishAsync(
                exchange: "",
                routingKey: queueName,
                mandatory: false,
                basicProperties: properties,
                body: body);
        }

        public async ValueTask DisposeAsync()
        {
            if (_channel != null) await _channel.CloseAsync();
            if (_connection != null) await _connection.CloseAsync();
        }
    }
}