using AutoCar.Shared.Contracts;
namespace AutoCar.Web.ViewModels;
public record HomeVm(PageResult<CarDto> Latest,PageResult<CarDto> Featured,PageResult<BrandDto> Brands,IReadOnlyList<PromotionDto> Promotions,IReadOnlyList<ReviewDto> Reviews,string? Error=null);
public record CatalogVm(PageResult<CarDto> Cars,PageResult<BrandDto> Brands,CarQuery Query);
public record DetailVm(CarDto Car,PageResult<CarDto> Related);
