using AutoCar.Web.Services;
using Microsoft.AspNetCore.Mvc;
namespace AutoCar.Web.Controllers;
public class MediaController(AutoCarClient api) : Controller
{
    [HttpGet("/media/catalog/{name}")]
    public async Task<IActionResult> CatalogImage(string name)
    {
        if(!System.Text.RegularExpressions.Regex.IsMatch(name,"^[a-z0-9-]+\\.webp$"))return NotFound();
        using var response=await api.CatalogImage(name);if(!response.IsSuccessStatusCode)return NotFound();
        Response.Headers.CacheControl="public,max-age=86400";
        return File(await response.Content.ReadAsByteArrayAsync(),"image/webp");
    }
    [HttpGet("/media/uploads/{name}")]
    public async Task<IActionResult> Image(string name)
    {
        if(!System.Text.RegularExpressions.Regex.IsMatch(name,"^[A-F0-9]{40}\\.(jpg|png|webp)$"))return NotFound();
        using var response=await api.Image(name);if(!response.IsSuccessStatusCode)return NotFound();
        return File(await response.Content.ReadAsByteArrayAsync(),response.Content.Headers.ContentType?.MediaType??"image/jpeg");
    }
}
