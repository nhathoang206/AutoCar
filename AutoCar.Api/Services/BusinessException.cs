namespace AutoCar.Api.Services;
public class BusinessException(int status,string message) : Exception(message)
{
    public int Status { get; }=status;
}
