using Azure.Messaging.ServiceBus;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.Json;
using System.Threading.Tasks;

namespace InvoiceProcessing
{
    public class InvoicePublisher
    {
        private readonly ServiceBusClient _client;

        public InvoicePublisher(ServiceBusClient client)
        {
            _client = client;
        }

        public async Task PublishInvoiceAsync(string blobUrl, bool valid,double amount, string version, string topicName = "invoices")
        {
            var payload = new
            {
                BlobUrl = blobUrl,
                InvoiceType = "International"
            };

            string json = JsonSerializer.Serialize(payload);

            var message = new ServiceBusMessage(BinaryData.FromString(json))
            {
                Subject = "CustomerInvoice",
                ContentType = "application/json"
            };

            message.ApplicationProperties["valid"] = valid;
            message.ApplicationProperties["amount"] = amount;
            message.ApplicationProperties["version"] = version;

            var sender = _client.CreateSender(topicName);
            await sender.SendMessageAsync(message);
        }
    }
}
