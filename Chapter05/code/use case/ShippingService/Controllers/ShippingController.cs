using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using Dapr;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Models;
using Dapr.Client;
using Newtonsoft.Json.Linq;
using Microsoft.Extensions.Configuration;

using Newtonsoft.Json;
using Grpc.Net.Client.Configuration;

using System.Net;

using System.Reflection;


namespace TrackingService.Controllers
{
    /// <summary>
    /// this code is for illustration purpose only!
    /// </summary>
    [ApiController]   
    public class ShippingController : ControllerBase
    {
        private readonly DaprClient _dapr;

        private readonly ILogger<ShippingController> _logger;

        public ShippingController(ILogger<ShippingController> logger, DaprClient dapr)
        {
            _logger = logger;
            _dapr = dapr;
        }      

        [Topic("daprsb", "order.paid")]
        [HttpPost]
        [Route("dapr")]      
        public async Task<IActionResult> ProcessOrderEvent([FromBody] OrderEvent ev)
        {

            _logger.LogInformation($"Received new event");
            _logger.LogInformation("{0} {1} {2}", ev.id, ev.name, ev.type);

            switch (ev.type)
            {
                case OrderEvent.EventType.Paid:
                    if (await GetOrder(ev.id)) //get details about the order
                    {
                        _logger.LogInformation($"Starting shipping process for order {ev.id}!");
                        await PublishShippingEvent(Guid.NewGuid(), ev.id, ShippingEvent.EventType.Shipped);
                    }
                    else
                    {
                        _logger.LogInformation($"order {ev.id} not found!");
                    }
                    
                    break;
                case OrderEvent.EventType.Updated:
                    if (await GetOrder(ev.id))
                    {
                        _logger.LogInformation($"Checking shipping process impact for order {ev.id}!");
                        await PublishShippingEvent(Guid.NewGuid(), ev.id, ShippingEvent.EventType.Updated);
                    }
                    else
                    {
                        _logger.LogInformation($"order {ev.id} not found, cancelling shipping process if any!");
                    }
                    
                    break;
                case OrderEvent.EventType.Cancelled:
                    _logger.LogInformation($"Cancelling shipping process for order {ev.id}!");
                    await PublishShippingEvent(Guid.NewGuid(), ev.id, ShippingEvent.EventType.Cancelled);
                    break;
            }

            return Ok();
        }
      
        async Task<bool> GetOrder(Guid id)
        {
            try
            {
                var request = _dapr.CreateInvokeMethodRequest<object>(
                    HttpMethod.Get, "orderquery", id.ToString(), null);
                var response = await _dapr.InvokeMethodWithResponseAsync(request);
                
                if (response.StatusCode == HttpStatusCode.NotFound)                
                    return false;
                    
                
                return true;
            }
            catch (Exception ex)
            {
                //should handle the other cases or rely on retry policies of a service mesh
                return false;                
            }
            
        }

        async Task<IActionResult> PublishShippingEvent(Guid ShippingId, Guid OrderId, ShippingEvent.EventType type)
        {
            var ev = new ShippingEvent
            {
                id = ShippingId,
                OrderId = OrderId,
                name = "ShippingEvent",
                type = type
            };
            await _dapr.PublishEventAsync<ShippingEvent>("daprsb", "order.shipped", ev);
            _logger.LogInformation($"shipping {ShippingId} complete!");
            return Ok();
        }

    }
}
