using AutoCar.Api.Data;
using AutoCar.Api.Models;
using AutoCar.Api.Services;
using AutoCar.Shared.Contracts;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
namespace AutoCar.Api.Controllers;
[ApiController,Route("api/car-models")]
public class CarModelsController(AppDbContext db) : ControllerBase
{
    [HttpGet] public Task<List<ModelDto>> Get()=>db.CarModels.Include(x=>x.Brand).Select(x=>new ModelDto(x.Id,x.BrandId,x.Name,x.Brand.Name)).ToListAsync();
    [HttpPost,Authorize(Roles="Admin")]
    public async Task<IActionResult> Create(ModelInput i){if(!await db.Brands.AnyAsync(x=>x.Id==i.BrandId))return BadRequest();var m=new CarModel{BrandId=i.BrandId,Name=i.Name};db.CarModels.Add(m);await db.SaveChangesAsync();return Created($"/api/car-models/{m.Id}",new ModelDto(m.Id,m.BrandId,m.Name,""));}
    [HttpPut("{id:int}"),Authorize(Roles="Admin")]
    public async Task<IActionResult> Update(int id,ModelInput i){var m=await db.CarModels.FindAsync(id);if(m==null)return NotFound();if(!await db.Brands.AnyAsync(x=>x.Id==i.BrandId))return BadRequest();m.BrandId=i.BrandId;m.Name=i.Name;await db.SaveChangesAsync();return NoContent();}
}
[ApiController,Route("api/car-variants")]
public class CarVariantsController(CarService cars) : ControllerBase
{
    [HttpGet]public Task<PageResult<CarDto>> Get([FromQuery]CarQuery q)=>cars.List(q,User.IsInRole("Admin"));
    [HttpPost,Authorize(Roles="Admin")]public async Task<IActionResult> Create(CarInput i){var c=await cars.Create(i);return Created($"/api/cars/{c.Id}",c);}
    [HttpPut("{id:int}"),Authorize(Roles="Admin")]public async Task<IActionResult> Update(int id,CarInput i){await cars.Update(id,i);return NoContent();}
}
