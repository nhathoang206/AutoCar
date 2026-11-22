using System.Net;
using System.Text.Json;
using System.Text.RegularExpressions;
using AutoCar.Shared.Contracts;

namespace AutoCar.Web.Services;

public record CarPhoto(string Key,string File,string Source,string Artist,string License,string LicenseUrl,string Original);

public sealed class CarPhotoCatalog(IWebHostEnvironment env)
{
    public static readonly Dictionary<string,string> Models=new(StringComparer.OrdinalIgnoreCase)
    {
        ["Audi A4"]="Audi A4",["Audi A6"]="Audi A6",["Audi Q5"]="Audi Q5",["Audi Q7"]="Audi Q7",
        ["Toyota Vios"]="Toyota Vios",["Toyota Corolla Cross"]="Toyota Corolla Cross",["Toyota Camry"]="Toyota Camry",["Toyota Fortuner"]="Toyota Fortuner",
        ["Honda City"]="Honda City",["Honda Civic"]="Honda Civic",["Honda CR-V"]="Honda CR-V",
        ["Hyundai Accent"]="Hyundai Accent",["Hyundai Tucson"]="Hyundai Tucson",["Hyundai Santa Fe"]="Hyundai Santa Fe",
        ["Volvo XC60"]="Volvo XC60",["Volvo XC90"]="Volvo XC90",
        ["Mercedes-Benz C-Class"]="Mercedes-Benz C-Class",["Mercedes-Benz E-Class"]="Mercedes-Benz E-Class",["Mercedes-Benz GLC"]="Mercedes-Benz GLC",
        ["BMW 3 Series"]="BMW 3 Series",["BMW 5 Series"]="BMW 5 Series",["BMW X5"]="BMW X5",
        ["Kia K3"]="Kia Forte",["Kia Sportage"]="Kia Sportage",["Kia Sorento"]="Kia Sorento",
        ["Ford Everest"]="Ford Everest",["Ford Ranger"]="Ford Ranger (T6)",
        ["Mazda Mazda3"]="Mazda3",["Mazda CX-5"]="Mazda CX-5",["Lexus ES"]="Lexus ES",["Lexus RX"]="Lexus RX",
        ["Porsche Macan"]="Porsche Macan",["Porsche Cayenne"]="Porsche Cayenne",
        ["Volkswagen Tiguan"]="Volkswagen Tiguan",["Volkswagen Teramont"]="Volkswagen Atlas",
        ["Mitsubishi Xpander"]="Mitsubishi Xpander",["Mitsubishi Outlander"]="Mitsubishi Outlander",
        ["VinFast VF 7"]="VinFast VF 7",["VinFast VF 8"]="VinFast VF 8"
    };
    public string DirectoryPath=>Path.Combine(env.WebRootPath,"images","cars");
    public string ManifestPath=>Path.Combine(DirectoryPath,"sources.json");
    public static string Slug(string key)=>Regex.Replace(key.ToLowerInvariant(),"[^a-z0-9]+","-").Trim('-');
    private readonly System.Collections.Concurrent.ConcurrentDictionary<string,CarPhoto> photos=new(StringComparer.OrdinalIgnoreCase);
    public IEnumerable<CarPhoto> All=>photos.Values;
    public System.Collections.Concurrent.ConcurrentDictionary<string,string> Errors {get;}=new();
    public void Load(){if(System.IO.File.Exists(ManifestPath))foreach(var p in JsonSerializer.Deserialize<CarPhoto[]>(System.IO.File.ReadAllText(ManifestPath))??[])photos[p.Key]=p;}
    public void Put(CarPhoto p)=>photos[p.Key]=p;
    public CarPhoto? Find(string brand,string model)=>photos.GetValueOrDefault(brand+" "+model);
    public string Image(CarDto c)=>c.Images.Length>0?"/media"+c.Images[0]:Find(c.Brand,c.Model) is {} p?"/images/cars/"+p.File:"/images/car-pending.svg";
}

