using System.Net;
using System.Net.Http.Headers;
using System.Text.Json;
using AutoCar.Shared.Contracts;
using Microsoft.AspNetCore.Authentication;
using Microsoft.AspNetCore.Authentication.Cookies;
namespace AutoCar.Web.Services;
public class ApiException(int status,string message) : Exception(message){public int Status { get; }=status;}
public class AutoCarClient(HttpClient client,IHttpContextAccessor accessor,SessionVault vault)
{
    public static readonly JsonSerializerOptions Json=new(JsonSerializerDefaults.Web);
    public Task<HttpResponseMessage> Image(string name)=>client.GetAsync("uploads/"+Uri.EscapeDataString(name));
    public Task<HttpResponseMessage> CatalogImage(string name)=>client.GetAsync("catalog/"+Uri.EscapeDataString(name));
    public async Task<HttpResponseMessage> Send(HttpMethod method,string path,HttpContent? content=null)
    {
        var entry=vault.Get(accessor.HttpContext?.User.FindFirst("session")?.Value);
        if(entry!=null)
        {
            await entry.Gate.WaitAsync();
            try
            {
                if(entry.Token.ExpiresAt<=DateTimeOffset.UtcNow.AddSeconds(30))
                {
                    using var refreshed=await client.PostAsJsonAsync("api/auth/refresh",new RefreshInput(entry.Token.RefreshToken));
                    if(!refreshed.IsSuccessStatusCode){await Expire();throw new ApiException(401,"Phiên đăng nhập hết hạn. Vui lòng đăng nhập lại.");}
                    entry.Token=(await refreshed.Content.ReadFromJsonAsync<TokenDto>())!;
                }
            }
            finally{entry.Gate.Release();}
        }
        var request=new HttpRequestMessage(method,"api/"+path){Content=content};
        if(entry!=null)request.Headers.Authorization=new AuthenticationHeaderValue("Bearer",entry.Token.AccessToken);
        var response=await client.SendAsync(request);
        if(response.StatusCode==HttpStatusCode.Unauthorized&&entry!=null)await Expire();
        return response;
    }
    private async Task Expire()
    {
        var context=accessor.HttpContext;if(context==null)return;
        var key=context.User.FindFirst("session")?.Value;if(key!=null)vault.Remove(key);
        await context.SignOutAsync(CookieAuthenticationDefaults.AuthenticationScheme);
        context.User=new System.Security.Claims.ClaimsPrincipal(new System.Security.Claims.ClaimsIdentity());
    }
    public async Task<T> Get<T>(string path)
    {
        using var response=await Send(HttpMethod.Get,path);await Ensure(response);return (await response.Content.ReadFromJsonAsync<T>(Json))!;
    }
    public async Task<TokenDto> Authenticate(string action,object input)
    {
        using var response=await client.PostAsJsonAsync("api/auth/"+action,input);await Ensure(response);return (await response.Content.ReadFromJsonAsync<TokenDto>(Json))!;
    }
    public static async Task Ensure(HttpResponseMessage response)
    {
        if(response.IsSuccessStatusCode)return;var title="Không thể kết nối dịch vụ. Vui lòng thử lại.";
        try{var json=await response.Content.ReadFromJsonAsync<JsonElement>();if(json.TryGetProperty("title",out var t))title=t.GetString()??title;if(json.TryGetProperty("errors",out var errors))title=string.Join(" ",errors.EnumerateObject().SelectMany(x=>x.Value.EnumerateArray()).Select(x=>x.GetString()));}catch(JsonException){}
        throw new ApiException((int)response.StatusCode,title);
    }
}
