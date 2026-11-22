using AutoCar.Shared.Contracts;

namespace AutoCar.Web.Services;

public static class BrandLogoCatalog
{
    // Original trademark artwork distributed by car-logos-dataset / Carlogos.
    // These are not AI illustrations, letter badges or redrawn approximations.
    public static readonly IReadOnlyDictionary<string,string> Brands=new Dictionary<string,string>(StringComparer.OrdinalIgnoreCase)
    {
        ["Audi"]="audi", ["Toyota"]="toyota", ["Honda"]="honda", ["Hyundai"]="hyundai",
        ["Volvo"]="volvo", ["Mercedes-Benz"]="mercedes-benz", ["BMW"]="bmw", ["Kia"]="kia",
        ["Ford"]="ford", ["Mazda"]="mazda", ["Lexus"]="lexus", ["Porsche"]="porsche",
        ["Volkswagen"]="volkswagen", ["Mitsubishi"]="mitsubishi", ["VinFast"]="vinfast"
    };

    public static string RemoteUrl(string slug)=>$"https://raw.githubusercontent.com/filippofilip95/car-logos-dataset/master/logos/optimized/{slug}.png";
    public static string FileName(string slug)=>$"{slug}.png";

    public static string? Resolve(BrandDto brand,IWebHostEnvironment environment)
    {
        if(!string.IsNullOrWhiteSpace(brand.LogoUrl))return "/media"+brand.LogoUrl;
        if(!Brands.TryGetValue(brand.Name.Trim(),out var slug))return null;
        var path=Path.Combine(environment.WebRootPath,"images","brands",FileName(slug));
        return File.Exists(path)?$"/images/brands/{FileName(slug)}":RemoteUrl(slug);
    }
}

public sealed class BrandLogoCacheService(IHttpClientFactory clients,IWebHostEnvironment environment,
    ILogger<BrandLogoCacheService> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var directory=Path.Combine(environment.WebRootPath,"images","brands");
        Directory.CreateDirectory(directory);
        await Parallel.ForEachAsync(BrandLogoCatalog.Brands.Values,new ParallelOptions{MaxDegreeOfParallelism=4,CancellationToken=stoppingToken},async(slug,token)=>
        {
            var path=Path.Combine(directory,BrandLogoCatalog.FileName(slug));
            if(File.Exists(path))return;
            try
            {
                using var response=await clients.CreateClient("BrandLogos").GetAsync(BrandLogoCatalog.RemoteUrl(slug),HttpCompletionOption.ResponseHeadersRead,token);
                response.EnsureSuccessStatusCode();
                if(response.Content.Headers.ContentLength>2*1024*1024)throw new InvalidDataException("Logo exceeds 2 MB.");
                await using var stream=await response.Content.ReadAsStreamAsync(token);
                using var buffer=new MemoryStream();
                var chunk=new byte[8192];int count;
                while((count=await stream.ReadAsync(chunk,token))>0)
                {
                    if(buffer.Length+count>2*1024*1024)throw new InvalidDataException("Logo exceeds 2 MB.");
                    buffer.Write(chunk,0,count);
                }
                var bytes=buffer.ToArray();
                if(bytes.Length<8||!bytes.AsSpan(0,8).SequenceEqual(new byte[]{137,80,78,71,13,10,26,10}))throw new InvalidDataException("Logo is not PNG artwork.");
                var temporary=path+"."+Guid.NewGuid().ToString("N")+".tmp";
                await File.WriteAllBytesAsync(temporary,bytes,token);
                File.Move(temporary,path,overwrite:true);
                logger.LogInformation("Cached original brand logo: {Brand}",slug);
            }
            catch(Exception ex) when(ex is HttpRequestException or IOException or TaskCanceledException)
            {
                logger.LogWarning("Brand logo {Brand} could not be cached: {Reason}",slug,ex.Message);
            }
        });
    }
}