public sealed class CarPhotoCacheService(CarPhotoCatalog catalog,IHttpClientFactory clients,ILogger<CarPhotoCacheService> logger):BackgroundService
{
    private static string Text(JsonElement metadata,string key)=>metadata.TryGetProperty(key,out var p)&&p.TryGetProperty("value",out var v)?WebUtility.HtmlDecode(Regex.Replace(v.GetString()??"","<[^>]*>"," ")).Trim():"";
    protected override async Task ExecuteAsync(CancellationToken token)
    {
        Directory.CreateDirectory(catalog.DirectoryPath);catalog.Load();await Task.Yield();
        var client=clients.CreateClient("CarPhotos");
        // One page lookup for the catalog avoids per-model API bursts.
        try
        {
            var missing=CarPhotoCatalog.Models.Where(x=>!File.Exists(Path.Combine(catalog.DirectoryPath,CarPhotoCatalog.Slug(x.Key)+".page.json"))).ToArray();
            if(missing.Length>0)
            {
                using var batch=JsonDocument.Parse(await client.GetStringAsync("https://en.wikipedia.org/w/api.php?action=query&format=json&redirects=1&prop=pageimages&piprop=name&titles="+Uri.EscapeDataString(string.Join('|',missing.Select(x=>x.Value))),token));
                var query=batch.RootElement.GetProperty("query");
                foreach(var pair in missing)
                {
                    var title=pair.Value;
                    foreach(var field in new[]{"normalized","redirects"})if(query.TryGetProperty(field,out var redirects))foreach(var redirect in redirects.EnumerateArray())if(redirect.GetProperty("from").GetString()==title)title=redirect.GetProperty("to").GetString()!;
                    var page=query.GetProperty("pages").EnumerateObject().FirstOrDefault(x=>x.Value.GetProperty("title").GetString()==title);
                    if(page.Value.ValueKind!=JsonValueKind.Undefined)await File.WriteAllTextAsync(Path.Combine(catalog.DirectoryPath,CarPhotoCatalog.Slug(pair.Key)+".page.json"),JsonSerializer.Serialize(new{query=new{pages=new Dictionary<string,JsonElement>{{page.Name,page.Value}}}}),token);
                }
            }
        }
        catch(Exception ex)when(ex is not OperationCanceledException || !token.IsCancellationRequested){logger.LogWarning("Catalog page lookup: {Reason}",ex.Message);}
        try
        {
            var files=new Dictionary<string,string>();
            foreach(var pair in CarPhotoCatalog.Models)
            {
                var path=Path.Combine(catalog.DirectoryPath,CarPhotoCatalog.Slug(pair.Key)+".page.json");
                if(!File.Exists(path)||File.Exists(Path.Combine(catalog.DirectoryPath,CarPhotoCatalog.Slug(pair.Key)+".info.json")))continue;
                using var page=JsonDocument.Parse(await File.ReadAllTextAsync(path,token));
                var value=page.RootElement.GetProperty("query").GetProperty("pages").EnumerateObject().First().Value;
                if(value.TryGetProperty("pageimage",out var image))files[pair.Key]="File:"+image.GetString();
            }
            if(files.Count>0)
            {
                using var batch=JsonDocument.Parse(await client.GetStringAsync("https://commons.wikimedia.org/w/api.php?action=query&format=json&prop=imageinfo&iiprop=url%7Cextmetadata&titles="+Uri.EscapeDataString(string.Join('|',files.Values)),token));
                foreach(var file in files)
                {
                    var page=batch.RootElement.GetProperty("query").GetProperty("pages").EnumerateObject().FirstOrDefault(x=>x.Value.GetProperty("title").GetString()==file.Value.Replace('_',' '));
                    if(page.Value.ValueKind!=JsonValueKind.Undefined)await File.WriteAllTextAsync(Path.Combine(catalog.DirectoryPath,CarPhotoCatalog.Slug(file.Key)+".info.json"),JsonSerializer.Serialize(new{query=new{pages=new Dictionary<string,JsonElement>{{page.Name,page.Value}}}}),token);
                }
            }
        }
        catch(Exception ex)when(ex is not OperationCanceledException || !token.IsCancellationRequested){logger.LogWarning("Catalog credits lookup: {Reason}",ex.Message);}
        foreach(var pair in CarPhotoCatalog.Models)
        {
            if(catalog.Find(pair.Key.Split(' ')[0],pair.Key[(pair.Key.IndexOf(' ')+1)..]) is {} existing&&File.Exists(Path.Combine(catalog.DirectoryPath,existing.File)))continue;
            var stage="page";
            try
            {
                var query="https://en.wikipedia.org/w/api.php?action=query&format=json&redirects=1&prop=pageimages&piprop=name&titles="+Uri.EscapeDataString(pair.Value);
                var pageCache=Path.Combine(catalog.DirectoryPath,CarPhotoCatalog.Slug(pair.Key)+".page.json");
                if(!File.Exists(pageCache))await File.WriteAllTextAsync(pageCache,await client.GetStringAsync(query,token),token);
                using var page=JsonDocument.Parse(await File.ReadAllTextAsync(pageCache,token));
                var file=page.RootElement.GetProperty("query").GetProperty("pages").EnumerateObject().First().Value.GetProperty("pageimage").GetString()!;
                stage="metadata";
                var infoCache=Path.Combine(catalog.DirectoryPath,CarPhotoCatalog.Slug(pair.Key)+".info.json");
                if(!File.Exists(infoCache))await File.WriteAllTextAsync(infoCache,await client.GetStringAsync("https://commons.wikimedia.org/w/api.php?action=query&format=json&prop=imageinfo&iiprop=url%7Cextmetadata&titles="+Uri.EscapeDataString("File:"+file),token),token);
                using var info=JsonDocument.Parse(await File.ReadAllTextAsync(infoCache,token));
                var photo=info.RootElement.GetProperty("query").GetProperty("pages").EnumerateObject().First().Value.GetProperty("imageinfo")[0];
                var metadata=photo.GetProperty("extmetadata");var license=Text(metadata,"LicenseShortName");
                if(!license.StartsWith("CC ",StringComparison.OrdinalIgnoreCase)&&!license.Contains("public domain",StringComparison.OrdinalIgnoreCase)&&!license.Equals("CC0",StringComparison.OrdinalIgnoreCase))throw new InvalidDataException("Unsupported photo license: "+license);
                var originalUri=new Uri(photo.GetProperty("url").GetString()!);
                var originalPath=originalUri.AbsolutePath;
                // Wikimedia's documented standard thumbnail width avoids downloading large originals.
                var url="https://thumb.wikimedia.org"+originalPath.Replace("/commons/","/commons/thumb/")+"/1280px-"+originalPath.Split('/').Last();
                stage="image "+url;
                if(url.StartsWith("//"))url="https:"+url;
                var uri=new Uri(url);
                if(uri.Scheme!="https"||!(uri.Host.Equals("wikimedia.org",StringComparison.OrdinalIgnoreCase)||uri.Host.EndsWith(".wikimedia.org",StringComparison.OrdinalIgnoreCase)))throw new InvalidDataException("Unexpected photo URL: "+url);
                using var response=await client.GetAsync(url,token);response.EnsureSuccessStatusCode();
                var bytes=await response.Content.ReadAsByteArrayAsync(token);
                if(bytes.Length>25*1024*1024||bytes.Length<12)throw new InvalidDataException("Invalid photo size");
                var extension=bytes[0]==255&&bytes[1]==216?".jpg":bytes[0]==137&&bytes[1]==80?".png":throw new InvalidDataException("Unsupported photo format");
                var name=CarPhotoCatalog.Slug(pair.Key)+extension;
                await File.WriteAllBytesAsync(Path.Combine(catalog.DirectoryPath,name),bytes,token);
                catalog.Put(new(pair.Key,name,photo.GetProperty("descriptionurl").GetString()!,Text(metadata,"Artist"),license,Text(metadata,"LicenseUrl"),photo.GetProperty("url").GetString()!));
                await File.WriteAllTextAsync(catalog.ManifestPath,JsonSerializer.Serialize(catalog.All.OrderBy(x=>x.Key),new JsonSerializerOptions{WriteIndented=true}),token);
                logger.LogInformation("Cached model photograph: {Model}",pair.Key);
            }
            catch(Exception ex)when(ex is not OperationCanceledException || !token.IsCancellationRequested){catalog.Errors[pair.Key]=stage+": "+ex.Message;logger.LogWarning("Model photo {Model}: {Reason}",pair.Key,ex.Message);}
            await Task.Delay(TimeSpan.FromSeconds(2),token);
        }
    }
}
