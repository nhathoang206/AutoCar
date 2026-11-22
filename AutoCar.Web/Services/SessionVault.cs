using System.Collections.Concurrent;
using AutoCar.Shared.Contracts;
namespace AutoCar.Web.Services;
public class SessionVault
{
    private readonly ConcurrentDictionary<string,Entry> entries=new();
    public sealed class Entry(TokenDto token){public TokenDto Token=token;public SemaphoreSlim Gate=new(1,1);public DateTimeOffset LastUsed=DateTimeOffset.UtcNow;}
    public string Add(TokenDto token)
    {
        foreach(var pair in entries.Where(x=>x.Value.LastUsed<DateTimeOffset.UtcNow.AddHours(-8)).ToArray())entries.TryRemove(pair.Key,out _);
        var key=Convert.ToHexString(System.Security.Cryptography.RandomNumberGenerator.GetBytes(32));entries[key]=new(token);return key;
    }
    public Entry? Get(string? key){if(key==null||!entries.TryGetValue(key,out var e))return null;if(e.LastUsed<DateTimeOffset.UtcNow.AddHours(-8)){entries.TryRemove(key,out _);return null;}e.LastUsed=DateTimeOffset.UtcNow;return e;}
    public void Remove(string key)=>entries.TryRemove(key,out _);
}
