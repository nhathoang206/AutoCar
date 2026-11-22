using System.Xml.Linq;
using Microsoft.AspNetCore.DataProtection.Repositories;
namespace AutoCar.Api.Services;
public sealed class MemoryKeyRepository : IXmlRepository
{
    private readonly List<XElement> elements=[];
    public IReadOnlyCollection<XElement> GetAllElements(){lock(elements)return elements.Select(x=>new XElement(x)).ToArray();}
    public void StoreElement(XElement element,string friendlyName){lock(elements)elements.Add(new XElement(element));}
}
