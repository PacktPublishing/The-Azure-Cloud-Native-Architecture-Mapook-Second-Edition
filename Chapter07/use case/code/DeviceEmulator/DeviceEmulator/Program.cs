using System;
using System.Text.Json;
using System.Threading.Tasks;
using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Producer;

class Program
{
    
    private const string eventHubName = "temperatures";
    private static readonly string[] deviceIds = { "store01-fridgeA", "store01-fridgeB", "store02-freezerA" };
    private static readonly Random random = new();

    static async Task Main(string[] args)
    {
        string connectionString = "";
        
        if (args.Length == 0 || string.IsNullOrEmpty(args[0]))
            throw new ApplicationException("Usage: ./DeviceEmulator <event hub connection string>");
        connectionString = args[0];
        var producerClient = new EventHubProducerClient(connectionString, eventHubName);

        while (true)
        {
            using EventDataBatch eventBatch = await producerClient.CreateBatchAsync();

            foreach (var deviceId in deviceIds)
            {
                var payload = new
                {
                    deviceId,
                    storeId = deviceId.Split('-')[0],
                    temperature = Math.Round(5 + 5 * random.NextDouble(), 2), // e.g., 5–10 °C
                    humidity = random.Next(60, 90),
                    timestamp = DateTime.UtcNow
                };

                string json = JsonSerializer.Serialize(payload);
                var eventData = new EventData(json);

                if (!eventBatch.TryAdd(eventData))
                {
                    Console.WriteLine("Event too large, skipping.");
                    continue;
                }

                Console.WriteLine($"Sending: {json}");
            }

            await producerClient.SendAsync(eventBatch);
            await Task.Delay(TimeSpan.FromSeconds(5)); 
        }
    }
}
