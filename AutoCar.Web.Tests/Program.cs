using System.Net;
using System.Text.Json;
using AutoCar.Web.Controllers;
using AutoCar.Web.Services;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging.Abstractions;

var failed = 0;
async Task Check(string name, HttpStatusCode status, string providerJson, string expectedCode)
{
    var controller = Create(new Stub(_ => Task.FromResult(new HttpResponseMessage(status) { Content = new StringContent(providerJson) })));
    var result = (ObjectResult)await controller.Reply(new("Hello", null, null), default);
    var json = JsonSerializer.SerializeToElement(result.Value);
    var pass = result.StatusCode == 503 && json.GetProperty("code").GetString() == expectedCode;
    Console.WriteLine($"{(pass ? "PASS" : "FAIL")} {name}");
    if (!pass) failed++;
}
await Check("Invalid API key", HttpStatusCode.Unauthorized, "{}", "ai_invalid_key");
await Check("Quota exhausted", HttpStatusCode.TooManyRequests, "{\"error\":{\"code\":\"insufficient_quota\"}}", "ai_quota_exhausted");
await Check("Rate limited", HttpStatusCode.TooManyRequests, "{\"error\":{\"code\":\"rate_limit_exceeded\"}}", "ai_rate_limited");
await Check("Model access", HttpStatusCode.NotFound, "{}", "ai_model_unavailable");
await Check("Non-JSON provider error", HttpStatusCode.BadGateway, "<html>Gateway error</html>", "ai_provider_unavailable");
await Check("Empty output", HttpStatusCode.OK, "{\"output\":[]}", "ai_invalid_response");

var success = Create(new Stub(async request => {
    var body = await request.Content!.ReadAsStringAsync();
    if (!body.Contains("False") || !body.Contains("instructions")) throw new Exception("Missing catalog outage context");
    return new(HttpStatusCode.OK) { Content = new StringContent("{\"output\":[{\"type\":\"message\",\"content\":[{\"type\":\"output_text\",\"text\":\"General guidance\"}]}]}") };
}));
var successResult = (ObjectResult)await success.Reply(new("Hello", null, null), default);
var successJson = JsonSerializer.SerializeToElement(successResult.Value);
var outagePass = successResult.StatusCode == 200 && !successJson.GetProperty("catalogAvailable").GetBoolean();
Console.WriteLine($"{(outagePass ? "PASS" : "FAIL")} Catalog outage still allows AI guidance");
if (!outagePass) failed++;

var disconnected = Create(new Stub(_ => throw new HttpRequestException("Network blocked")));
var network = (ObjectResult)await disconnected.Reply(new("Hello", null, null), default);
var networkPass = JsonSerializer.SerializeToElement(network.Value).GetProperty("code").GetString() == "ai_network_error";
Console.WriteLine($"{(networkPass ? "PASS" : "FAIL")} Network error distinguished");
if (!networkPass) failed++;

var local = Create(new Stub(async request => {
    using var body = JsonDocument.Parse(await request.Content!.ReadAsStringAsync());
    if (request.RequestUri!.AbsolutePath != "/api/chat" || request.Headers.Authorization != null || body.RootElement.GetProperty("stream").GetBoolean())
        throw new Exception("Local AI must call Ollama without API credentials or streaming");
    if (body.RootElement.GetProperty("messages")[0].GetProperty("role").GetString() != "system")
        throw new Exception("Missing system grounding");
    return new(HttpStatusCode.OK) { Content = new StringContent("{\"message\":{\"role\":\"assistant\",\"content\":\"Hello from local AI\"}}") };
}), "Ollama");
var localResult = (ObjectResult)await local.Reply(new("Hello", null, null), default);
var localPass = localResult.StatusCode == 200 && JsonSerializer.SerializeToElement(localResult.Value).GetProperty("provider").GetString() == "Ollama";
Console.WriteLine($"{(localPass ? "PASS" : "FAIL")} Free local AI works without API key");
if (!localPass) failed++;

foreach (var test in new[] { "missing-model", "offline", "empty-response" }) {
    var unavailable = Create(new Stub(_ => test == "offline" ? throw new HttpRequestException("Offline") : Task.FromResult(new HttpResponseMessage(test == "missing-model" ? HttpStatusCode.NotFound : HttpStatusCode.OK) { Content = new StringContent("{}") })), "Ollama");
    var unavailableResult = (ObjectResult)await unavailable.Reply(new("Hello", null, null), default);
    var pass = unavailableResult.StatusCode == 503 && JsonSerializer.SerializeToElement(unavailableResult.Value).GetProperty("code").GetString() == "local_ai_unavailable";
    Console.WriteLine($"{(pass ? "PASS" : "FAIL")} Local AI {test} gives setup guidance");
    if (!pass) failed++;
}
Environment.ExitCode = failed == 0 ? 0 : 1;

static ChatController Create(HttpMessageHandler provider, string name = "OpenAI")
{
    var config = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?> { ["AI:Provider"] = name, ["AI:ApiKey"] = name == "OpenAI" ? "test-placeholder" : null, ["AI:Model"] = "test-model" }).Build();
    var catalog = new AutoCarClient(new HttpClient(new Stub(_ => throw new HttpRequestException("Catalog offline"))) { BaseAddress = new Uri("http://catalog.test/") }, new HttpContextAccessor(), new SessionVault());
    return new ChatController(catalog, new ClientFactory(new HttpClient(provider)), config, NullLogger<ChatController>.Instance);
}
sealed class ClientFactory(HttpClient client) : IHttpClientFactory
{
    public HttpClient CreateClient(string name) => client;
}
sealed class Stub(Func<HttpRequestMessage, Task<HttpResponseMessage>> send) : HttpMessageHandler
{
    protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken cancellationToken) => send(request);
}
