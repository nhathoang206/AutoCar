using AutoCar.Web.Services;
using Microsoft.AspNetCore.Mvc;
namespace AutoCar.Web.Controllers;
[Route("gateway")]
public class GatewayController(AutoCarClient api) : Controller
{
    private static readonly HashSet<string> Allowed=["brands","cars","car-models","car-variants","favorites","orders","test-drive-bookings","quote-requests","reviews","dashboard","users","uploads","notifications","public"];
    [HttpGet("{**path}"),HttpPost("{**path}"),HttpPut("{**path}"),HttpDelete("{**path}")]
    public async Task<IActionResult> Forward(string path)
    {
        var root=path.Split('/')[0];if(!Allowed.Contains(root)&&path is not ("auth/me" or "auth/change-password"))return NotFound();
        if(path.Contains(".."))return BadRequest();
        HttpContent? content=null;
        if(Request.Method!="GET")
        {
            // Global AutoValidateAntiforgeryToken validates all non-GET gateway calls.
            content=new StreamContent(Request.Body);content.Headers.ContentType=System.Net.Http.Headers.MediaTypeHeaderValue.Parse(Request.ContentType??"application/json");
        }
        try
        {
            using var response=await api.Send(new HttpMethod(Request.Method),path+Request.QueryString,content);
            var bytes=await response.Content.ReadAsByteArrayAsync();
            Response.StatusCode=(int)response.StatusCode;
            if(response.Content.Headers.ContentDisposition!=null)Response.Headers.ContentDisposition=response.Content.Headers.ContentDisposition.ToString();
            return File(bytes,response.Content.Headers.ContentType?.ToString()??"application/json");
        }
        catch(ApiException e){return StatusCode(e.Status,new{title=e.Message});}
        catch(HttpRequestException){return StatusCode(503,new{title="API chưa sẵn sàng. Hãy kiểm tra AutoCar.Api và SQL Server."});}
    }
}
