using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;
using AutoCar.Api.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.EntityFrameworkCore.Migrations;

namespace AutoCar.Tests;

public static class SqlScriptWriter
{
    private static string Literal(string value) => "N'" + value.Replace("'", "''") + "'";

    // EF's idempotent script checks migration history, not individual objects.
    // This bootstrap additionally handles an interrupted/manual initial install.
    public static string Generate(AppDbContext db)
    {
        var sql = db.GetService<IMigrator>().GenerateScript(options: MigrationsSqlGenerationOptions.Idempotent);
        sql = Regex.Replace(sql, @"^\s*GO\s*$", "", RegexOptions.Multiline | RegexOptions.IgnoreCase);
        sql = Regex.Replace(sql, @"^BEGIN TRANSACTION;\s*$|^COMMIT;\s*$", "", RegexOptions.Multiline);
        sql = Regex.Replace(sql, @"(?m)^(\s*)CREATE TABLE \[([^\]]+)\]", m =>
            $"{m.Groups[1].Value}IF OBJECT_ID(N'[dbo].[{m.Groups[2].Value}]', N'U') IS NULL\n{m.Groups[1].Value}CREATE TABLE [{m.Groups[2].Value}]");
        sql = Regex.Replace(sql, @"(?m)^([ \t]*)(CREATE (?:UNIQUE )?INDEX \[([^\]]+)\] ON \[([^\]]+)\][^\r\n]*;)", m =>
            $"{m.Groups[1].Value}IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[{m.Groups[4].Value}]') AND name = {Literal(m.Groups[3].Value)})\n{m.Groups[1].Value}{m.Groups[2].Value}");
        // Filtered unique indexes are emitted as dynamic SQL by EF.
        sql = Regex.Replace(sql, @"(?m)^([ \t]*)(EXEC\(N'CREATE (?:UNIQUE )?INDEX \[([^\]]+)\] ON \[([^\]]+)\][^\r\n]*\);)", m =>
            $"{m.Groups[1].Value}IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[{m.Groups[4].Value}]') AND name = {Literal(m.Groups[3].Value)})\n{m.Groups[1].Value}{m.Groups[2].Value}");

        var validation = ValidateSchema(db);
        return """
            -- AutoCar bootstrap/recovery generated from EF Core migrations and model.
            -- Run the WHOLE file in SSMS. No DROP TABLE / DROP INDEX / data deletion.
            -- Existing objects are skipped, but schema must match before COMMIT.
            -- On mismatch all changes, including migration-history inserts, roll back.
            IF DB_ID(N'AutoCarDB') IS NULL CREATE DATABASE [AutoCarDB];
            GO
            USE [AutoCarDB];
            GO
            IF @@TRANCOUNT <> 0
            BEGIN
                RAISERROR(N'An existing transaction is open. Run this script in a new SSMS query connection.', 16, 1);
                RETURN;
            END;
            SET XACT_ABORT ON;
            BEGIN TRY
                BEGIN TRANSACTION;

            """ + sql + "\n-- Validate before committing migration history.\n" + validation + """

                COMMIT TRANSACTION;
                PRINT N'AutoCarDB schema verified; migration history committed. Existing data preserved.';
            END TRY
            BEGIN CATCH
                IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
                THROW;
            END CATCH;
            GO
            """;
    }

