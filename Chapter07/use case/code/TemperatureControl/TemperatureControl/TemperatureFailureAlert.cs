using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace TemperatureControl;

public class TemperatureFailureAlert
{
    //private readonly ILogger<TemperatureFailureAlert> _logger;

    public TemperatureFailureAlert()
    {
    
    }

    [Function("TemperatureFailureAlert")]
    public async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Function, "post", Route = null)] HttpRequest req, FunctionContext context)
    {
        var logger = context.GetLogger("TemperatureFailureAlert");

        try
        {           

            string body = await new StreamReader(req.Body).ReadToEndAsync();
            logger.LogTrace("body is {0}", body);
            if (string.IsNullOrEmpty(body))
                return new BadRequestResult();

            var events = JsonSerializer.Deserialize<List<SensorData>>(body, new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            });

            
            foreach (var e in events)
            {
                logger.LogWarning(
                    "Abnormal temperature {0} detected for Device {1} from store {3} alert: {3}.",
                    e.AvgTemp, e.DeviceId, e.StoreId, e.AlertMessage);
            }

            return new OkResult();
        }
        catch (Exception ex)
        {
            logger.LogError("Exception occurred during function execution {0}. ",ex.Message);
            throw;
        }
    }

}
public class SensorData
{
    public string DeviceId { get; set; }
    public string StoreId { get; set; }
    public DateTime AlertGeneratedAt { get; set; }
    public double AvgTemp { get; set; }
    public string AlertMessage { get; set; }
}