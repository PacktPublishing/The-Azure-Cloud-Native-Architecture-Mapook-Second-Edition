using System.IO;
using System.Text.Json;
using System.Threading.Tasks;
using Azure.Messaging.ServiceBus;
using Azure.Storage.Blobs;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;


namespace InvoiceProcessing
{
    public class InvoiceFunctions
    {
        private readonly ILogger<InvoiceFunctions> _logger;
        private readonly InvoicePublisher _publisher;

        public InvoiceFunctions(ILogger<InvoiceFunctions> logger, InvoicePublisher publisher)
        {
            _logger = logger;
            _publisher = publisher;
        }

        [Function(nameof(InvoiceFunctions))]        
        public async Task InvoiceLanded([BlobTrigger("invoices/{name}", Connection = "AzureWebJobsBusinessStorage")] BlobClient blobClient,
        string name, 
        FunctionContext context)
        {
            string blobUrl = blobClient.Uri.ToString();
            _logger.LogInformation($"Blob trigger function processed blob\n Name:{name} \n");

            //pretend to handle the blob. The below properties would result fromt the parsing           
            // if you add a try/catch, make sure to throw again the exception for the function runtime to catch it as well, else
            // the function execution will be seen as green!
            var payload = new
            {
                BlobUrl = blobUrl                
            };
            var json = JsonSerializer.Serialize(payload);
            _logger.LogInformation(json);
            var message = new ServiceBusMessage(BinaryData.FromString(json))            {
                
                Subject = "CustomerInvoice",
                ContentType = "application/json"
            };

            await _publisher.PublishInvoiceAsync(
                blobUrl, 
                (new Random().Next(10) < 5) ? true : false, 
                new Random().Next(15000),"v1");

        }
    }
}