    public static string ValidateSchema(AppDbContext db)
    {
        var model = db.GetService<IDesignTimeModel>().Model;
        var b = new StringBuilder();
        void Require(string condition, string message) => b.AppendLine($"IF {condition}\n    THROW 51000, {Literal(message)}, 1;");
        foreach (var table in model.GetRelationalModel().Tables)
        {
            var name = $"[dbo].[{table.Name}]";
            var objectId = $"OBJECT_ID({Literal(name)}, N'U')";
            Require($"{objectId} IS NULL", $"Missing table: {table.Name}. No migration history committed.");
            Require($"(SELECT COUNT(*) FROM sys.columns WHERE object_id = {objectId}) <> {table.Columns.Count()}", $"Column count mismatch: {table.Name}.");
            foreach (var column in table.Columns)
            {
                var type = column.StoreType.ToLowerInvariant();
                var typeName = type.Split('(')[0];
                if (typeName == "rowversion") typeName = "timestamp";
                var extra = "";
                var size = Regex.Match(type, @"\((max|\d+)(?:,\s*(\d+))?\)");
                if (typeName is "nvarchar" or "varchar" or "varbinary")
                {
                    var length = size.Groups[1].Value == "max" ? -1 : int.Parse(size.Groups[1].Value, CultureInfo.InvariantCulture) * (typeName == "nvarchar" ? 2 : 1);
                    extra += $" AND c.max_length = {length}";
                }
                if (typeName == "decimal") extra += $" AND c.precision = {size.Groups[1].Value} AND c.scale = {size.Groups[2].Value}";
                var identity = column.PropertyMappings.Any(p => p.Property.GetValueGenerationStrategy() == SqlServerValueGenerationStrategy.IdentityColumn);
                Require($"NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = {objectId} AND c.name = {Literal(column.Name)} AND TYPE_NAME(c.system_type_id) = {Literal(typeName)} AND c.is_nullable = {(column.IsNullable ? 1 : 0)} AND c.is_identity = {(identity ? 1 : 0)} AND c.is_computed = 0{extra})", $"Column definition mismatch: {table.Name}.{column.Name}.");
            }
            var key = table.PrimaryKey;
            if (key != null)
            {
                var expected = string.Join('|', key.Columns.Select(c => c.Name));
                Require($"NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = {objectId} AND i.is_primary_key = 1 AND i.is_disabled = 0 AND {IndexColumns("i")} = {Literal(expected)})", $"Primary key mismatch: {table.Name}.");
            }
            foreach (var index in table.Indexes)
            {
                var columns = string.Join('|', index.Columns.Select(c => c.Name));
                var filter = index.Filter == null ? "i.has_filter = 0" : $"{Normalize("i.filter_definition")} = {Normalize(Literal(index.Filter))}";
                Require($"NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = {objectId} AND i.name = {Literal(index.Name)} AND i.is_unique = {(index.IsUnique ? 1 : 0)} AND i.is_disabled = 0 AND i.is_hypothetical = 0 AND {IndexColumns("i")} = {Literal(columns)} AND {filter})", $"Index definition mismatch: {table.Name}.{index.Name}.");
            }
            foreach (var fk in table.ForeignKeyConstraints)
            {
                var columns = string.Join('|', fk.Columns.Zip(fk.PrincipalColumns, (c, p) => c.Name + ":" + p.Name));
                var actual = "(SELECT STRING_AGG(CONVERT(nvarchar(max), pc.name + N':' + rc.name), N'|') WITHIN GROUP (ORDER BY fc.constraint_column_id) FROM sys.foreign_key_columns fc JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id WHERE fc.constraint_object_id = f.object_id)";
                Require($"NOT EXISTS (SELECT 1 FROM sys.foreign_keys f WHERE f.parent_object_id = {objectId} AND f.name = {Literal(fk.Name)} AND f.referenced_object_id = OBJECT_ID({Literal("[dbo].[" + fk.PrincipalTable.Name + "]")}) AND f.is_disabled = 0 AND f.is_not_trusted = 0 AND f.delete_referential_action = 0 AND {actual} = {Literal(columns)})", $"Foreign key mismatch: {fk.Name}.");
            }
            foreach (var check in table.CheckConstraints)
            {
                var constraintName = check.Name ?? throw new InvalidOperationException("A check constraint must have a name.");
                Require($"NOT EXISTS (SELECT 1 FROM sys.check_constraints c WHERE c.parent_object_id = {objectId} AND c.name = {Literal(constraintName)} AND c.is_disabled = 0 AND c.is_not_trusted = 0 AND {Normalize("c.definition")} = {Normalize(Literal(check.Sql))})", $"Check constraint mismatch: {constraintName}.");
            }
        }
        return b.ToString();
    }

    private static string IndexColumns(string alias) => $"(SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N'|') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = {alias}.object_id AND ic.index_id = {alias}.index_id AND ic.key_ordinal > 0)";
    private static string Normalize(string expression) => $"UPPER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE({expression}, N'[', N''), N']', N''), N'(', N''), N')', N''), N' ', N''), CHAR(13), N''), CHAR(10), N''))";
}
