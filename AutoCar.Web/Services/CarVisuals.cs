namespace AutoCar.Web.Services;

public static class CarVisuals
{
    // Never substitute a photograph of another model for a missing product photograph.
    public static string Placeholder(string? bodyStyle) => "/images/car-pending.svg";
}
