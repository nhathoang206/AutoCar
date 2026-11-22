using AutoCar.Api.Models;
using AutoCar.Shared.Contracts;
namespace AutoCar.Api.Mapping;
public static class CarMapping
{
    public static CarDto Dto(this CarVariant c)=>new()
    {
        Id=c.Id,CarModelId=c.CarModelId,BrandId=c.CarModel.BrandId,Brand=c.CarModel.Brand.Name,Model=c.CarModel.Name,
        Code=c.Code,Name=c.Name,Year=c.Year,Price=c.Price,Seats=c.Seats,Fuel=c.Fuel,Transmission=c.Transmission,
        BodyStyle=c.BodyStyle,Origin=c.Origin,Engine=c.Engine,Power=c.Power,Torque=c.Torque,Drivetrain=c.Drivetrain,
        Colors=c.Colors,Dimensions=c.Dimensions,Consumption=c.Consumption,Description=c.Description,
        IsFeatured=c.IsFeatured,IsVisible=c.IsVisible,Stock=c.Inventory.Stock,Sold=c.Inventory.Sold,Views=c.Views,
        CreatedAt=c.CreatedAt,Images=c.Images.OrderBy(x=>x.SortOrder).Select(x=>x.Url).ToArray(),RowVersion=Convert.ToBase64String(c.RowVersion),InventoryVersion=Convert.ToBase64String(c.Inventory.RowVersion)
    };
    public static void Apply(this CarVariant c,CarInput i)
    {
        c.CarModelId=i.CarModelId;c.Code=i.Code.Trim();c.Name=i.Name.Trim();c.Year=i.Year;c.Price=i.Price;c.Seats=i.Seats;
        c.Fuel=i.Fuel;c.Transmission=i.Transmission;c.BodyStyle=i.BodyStyle;c.Origin=i.Origin;c.Engine=i.Engine;
        c.Power=i.Power;c.Torque=i.Torque;c.Drivetrain=i.Drivetrain;c.Colors=i.Colors;c.Dimensions=i.Dimensions;
        c.Consumption=i.Consumption;c.Description=i.Description;c.IsFeatured=i.IsFeatured;c.IsVisible=i.IsVisible;
    }
}
