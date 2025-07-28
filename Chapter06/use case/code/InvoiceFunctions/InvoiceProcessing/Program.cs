using Microsoft.Azure.Functions.Worker.Configuration;
using Microsoft.Extensions.Hosting;
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using OpenTelemetry.Trace;
using OpenTelemetry.Logs;

using Microsoft.Extensions.DependencyInjection;
using Azure.Monitor.OpenTelemetry.Exporter;
using Microsoft.Extensions.Configuration;
using Azure.Identity;
using Azure.Messaging.ServiceBus;
using InvoiceProcessing;

var host = new HostBuilder()
    .ConfigureFunctionsWorkerDefaults()
    .ConfigureAppConfiguration((hostingContext, config) =>
    {
        config.AddEnvironmentVariables();
    })
    .ConfigureServices((context, services) =>
    {
        var configuration = context.Configuration;
        var aiConnectionString = configuration["APPLICATIONINSIGHTS_CONNECTION_STRING"];
        var serviceBusFQDN = configuration["ServiceBusConnectionFQDN"];
        var managedIdentityId = configuration["ServiceBusConnectionclientId"];
        
        services.AddOpenTelemetry()
            .WithTracing(builder => builder
                .SetResourceBuilder(ResourceBuilder.CreateDefault().AddService("invoices"))
                .AddSource("Microsoft.Azure.Functions.Worker")
                .AddAspNetCoreInstrumentation()
                .AddHttpClientInstrumentation()
                .AddAzureMonitorTraceExporter(options =>
                {
                    options.ConnectionString = aiConnectionString;
                }))
            .WithMetrics(builder => builder
                .AddAspNetCoreInstrumentation()
                .AddHttpClientInstrumentation()                      
                .AddAzureMonitorMetricExporter(options =>
                {
                    options.ConnectionString = aiConnectionString;
                }));
        //using straight Service Bus SDK because currently output binding does not support setting custom properties.
        //you will find examples online but they all fail.
        services.AddSingleton(serviceProvider =>
        {
            
            var credential = new DefaultAzureCredential(new DefaultAzureCredentialOptions
            {
                ManagedIdentityClientId = managedIdentityId
            });

            return new ServiceBusClient(serviceBusFQDN, credential);
        });
        services.AddScoped<InvoicePublisher>();
    })
    
    .Build();

host.Run();