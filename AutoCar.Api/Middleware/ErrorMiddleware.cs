using AutoCar.Api.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Mvc;
namespace AutoCar.Api.Middleware;
public class ErrorMiddleware(RequestDelegate next,ILogger<ErrorMiddleware> logger)
{
    public async Task InvokeAsync(HttpContext context)
    {
        try {await next(context);}
        catch(Exception ex)
        {
            var (status,message)=ex switch
            {
                BusinessException b => (b.Status,b.Message),
                DbUpdateConcurrencyException => (409,"Dữ liệu vừa được cập nhật. Vui lòng tải lại."),
                DbUpdateException => (409,"Dữ liệu trùng hoặc đang được sử dụng bởi giao dịch khác."),
                Microsoft.Data.SqlClient.SqlException sql when sql.Number==1205 => (409,"Giao dịch đang cạnh tranh. Vui lòng tải lại và thử lại."),
                InvalidOperationException wrapped when IsDeadlock(wrapped) => (409,"Giao dịch đang cạnh tranh. Vui lòng tải lại và thử lại."),
                _ => (500,"Không thể xử lý yêu cầu. Vui lòng thử lại sau.")
            };
            if(status==500) logger.LogError(ex,"Request failed {Trace}",context.TraceIdentifier);
            context.Response.StatusCode=status;
            await context.Response.WriteAsJsonAsync(new ProblemDetails {Status=status,Title=message,Extensions={ ["traceId"]=context.TraceIdentifier }});
        }
    }
    private static bool IsDeadlock(Exception error)
    {
        for(Exception? current=error;current!=null;current=current.InnerException)
            if(current is Microsoft.Data.SqlClient.SqlException {Number:1205})return true;
        return false;
    }
}
