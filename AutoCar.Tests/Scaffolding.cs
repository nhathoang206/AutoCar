using AutoCar.Api.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.EntityFrameworkCore.Migrations.Design;
using Microsoft.EntityFrameworkCore.SqlServer.Design.Internal;
using Microsoft.Extensions.DependencyInjection;
namespace AutoCar.Tests;
public static class Scaffolding
{
    public static void Generate(string root)
    {
        using var db=new AppDbContext(new DbContextOptionsBuilder<AppDbContext>().UseSqlServer("Server=.;Database=AutoCarDB;Integrated Security=true;TrustServerCertificate=true").Options);
        var services=new ServiceCollection();services.AddEntityFrameworkDesignTimeServices();services.AddDbContextDesignTimeServices(db);
#pragma warning disable EF1001
        new SqlServerDesignTimeServices().ConfigureDesignTimeServices(services);
#pragma warning restore EF1001
        using var provider=services.BuildServiceProvider();var scaffolder=provider.GetRequiredService<IMigrationsScaffolder>();var migration=scaffolder.ScaffoldMigration("InitialCreate","AutoCar.Api");scaffolder.Save(Path.Combine(root,"AutoCar.Api"),migration,Path.Combine(root,"AutoCar.Api","Migrations"));Console.WriteLine("Generated EF migration and snapshot.");
    }
}
