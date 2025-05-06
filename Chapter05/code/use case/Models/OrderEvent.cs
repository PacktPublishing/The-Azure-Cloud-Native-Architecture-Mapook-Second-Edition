using System;
using System.Collections.Generic;
using System.Text;

namespace Models
{
    public class OrderEvent
    {
        public Guid id { get; set; }
        public string name { get; set; }
        public enum EventType { Created, Cancelled, Updated, Paid}
        public EventType type { get; set; }
    }
    public class ShippingEvent
    {
        public Guid id { get; set; }
        public Guid OrderId { get; set; }
        public string name { get; set; }
        public enum EventType { Shipped, Cancelled, Updated }
        public EventType type { get; set; }
    }

}
