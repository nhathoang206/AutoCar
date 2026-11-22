using System.Text.Json;
using System.Text.RegularExpressions;
using AutoCar.Api.Models;
using Microsoft.EntityFrameworkCore;
namespace AutoCar.Api.Data;

public static class ModelPhotoSeed
{
    private sealed record Photo(string Key,string File);
    public static async Task Run(AppDbContext db,string webRoot)
    {
        var directory=Path.Combine(webRoot,"catalog");var manifest=Path.Combine(directory,"sources.json");
        if(!File.Exists(manifest))return;
        var photos=JsonSerializer.Deserialize<Photo[]>(await File.ReadAllTextAsync(manifest))??[];
        var cars=await db.CarVariants.Include(x=>x.CarModel).ThenInclude(x=>x.Brand).Include(x=>x.Images).Where(x=>x.Code.StartsWith("DEMO-")).ToListAsync();
        foreach(var car in cars)
        {
            if(car.Images.Count>0)continue;
            var photo=photos.FirstOrDefault(x=>x.Key==car.CarModel.Brand.Name+" "+car.CarModel.Name);
            if(photo==null||!Regex.IsMatch(photo.File,"^[a-z0-9-]+\\.webp$")||!File.Exists(Path.Combine(directory,photo.File)))continue;
            car.Images.Add(new CarImage{Url="/catalog/"+photo.File,SortOrder=0});
        }
        await db.SaveChangesAsync();
    }
}
