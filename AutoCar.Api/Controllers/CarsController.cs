using AutoCar.Api.Data;
using AutoCar.Api.Mapping;
using AutoCar.Api.Services;
using AutoCar.Shared.Contracts;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
namespace AutoCar.Api.Controllers;
[ApiController,Route("api/[controller]")]
public class CarsController(CarService cars,AppDbContext db) : ControllerBase
{
    [HttpGet, HttpGet("search")]
    public Task<PageResult<CarDto>> List([FromQuery]CarQuery q)=>cars.List(q,User.IsInRole("Admin"));
    [HttpGet("featured")]
    public Task<PageResult<CarDto>> Featured()=>cars.List(new(){Featured=true,PageSize=6});
    [HttpGet("{id:int}")]
    public async Task<CarDto> Get(int id)
    {
        var c=await cars.Find(id,User.IsInRole("Admin"));await db.CarVariants.Where(x=>x.Id==id).ExecuteUpdateAsync(s=>s.SetProperty(x=>x.Views,x=>x.Views+1));return c.Dto();
    }
    [HttpPost,Authorize(Roles="Admin")]
    public async Task<IActionResult> Create(CarInput input){var c=await cars.Create(input);return CreatedAtAction(nameof(Get),new{id=c.Id},c);}
    [HttpPut("{id:int}"),Authorize(Roles="Admin")]
    public async Task<IActionResult> Update(int id,CarInput input){await cars.Update(id,input);return NoContent();}
    [HttpDelete("{id:int}"),Authorize(Roles="Admin")]
    public async Task<IActionResult> Delete(int id){var c=await cars.Find(id,true);c.IsVisible=false;await db.SaveChangesAsync();return NoContent();}
}
