using Microsoft.AspNetCore.Http.Features;
using OpenTelemetry.Metrics;
using OpenTelemetry.Resources;
using Serilog;

Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Information()
    .MinimumLevel.Override("Microsoft", Serilog.Events.LogEventLevel.Warning)
    .MinimumLevel.Override("Microsoft.Hosting", Serilog.Events.LogEventLevel.Information)
    .Enrich.FromLogContext()
    .WriteTo.Console()
    .CreateLogger();

var builder = WebApplication.CreateBuilder(args);

builder.Host.UseSerilog();

builder.Services.AddOpenApi();
builder.Services.AddOpenTelemetry()
    .ConfigureResource(resource => resource.AddService(serviceName: "some-service", serviceVersion: "0.0.1"))
    .WithMetrics(metrics =>
    {
        metrics.AddAspNetCoreInstrumentation();
        metrics.AddPrometheusExporter();
    });

var app = builder.Build();

app.MapOpenApi();
app.UseSerilogRequestLogging();
app.MapPrometheusScrapingEndpoint();
app.Use(async (ctx, next) =>
{
    var tagsFeature = ctx.Features.Get<IHttpMetricsTagsFeature>();
    if (tagsFeature != null && ctx.Request.Headers.TryGetValue("X-APP-CUSTOMER", out var customers))
    {
        tagsFeature.Tags.Add(new KeyValuePair<string, object?>("customer", customers[0]));
    }
    await next.Invoke();
});
app.MapGet("/api/documents/{documentId:int}", async (int documentId) =>
{
    await Task.Delay(Random.Shared.Next(10, 100));
    return Random.Shared.Next(100, 501) switch
    {
        400 => Results.BadRequest(),
        401 => Results.Unauthorized(),
        404 => Results.NotFound(),
        500 => Results.InternalServerError(),
        _ => Results.Ok(new { Id = documentId, Content = $"Content of the {documentId} document." }),
    };
});
app.MapPut("/api/documents/", async () =>
{
    await Task.Delay(Random.Shared.Next(100, 500));
    return Random.Shared.Next(100, 501) switch
    {
        400 => Results.BadRequest(),
        403 => Results.Forbid(),
        409 => Results.Conflict(),
        500 => Results.InternalServerError(),
        _ => Results.Ok(new { Id = Random.Shared.Next() }),
    };
});

app.Run();