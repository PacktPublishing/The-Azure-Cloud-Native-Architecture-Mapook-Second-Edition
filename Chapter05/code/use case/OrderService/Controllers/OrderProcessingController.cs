using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using CloudNative.CloudEvents;
using Dapr;
using Dapr.Client;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using Models;
using Newtonsoft.Json;

namespace OrderService.Controllers
{
    /// <summary>
    /// this code is for illustration purpose only!
    /// </summary>
    [ApiController]  
    public class OrderController : ControllerBase
    {
        private readonly DaprClient _dapr;
        private readonly ILogger<OrderController> _logger;

        public OrderController(ILogger<OrderController> logger, DaprClient dapr)
        {
            _logger = logger;
            _dapr = dapr;
        }
        [Topic("daprsb", "order.placed")] //this route subscribes to the order topic
        [HttpPost]
        [Route("dapr")]
        public async Task<IActionResult> ProcessOrder([FromBody] Order order)
        {
            
            _logger.LogInformation($"Order with id {order.Id} processed!");
            //we'll pretend it is already paid
            _logger.LogInformation($"Order with id {order.Id} paid!");
            await PublishOrderPaidEvent(order.Id, OrderEvent.EventType.Paid);
            return StatusCode(StatusCodes.Status201Created);
        }

        [HttpPost]
        [Route("order")] //the HTTP route creates a message to the order topic
        public async Task<IActionResult> Order([FromBody] Order order, [FromServices] DaprClient daprClient)
        {
            _logger.LogInformation($"Order with id {order.Id} created!");
            await _dapr.PublishEventAsync<Order>("daprsb", "order.placed", order);
            return StatusCode(StatusCodes.Status201Created);
        }
        /// <summary>
        /// this method publishes an order event to the shipping topic (we'll pretend it's already paid)
        /// </summary>
        /// <param name="OrderId"></param>
        /// <param name="type"></param>
        /// <returns></returns>
        async Task<IActionResult> PublishOrderPaidEvent(Guid OrderId, OrderEvent.EventType type)
        {
            var ev = new OrderEvent
            {
                id = OrderId,
                name = "OrderEvent",
                type = type
            };
            await _dapr.PublishEventAsync<OrderEvent>("daprsb", "order.paid", ev);
            return Ok();
        }     

    }
}
