using RabbitMQ.Client;
using System.Text;
using System.Text.Json;

namespace Shared.RabbitMQ
{
    public class RabbitMQPublisher : IAsyncDisposable
    {
        private readonly IConnection _connection;
        private readonly IChannel _channel;

        private RabbitMQPublisher(IConnection connection, IChannel channel)
        {
            _connection = connection;
            _channel = channel;
        }
        //----------------------------------------------------------------------------------------

        public static async Task<RabbitMQPublisher> CreateAsync(string hostName = "localhost")
        {
            var factory = new ConnectionFactory { HostName = hostName };
            var connection = await factory.CreateConnectionAsync();
            var channel = await connection.CreateChannelAsync();
            return new RabbitMQPublisher(connection, channel);
        }
        //----------------------------------------------------------------------------------------

        public async Task PublishAsync<T>(string queueName, T message)
        {
            await _channel.QueueDeclareAsync(
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
        //----------------------------------------------------------------------------------------

        public async ValueTask DisposeAsync()
        {
            await _channel.CloseAsync();
            await _connection.CloseAsync();
        }
        //----------------------------------------------------------------------------------------

    }
}