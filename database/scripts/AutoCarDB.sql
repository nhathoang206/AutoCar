-- AutoCarDB recovery: SQL Server 2017+; compatibility level >= 110.
-- Run the WHOLE file in a NEW SSMS connection. Stop app writes/migrations first.
-- No DROP/DELETE/TRUNCATE; conflicting standalone stats cause rollback.
-- Existing schema must pass the original model checks before history is recorded.
-- Database creation is outside the transaction; an empty new DB can remain on failure.
-- Existing migration history does NOT authorize silently repairing schema drift.
USE [master];
GO
IF @@TRANCOUNT <> 0
BEGIN
    RAISERROR(N'Open transaction: use a NEW connection.', 16, 1);
    RETURN;
END;
IF DB_ID(N'AutoCarDB') IS NULL EXEC(N'CREATE DATABASE [AutoCarDB]');
GO
USE [AutoCarDB];
GO
IF DB_NAME() <> N'AutoCarDB' OR @@TRANCOUNT <> 0
BEGIN
    RAISERROR(N'Wrong database or open transaction: use a NEW connection.', 16, 1);
    RETURN;
END;
SET NOCOUNT ON;
SET XACT_ABORT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
SET ANSI_PADDING ON;
SET ANSI_WARNINGS ON;
SET CONCAT_NULL_YIELDS_NULL ON;
SET ARITHABORT ON;
SET NUMERIC_ROUNDABORT OFF;
BEGIN TRY
    BEGIN TRANSACTION;
    DECLARE @LockResult int;
    EXEC @LockResult = sys.sp_getapplock
        @Resource = N'AutoCarDB.schema-recovery', @LockMode = N'Exclusive',
        @LockOwner = N'Transaction', @LockTimeout = 0;
    IF @LockResult < 0 THROW 51002, N'Another recovery is running. Retry later.', 1;
    -- Lower execution scope lets TRY/CATCH catch compilation errors in the payload.
    EXEC sys.sp_executesql N'IF OBJECT_ID(N''[dbo].[__EFMigrationsHistory]'', N''U'') IS NULL
BEGIN
    IF OBJECT_ID(N''[dbo].[__EFMigrationsHistory]'', N''U'') IS NULL
    CREATE TABLE [dbo].[__EFMigrationsHistory] (
        [MigrationId] nvarchar(150) NOT NULL,
        [ProductVersion] nvarchar(32) NOT NULL,
        CONSTRAINT [PK___EFMigrationsHistory] PRIMARY KEY ([MigrationId])
    );
END;


IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF OBJECT_ID(N''[dbo].[AspNetRoles]'', N''U'') IS NULL
    CREATE TABLE [dbo].[AspNetRoles] (
        [Id] nvarchar(450) NOT NULL,
        [Name] nvarchar(max) NULL,
        [NormalizedName] nvarchar(256) NULL,
        [ConcurrencyStamp] nvarchar(max) NULL,
        CONSTRAINT [PK_AspNetRoles] PRIMARY KEY ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF OBJECT_ID(N''[dbo].[AspNetUsers]'', N''U'') IS NULL
    CREATE TABLE [dbo].[AspNetUsers] (
        [Id] nvarchar(450) NOT NULL,
        [FullName] nvarchar(100) NOT NULL,
        [Address] nvarchar(300) NULL,
        [UserName] nvarchar(max) NULL,
        [NormalizedUserName] nvarchar(256) NULL,
        [Email] nvarchar(256) NULL,
        [NormalizedEmail] nvarchar(256) NULL,
        [EmailConfirmed] bit NOT NULL,
        [PasswordHash] nvarchar(max) NULL,
        [SecurityStamp] nvarchar(max) NULL,
        [ConcurrencyStamp] nvarchar(max) NULL,
        [PhoneNumber] nvarchar(max) NULL,
        [PhoneNumberConfirmed] bit NOT NULL,
        [TwoFactorEnabled] bit NOT NULL,
        [LockoutEnd] datetimeoffset NULL,
        [LockoutEnabled] bit NOT NULL,
        [AccessFailedCount] int NOT NULL,
        CONSTRAINT [PK_AspNetUsers] PRIMARY KEY ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF OBJECT_ID(N''[dbo].[Brands]'', N''U'') IS NULL
    CREATE TABLE [dbo].[Brands] (
        [Id] int NOT NULL IDENTITY,
        [Name] nvarchar(80) NOT NULL,
        [LogoUrl] nvarchar(max) NULL,
        [IsActive] bit NOT NULL,
        CONSTRAINT [PK_Brands] PRIMARY KEY ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF OBJECT_ID(N''[dbo].[Contacts]'', N''U'') IS NULL
    CREATE TABLE [dbo].[Contacts] (
        [Id] int NOT NULL IDENTITY,
        [Name] nvarchar(max) NOT NULL,
        [Email] nvarchar(max) NOT NULL,
        [Message] nvarchar(max) NOT NULL,
        [CreatedAt] datetimeoffset NOT NULL,
        CONSTRAINT [PK_Contacts] PRIMARY KEY ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF OBJECT_ID(N''[dbo].[Promotions]'', N''U'') IS NULL
    CREATE TABLE [dbo].[Promotions] (
        [Id] int NOT NULL IDENTITY,
        [Title] nvarchar(max) NOT NULL,
        [Description] nvarchar(max) NOT NULL,
        [StartsAt] datetimeoffset NOT NULL,
        [EndsAt] datetimeoffset NOT NULL,
        CONSTRAINT [PK_Promotions] PRIMARY KEY ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF OBJECT_ID(N''[dbo].[AspNetUserRoles]'', N''U'') IS NULL
    CREATE TABLE [dbo].[AspNetUserRoles] (
        [UserId] nvarchar(450) NOT NULL,
        [RoleId] nvarchar(450) NOT NULL,
        CONSTRAINT [PK_AspNetUserRoles] PRIMARY KEY ([UserId], [RoleId]),
        CONSTRAINT [FK_AspNetUserRoles_AspNetRoles_RoleId] FOREIGN KEY ([RoleId]) REFERENCES [dbo].[AspNetRoles] ([Id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_AspNetUserRoles_AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF OBJECT_ID(N''[dbo].[AuditLogs]'', N''U'') IS NULL
    CREATE TABLE [dbo].[AuditLogs] (
        [Id] int NOT NULL IDENTITY,
        [ActorId] nvarchar(450) NOT NULL,
        [Action] nvarchar(max) NOT NULL,
        [Resource] nvarchar(max) NOT NULL,
        [At] datetimeoffset NOT NULL,
        CONSTRAINT [PK_AuditLogs] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_AuditLogs_AspNetUsers_ActorId] FOREIGN KEY ([ActorId]) REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF OBJECT_ID(N''[dbo].[Notifications]'', N''U'') IS NULL
    CREATE TABLE [dbo].[Notifications] (
        [Id] int NOT NULL IDENTITY,
        [UserId] nvarchar(450) NOT NULL,
        [Message] nvarchar(max) NOT NULL,
        [IsRead] bit NOT NULL,
        [CreatedAt] datetimeoffset NOT NULL,
        CONSTRAINT [PK_Notifications] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Notifications_AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF OBJECT_ID(N''[dbo].[Orders]'', N''U'') IS NULL
    CREATE TABLE [dbo].[Orders] (
        [Id] int NOT NULL IDENTITY,
        [UserId] nvarchar(450) NOT NULL,
        [AssignedSalesId] nvarchar(450) NULL,
        [Status] nvarchar(450) NOT NULL,
        [PaymentStatus] nvarchar(max) NOT NULL,
        [Total] decimal(18,2) NOT NULL,
        [Note] nvarchar(max) NULL,
        [CreatedAt] datetimeoffset NOT NULL,
        [CompletedAt] datetimeoffset NULL,
        [RowVersion] rowversion NOT NULL,
        CONSTRAINT [PK_Orders] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Orders_AspNetUsers_AssignedSalesId] FOREIGN KEY ([AssignedSalesId]) REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_Orders_AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF OBJECT_ID(N''[dbo].[RefreshSessions]'', N''U'') IS NULL
    CREATE TABLE [dbo].[RefreshSessions] (
        [Id] int NOT NULL IDENTITY,
        [UserId] nvarchar(450) NOT NULL,
        [TokenHash] nvarchar(64) NOT NULL,
        [ExpiresAt] datetimeoffset NOT NULL,
        [Revoked] bit NOT NULL,
        [RowVersion] rowversion NOT NULL,
        CONSTRAINT [PK_RefreshSessions] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_RefreshSessions_AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF OBJECT_ID(N''[dbo].[CarModels]'', N''U'') IS NULL
    CREATE TABLE [dbo].[CarModels] (
        [Id] int NOT NULL IDENTITY,
        [BrandId] int NOT NULL,
        [Name] nvarchar(100) NOT NULL,
        CONSTRAINT [PK_CarModels] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_CarModels_Brands_BrandId] FOREIGN KEY ([BrandId]) REFERENCES [dbo].[Brands] ([Id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF OBJECT_ID(N''[dbo].[OrderHistories]'', N''U'') IS NULL
    CREATE TABLE [dbo].[OrderHistories] (
        [Id] int NOT NULL IDENTITY,
        [OrderId] int NOT NULL,
        [Status] nvarchar(max) NOT NULL,
        [ActorId] nvarchar(450) NOT NULL,
        [Note] nvarchar(max) NULL,
        [At] datetimeoffset NOT NULL,
        CONSTRAINT [PK_OrderHistories] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_OrderHistories_AspNetUsers_ActorId] FOREIGN KEY ([ActorId]) REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_OrderHistories_Orders_OrderId] FOREIGN KEY ([OrderId]) REFERENCES [dbo].[Orders] ([Id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF OBJECT_ID(N''[dbo].[Payments]'', N''U'') IS NULL
    CREATE TABLE [dbo].[Payments] (
        [Id] int NOT NULL IDENTITY,
        [OrderId] int NOT NULL,
        [Amount] decimal(18,2) NOT NULL,
        [Reference] nvarchar(200) NOT NULL,
        [ConfirmedById] nvarchar(450) NOT NULL,
        [At] datetimeoffset NOT NULL,
        CONSTRAINT [PK_Payments] PRIMARY KEY ([Id]),
        CONSTRAINT [CK_Payment_Amount] CHECK ([Amount] > 0),
        CONSTRAINT [FK_Payments_AspNetUsers_ConfirmedById] FOREIGN KEY ([ConfirmedById]) REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_Payments_Orders_OrderId] FOREIGN KEY ([OrderId]) REFERENCES [dbo].[Orders] ([Id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') IS NULL
    CREATE TABLE [dbo].[CarVariants] (
        [Id] int NOT NULL IDENTITY,
        [CarModelId] int NOT NULL,
        [Code] nvarchar(50) NOT NULL,
        [Name] nvarchar(120) NOT NULL,
        [Year] int NOT NULL,
        [Price] decimal(18,2) NOT NULL,
        [Seats] int NOT NULL,
        [Fuel] nvarchar(max) NOT NULL,
        [Transmission] nvarchar(max) NOT NULL,
        [BodyStyle] nvarchar(450) NOT NULL,
        [Origin] nvarchar(max) NOT NULL,
        [Engine] nvarchar(max) NOT NULL,
        [Power] nvarchar(max) NOT NULL,
        [Torque] nvarchar(max) NOT NULL,
        [Drivetrain] nvarchar(max) NOT NULL,
        [Colors] nvarchar(max) NOT NULL,
        [Dimensions] nvarchar(max) NOT NULL,
        [Consumption] nvarchar(max) NOT NULL,
        [Description] nvarchar(max) NOT NULL,
        [IsFeatured] bit NOT NULL,
        [IsVisible] bit NOT NULL,
        [Views] int NOT NULL,
        [CreatedAt] datetimeoffset NOT NULL,
        [RowVersion] rowversion NOT NULL,
        CONSTRAINT [PK_CarVariants] PRIMARY KEY ([Id]),
        CONSTRAINT [CK_Car_Price] CHECK ([Price] >= 0),
        CONSTRAINT [FK_CarVariants_CarModels_CarModelId] FOREIGN KEY ([CarModelId]) REFERENCES [dbo].[CarModels] ([Id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF OBJECT_ID(N''[dbo].[CarImages]'', N''U'') IS NULL
    CREATE TABLE [dbo].[CarImages] (
        [Id] int NOT NULL IDENTITY,
        [CarVariantId] int NOT NULL,
        [Url] nvarchar(max) NOT NULL,
        [SortOrder] int NOT NULL,
        CONSTRAINT [PK_CarImages] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_CarImages_CarVariants_CarVariantId] FOREIGN KEY ([CarVariantId]) REFERENCES [dbo].[CarVariants] ([Id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF OBJECT_ID(N''[dbo].[CarInventories]'', N''U'') IS NULL
    CREATE TABLE [dbo].[CarInventories] (
        [Id] int NOT NULL IDENTITY,
        [CarVariantId] int NOT NULL,
        [Stock] int NOT NULL,
        [Sold] int NOT NULL,
        [RowVersion] rowversion NOT NULL,
        CONSTRAINT [PK_CarInventories] PRIMARY KEY ([Id]),
        CONSTRAINT [CK_Inventory_Sold] CHECK ([Sold] >= 0),
        CONSTRAINT [CK_Inventory_Stock] CHECK ([Stock] >= 0),
        CONSTRAINT [FK_CarInventories_CarVariants_CarVariantId] FOREIGN KEY ([CarVariantId]) REFERENCES [dbo].[CarVariants] ([Id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF OBJECT_ID(N''[dbo].[Favorites]'', N''U'') IS NULL
    CREATE TABLE [dbo].[Favorites] (
        [Id] int NOT NULL IDENTITY,
        [UserId] nvarchar(450) NOT NULL,
        [CarVariantId] int NOT NULL,
        CONSTRAINT [PK_Favorites] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Favorites_AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_Favorites_CarVariants_CarVariantId] FOREIGN KEY ([CarVariantId]) REFERENCES [dbo].[CarVariants] ([Id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF OBJECT_ID(N''[dbo].[OrderItems]'', N''U'') IS NULL
    CREATE TABLE [dbo].[OrderItems] (
        [Id] int NOT NULL IDENTITY,
        [OrderId] int NOT NULL,
        [CarVariantId] int NOT NULL,
        [Quantity] int NOT NULL,
        [UnitPrice] decimal(18,2) NOT NULL,
        CONSTRAINT [PK_OrderItems] PRIMARY KEY ([Id]),
        CONSTRAINT [CK_OrderItem_Price] CHECK ([UnitPrice] >= 0),
        CONSTRAINT [CK_OrderItem_Quantity] CHECK ([Quantity] > 0),
        CONSTRAINT [FK_OrderItems_CarVariants_CarVariantId] FOREIGN KEY ([CarVariantId]) REFERENCES [dbo].[CarVariants] ([Id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_OrderItems_Orders_OrderId] FOREIGN KEY ([OrderId]) REFERENCES [dbo].[Orders] ([Id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF OBJECT_ID(N''[dbo].[QuoteRequests]'', N''U'') IS NULL
    CREATE TABLE [dbo].[QuoteRequests] (
        [Id] int NOT NULL IDENTITY,
        [UserId] nvarchar(450) NOT NULL,
        [CarVariantId] int NOT NULL,
        [AssignedSalesId] nvarchar(450) NULL,
        [Phone] nvarchar(max) NOT NULL,
        [Message] nvarchar(max) NULL,
        [Status] nvarchar(max) NOT NULL,
        [Response] nvarchar(max) NULL,
        [CreatedAt] datetimeoffset NOT NULL,
        CONSTRAINT [PK_QuoteRequests] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_QuoteRequests_AspNetUsers_AssignedSalesId] FOREIGN KEY ([AssignedSalesId]) REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_QuoteRequests_AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_QuoteRequests_CarVariants_CarVariantId] FOREIGN KEY ([CarVariantId]) REFERENCES [dbo].[CarVariants] ([Id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF OBJECT_ID(N''[dbo].[Reviews]'', N''U'') IS NULL
    CREATE TABLE [dbo].[Reviews] (
        [Id] int NOT NULL IDENTITY,
        [CarVariantId] int NOT NULL,
        [UserId] nvarchar(450) NOT NULL,
        [Rating] int NOT NULL,
        [Comment] nvarchar(max) NOT NULL,
        [CreatedAt] datetimeoffset NOT NULL,
        CONSTRAINT [PK_Reviews] PRIMARY KEY ([Id]),
        CONSTRAINT [CK_Review_Rating] CHECK ([Rating] BETWEEN 1 AND 5),
        CONSTRAINT [FK_Reviews_AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_Reviews_CarVariants_CarVariantId] FOREIGN KEY ([CarVariantId]) REFERENCES [dbo].[CarVariants] ([Id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF OBJECT_ID(N''[dbo].[TestDriveBookings]'', N''U'') IS NULL
    CREATE TABLE [dbo].[TestDriveBookings] (
        [Id] int NOT NULL IDENTITY,
        [UserId] nvarchar(450) NOT NULL,
        [CarVariantId] int NOT NULL,
        [AssignedSalesId] nvarchar(450) NULL,
        [ScheduledAt] datetimeoffset NOT NULL,
        [Phone] nvarchar(max) NOT NULL,
        [Note] nvarchar(max) NULL,
        [Status] nvarchar(max) NOT NULL,
        CONSTRAINT [PK_TestDriveBookings] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_TestDriveBookings_AspNetUsers_AssignedSalesId] FOREIGN KEY ([AssignedSalesId]) REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_TestDriveBookings_AspNetUsers_UserId] FOREIGN KEY ([UserId]) REFERENCES [dbo].[AspNetUsers] ([Id]) ON DELETE NO ACTION,
        CONSTRAINT [FK_TestDriveBookings_CarVariants_CarVariantId] FOREIGN KEY ([CarVariantId]) REFERENCES [dbo].[CarVariants] ([Id]) ON DELETE NO ACTION
    );
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[AspNetRoles]'', N''U'') AND name = N''IX_AspNetRoles_NormalizedName'')
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.stats WHERE object_id = OBJECT_ID(N''[dbo].[AspNetRoles]'', N''U'') AND name = N''IX_AspNetRoles_NormalizedName'')
            THROW 51001, N''Standalone statistics conflict: dbo.AspNetRoles.IX_AspNetRoles_NormalizedName. Inspect manually; no objects dropped.'', 1;
        EXEC(N''CREATE UNIQUE INDEX [IX_AspNetRoles_NormalizedName] ON [dbo].[AspNetRoles] ([NormalizedName]) WHERE [NormalizedName] IS NOT NULL'');
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[AspNetUserRoles]'', N''U'') AND name = N''IX_AspNetUserRoles_RoleId'')
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.stats WHERE object_id = OBJECT_ID(N''[dbo].[AspNetUserRoles]'', N''U'') AND name = N''IX_AspNetUserRoles_RoleId'')
            THROW 51001, N''Standalone statistics conflict: dbo.AspNetUserRoles.IX_AspNetUserRoles_RoleId. Inspect manually; no objects dropped.'', 1;
        EXEC(N''CREATE INDEX [IX_AspNetUserRoles_RoleId] ON [dbo].[AspNetUserRoles] ([RoleId])'');
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[AspNetUsers]'', N''U'') AND name = N''IX_AspNetUsers_Email'')
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.stats WHERE object_id = OBJECT_ID(N''[dbo].[AspNetUsers]'', N''U'') AND name = N''IX_AspNetUsers_Email'')
            THROW 51001, N''Standalone statistics conflict: dbo.AspNetUsers.IX_AspNetUsers_Email. Inspect manually; no objects dropped.'', 1;
        EXEC(N''CREATE UNIQUE INDEX [IX_AspNetUsers_Email] ON [dbo].[AspNetUsers] ([Email]) WHERE [Email] IS NOT NULL'');
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[AspNetUsers]'', N''U'') AND name = N''IX_AspNetUsers_NormalizedUserName'')
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.stats WHERE object_id = OBJECT_ID(N''[dbo].[AspNetUsers]'', N''U'') AND name = N''IX_AspNetUsers_NormalizedUserName'')
            THROW 51001, N''Standalone statistics conflict: dbo.AspNetUsers.IX_AspNetUsers_NormalizedUserName. Inspect manually; no objects dropped.'', 1;
        EXEC(N''CREATE UNIQUE INDEX [IX_AspNetUsers_NormalizedUserName] ON [dbo].[AspNetUsers] ([NormalizedUserName]) WHERE [NormalizedUserName] IS NOT NULL'');
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[AuditLogs]'', N''U'') AND name = N''IX_AuditLogs_ActorId'')
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.stats WHERE object_id = OBJECT_ID(N''[dbo].[AuditLogs]'', N''U'') AND name = N''IX_AuditLogs_ActorId'')
            THROW 51001, N''Standalone statistics conflict: dbo.AuditLogs.IX_AuditLogs_ActorId. Inspect manually; no objects dropped.'', 1;
        EXEC(N''CREATE INDEX [IX_AuditLogs_ActorId] ON [dbo].[AuditLogs] ([ActorId])'');
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[Brands]'', N''U'') AND name = N''IX_Brands_Name'')
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.stats WHERE object_id = OBJECT_ID(N''[dbo].[Brands]'', N''U'') AND name = N''IX_Brands_Name'')
            THROW 51001, N''Standalone statistics conflict: dbo.Brands.IX_Brands_Name. Inspect manually; no objects dropped.'', 1;
        EXEC(N''CREATE UNIQUE INDEX [IX_Brands_Name] ON [dbo].[Brands] ([Name])'');
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[CarImages]'', N''U'') AND name = N''IX_CarImages_CarVariantId'')
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.stats WHERE object_id = OBJECT_ID(N''[dbo].[CarImages]'', N''U'') AND name = N''IX_CarImages_CarVariantId'')
            THROW 51001, N''Standalone statistics conflict: dbo.CarImages.IX_CarImages_CarVariantId. Inspect manually; no objects dropped.'', 1;
        EXEC(N''CREATE INDEX [IX_CarImages_CarVariantId] ON [dbo].[CarImages] ([CarVariantId])'');
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[CarInventories]'', N''U'') AND name = N''IX_CarInventories_CarVariantId'')
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.stats WHERE object_id = OBJECT_ID(N''[dbo].[CarInventories]'', N''U'') AND name = N''IX_CarInventories_CarVariantId'')
            THROW 51001, N''Standalone statistics conflict: dbo.CarInventories.IX_CarInventories_CarVariantId. Inspect manually; no objects dropped.'', 1;
        EXEC(N''CREATE UNIQUE INDEX [IX_CarInventories_CarVariantId] ON [dbo].[CarInventories] ([CarVariantId])'');
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[CarModels]'', N''U'') AND name = N''IX_CarModels_BrandId_Name'')
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.stats WHERE object_id = OBJECT_ID(N''[dbo].[CarModels]'', N''U'') AND name = N''IX_CarModels_BrandId_Name'')
            THROW 51001, N''Standalone statistics conflict: dbo.CarModels.IX_CarModels_BrandId_Name. Inspect manually; no objects dropped.'', 1;
        EXEC(N''CREATE UNIQUE INDEX [IX_CarModels_BrandId_Name] ON [dbo].[CarModels] ([BrandId], [Name])'');
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') AND name = N''IX_CarVariants_CarModelId'')
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.stats WHERE object_id = OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') AND name = N''IX_CarVariants_CarModelId'')
            THROW 51001, N''Standalone statistics conflict: dbo.CarVariants.IX_CarVariants_CarModelId. Inspect manually; no objects dropped.'', 1;
        EXEC(N''CREATE INDEX [IX_CarVariants_CarModelId] ON [dbo].[CarVariants] ([CarModelId])'');
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') AND name = N''IX_CarVariants_Code'')
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.stats WHERE object_id = OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') AND name = N''IX_CarVariants_Code'')
            THROW 51001, N''Standalone statistics conflict: dbo.CarVariants.IX_CarVariants_Code. Inspect manually; no objects dropped.'', 1;
        EXEC(N''CREATE UNIQUE INDEX [IX_CarVariants_Code] ON [dbo].[CarVariants] ([Code])'');
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') AND name = N''IX_CarVariants_IsVisible_Price'')
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.stats WHERE object_id = OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') AND name = N''IX_CarVariants_IsVisible_Price'')
            THROW 51001, N''Standalone statistics conflict: dbo.CarVariants.IX_CarVariants_IsVisible_Price. Inspect manually; no objects dropped.'', 1;
        EXEC(N''CREATE INDEX [IX_CarVariants_IsVisible_Price] ON [dbo].[CarVariants] ([IsVisible], [Price])'');
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') AND name = N''IX_CarVariants_Year_BodyStyle'')
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.stats WHERE object_id = OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') AND name = N''IX_CarVariants_Year_BodyStyle'')
            THROW 51001, N''Standalone statistics conflict: dbo.CarVariants.IX_CarVariants_Year_BodyStyle. Inspect manually; no objects dropped.'', 1;
        EXEC(N''CREATE INDEX [IX_CarVariants_Year_BodyStyle] ON [dbo].[CarVariants] ([Year], [BodyStyle])'');
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[Favorites]'', N''U'') AND name = N''IX_Favorites_CarVariantId'')
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.stats WHERE object_id = OBJECT_ID(N''[dbo].[Favorites]'', N''U'') AND name = N''IX_Favorites_CarVariantId'')
            THROW 51001, N''Standalone statistics conflict: dbo.Favorites.IX_Favorites_CarVariantId. Inspect manually; no objects dropped.'', 1;
        EXEC(N''CREATE INDEX [IX_Favorites_CarVariantId] ON [dbo].[Favorites] ([CarVariantId])'');
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[Favorites]'', N''U'') AND name = N''IX_Favorites_UserId_CarVariantId'')
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.stats WHERE object_id = OBJECT_ID(N''[dbo].[Favorites]'', N''U'') AND name = N''IX_Favorites_UserId_CarVariantId'')
            THROW 51001, N''Standalone statistics conflict: dbo.Favorites.IX_Favorites_UserId_CarVariantId. Inspect manually; no objects dropped.'', 1;
        EXEC(N''CREATE UNIQUE INDEX [IX_Favorites_UserId_CarVariantId] ON [dbo].[Favorites] ([UserId], [CarVariantId])'');
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[Notifications]'', N''U'') AND name = N''IX_Notifications_UserId'')
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.stats WHERE object_id = OBJECT_ID(N''[dbo].[Notifications]'', N''U'') AND name = N''IX_Notifications_UserId'')
            THROW 51001, N''Standalone statistics conflict: dbo.Notifications.IX_Notifications_UserId. Inspect manually; no objects dropped.'', 1;
        EXEC(N''CREATE INDEX [IX_Notifications_UserId] ON [dbo].[Notifications] ([UserId])'');
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[OrderHistories]'', N''U'') AND name = N''IX_OrderHistories_ActorId'')
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.stats WHERE object_id = OBJECT_ID(N''[dbo].[OrderHistories]'', N''U'') AND name = N''IX_OrderHistories_ActorId'')
            THROW 51001, N''Standalone statistics conflict: dbo.OrderHistories.IX_OrderHistories_ActorId. Inspect manually; no objects dropped.'', 1;
        EXEC(N''CREATE INDEX [IX_OrderHistories_ActorId] ON [dbo].[OrderHistories] ([ActorId])'');
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[OrderHistories]'', N''U'') AND name = N''IX_OrderHistories_OrderId'')
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.stats WHERE object_id = OBJECT_ID(N''[dbo].[OrderHistories]'', N''U'') AND name = N''IX_OrderHistories_OrderId'')
            THROW 51001, N''Standalone statistics conflict: dbo.OrderHistories.IX_OrderHistories_OrderId. Inspect manually; no objects dropped.'', 1;
        EXEC(N''CREATE INDEX [IX_OrderHistories_OrderId] ON [dbo].[OrderHistories] ([OrderId])'');
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[OrderItems]'', N''U'') AND name = N''IX_OrderItems_CarVariantId'')
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.stats WHERE object_id = OBJECT_ID(N''[dbo].[OrderItems]'', N''U'') AND name = N''IX_OrderItems_CarVariantId'')
            THROW 51001, N''Standalone statistics conflict: dbo.OrderItems.IX_OrderItems_CarVariantId. Inspect manually; no objects dropped.'', 1;
        EXEC(N''CREATE INDEX [IX_OrderItems_CarVariantId] ON [dbo].[OrderItems] ([CarVariantId])'');
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[OrderItems]'', N''U'') AND name = N''IX_OrderItems_OrderId'')
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.stats WHERE object_id = OBJECT_ID(N''[dbo].[OrderItems]'', N''U'') AND name = N''IX_OrderItems_OrderId'')
            THROW 51001, N''Standalone statistics conflict: dbo.OrderItems.IX_OrderItems_OrderId. Inspect manually; no objects dropped.'', 1;
        EXEC(N''CREATE INDEX [IX_OrderItems_OrderId] ON [dbo].[OrderItems] ([OrderId])'');
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[Orders]'', N''U'') AND name = N''IX_Orders_AssignedSalesId'')
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.stats WHERE object_id = OBJECT_ID(N''[dbo].[Orders]'', N''U'') AND name = N''IX_Orders_AssignedSalesId'')
            THROW 51001, N''Standalone statistics conflict: dbo.Orders.IX_Orders_AssignedSalesId. Inspect manually; no objects dropped.'', 1;
        EXEC(N''CREATE INDEX [IX_Orders_AssignedSalesId] ON [dbo].[Orders] ([AssignedSalesId])'');
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[Orders]'', N''U'') AND name = N''IX_Orders_Status_CreatedAt'')
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.stats WHERE object_id = OBJECT_ID(N''[dbo].[Orders]'', N''U'') AND name = N''IX_Orders_Status_CreatedAt'')
            THROW 51001, N''Standalone statistics conflict: dbo.Orders.IX_Orders_Status_CreatedAt. Inspect manually; no objects dropped.'', 1;
        EXEC(N''CREATE INDEX [IX_Orders_Status_CreatedAt] ON [dbo].[Orders] ([Status], [CreatedAt])'');
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[Orders]'', N''U'') AND name = N''IX_Orders_UserId'')
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.stats WHERE object_id = OBJECT_ID(N''[dbo].[Orders]'', N''U'') AND name = N''IX_Orders_UserId'')
            THROW 51001, N''Standalone statistics conflict: dbo.Orders.IX_Orders_UserId. Inspect manually; no objects dropped.'', 1;
        EXEC(N''CREATE INDEX [IX_Orders_UserId] ON [dbo].[Orders] ([UserId])'');
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[Payments]'', N''U'') AND name = N''IX_Payments_ConfirmedById'')
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.stats WHERE object_id = OBJECT_ID(N''[dbo].[Payments]'', N''U'') AND name = N''IX_Payments_ConfirmedById'')
            THROW 51001, N''Standalone statistics conflict: dbo.Payments.IX_Payments_ConfirmedById. Inspect manually; no objects dropped.'', 1;
        EXEC(N''CREATE INDEX [IX_Payments_ConfirmedById] ON [dbo].[Payments] ([ConfirmedById])'');
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[Payments]'', N''U'') AND name = N''IX_Payments_OrderId'')
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.stats WHERE object_id = OBJECT_ID(N''[dbo].[Payments]'', N''U'') AND name = N''IX_Payments_OrderId'')
            THROW 51001, N''Standalone statistics conflict: dbo.Payments.IX_Payments_OrderId. Inspect manually; no objects dropped.'', 1;
        EXEC(N''CREATE INDEX [IX_Payments_OrderId] ON [dbo].[Payments] ([OrderId])'');
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[Payments]'', N''U'') AND name = N''IX_Payments_Reference'')
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.stats WHERE object_id = OBJECT_ID(N''[dbo].[Payments]'', N''U'') AND name = N''IX_Payments_Reference'')
            THROW 51001, N''Standalone statistics conflict: dbo.Payments.IX_Payments_Reference. Inspect manually; no objects dropped.'', 1;
        EXEC(N''CREATE UNIQUE INDEX [IX_Payments_Reference] ON [dbo].[Payments] ([Reference])'');
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[QuoteRequests]'', N''U'') AND name = N''IX_QuoteRequests_AssignedSalesId'')
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.stats WHERE object_id = OBJECT_ID(N''[dbo].[QuoteRequests]'', N''U'') AND name = N''IX_QuoteRequests_AssignedSalesId'')
            THROW 51001, N''Standalone statistics conflict: dbo.QuoteRequests.IX_QuoteRequests_AssignedSalesId. Inspect manually; no objects dropped.'', 1;
        EXEC(N''CREATE INDEX [IX_QuoteRequests_AssignedSalesId] ON [dbo].[QuoteRequests] ([AssignedSalesId])'');
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[QuoteRequests]'', N''U'') AND name = N''IX_QuoteRequests_CarVariantId'')
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.stats WHERE object_id = OBJECT_ID(N''[dbo].[QuoteRequests]'', N''U'') AND name = N''IX_QuoteRequests_CarVariantId'')
            THROW 51001, N''Standalone statistics conflict: dbo.QuoteRequests.IX_QuoteRequests_CarVariantId. Inspect manually; no objects dropped.'', 1;
        EXEC(N''CREATE INDEX [IX_QuoteRequests_CarVariantId] ON [dbo].[QuoteRequests] ([CarVariantId])'');
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[QuoteRequests]'', N''U'') AND name = N''IX_QuoteRequests_UserId'')
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.stats WHERE object_id = OBJECT_ID(N''[dbo].[QuoteRequests]'', N''U'') AND name = N''IX_QuoteRequests_UserId'')
            THROW 51001, N''Standalone statistics conflict: dbo.QuoteRequests.IX_QuoteRequests_UserId. Inspect manually; no objects dropped.'', 1;
        EXEC(N''CREATE INDEX [IX_QuoteRequests_UserId] ON [dbo].[QuoteRequests] ([UserId])'');
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[RefreshSessions]'', N''U'') AND name = N''IX_RefreshSessions_TokenHash'')
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.stats WHERE object_id = OBJECT_ID(N''[dbo].[RefreshSessions]'', N''U'') AND name = N''IX_RefreshSessions_TokenHash'')
            THROW 51001, N''Standalone statistics conflict: dbo.RefreshSessions.IX_RefreshSessions_TokenHash. Inspect manually; no objects dropped.'', 1;
        EXEC(N''CREATE UNIQUE INDEX [IX_RefreshSessions_TokenHash] ON [dbo].[RefreshSessions] ([TokenHash])'');
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[RefreshSessions]'', N''U'') AND name = N''IX_RefreshSessions_UserId'')
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.stats WHERE object_id = OBJECT_ID(N''[dbo].[RefreshSessions]'', N''U'') AND name = N''IX_RefreshSessions_UserId'')
            THROW 51001, N''Standalone statistics conflict: dbo.RefreshSessions.IX_RefreshSessions_UserId. Inspect manually; no objects dropped.'', 1;
        EXEC(N''CREATE INDEX [IX_RefreshSessions_UserId] ON [dbo].[RefreshSessions] ([UserId])'');
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[Reviews]'', N''U'') AND name = N''IX_Reviews_CarVariantId'')
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.stats WHERE object_id = OBJECT_ID(N''[dbo].[Reviews]'', N''U'') AND name = N''IX_Reviews_CarVariantId'')
            THROW 51001, N''Standalone statistics conflict: dbo.Reviews.IX_Reviews_CarVariantId. Inspect manually; no objects dropped.'', 1;
        EXEC(N''CREATE INDEX [IX_Reviews_CarVariantId] ON [dbo].[Reviews] ([CarVariantId])'');
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[Reviews]'', N''U'') AND name = N''IX_Reviews_UserId_CarVariantId'')
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.stats WHERE object_id = OBJECT_ID(N''[dbo].[Reviews]'', N''U'') AND name = N''IX_Reviews_UserId_CarVariantId'')
            THROW 51001, N''Standalone statistics conflict: dbo.Reviews.IX_Reviews_UserId_CarVariantId. Inspect manually; no objects dropped.'', 1;
        EXEC(N''CREATE UNIQUE INDEX [IX_Reviews_UserId_CarVariantId] ON [dbo].[Reviews] ([UserId], [CarVariantId])'');
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[TestDriveBookings]'', N''U'') AND name = N''IX_TestDriveBookings_AssignedSalesId_ScheduledAt'')
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.stats WHERE object_id = OBJECT_ID(N''[dbo].[TestDriveBookings]'', N''U'') AND name = N''IX_TestDriveBookings_AssignedSalesId_ScheduledAt'')
            THROW 51001, N''Standalone statistics conflict: dbo.TestDriveBookings.IX_TestDriveBookings_AssignedSalesId_ScheduledAt. Inspect manually; no objects dropped.'', 1;
        EXEC(N''CREATE INDEX [IX_TestDriveBookings_AssignedSalesId_ScheduledAt] ON [dbo].[TestDriveBookings] ([AssignedSalesId], [ScheduledAt])'');
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[TestDriveBookings]'', N''U'') AND name = N''IX_TestDriveBookings_CarVariantId'')
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.stats WHERE object_id = OBJECT_ID(N''[dbo].[TestDriveBookings]'', N''U'') AND name = N''IX_TestDriveBookings_CarVariantId'')
            THROW 51001, N''Standalone statistics conflict: dbo.TestDriveBookings.IX_TestDriveBookings_CarVariantId. Inspect manually; no objects dropped.'', 1;
        EXEC(N''CREATE INDEX [IX_TestDriveBookings_CarVariantId] ON [dbo].[TestDriveBookings] ([CarVariantId])'');
    END;
END;

IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID(N''[dbo].[TestDriveBookings]'', N''U'') AND name = N''IX_TestDriveBookings_UserId'')
    BEGIN
        IF EXISTS (SELECT 1 FROM sys.stats WHERE object_id = OBJECT_ID(N''[dbo].[TestDriveBookings]'', N''U'') AND name = N''IX_TestDriveBookings_UserId'')
            THROW 51001, N''Standalone statistics conflict: dbo.TestDriveBookings.IX_TestDriveBookings_UserId. Inspect manually; no objects dropped.'', 1;
        EXEC(N''CREATE INDEX [IX_TestDriveBookings_UserId] ON [dbo].[TestDriveBookings] ([UserId])'');
    END;
END;




-- Validate before committing migration history.
IF OBJECT_ID(N''[dbo].[AspNetRoles]'', N''U'') IS NULL
    THROW 51000, N''Missing table: AspNetRoles. No migration history committed.'', 1;
IF (SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID(N''[dbo].[AspNetRoles]'', N''U'')) <> 4
    THROW 51000, N''Column count mismatch: AspNetRoles.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[AspNetRoles]'', N''U'') AND c.name = N''Id'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = 900)
    THROW 51000, N''Column definition mismatch: AspNetRoles.Id.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[AspNetRoles]'', N''U'') AND c.name = N''ConcurrencyStamp'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 1 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = -1)
    THROW 51000, N''Column definition mismatch: AspNetRoles.ConcurrencyStamp.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[AspNetRoles]'', N''U'') AND c.name = N''Name'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 1 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = -1)
    THROW 51000, N''Column definition mismatch: AspNetRoles.Name.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[AspNetRoles]'', N''U'') AND c.name = N''NormalizedName'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 1 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = 512)
    THROW 51000, N''Column definition mismatch: AspNetRoles.NormalizedName.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[AspNetRoles]'', N''U'') AND i.is_primary_key = 1 AND i.is_disabled = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''Id'')
    THROW 51000, N''Primary key mismatch: AspNetRoles.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[AspNetRoles]'', N''U'') AND i.name = N''IX_AspNetRoles_NormalizedName'' AND i.is_unique = 1 AND i.is_disabled = 0 AND i.is_hypothetical = 0 AND i.type = 2 AND NOT EXISTS (SELECT 1 FROM sys.index_columns extra WHERE extra.object_id = i.object_id AND extra.index_id = i.index_id AND (extra.is_included_column = 1 OR (extra.key_ordinal > 0 AND extra.is_descending_key = 1))) AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''NormalizedName'' AND UPPER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(i.filter_definition, N''['', N''''), N'']'', N''''), N''('', N''''), N'')'', N''''), N'' '', N''''), CHAR(13), N''''), CHAR(10), N'''')) = UPPER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(N''[NormalizedName] IS NOT NULL'', N''['', N''''), N'']'', N''''), N''('', N''''), N'')'', N''''), N'' '', N''''), CHAR(13), N''''), CHAR(10), N'''')))
    THROW 51000, N''Index definition mismatch: AspNetRoles.IX_AspNetRoles_NormalizedName.'', 1;
IF OBJECT_ID(N''[dbo].[AspNetUserRoles]'', N''U'') IS NULL
    THROW 51000, N''Missing table: AspNetUserRoles. No migration history committed.'', 1;
IF (SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID(N''[dbo].[AspNetUserRoles]'', N''U'')) <> 2
    THROW 51000, N''Column count mismatch: AspNetUserRoles.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[AspNetUserRoles]'', N''U'') AND c.name = N''UserId'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = 900)
    THROW 51000, N''Column definition mismatch: AspNetUserRoles.UserId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[AspNetUserRoles]'', N''U'') AND c.name = N''RoleId'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = 900)
    THROW 51000, N''Column definition mismatch: AspNetUserRoles.RoleId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[AspNetUserRoles]'', N''U'') AND i.is_primary_key = 1 AND i.is_disabled = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''UserId|RoleId'')
    THROW 51000, N''Primary key mismatch: AspNetUserRoles.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[AspNetUserRoles]'', N''U'') AND i.name = N''IX_AspNetUserRoles_RoleId'' AND i.is_unique = 0 AND i.is_disabled = 0 AND i.is_hypothetical = 0 AND i.type = 2 AND NOT EXISTS (SELECT 1 FROM sys.index_columns extra WHERE extra.object_id = i.object_id AND extra.index_id = i.index_id AND (extra.is_included_column = 1 OR (extra.key_ordinal > 0 AND extra.is_descending_key = 1))) AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''RoleId'' AND i.has_filter = 0)
    THROW 51000, N''Index definition mismatch: AspNetUserRoles.IX_AspNetUserRoles_RoleId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys f WHERE f.parent_object_id = OBJECT_ID(N''[dbo].[AspNetUserRoles]'', N''U'') AND f.name = N''FK_AspNetUserRoles_AspNetRoles_RoleId'' AND f.referenced_object_id = OBJECT_ID(N''[dbo].[AspNetRoles]'') AND f.is_disabled = 0 AND f.is_not_trusted = 0 AND f.delete_referential_action = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), pc.name + N'':'' + rc.name), N''|'') WITHIN GROUP (ORDER BY fc.constraint_column_id) FROM sys.foreign_key_columns fc JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id WHERE fc.constraint_object_id = f.object_id) = N''RoleId:Id'')
    THROW 51000, N''Foreign key mismatch: FK_AspNetUserRoles_AspNetRoles_RoleId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys f WHERE f.parent_object_id = OBJECT_ID(N''[dbo].[AspNetUserRoles]'', N''U'') AND f.name = N''FK_AspNetUserRoles_AspNetUsers_UserId'' AND f.referenced_object_id = OBJECT_ID(N''[dbo].[AspNetUsers]'') AND f.is_disabled = 0 AND f.is_not_trusted = 0 AND f.delete_referential_action = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), pc.name + N'':'' + rc.name), N''|'') WITHIN GROUP (ORDER BY fc.constraint_column_id) FROM sys.foreign_key_columns fc JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id WHERE fc.constraint_object_id = f.object_id) = N''UserId:Id'')
    THROW 51000, N''Foreign key mismatch: FK_AspNetUserRoles_AspNetUsers_UserId.'', 1;
IF OBJECT_ID(N''[dbo].[AspNetUsers]'', N''U'') IS NULL
    THROW 51000, N''Missing table: AspNetUsers. No migration history committed.'', 1;
IF (SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID(N''[dbo].[AspNetUsers]'', N''U'')) <> 17
    THROW 51000, N''Column count mismatch: AspNetUsers.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[AspNetUsers]'', N''U'') AND c.name = N''Id'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = 900)
    THROW 51000, N''Column definition mismatch: AspNetUsers.Id.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[AspNetUsers]'', N''U'') AND c.name = N''AccessFailedCount'' AND TYPE_NAME(c.system_type_id) = N''int'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: AspNetUsers.AccessFailedCount.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[AspNetUsers]'', N''U'') AND c.name = N''Address'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 1 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = 600)
    THROW 51000, N''Column definition mismatch: AspNetUsers.Address.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[AspNetUsers]'', N''U'') AND c.name = N''ConcurrencyStamp'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 1 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = -1)
    THROW 51000, N''Column definition mismatch: AspNetUsers.ConcurrencyStamp.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[AspNetUsers]'', N''U'') AND c.name = N''Email'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 1 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = 512)
    THROW 51000, N''Column definition mismatch: AspNetUsers.Email.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[AspNetUsers]'', N''U'') AND c.name = N''EmailConfirmed'' AND TYPE_NAME(c.system_type_id) = N''bit'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: AspNetUsers.EmailConfirmed.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[AspNetUsers]'', N''U'') AND c.name = N''FullName'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = 200)
    THROW 51000, N''Column definition mismatch: AspNetUsers.FullName.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[AspNetUsers]'', N''U'') AND c.name = N''LockoutEnabled'' AND TYPE_NAME(c.system_type_id) = N''bit'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: AspNetUsers.LockoutEnabled.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[AspNetUsers]'', N''U'') AND c.name = N''LockoutEnd'' AND TYPE_NAME(c.system_type_id) = N''datetimeoffset'' AND c.is_nullable = 1 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: AspNetUsers.LockoutEnd.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[AspNetUsers]'', N''U'') AND c.name = N''NormalizedEmail'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 1 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = 512)
    THROW 51000, N''Column definition mismatch: AspNetUsers.NormalizedEmail.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[AspNetUsers]'', N''U'') AND c.name = N''NormalizedUserName'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 1 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = 512)
    THROW 51000, N''Column definition mismatch: AspNetUsers.NormalizedUserName.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[AspNetUsers]'', N''U'') AND c.name = N''PasswordHash'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 1 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = -1)
    THROW 51000, N''Column definition mismatch: AspNetUsers.PasswordHash.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[AspNetUsers]'', N''U'') AND c.name = N''PhoneNumber'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 1 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = -1)
    THROW 51000, N''Column definition mismatch: AspNetUsers.PhoneNumber.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[AspNetUsers]'', N''U'') AND c.name = N''PhoneNumberConfirmed'' AND TYPE_NAME(c.system_type_id) = N''bit'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: AspNetUsers.PhoneNumberConfirmed.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[AspNetUsers]'', N''U'') AND c.name = N''SecurityStamp'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 1 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = -1)
    THROW 51000, N''Column definition mismatch: AspNetUsers.SecurityStamp.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[AspNetUsers]'', N''U'') AND c.name = N''TwoFactorEnabled'' AND TYPE_NAME(c.system_type_id) = N''bit'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: AspNetUsers.TwoFactorEnabled.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[AspNetUsers]'', N''U'') AND c.name = N''UserName'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 1 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = -1)
    THROW 51000, N''Column definition mismatch: AspNetUsers.UserName.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[AspNetUsers]'', N''U'') AND i.is_primary_key = 1 AND i.is_disabled = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''Id'')
    THROW 51000, N''Primary key mismatch: AspNetUsers.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[AspNetUsers]'', N''U'') AND i.name = N''IX_AspNetUsers_Email'' AND i.is_unique = 1 AND i.is_disabled = 0 AND i.is_hypothetical = 0 AND i.type = 2 AND NOT EXISTS (SELECT 1 FROM sys.index_columns extra WHERE extra.object_id = i.object_id AND extra.index_id = i.index_id AND (extra.is_included_column = 1 OR (extra.key_ordinal > 0 AND extra.is_descending_key = 1))) AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''Email'' AND UPPER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(i.filter_definition, N''['', N''''), N'']'', N''''), N''('', N''''), N'')'', N''''), N'' '', N''''), CHAR(13), N''''), CHAR(10), N'''')) = UPPER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(N''[Email] IS NOT NULL'', N''['', N''''), N'']'', N''''), N''('', N''''), N'')'', N''''), N'' '', N''''), CHAR(13), N''''), CHAR(10), N'''')))
    THROW 51000, N''Index definition mismatch: AspNetUsers.IX_AspNetUsers_Email.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[AspNetUsers]'', N''U'') AND i.name = N''IX_AspNetUsers_NormalizedUserName'' AND i.is_unique = 1 AND i.is_disabled = 0 AND i.is_hypothetical = 0 AND i.type = 2 AND NOT EXISTS (SELECT 1 FROM sys.index_columns extra WHERE extra.object_id = i.object_id AND extra.index_id = i.index_id AND (extra.is_included_column = 1 OR (extra.key_ordinal > 0 AND extra.is_descending_key = 1))) AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''NormalizedUserName'' AND UPPER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(i.filter_definition, N''['', N''''), N'']'', N''''), N''('', N''''), N'')'', N''''), N'' '', N''''), CHAR(13), N''''), CHAR(10), N'''')) = UPPER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(N''[NormalizedUserName] IS NOT NULL'', N''['', N''''), N'']'', N''''), N''('', N''''), N'')'', N''''), N'' '', N''''), CHAR(13), N''''), CHAR(10), N'''')))
    THROW 51000, N''Index definition mismatch: AspNetUsers.IX_AspNetUsers_NormalizedUserName.'', 1;
IF OBJECT_ID(N''[dbo].[AuditLogs]'', N''U'') IS NULL
    THROW 51000, N''Missing table: AuditLogs. No migration history committed.'', 1;
IF (SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID(N''[dbo].[AuditLogs]'', N''U'')) <> 5
    THROW 51000, N''Column count mismatch: AuditLogs.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[AuditLogs]'', N''U'') AND c.name = N''Id'' AND TYPE_NAME(c.system_type_id) = N''int'' AND c.is_nullable = 0 AND c.is_identity = 1 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: AuditLogs.Id.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[AuditLogs]'', N''U'') AND c.name = N''Action'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = -1)
    THROW 51000, N''Column definition mismatch: AuditLogs.Action.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[AuditLogs]'', N''U'') AND c.name = N''ActorId'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = 900)
    THROW 51000, N''Column definition mismatch: AuditLogs.ActorId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[AuditLogs]'', N''U'') AND c.name = N''At'' AND TYPE_NAME(c.system_type_id) = N''datetimeoffset'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: AuditLogs.At.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[AuditLogs]'', N''U'') AND c.name = N''Resource'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = -1)
    THROW 51000, N''Column definition mismatch: AuditLogs.Resource.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[AuditLogs]'', N''U'') AND i.is_primary_key = 1 AND i.is_disabled = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''Id'')
    THROW 51000, N''Primary key mismatch: AuditLogs.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[AuditLogs]'', N''U'') AND i.name = N''IX_AuditLogs_ActorId'' AND i.is_unique = 0 AND i.is_disabled = 0 AND i.is_hypothetical = 0 AND i.type = 2 AND NOT EXISTS (SELECT 1 FROM sys.index_columns extra WHERE extra.object_id = i.object_id AND extra.index_id = i.index_id AND (extra.is_included_column = 1 OR (extra.key_ordinal > 0 AND extra.is_descending_key = 1))) AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''ActorId'' AND i.has_filter = 0)
    THROW 51000, N''Index definition mismatch: AuditLogs.IX_AuditLogs_ActorId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys f WHERE f.parent_object_id = OBJECT_ID(N''[dbo].[AuditLogs]'', N''U'') AND f.name = N''FK_AuditLogs_AspNetUsers_ActorId'' AND f.referenced_object_id = OBJECT_ID(N''[dbo].[AspNetUsers]'') AND f.is_disabled = 0 AND f.is_not_trusted = 0 AND f.delete_referential_action = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), pc.name + N'':'' + rc.name), N''|'') WITHIN GROUP (ORDER BY fc.constraint_column_id) FROM sys.foreign_key_columns fc JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id WHERE fc.constraint_object_id = f.object_id) = N''ActorId:Id'')
    THROW 51000, N''Foreign key mismatch: FK_AuditLogs_AspNetUsers_ActorId.'', 1;
IF OBJECT_ID(N''[dbo].[Brands]'', N''U'') IS NULL
    THROW 51000, N''Missing table: Brands. No migration history committed.'', 1;
IF (SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID(N''[dbo].[Brands]'', N''U'')) <> 4
    THROW 51000, N''Column count mismatch: Brands.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Brands]'', N''U'') AND c.name = N''Id'' AND TYPE_NAME(c.system_type_id) = N''int'' AND c.is_nullable = 0 AND c.is_identity = 1 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: Brands.Id.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Brands]'', N''U'') AND c.name = N''IsActive'' AND TYPE_NAME(c.system_type_id) = N''bit'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: Brands.IsActive.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Brands]'', N''U'') AND c.name = N''LogoUrl'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 1 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = -1)
    THROW 51000, N''Column definition mismatch: Brands.LogoUrl.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Brands]'', N''U'') AND c.name = N''Name'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = 160)
    THROW 51000, N''Column definition mismatch: Brands.Name.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[Brands]'', N''U'') AND i.is_primary_key = 1 AND i.is_disabled = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''Id'')
    THROW 51000, N''Primary key mismatch: Brands.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[Brands]'', N''U'') AND i.name = N''IX_Brands_Name'' AND i.is_unique = 1 AND i.is_disabled = 0 AND i.is_hypothetical = 0 AND i.type = 2 AND NOT EXISTS (SELECT 1 FROM sys.index_columns extra WHERE extra.object_id = i.object_id AND extra.index_id = i.index_id AND (extra.is_included_column = 1 OR (extra.key_ordinal > 0 AND extra.is_descending_key = 1))) AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''Name'' AND i.has_filter = 0)
    THROW 51000, N''Index definition mismatch: Brands.IX_Brands_Name.'', 1;
IF OBJECT_ID(N''[dbo].[CarImages]'', N''U'') IS NULL
    THROW 51000, N''Missing table: CarImages. No migration history committed.'', 1;
IF (SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID(N''[dbo].[CarImages]'', N''U'')) <> 4
    THROW 51000, N''Column count mismatch: CarImages.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[CarImages]'', N''U'') AND c.name = N''Id'' AND TYPE_NAME(c.system_type_id) = N''int'' AND c.is_nullable = 0 AND c.is_identity = 1 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: CarImages.Id.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[CarImages]'', N''U'') AND c.name = N''CarVariantId'' AND TYPE_NAME(c.system_type_id) = N''int'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: CarImages.CarVariantId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[CarImages]'', N''U'') AND c.name = N''SortOrder'' AND TYPE_NAME(c.system_type_id) = N''int'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: CarImages.SortOrder.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[CarImages]'', N''U'') AND c.name = N''Url'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = -1)
    THROW 51000, N''Column definition mismatch: CarImages.Url.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[CarImages]'', N''U'') AND i.is_primary_key = 1 AND i.is_disabled = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''Id'')
    THROW 51000, N''Primary key mismatch: CarImages.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[CarImages]'', N''U'') AND i.name = N''IX_CarImages_CarVariantId'' AND i.is_unique = 0 AND i.is_disabled = 0 AND i.is_hypothetical = 0 AND i.type = 2 AND NOT EXISTS (SELECT 1 FROM sys.index_columns extra WHERE extra.object_id = i.object_id AND extra.index_id = i.index_id AND (extra.is_included_column = 1 OR (extra.key_ordinal > 0 AND extra.is_descending_key = 1))) AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''CarVariantId'' AND i.has_filter = 0)
    THROW 51000, N''Index definition mismatch: CarImages.IX_CarImages_CarVariantId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys f WHERE f.parent_object_id = OBJECT_ID(N''[dbo].[CarImages]'', N''U'') AND f.name = N''FK_CarImages_CarVariants_CarVariantId'' AND f.referenced_object_id = OBJECT_ID(N''[dbo].[CarVariants]'') AND f.is_disabled = 0 AND f.is_not_trusted = 0 AND f.delete_referential_action = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), pc.name + N'':'' + rc.name), N''|'') WITHIN GROUP (ORDER BY fc.constraint_column_id) FROM sys.foreign_key_columns fc JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id WHERE fc.constraint_object_id = f.object_id) = N''CarVariantId:Id'')
    THROW 51000, N''Foreign key mismatch: FK_CarImages_CarVariants_CarVariantId.'', 1;
IF OBJECT_ID(N''[dbo].[CarInventories]'', N''U'') IS NULL
    THROW 51000, N''Missing table: CarInventories. No migration history committed.'', 1;
IF (SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID(N''[dbo].[CarInventories]'', N''U'')) <> 5
    THROW 51000, N''Column count mismatch: CarInventories.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[CarInventories]'', N''U'') AND c.name = N''Id'' AND TYPE_NAME(c.system_type_id) = N''int'' AND c.is_nullable = 0 AND c.is_identity = 1 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: CarInventories.Id.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[CarInventories]'', N''U'') AND c.name = N''CarVariantId'' AND TYPE_NAME(c.system_type_id) = N''int'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: CarInventories.CarVariantId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[CarInventories]'', N''U'') AND c.name = N''RowVersion'' AND TYPE_NAME(c.system_type_id) = N''timestamp'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: CarInventories.RowVersion.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[CarInventories]'', N''U'') AND c.name = N''Sold'' AND TYPE_NAME(c.system_type_id) = N''int'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: CarInventories.Sold.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[CarInventories]'', N''U'') AND c.name = N''Stock'' AND TYPE_NAME(c.system_type_id) = N''int'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: CarInventories.Stock.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[CarInventories]'', N''U'') AND i.is_primary_key = 1 AND i.is_disabled = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''Id'')
    THROW 51000, N''Primary key mismatch: CarInventories.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[CarInventories]'', N''U'') AND i.name = N''IX_CarInventories_CarVariantId'' AND i.is_unique = 1 AND i.is_disabled = 0 AND i.is_hypothetical = 0 AND i.type = 2 AND NOT EXISTS (SELECT 1 FROM sys.index_columns extra WHERE extra.object_id = i.object_id AND extra.index_id = i.index_id AND (extra.is_included_column = 1 OR (extra.key_ordinal > 0 AND extra.is_descending_key = 1))) AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''CarVariantId'' AND i.has_filter = 0)
    THROW 51000, N''Index definition mismatch: CarInventories.IX_CarInventories_CarVariantId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys f WHERE f.parent_object_id = OBJECT_ID(N''[dbo].[CarInventories]'', N''U'') AND f.name = N''FK_CarInventories_CarVariants_CarVariantId'' AND f.referenced_object_id = OBJECT_ID(N''[dbo].[CarVariants]'') AND f.is_disabled = 0 AND f.is_not_trusted = 0 AND f.delete_referential_action = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), pc.name + N'':'' + rc.name), N''|'') WITHIN GROUP (ORDER BY fc.constraint_column_id) FROM sys.foreign_key_columns fc JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id WHERE fc.constraint_object_id = f.object_id) = N''CarVariantId:Id'')
    THROW 51000, N''Foreign key mismatch: FK_CarInventories_CarVariants_CarVariantId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints c WHERE c.parent_object_id = OBJECT_ID(N''[dbo].[CarInventories]'', N''U'') AND c.name = N''CK_Inventory_Sold'' AND c.is_disabled = 0 AND c.is_not_trusted = 0 AND UPPER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(c.definition, N''['', N''''), N'']'', N''''), N''('', N''''), N'')'', N''''), N'' '', N''''), CHAR(13), N''''), CHAR(10), N'''')) = UPPER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(N''[Sold] >= 0'', N''['', N''''), N'']'', N''''), N''('', N''''), N'')'', N''''), N'' '', N''''), CHAR(13), N''''), CHAR(10), N'''')))
    THROW 51000, N''Check constraint mismatch: CK_Inventory_Sold.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints c WHERE c.parent_object_id = OBJECT_ID(N''[dbo].[CarInventories]'', N''U'') AND c.name = N''CK_Inventory_Stock'' AND c.is_disabled = 0 AND c.is_not_trusted = 0 AND UPPER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(c.definition, N''['', N''''), N'']'', N''''), N''('', N''''), N'')'', N''''), N'' '', N''''), CHAR(13), N''''), CHAR(10), N'''')) = UPPER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(N''[Stock] >= 0'', N''['', N''''), N'']'', N''''), N''('', N''''), N'')'', N''''), N'' '', N''''), CHAR(13), N''''), CHAR(10), N'''')))
    THROW 51000, N''Check constraint mismatch: CK_Inventory_Stock.'', 1;
IF OBJECT_ID(N''[dbo].[CarModels]'', N''U'') IS NULL
    THROW 51000, N''Missing table: CarModels. No migration history committed.'', 1;
IF (SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID(N''[dbo].[CarModels]'', N''U'')) <> 3
    THROW 51000, N''Column count mismatch: CarModels.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[CarModels]'', N''U'') AND c.name = N''Id'' AND TYPE_NAME(c.system_type_id) = N''int'' AND c.is_nullable = 0 AND c.is_identity = 1 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: CarModels.Id.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[CarModels]'', N''U'') AND c.name = N''BrandId'' AND TYPE_NAME(c.system_type_id) = N''int'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: CarModels.BrandId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[CarModels]'', N''U'') AND c.name = N''Name'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = 200)
    THROW 51000, N''Column definition mismatch: CarModels.Name.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[CarModels]'', N''U'') AND i.is_primary_key = 1 AND i.is_disabled = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''Id'')
    THROW 51000, N''Primary key mismatch: CarModels.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[CarModels]'', N''U'') AND i.name = N''IX_CarModels_BrandId_Name'' AND i.is_unique = 1 AND i.is_disabled = 0 AND i.is_hypothetical = 0 AND i.type = 2 AND NOT EXISTS (SELECT 1 FROM sys.index_columns extra WHERE extra.object_id = i.object_id AND extra.index_id = i.index_id AND (extra.is_included_column = 1 OR (extra.key_ordinal > 0 AND extra.is_descending_key = 1))) AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''BrandId|Name'' AND i.has_filter = 0)
    THROW 51000, N''Index definition mismatch: CarModels.IX_CarModels_BrandId_Name.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys f WHERE f.parent_object_id = OBJECT_ID(N''[dbo].[CarModels]'', N''U'') AND f.name = N''FK_CarModels_Brands_BrandId'' AND f.referenced_object_id = OBJECT_ID(N''[dbo].[Brands]'') AND f.is_disabled = 0 AND f.is_not_trusted = 0 AND f.delete_referential_action = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), pc.name + N'':'' + rc.name), N''|'') WITHIN GROUP (ORDER BY fc.constraint_column_id) FROM sys.foreign_key_columns fc JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id WHERE fc.constraint_object_id = f.object_id) = N''BrandId:Id'')
    THROW 51000, N''Foreign key mismatch: FK_CarModels_Brands_BrandId.'', 1;
IF OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') IS NULL
    THROW 51000, N''Missing table: CarVariants. No migration history committed.'', 1;
IF (SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID(N''[dbo].[CarVariants]'', N''U'')) <> 24
    THROW 51000, N''Column count mismatch: CarVariants.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') AND c.name = N''Id'' AND TYPE_NAME(c.system_type_id) = N''int'' AND c.is_nullable = 0 AND c.is_identity = 1 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: CarVariants.Id.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') AND c.name = N''BodyStyle'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = 900)
    THROW 51000, N''Column definition mismatch: CarVariants.BodyStyle.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') AND c.name = N''CarModelId'' AND TYPE_NAME(c.system_type_id) = N''int'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: CarVariants.CarModelId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') AND c.name = N''Code'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = 100)
    THROW 51000, N''Column definition mismatch: CarVariants.Code.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') AND c.name = N''Colors'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = -1)
    THROW 51000, N''Column definition mismatch: CarVariants.Colors.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') AND c.name = N''Consumption'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = -1)
    THROW 51000, N''Column definition mismatch: CarVariants.Consumption.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') AND c.name = N''CreatedAt'' AND TYPE_NAME(c.system_type_id) = N''datetimeoffset'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: CarVariants.CreatedAt.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') AND c.name = N''Description'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = -1)
    THROW 51000, N''Column definition mismatch: CarVariants.Description.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') AND c.name = N''Dimensions'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = -1)
    THROW 51000, N''Column definition mismatch: CarVariants.Dimensions.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') AND c.name = N''Drivetrain'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = -1)
    THROW 51000, N''Column definition mismatch: CarVariants.Drivetrain.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') AND c.name = N''Engine'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = -1)
    THROW 51000, N''Column definition mismatch: CarVariants.Engine.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') AND c.name = N''Fuel'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = -1)
    THROW 51000, N''Column definition mismatch: CarVariants.Fuel.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') AND c.name = N''IsFeatured'' AND TYPE_NAME(c.system_type_id) = N''bit'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: CarVariants.IsFeatured.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') AND c.name = N''IsVisible'' AND TYPE_NAME(c.system_type_id) = N''bit'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: CarVariants.IsVisible.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') AND c.name = N''Name'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = 240)
    THROW 51000, N''Column definition mismatch: CarVariants.Name.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') AND c.name = N''Origin'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = -1)
    THROW 51000, N''Column definition mismatch: CarVariants.Origin.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') AND c.name = N''Power'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = -1)
    THROW 51000, N''Column definition mismatch: CarVariants.Power.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') AND c.name = N''Price'' AND TYPE_NAME(c.system_type_id) = N''decimal'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.precision = 18 AND c.scale = 2)
    THROW 51000, N''Column definition mismatch: CarVariants.Price.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') AND c.name = N''RowVersion'' AND TYPE_NAME(c.system_type_id) = N''timestamp'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: CarVariants.RowVersion.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') AND c.name = N''Seats'' AND TYPE_NAME(c.system_type_id) = N''int'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: CarVariants.Seats.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') AND c.name = N''Torque'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = -1)
    THROW 51000, N''Column definition mismatch: CarVariants.Torque.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') AND c.name = N''Transmission'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = -1)
    THROW 51000, N''Column definition mismatch: CarVariants.Transmission.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') AND c.name = N''Views'' AND TYPE_NAME(c.system_type_id) = N''int'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: CarVariants.Views.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') AND c.name = N''Year'' AND TYPE_NAME(c.system_type_id) = N''int'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: CarVariants.Year.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') AND i.is_primary_key = 1 AND i.is_disabled = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''Id'')
    THROW 51000, N''Primary key mismatch: CarVariants.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') AND i.name = N''IX_CarVariants_CarModelId'' AND i.is_unique = 0 AND i.is_disabled = 0 AND i.is_hypothetical = 0 AND i.type = 2 AND NOT EXISTS (SELECT 1 FROM sys.index_columns extra WHERE extra.object_id = i.object_id AND extra.index_id = i.index_id AND (extra.is_included_column = 1 OR (extra.key_ordinal > 0 AND extra.is_descending_key = 1))) AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''CarModelId'' AND i.has_filter = 0)
    THROW 51000, N''Index definition mismatch: CarVariants.IX_CarVariants_CarModelId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') AND i.name = N''IX_CarVariants_Code'' AND i.is_unique = 1 AND i.is_disabled = 0 AND i.is_hypothetical = 0 AND i.type = 2 AND NOT EXISTS (SELECT 1 FROM sys.index_columns extra WHERE extra.object_id = i.object_id AND extra.index_id = i.index_id AND (extra.is_included_column = 1 OR (extra.key_ordinal > 0 AND extra.is_descending_key = 1))) AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''Code'' AND i.has_filter = 0)
    THROW 51000, N''Index definition mismatch: CarVariants.IX_CarVariants_Code.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') AND i.name = N''IX_CarVariants_IsVisible_Price'' AND i.is_unique = 0 AND i.is_disabled = 0 AND i.is_hypothetical = 0 AND i.type = 2 AND NOT EXISTS (SELECT 1 FROM sys.index_columns extra WHERE extra.object_id = i.object_id AND extra.index_id = i.index_id AND (extra.is_included_column = 1 OR (extra.key_ordinal > 0 AND extra.is_descending_key = 1))) AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''IsVisible|Price'' AND i.has_filter = 0)
    THROW 51000, N''Index definition mismatch: CarVariants.IX_CarVariants_IsVisible_Price.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') AND i.name = N''IX_CarVariants_Year_BodyStyle'' AND i.is_unique = 0 AND i.is_disabled = 0 AND i.is_hypothetical = 0 AND i.type = 2 AND NOT EXISTS (SELECT 1 FROM sys.index_columns extra WHERE extra.object_id = i.object_id AND extra.index_id = i.index_id AND (extra.is_included_column = 1 OR (extra.key_ordinal > 0 AND extra.is_descending_key = 1))) AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''Year|BodyStyle'' AND i.has_filter = 0)
    THROW 51000, N''Index definition mismatch: CarVariants.IX_CarVariants_Year_BodyStyle.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys f WHERE f.parent_object_id = OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') AND f.name = N''FK_CarVariants_CarModels_CarModelId'' AND f.referenced_object_id = OBJECT_ID(N''[dbo].[CarModels]'') AND f.is_disabled = 0 AND f.is_not_trusted = 0 AND f.delete_referential_action = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), pc.name + N'':'' + rc.name), N''|'') WITHIN GROUP (ORDER BY fc.constraint_column_id) FROM sys.foreign_key_columns fc JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id WHERE fc.constraint_object_id = f.object_id) = N''CarModelId:Id'')
    THROW 51000, N''Foreign key mismatch: FK_CarVariants_CarModels_CarModelId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints c WHERE c.parent_object_id = OBJECT_ID(N''[dbo].[CarVariants]'', N''U'') AND c.name = N''CK_Car_Price'' AND c.is_disabled = 0 AND c.is_not_trusted = 0 AND UPPER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(c.definition, N''['', N''''), N'']'', N''''), N''('', N''''), N'')'', N''''), N'' '', N''''), CHAR(13), N''''), CHAR(10), N'''')) = UPPER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(N''[Price] >= 0'', N''['', N''''), N'']'', N''''), N''('', N''''), N'')'', N''''), N'' '', N''''), CHAR(13), N''''), CHAR(10), N'''')))
    THROW 51000, N''Check constraint mismatch: CK_Car_Price.'', 1;
IF OBJECT_ID(N''[dbo].[Contacts]'', N''U'') IS NULL
    THROW 51000, N''Missing table: Contacts. No migration history committed.'', 1;
IF (SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID(N''[dbo].[Contacts]'', N''U'')) <> 5
    THROW 51000, N''Column count mismatch: Contacts.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Contacts]'', N''U'') AND c.name = N''Id'' AND TYPE_NAME(c.system_type_id) = N''int'' AND c.is_nullable = 0 AND c.is_identity = 1 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: Contacts.Id.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Contacts]'', N''U'') AND c.name = N''CreatedAt'' AND TYPE_NAME(c.system_type_id) = N''datetimeoffset'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: Contacts.CreatedAt.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Contacts]'', N''U'') AND c.name = N''Email'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = -1)
    THROW 51000, N''Column definition mismatch: Contacts.Email.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Contacts]'', N''U'') AND c.name = N''Message'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = -1)
    THROW 51000, N''Column definition mismatch: Contacts.Message.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Contacts]'', N''U'') AND c.name = N''Name'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = -1)
    THROW 51000, N''Column definition mismatch: Contacts.Name.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[Contacts]'', N''U'') AND i.is_primary_key = 1 AND i.is_disabled = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''Id'')
    THROW 51000, N''Primary key mismatch: Contacts.'', 1;
IF OBJECT_ID(N''[dbo].[Favorites]'', N''U'') IS NULL
    THROW 51000, N''Missing table: Favorites. No migration history committed.'', 1;
IF (SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID(N''[dbo].[Favorites]'', N''U'')) <> 3
    THROW 51000, N''Column count mismatch: Favorites.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Favorites]'', N''U'') AND c.name = N''Id'' AND TYPE_NAME(c.system_type_id) = N''int'' AND c.is_nullable = 0 AND c.is_identity = 1 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: Favorites.Id.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Favorites]'', N''U'') AND c.name = N''CarVariantId'' AND TYPE_NAME(c.system_type_id) = N''int'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: Favorites.CarVariantId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Favorites]'', N''U'') AND c.name = N''UserId'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = 900)
    THROW 51000, N''Column definition mismatch: Favorites.UserId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[Favorites]'', N''U'') AND i.is_primary_key = 1 AND i.is_disabled = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''Id'')
    THROW 51000, N''Primary key mismatch: Favorites.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[Favorites]'', N''U'') AND i.name = N''IX_Favorites_CarVariantId'' AND i.is_unique = 0 AND i.is_disabled = 0 AND i.is_hypothetical = 0 AND i.type = 2 AND NOT EXISTS (SELECT 1 FROM sys.index_columns extra WHERE extra.object_id = i.object_id AND extra.index_id = i.index_id AND (extra.is_included_column = 1 OR (extra.key_ordinal > 0 AND extra.is_descending_key = 1))) AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''CarVariantId'' AND i.has_filter = 0)
    THROW 51000, N''Index definition mismatch: Favorites.IX_Favorites_CarVariantId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[Favorites]'', N''U'') AND i.name = N''IX_Favorites_UserId_CarVariantId'' AND i.is_unique = 1 AND i.is_disabled = 0 AND i.is_hypothetical = 0 AND i.type = 2 AND NOT EXISTS (SELECT 1 FROM sys.index_columns extra WHERE extra.object_id = i.object_id AND extra.index_id = i.index_id AND (extra.is_included_column = 1 OR (extra.key_ordinal > 0 AND extra.is_descending_key = 1))) AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''UserId|CarVariantId'' AND i.has_filter = 0)
    THROW 51000, N''Index definition mismatch: Favorites.IX_Favorites_UserId_CarVariantId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys f WHERE f.parent_object_id = OBJECT_ID(N''[dbo].[Favorites]'', N''U'') AND f.name = N''FK_Favorites_AspNetUsers_UserId'' AND f.referenced_object_id = OBJECT_ID(N''[dbo].[AspNetUsers]'') AND f.is_disabled = 0 AND f.is_not_trusted = 0 AND f.delete_referential_action = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), pc.name + N'':'' + rc.name), N''|'') WITHIN GROUP (ORDER BY fc.constraint_column_id) FROM sys.foreign_key_columns fc JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id WHERE fc.constraint_object_id = f.object_id) = N''UserId:Id'')
    THROW 51000, N''Foreign key mismatch: FK_Favorites_AspNetUsers_UserId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys f WHERE f.parent_object_id = OBJECT_ID(N''[dbo].[Favorites]'', N''U'') AND f.name = N''FK_Favorites_CarVariants_CarVariantId'' AND f.referenced_object_id = OBJECT_ID(N''[dbo].[CarVariants]'') AND f.is_disabled = 0 AND f.is_not_trusted = 0 AND f.delete_referential_action = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), pc.name + N'':'' + rc.name), N''|'') WITHIN GROUP (ORDER BY fc.constraint_column_id) FROM sys.foreign_key_columns fc JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id WHERE fc.constraint_object_id = f.object_id) = N''CarVariantId:Id'')
    THROW 51000, N''Foreign key mismatch: FK_Favorites_CarVariants_CarVariantId.'', 1;
IF OBJECT_ID(N''[dbo].[Notifications]'', N''U'') IS NULL
    THROW 51000, N''Missing table: Notifications. No migration history committed.'', 1;
IF (SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID(N''[dbo].[Notifications]'', N''U'')) <> 5
    THROW 51000, N''Column count mismatch: Notifications.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Notifications]'', N''U'') AND c.name = N''Id'' AND TYPE_NAME(c.system_type_id) = N''int'' AND c.is_nullable = 0 AND c.is_identity = 1 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: Notifications.Id.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Notifications]'', N''U'') AND c.name = N''CreatedAt'' AND TYPE_NAME(c.system_type_id) = N''datetimeoffset'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: Notifications.CreatedAt.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Notifications]'', N''U'') AND c.name = N''IsRead'' AND TYPE_NAME(c.system_type_id) = N''bit'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: Notifications.IsRead.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Notifications]'', N''U'') AND c.name = N''Message'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = -1)
    THROW 51000, N''Column definition mismatch: Notifications.Message.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Notifications]'', N''U'') AND c.name = N''UserId'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = 900)
    THROW 51000, N''Column definition mismatch: Notifications.UserId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[Notifications]'', N''U'') AND i.is_primary_key = 1 AND i.is_disabled = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''Id'')
    THROW 51000, N''Primary key mismatch: Notifications.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[Notifications]'', N''U'') AND i.name = N''IX_Notifications_UserId'' AND i.is_unique = 0 AND i.is_disabled = 0 AND i.is_hypothetical = 0 AND i.type = 2 AND NOT EXISTS (SELECT 1 FROM sys.index_columns extra WHERE extra.object_id = i.object_id AND extra.index_id = i.index_id AND (extra.is_included_column = 1 OR (extra.key_ordinal > 0 AND extra.is_descending_key = 1))) AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''UserId'' AND i.has_filter = 0)
    THROW 51000, N''Index definition mismatch: Notifications.IX_Notifications_UserId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys f WHERE f.parent_object_id = OBJECT_ID(N''[dbo].[Notifications]'', N''U'') AND f.name = N''FK_Notifications_AspNetUsers_UserId'' AND f.referenced_object_id = OBJECT_ID(N''[dbo].[AspNetUsers]'') AND f.is_disabled = 0 AND f.is_not_trusted = 0 AND f.delete_referential_action = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), pc.name + N'':'' + rc.name), N''|'') WITHIN GROUP (ORDER BY fc.constraint_column_id) FROM sys.foreign_key_columns fc JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id WHERE fc.constraint_object_id = f.object_id) = N''UserId:Id'')
    THROW 51000, N''Foreign key mismatch: FK_Notifications_AspNetUsers_UserId.'', 1;
IF OBJECT_ID(N''[dbo].[OrderHistories]'', N''U'') IS NULL
    THROW 51000, N''Missing table: OrderHistories. No migration history committed.'', 1;
IF (SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID(N''[dbo].[OrderHistories]'', N''U'')) <> 6
    THROW 51000, N''Column count mismatch: OrderHistories.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[OrderHistories]'', N''U'') AND c.name = N''Id'' AND TYPE_NAME(c.system_type_id) = N''int'' AND c.is_nullable = 0 AND c.is_identity = 1 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: OrderHistories.Id.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[OrderHistories]'', N''U'') AND c.name = N''ActorId'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = 900)
    THROW 51000, N''Column definition mismatch: OrderHistories.ActorId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[OrderHistories]'', N''U'') AND c.name = N''At'' AND TYPE_NAME(c.system_type_id) = N''datetimeoffset'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: OrderHistories.At.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[OrderHistories]'', N''U'') AND c.name = N''Note'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 1 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = -1)
    THROW 51000, N''Column definition mismatch: OrderHistories.Note.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[OrderHistories]'', N''U'') AND c.name = N''OrderId'' AND TYPE_NAME(c.system_type_id) = N''int'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: OrderHistories.OrderId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[OrderHistories]'', N''U'') AND c.name = N''Status'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = -1)
    THROW 51000, N''Column definition mismatch: OrderHistories.Status.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[OrderHistories]'', N''U'') AND i.is_primary_key = 1 AND i.is_disabled = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''Id'')
    THROW 51000, N''Primary key mismatch: OrderHistories.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[OrderHistories]'', N''U'') AND i.name = N''IX_OrderHistories_ActorId'' AND i.is_unique = 0 AND i.is_disabled = 0 AND i.is_hypothetical = 0 AND i.type = 2 AND NOT EXISTS (SELECT 1 FROM sys.index_columns extra WHERE extra.object_id = i.object_id AND extra.index_id = i.index_id AND (extra.is_included_column = 1 OR (extra.key_ordinal > 0 AND extra.is_descending_key = 1))) AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''ActorId'' AND i.has_filter = 0)
    THROW 51000, N''Index definition mismatch: OrderHistories.IX_OrderHistories_ActorId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[OrderHistories]'', N''U'') AND i.name = N''IX_OrderHistories_OrderId'' AND i.is_unique = 0 AND i.is_disabled = 0 AND i.is_hypothetical = 0 AND i.type = 2 AND NOT EXISTS (SELECT 1 FROM sys.index_columns extra WHERE extra.object_id = i.object_id AND extra.index_id = i.index_id AND (extra.is_included_column = 1 OR (extra.key_ordinal > 0 AND extra.is_descending_key = 1))) AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''OrderId'' AND i.has_filter = 0)
    THROW 51000, N''Index definition mismatch: OrderHistories.IX_OrderHistories_OrderId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys f WHERE f.parent_object_id = OBJECT_ID(N''[dbo].[OrderHistories]'', N''U'') AND f.name = N''FK_OrderHistories_AspNetUsers_ActorId'' AND f.referenced_object_id = OBJECT_ID(N''[dbo].[AspNetUsers]'') AND f.is_disabled = 0 AND f.is_not_trusted = 0 AND f.delete_referential_action = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), pc.name + N'':'' + rc.name), N''|'') WITHIN GROUP (ORDER BY fc.constraint_column_id) FROM sys.foreign_key_columns fc JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id WHERE fc.constraint_object_id = f.object_id) = N''ActorId:Id'')
    THROW 51000, N''Foreign key mismatch: FK_OrderHistories_AspNetUsers_ActorId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys f WHERE f.parent_object_id = OBJECT_ID(N''[dbo].[OrderHistories]'', N''U'') AND f.name = N''FK_OrderHistories_Orders_OrderId'' AND f.referenced_object_id = OBJECT_ID(N''[dbo].[Orders]'') AND f.is_disabled = 0 AND f.is_not_trusted = 0 AND f.delete_referential_action = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), pc.name + N'':'' + rc.name), N''|'') WITHIN GROUP (ORDER BY fc.constraint_column_id) FROM sys.foreign_key_columns fc JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id WHERE fc.constraint_object_id = f.object_id) = N''OrderId:Id'')
    THROW 51000, N''Foreign key mismatch: FK_OrderHistories_Orders_OrderId.'', 1;
IF OBJECT_ID(N''[dbo].[OrderItems]'', N''U'') IS NULL
    THROW 51000, N''Missing table: OrderItems. No migration history committed.'', 1;
IF (SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID(N''[dbo].[OrderItems]'', N''U'')) <> 5
    THROW 51000, N''Column count mismatch: OrderItems.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[OrderItems]'', N''U'') AND c.name = N''Id'' AND TYPE_NAME(c.system_type_id) = N''int'' AND c.is_nullable = 0 AND c.is_identity = 1 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: OrderItems.Id.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[OrderItems]'', N''U'') AND c.name = N''CarVariantId'' AND TYPE_NAME(c.system_type_id) = N''int'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: OrderItems.CarVariantId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[OrderItems]'', N''U'') AND c.name = N''OrderId'' AND TYPE_NAME(c.system_type_id) = N''int'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: OrderItems.OrderId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[OrderItems]'', N''U'') AND c.name = N''Quantity'' AND TYPE_NAME(c.system_type_id) = N''int'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: OrderItems.Quantity.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[OrderItems]'', N''U'') AND c.name = N''UnitPrice'' AND TYPE_NAME(c.system_type_id) = N''decimal'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.precision = 18 AND c.scale = 2)
    THROW 51000, N''Column definition mismatch: OrderItems.UnitPrice.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[OrderItems]'', N''U'') AND i.is_primary_key = 1 AND i.is_disabled = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''Id'')
    THROW 51000, N''Primary key mismatch: OrderItems.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[OrderItems]'', N''U'') AND i.name = N''IX_OrderItems_CarVariantId'' AND i.is_unique = 0 AND i.is_disabled = 0 AND i.is_hypothetical = 0 AND i.type = 2 AND NOT EXISTS (SELECT 1 FROM sys.index_columns extra WHERE extra.object_id = i.object_id AND extra.index_id = i.index_id AND (extra.is_included_column = 1 OR (extra.key_ordinal > 0 AND extra.is_descending_key = 1))) AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''CarVariantId'' AND i.has_filter = 0)
    THROW 51000, N''Index definition mismatch: OrderItems.IX_OrderItems_CarVariantId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[OrderItems]'', N''U'') AND i.name = N''IX_OrderItems_OrderId'' AND i.is_unique = 0 AND i.is_disabled = 0 AND i.is_hypothetical = 0 AND i.type = 2 AND NOT EXISTS (SELECT 1 FROM sys.index_columns extra WHERE extra.object_id = i.object_id AND extra.index_id = i.index_id AND (extra.is_included_column = 1 OR (extra.key_ordinal > 0 AND extra.is_descending_key = 1))) AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''OrderId'' AND i.has_filter = 0)
    THROW 51000, N''Index definition mismatch: OrderItems.IX_OrderItems_OrderId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys f WHERE f.parent_object_id = OBJECT_ID(N''[dbo].[OrderItems]'', N''U'') AND f.name = N''FK_OrderItems_CarVariants_CarVariantId'' AND f.referenced_object_id = OBJECT_ID(N''[dbo].[CarVariants]'') AND f.is_disabled = 0 AND f.is_not_trusted = 0 AND f.delete_referential_action = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), pc.name + N'':'' + rc.name), N''|'') WITHIN GROUP (ORDER BY fc.constraint_column_id) FROM sys.foreign_key_columns fc JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id WHERE fc.constraint_object_id = f.object_id) = N''CarVariantId:Id'')
    THROW 51000, N''Foreign key mismatch: FK_OrderItems_CarVariants_CarVariantId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys f WHERE f.parent_object_id = OBJECT_ID(N''[dbo].[OrderItems]'', N''U'') AND f.name = N''FK_OrderItems_Orders_OrderId'' AND f.referenced_object_id = OBJECT_ID(N''[dbo].[Orders]'') AND f.is_disabled = 0 AND f.is_not_trusted = 0 AND f.delete_referential_action = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), pc.name + N'':'' + rc.name), N''|'') WITHIN GROUP (ORDER BY fc.constraint_column_id) FROM sys.foreign_key_columns fc JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id WHERE fc.constraint_object_id = f.object_id) = N''OrderId:Id'')
    THROW 51000, N''Foreign key mismatch: FK_OrderItems_Orders_OrderId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints c WHERE c.parent_object_id = OBJECT_ID(N''[dbo].[OrderItems]'', N''U'') AND c.name = N''CK_OrderItem_Price'' AND c.is_disabled = 0 AND c.is_not_trusted = 0 AND UPPER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(c.definition, N''['', N''''), N'']'', N''''), N''('', N''''), N'')'', N''''), N'' '', N''''), CHAR(13), N''''), CHAR(10), N'''')) = UPPER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(N''[UnitPrice] >= 0'', N''['', N''''), N'']'', N''''), N''('', N''''), N'')'', N''''), N'' '', N''''), CHAR(13), N''''), CHAR(10), N'''')))
    THROW 51000, N''Check constraint mismatch: CK_OrderItem_Price.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints c WHERE c.parent_object_id = OBJECT_ID(N''[dbo].[OrderItems]'', N''U'') AND c.name = N''CK_OrderItem_Quantity'' AND c.is_disabled = 0 AND c.is_not_trusted = 0 AND UPPER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(c.definition, N''['', N''''), N'']'', N''''), N''('', N''''), N'')'', N''''), N'' '', N''''), CHAR(13), N''''), CHAR(10), N'''')) = UPPER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(N''[Quantity] > 0'', N''['', N''''), N'']'', N''''), N''('', N''''), N'')'', N''''), N'' '', N''''), CHAR(13), N''''), CHAR(10), N'''')))
    THROW 51000, N''Check constraint mismatch: CK_OrderItem_Quantity.'', 1;
IF OBJECT_ID(N''[dbo].[Orders]'', N''U'') IS NULL
    THROW 51000, N''Missing table: Orders. No migration history committed.'', 1;
IF (SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID(N''[dbo].[Orders]'', N''U'')) <> 10
    THROW 51000, N''Column count mismatch: Orders.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Orders]'', N''U'') AND c.name = N''Id'' AND TYPE_NAME(c.system_type_id) = N''int'' AND c.is_nullable = 0 AND c.is_identity = 1 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: Orders.Id.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Orders]'', N''U'') AND c.name = N''AssignedSalesId'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 1 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = 900)
    THROW 51000, N''Column definition mismatch: Orders.AssignedSalesId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Orders]'', N''U'') AND c.name = N''CompletedAt'' AND TYPE_NAME(c.system_type_id) = N''datetimeoffset'' AND c.is_nullable = 1 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: Orders.CompletedAt.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Orders]'', N''U'') AND c.name = N''CreatedAt'' AND TYPE_NAME(c.system_type_id) = N''datetimeoffset'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: Orders.CreatedAt.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Orders]'', N''U'') AND c.name = N''Note'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 1 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = -1)
    THROW 51000, N''Column definition mismatch: Orders.Note.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Orders]'', N''U'') AND c.name = N''PaymentStatus'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = -1)
    THROW 51000, N''Column definition mismatch: Orders.PaymentStatus.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Orders]'', N''U'') AND c.name = N''RowVersion'' AND TYPE_NAME(c.system_type_id) = N''timestamp'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: Orders.RowVersion.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Orders]'', N''U'') AND c.name = N''Status'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = 900)
    THROW 51000, N''Column definition mismatch: Orders.Status.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Orders]'', N''U'') AND c.name = N''Total'' AND TYPE_NAME(c.system_type_id) = N''decimal'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.precision = 18 AND c.scale = 2)
    THROW 51000, N''Column definition mismatch: Orders.Total.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Orders]'', N''U'') AND c.name = N''UserId'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = 900)
    THROW 51000, N''Column definition mismatch: Orders.UserId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[Orders]'', N''U'') AND i.is_primary_key = 1 AND i.is_disabled = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''Id'')
    THROW 51000, N''Primary key mismatch: Orders.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[Orders]'', N''U'') AND i.name = N''IX_Orders_AssignedSalesId'' AND i.is_unique = 0 AND i.is_disabled = 0 AND i.is_hypothetical = 0 AND i.type = 2 AND NOT EXISTS (SELECT 1 FROM sys.index_columns extra WHERE extra.object_id = i.object_id AND extra.index_id = i.index_id AND (extra.is_included_column = 1 OR (extra.key_ordinal > 0 AND extra.is_descending_key = 1))) AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''AssignedSalesId'' AND i.has_filter = 0)
    THROW 51000, N''Index definition mismatch: Orders.IX_Orders_AssignedSalesId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[Orders]'', N''U'') AND i.name = N''IX_Orders_Status_CreatedAt'' AND i.is_unique = 0 AND i.is_disabled = 0 AND i.is_hypothetical = 0 AND i.type = 2 AND NOT EXISTS (SELECT 1 FROM sys.index_columns extra WHERE extra.object_id = i.object_id AND extra.index_id = i.index_id AND (extra.is_included_column = 1 OR (extra.key_ordinal > 0 AND extra.is_descending_key = 1))) AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''Status|CreatedAt'' AND i.has_filter = 0)
    THROW 51000, N''Index definition mismatch: Orders.IX_Orders_Status_CreatedAt.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[Orders]'', N''U'') AND i.name = N''IX_Orders_UserId'' AND i.is_unique = 0 AND i.is_disabled = 0 AND i.is_hypothetical = 0 AND i.type = 2 AND NOT EXISTS (SELECT 1 FROM sys.index_columns extra WHERE extra.object_id = i.object_id AND extra.index_id = i.index_id AND (extra.is_included_column = 1 OR (extra.key_ordinal > 0 AND extra.is_descending_key = 1))) AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''UserId'' AND i.has_filter = 0)
    THROW 51000, N''Index definition mismatch: Orders.IX_Orders_UserId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys f WHERE f.parent_object_id = OBJECT_ID(N''[dbo].[Orders]'', N''U'') AND f.name = N''FK_Orders_AspNetUsers_AssignedSalesId'' AND f.referenced_object_id = OBJECT_ID(N''[dbo].[AspNetUsers]'') AND f.is_disabled = 0 AND f.is_not_trusted = 0 AND f.delete_referential_action = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), pc.name + N'':'' + rc.name), N''|'') WITHIN GROUP (ORDER BY fc.constraint_column_id) FROM sys.foreign_key_columns fc JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id WHERE fc.constraint_object_id = f.object_id) = N''AssignedSalesId:Id'')
    THROW 51000, N''Foreign key mismatch: FK_Orders_AspNetUsers_AssignedSalesId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys f WHERE f.parent_object_id = OBJECT_ID(N''[dbo].[Orders]'', N''U'') AND f.name = N''FK_Orders_AspNetUsers_UserId'' AND f.referenced_object_id = OBJECT_ID(N''[dbo].[AspNetUsers]'') AND f.is_disabled = 0 AND f.is_not_trusted = 0 AND f.delete_referential_action = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), pc.name + N'':'' + rc.name), N''|'') WITHIN GROUP (ORDER BY fc.constraint_column_id) FROM sys.foreign_key_columns fc JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id WHERE fc.constraint_object_id = f.object_id) = N''UserId:Id'')
    THROW 51000, N''Foreign key mismatch: FK_Orders_AspNetUsers_UserId.'', 1;
IF OBJECT_ID(N''[dbo].[Payments]'', N''U'') IS NULL
    THROW 51000, N''Missing table: Payments. No migration history committed.'', 1;
IF (SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID(N''[dbo].[Payments]'', N''U'')) <> 6
    THROW 51000, N''Column count mismatch: Payments.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Payments]'', N''U'') AND c.name = N''Id'' AND TYPE_NAME(c.system_type_id) = N''int'' AND c.is_nullable = 0 AND c.is_identity = 1 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: Payments.Id.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Payments]'', N''U'') AND c.name = N''Amount'' AND TYPE_NAME(c.system_type_id) = N''decimal'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.precision = 18 AND c.scale = 2)
    THROW 51000, N''Column definition mismatch: Payments.Amount.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Payments]'', N''U'') AND c.name = N''At'' AND TYPE_NAME(c.system_type_id) = N''datetimeoffset'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: Payments.At.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Payments]'', N''U'') AND c.name = N''ConfirmedById'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = 900)
    THROW 51000, N''Column definition mismatch: Payments.ConfirmedById.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Payments]'', N''U'') AND c.name = N''OrderId'' AND TYPE_NAME(c.system_type_id) = N''int'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: Payments.OrderId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Payments]'', N''U'') AND c.name = N''Reference'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = 400)
    THROW 51000, N''Column definition mismatch: Payments.Reference.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[Payments]'', N''U'') AND i.is_primary_key = 1 AND i.is_disabled = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''Id'')
    THROW 51000, N''Primary key mismatch: Payments.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[Payments]'', N''U'') AND i.name = N''IX_Payments_ConfirmedById'' AND i.is_unique = 0 AND i.is_disabled = 0 AND i.is_hypothetical = 0 AND i.type = 2 AND NOT EXISTS (SELECT 1 FROM sys.index_columns extra WHERE extra.object_id = i.object_id AND extra.index_id = i.index_id AND (extra.is_included_column = 1 OR (extra.key_ordinal > 0 AND extra.is_descending_key = 1))) AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''ConfirmedById'' AND i.has_filter = 0)
    THROW 51000, N''Index definition mismatch: Payments.IX_Payments_ConfirmedById.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[Payments]'', N''U'') AND i.name = N''IX_Payments_OrderId'' AND i.is_unique = 0 AND i.is_disabled = 0 AND i.is_hypothetical = 0 AND i.type = 2 AND NOT EXISTS (SELECT 1 FROM sys.index_columns extra WHERE extra.object_id = i.object_id AND extra.index_id = i.index_id AND (extra.is_included_column = 1 OR (extra.key_ordinal > 0 AND extra.is_descending_key = 1))) AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''OrderId'' AND i.has_filter = 0)
    THROW 51000, N''Index definition mismatch: Payments.IX_Payments_OrderId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[Payments]'', N''U'') AND i.name = N''IX_Payments_Reference'' AND i.is_unique = 1 AND i.is_disabled = 0 AND i.is_hypothetical = 0 AND i.type = 2 AND NOT EXISTS (SELECT 1 FROM sys.index_columns extra WHERE extra.object_id = i.object_id AND extra.index_id = i.index_id AND (extra.is_included_column = 1 OR (extra.key_ordinal > 0 AND extra.is_descending_key = 1))) AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''Reference'' AND i.has_filter = 0)
    THROW 51000, N''Index definition mismatch: Payments.IX_Payments_Reference.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys f WHERE f.parent_object_id = OBJECT_ID(N''[dbo].[Payments]'', N''U'') AND f.name = N''FK_Payments_AspNetUsers_ConfirmedById'' AND f.referenced_object_id = OBJECT_ID(N''[dbo].[AspNetUsers]'') AND f.is_disabled = 0 AND f.is_not_trusted = 0 AND f.delete_referential_action = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), pc.name + N'':'' + rc.name), N''|'') WITHIN GROUP (ORDER BY fc.constraint_column_id) FROM sys.foreign_key_columns fc JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id WHERE fc.constraint_object_id = f.object_id) = N''ConfirmedById:Id'')
    THROW 51000, N''Foreign key mismatch: FK_Payments_AspNetUsers_ConfirmedById.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys f WHERE f.parent_object_id = OBJECT_ID(N''[dbo].[Payments]'', N''U'') AND f.name = N''FK_Payments_Orders_OrderId'' AND f.referenced_object_id = OBJECT_ID(N''[dbo].[Orders]'') AND f.is_disabled = 0 AND f.is_not_trusted = 0 AND f.delete_referential_action = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), pc.name + N'':'' + rc.name), N''|'') WITHIN GROUP (ORDER BY fc.constraint_column_id) FROM sys.foreign_key_columns fc JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id WHERE fc.constraint_object_id = f.object_id) = N''OrderId:Id'')
    THROW 51000, N''Foreign key mismatch: FK_Payments_Orders_OrderId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints c WHERE c.parent_object_id = OBJECT_ID(N''[dbo].[Payments]'', N''U'') AND c.name = N''CK_Payment_Amount'' AND c.is_disabled = 0 AND c.is_not_trusted = 0 AND UPPER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(c.definition, N''['', N''''), N'']'', N''''), N''('', N''''), N'')'', N''''), N'' '', N''''), CHAR(13), N''''), CHAR(10), N'''')) = UPPER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(N''[Amount] > 0'', N''['', N''''), N'']'', N''''), N''('', N''''), N'')'', N''''), N'' '', N''''), CHAR(13), N''''), CHAR(10), N'''')))
    THROW 51000, N''Check constraint mismatch: CK_Payment_Amount.'', 1;
IF OBJECT_ID(N''[dbo].[Promotions]'', N''U'') IS NULL
    THROW 51000, N''Missing table: Promotions. No migration history committed.'', 1;
IF (SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID(N''[dbo].[Promotions]'', N''U'')) <> 5
    THROW 51000, N''Column count mismatch: Promotions.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Promotions]'', N''U'') AND c.name = N''Id'' AND TYPE_NAME(c.system_type_id) = N''int'' AND c.is_nullable = 0 AND c.is_identity = 1 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: Promotions.Id.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Promotions]'', N''U'') AND c.name = N''Description'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = -1)
    THROW 51000, N''Column definition mismatch: Promotions.Description.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Promotions]'', N''U'') AND c.name = N''EndsAt'' AND TYPE_NAME(c.system_type_id) = N''datetimeoffset'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: Promotions.EndsAt.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Promotions]'', N''U'') AND c.name = N''StartsAt'' AND TYPE_NAME(c.system_type_id) = N''datetimeoffset'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: Promotions.StartsAt.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Promotions]'', N''U'') AND c.name = N''Title'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = -1)
    THROW 51000, N''Column definition mismatch: Promotions.Title.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[Promotions]'', N''U'') AND i.is_primary_key = 1 AND i.is_disabled = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''Id'')
    THROW 51000, N''Primary key mismatch: Promotions.'', 1;
IF OBJECT_ID(N''[dbo].[QuoteRequests]'', N''U'') IS NULL
    THROW 51000, N''Missing table: QuoteRequests. No migration history committed.'', 1;
IF (SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID(N''[dbo].[QuoteRequests]'', N''U'')) <> 9
    THROW 51000, N''Column count mismatch: QuoteRequests.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[QuoteRequests]'', N''U'') AND c.name = N''Id'' AND TYPE_NAME(c.system_type_id) = N''int'' AND c.is_nullable = 0 AND c.is_identity = 1 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: QuoteRequests.Id.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[QuoteRequests]'', N''U'') AND c.name = N''AssignedSalesId'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 1 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = 900)
    THROW 51000, N''Column definition mismatch: QuoteRequests.AssignedSalesId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[QuoteRequests]'', N''U'') AND c.name = N''CarVariantId'' AND TYPE_NAME(c.system_type_id) = N''int'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: QuoteRequests.CarVariantId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[QuoteRequests]'', N''U'') AND c.name = N''CreatedAt'' AND TYPE_NAME(c.system_type_id) = N''datetimeoffset'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: QuoteRequests.CreatedAt.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[QuoteRequests]'', N''U'') AND c.name = N''Message'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 1 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = -1)
    THROW 51000, N''Column definition mismatch: QuoteRequests.Message.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[QuoteRequests]'', N''U'') AND c.name = N''Phone'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = -1)
    THROW 51000, N''Column definition mismatch: QuoteRequests.Phone.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[QuoteRequests]'', N''U'') AND c.name = N''Response'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 1 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = -1)
    THROW 51000, N''Column definition mismatch: QuoteRequests.Response.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[QuoteRequests]'', N''U'') AND c.name = N''Status'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = -1)
    THROW 51000, N''Column definition mismatch: QuoteRequests.Status.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[QuoteRequests]'', N''U'') AND c.name = N''UserId'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = 900)
    THROW 51000, N''Column definition mismatch: QuoteRequests.UserId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[QuoteRequests]'', N''U'') AND i.is_primary_key = 1 AND i.is_disabled = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''Id'')
    THROW 51000, N''Primary key mismatch: QuoteRequests.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[QuoteRequests]'', N''U'') AND i.name = N''IX_QuoteRequests_AssignedSalesId'' AND i.is_unique = 0 AND i.is_disabled = 0 AND i.is_hypothetical = 0 AND i.type = 2 AND NOT EXISTS (SELECT 1 FROM sys.index_columns extra WHERE extra.object_id = i.object_id AND extra.index_id = i.index_id AND (extra.is_included_column = 1 OR (extra.key_ordinal > 0 AND extra.is_descending_key = 1))) AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''AssignedSalesId'' AND i.has_filter = 0)
    THROW 51000, N''Index definition mismatch: QuoteRequests.IX_QuoteRequests_AssignedSalesId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[QuoteRequests]'', N''U'') AND i.name = N''IX_QuoteRequests_CarVariantId'' AND i.is_unique = 0 AND i.is_disabled = 0 AND i.is_hypothetical = 0 AND i.type = 2 AND NOT EXISTS (SELECT 1 FROM sys.index_columns extra WHERE extra.object_id = i.object_id AND extra.index_id = i.index_id AND (extra.is_included_column = 1 OR (extra.key_ordinal > 0 AND extra.is_descending_key = 1))) AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''CarVariantId'' AND i.has_filter = 0)
    THROW 51000, N''Index definition mismatch: QuoteRequests.IX_QuoteRequests_CarVariantId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[QuoteRequests]'', N''U'') AND i.name = N''IX_QuoteRequests_UserId'' AND i.is_unique = 0 AND i.is_disabled = 0 AND i.is_hypothetical = 0 AND i.type = 2 AND NOT EXISTS (SELECT 1 FROM sys.index_columns extra WHERE extra.object_id = i.object_id AND extra.index_id = i.index_id AND (extra.is_included_column = 1 OR (extra.key_ordinal > 0 AND extra.is_descending_key = 1))) AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''UserId'' AND i.has_filter = 0)
    THROW 51000, N''Index definition mismatch: QuoteRequests.IX_QuoteRequests_UserId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys f WHERE f.parent_object_id = OBJECT_ID(N''[dbo].[QuoteRequests]'', N''U'') AND f.name = N''FK_QuoteRequests_AspNetUsers_AssignedSalesId'' AND f.referenced_object_id = OBJECT_ID(N''[dbo].[AspNetUsers]'') AND f.is_disabled = 0 AND f.is_not_trusted = 0 AND f.delete_referential_action = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), pc.name + N'':'' + rc.name), N''|'') WITHIN GROUP (ORDER BY fc.constraint_column_id) FROM sys.foreign_key_columns fc JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id WHERE fc.constraint_object_id = f.object_id) = N''AssignedSalesId:Id'')
    THROW 51000, N''Foreign key mismatch: FK_QuoteRequests_AspNetUsers_AssignedSalesId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys f WHERE f.parent_object_id = OBJECT_ID(N''[dbo].[QuoteRequests]'', N''U'') AND f.name = N''FK_QuoteRequests_AspNetUsers_UserId'' AND f.referenced_object_id = OBJECT_ID(N''[dbo].[AspNetUsers]'') AND f.is_disabled = 0 AND f.is_not_trusted = 0 AND f.delete_referential_action = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), pc.name + N'':'' + rc.name), N''|'') WITHIN GROUP (ORDER BY fc.constraint_column_id) FROM sys.foreign_key_columns fc JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id WHERE fc.constraint_object_id = f.object_id) = N''UserId:Id'')
    THROW 51000, N''Foreign key mismatch: FK_QuoteRequests_AspNetUsers_UserId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys f WHERE f.parent_object_id = OBJECT_ID(N''[dbo].[QuoteRequests]'', N''U'') AND f.name = N''FK_QuoteRequests_CarVariants_CarVariantId'' AND f.referenced_object_id = OBJECT_ID(N''[dbo].[CarVariants]'') AND f.is_disabled = 0 AND f.is_not_trusted = 0 AND f.delete_referential_action = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), pc.name + N'':'' + rc.name), N''|'') WITHIN GROUP (ORDER BY fc.constraint_column_id) FROM sys.foreign_key_columns fc JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id WHERE fc.constraint_object_id = f.object_id) = N''CarVariantId:Id'')
    THROW 51000, N''Foreign key mismatch: FK_QuoteRequests_CarVariants_CarVariantId.'', 1;
IF OBJECT_ID(N''[dbo].[RefreshSessions]'', N''U'') IS NULL
    THROW 51000, N''Missing table: RefreshSessions. No migration history committed.'', 1;
IF (SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID(N''[dbo].[RefreshSessions]'', N''U'')) <> 6
    THROW 51000, N''Column count mismatch: RefreshSessions.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[RefreshSessions]'', N''U'') AND c.name = N''Id'' AND TYPE_NAME(c.system_type_id) = N''int'' AND c.is_nullable = 0 AND c.is_identity = 1 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: RefreshSessions.Id.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[RefreshSessions]'', N''U'') AND c.name = N''ExpiresAt'' AND TYPE_NAME(c.system_type_id) = N''datetimeoffset'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: RefreshSessions.ExpiresAt.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[RefreshSessions]'', N''U'') AND c.name = N''Revoked'' AND TYPE_NAME(c.system_type_id) = N''bit'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: RefreshSessions.Revoked.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[RefreshSessions]'', N''U'') AND c.name = N''RowVersion'' AND TYPE_NAME(c.system_type_id) = N''timestamp'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: RefreshSessions.RowVersion.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[RefreshSessions]'', N''U'') AND c.name = N''TokenHash'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = 128)
    THROW 51000, N''Column definition mismatch: RefreshSessions.TokenHash.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[RefreshSessions]'', N''U'') AND c.name = N''UserId'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = 900)
    THROW 51000, N''Column definition mismatch: RefreshSessions.UserId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[RefreshSessions]'', N''U'') AND i.is_primary_key = 1 AND i.is_disabled = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''Id'')
    THROW 51000, N''Primary key mismatch: RefreshSessions.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[RefreshSessions]'', N''U'') AND i.name = N''IX_RefreshSessions_TokenHash'' AND i.is_unique = 1 AND i.is_disabled = 0 AND i.is_hypothetical = 0 AND i.type = 2 AND NOT EXISTS (SELECT 1 FROM sys.index_columns extra WHERE extra.object_id = i.object_id AND extra.index_id = i.index_id AND (extra.is_included_column = 1 OR (extra.key_ordinal > 0 AND extra.is_descending_key = 1))) AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''TokenHash'' AND i.has_filter = 0)
    THROW 51000, N''Index definition mismatch: RefreshSessions.IX_RefreshSessions_TokenHash.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[RefreshSessions]'', N''U'') AND i.name = N''IX_RefreshSessions_UserId'' AND i.is_unique = 0 AND i.is_disabled = 0 AND i.is_hypothetical = 0 AND i.type = 2 AND NOT EXISTS (SELECT 1 FROM sys.index_columns extra WHERE extra.object_id = i.object_id AND extra.index_id = i.index_id AND (extra.is_included_column = 1 OR (extra.key_ordinal > 0 AND extra.is_descending_key = 1))) AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''UserId'' AND i.has_filter = 0)
    THROW 51000, N''Index definition mismatch: RefreshSessions.IX_RefreshSessions_UserId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys f WHERE f.parent_object_id = OBJECT_ID(N''[dbo].[RefreshSessions]'', N''U'') AND f.name = N''FK_RefreshSessions_AspNetUsers_UserId'' AND f.referenced_object_id = OBJECT_ID(N''[dbo].[AspNetUsers]'') AND f.is_disabled = 0 AND f.is_not_trusted = 0 AND f.delete_referential_action = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), pc.name + N'':'' + rc.name), N''|'') WITHIN GROUP (ORDER BY fc.constraint_column_id) FROM sys.foreign_key_columns fc JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id WHERE fc.constraint_object_id = f.object_id) = N''UserId:Id'')
    THROW 51000, N''Foreign key mismatch: FK_RefreshSessions_AspNetUsers_UserId.'', 1;
IF OBJECT_ID(N''[dbo].[Reviews]'', N''U'') IS NULL
    THROW 51000, N''Missing table: Reviews. No migration history committed.'', 1;
IF (SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID(N''[dbo].[Reviews]'', N''U'')) <> 6
    THROW 51000, N''Column count mismatch: Reviews.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Reviews]'', N''U'') AND c.name = N''Id'' AND TYPE_NAME(c.system_type_id) = N''int'' AND c.is_nullable = 0 AND c.is_identity = 1 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: Reviews.Id.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Reviews]'', N''U'') AND c.name = N''CarVariantId'' AND TYPE_NAME(c.system_type_id) = N''int'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: Reviews.CarVariantId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Reviews]'', N''U'') AND c.name = N''Comment'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = -1)
    THROW 51000, N''Column definition mismatch: Reviews.Comment.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Reviews]'', N''U'') AND c.name = N''CreatedAt'' AND TYPE_NAME(c.system_type_id) = N''datetimeoffset'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: Reviews.CreatedAt.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Reviews]'', N''U'') AND c.name = N''Rating'' AND TYPE_NAME(c.system_type_id) = N''int'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: Reviews.Rating.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[Reviews]'', N''U'') AND c.name = N''UserId'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = 900)
    THROW 51000, N''Column definition mismatch: Reviews.UserId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[Reviews]'', N''U'') AND i.is_primary_key = 1 AND i.is_disabled = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''Id'')
    THROW 51000, N''Primary key mismatch: Reviews.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[Reviews]'', N''U'') AND i.name = N''IX_Reviews_CarVariantId'' AND i.is_unique = 0 AND i.is_disabled = 0 AND i.is_hypothetical = 0 AND i.type = 2 AND NOT EXISTS (SELECT 1 FROM sys.index_columns extra WHERE extra.object_id = i.object_id AND extra.index_id = i.index_id AND (extra.is_included_column = 1 OR (extra.key_ordinal > 0 AND extra.is_descending_key = 1))) AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''CarVariantId'' AND i.has_filter = 0)
    THROW 51000, N''Index definition mismatch: Reviews.IX_Reviews_CarVariantId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[Reviews]'', N''U'') AND i.name = N''IX_Reviews_UserId_CarVariantId'' AND i.is_unique = 1 AND i.is_disabled = 0 AND i.is_hypothetical = 0 AND i.type = 2 AND NOT EXISTS (SELECT 1 FROM sys.index_columns extra WHERE extra.object_id = i.object_id AND extra.index_id = i.index_id AND (extra.is_included_column = 1 OR (extra.key_ordinal > 0 AND extra.is_descending_key = 1))) AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''UserId|CarVariantId'' AND i.has_filter = 0)
    THROW 51000, N''Index definition mismatch: Reviews.IX_Reviews_UserId_CarVariantId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys f WHERE f.parent_object_id = OBJECT_ID(N''[dbo].[Reviews]'', N''U'') AND f.name = N''FK_Reviews_AspNetUsers_UserId'' AND f.referenced_object_id = OBJECT_ID(N''[dbo].[AspNetUsers]'') AND f.is_disabled = 0 AND f.is_not_trusted = 0 AND f.delete_referential_action = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), pc.name + N'':'' + rc.name), N''|'') WITHIN GROUP (ORDER BY fc.constraint_column_id) FROM sys.foreign_key_columns fc JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id WHERE fc.constraint_object_id = f.object_id) = N''UserId:Id'')
    THROW 51000, N''Foreign key mismatch: FK_Reviews_AspNetUsers_UserId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys f WHERE f.parent_object_id = OBJECT_ID(N''[dbo].[Reviews]'', N''U'') AND f.name = N''FK_Reviews_CarVariants_CarVariantId'' AND f.referenced_object_id = OBJECT_ID(N''[dbo].[CarVariants]'') AND f.is_disabled = 0 AND f.is_not_trusted = 0 AND f.delete_referential_action = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), pc.name + N'':'' + rc.name), N''|'') WITHIN GROUP (ORDER BY fc.constraint_column_id) FROM sys.foreign_key_columns fc JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id WHERE fc.constraint_object_id = f.object_id) = N''CarVariantId:Id'')
    THROW 51000, N''Foreign key mismatch: FK_Reviews_CarVariants_CarVariantId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.check_constraints c WHERE c.parent_object_id = OBJECT_ID(N''[dbo].[Reviews]'', N''U'') AND c.name = N''CK_Review_Rating'' AND c.is_disabled = 0 AND c.is_not_trusted = 0 AND UPPER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(c.definition, N''['', N''''), N'']'', N''''), N''('', N''''), N'')'', N''''), N'' '', N''''), CHAR(13), N''''), CHAR(10), N'''')) IN (N''RATINGBETWEEN1AND5'', N''RATING>=1ANDRATING<=5'', N''RATING<=5ANDRATING>=1''))
    THROW 51000, N''Check constraint mismatch: CK_Review_Rating.'', 1;
IF OBJECT_ID(N''[dbo].[TestDriveBookings]'', N''U'') IS NULL
    THROW 51000, N''Missing table: TestDriveBookings. No migration history committed.'', 1;
IF (SELECT COUNT(*) FROM sys.columns WHERE object_id = OBJECT_ID(N''[dbo].[TestDriveBookings]'', N''U'')) <> 8
    THROW 51000, N''Column count mismatch: TestDriveBookings.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[TestDriveBookings]'', N''U'') AND c.name = N''Id'' AND TYPE_NAME(c.system_type_id) = N''int'' AND c.is_nullable = 0 AND c.is_identity = 1 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: TestDriveBookings.Id.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[TestDriveBookings]'', N''U'') AND c.name = N''AssignedSalesId'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 1 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = 900)
    THROW 51000, N''Column definition mismatch: TestDriveBookings.AssignedSalesId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[TestDriveBookings]'', N''U'') AND c.name = N''CarVariantId'' AND TYPE_NAME(c.system_type_id) = N''int'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: TestDriveBookings.CarVariantId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[TestDriveBookings]'', N''U'') AND c.name = N''Note'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 1 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = -1)
    THROW 51000, N''Column definition mismatch: TestDriveBookings.Note.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[TestDriveBookings]'', N''U'') AND c.name = N''Phone'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = -1)
    THROW 51000, N''Column definition mismatch: TestDriveBookings.Phone.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[TestDriveBookings]'', N''U'') AND c.name = N''ScheduledAt'' AND TYPE_NAME(c.system_type_id) = N''datetimeoffset'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0)
    THROW 51000, N''Column definition mismatch: TestDriveBookings.ScheduledAt.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[TestDriveBookings]'', N''U'') AND c.name = N''Status'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = -1)
    THROW 51000, N''Column definition mismatch: TestDriveBookings.Status.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.columns c WHERE c.object_id = OBJECT_ID(N''[dbo].[TestDriveBookings]'', N''U'') AND c.name = N''UserId'' AND TYPE_NAME(c.system_type_id) = N''nvarchar'' AND c.is_nullable = 0 AND c.is_identity = 0 AND c.is_computed = 0 AND c.max_length = 900)
    THROW 51000, N''Column definition mismatch: TestDriveBookings.UserId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[TestDriveBookings]'', N''U'') AND i.is_primary_key = 1 AND i.is_disabled = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''Id'')
    THROW 51000, N''Primary key mismatch: TestDriveBookings.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[TestDriveBookings]'', N''U'') AND i.name = N''IX_TestDriveBookings_AssignedSalesId_ScheduledAt'' AND i.is_unique = 0 AND i.is_disabled = 0 AND i.is_hypothetical = 0 AND i.type = 2 AND NOT EXISTS (SELECT 1 FROM sys.index_columns extra WHERE extra.object_id = i.object_id AND extra.index_id = i.index_id AND (extra.is_included_column = 1 OR (extra.key_ordinal > 0 AND extra.is_descending_key = 1))) AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''AssignedSalesId|ScheduledAt'' AND i.has_filter = 0)
    THROW 51000, N''Index definition mismatch: TestDriveBookings.IX_TestDriveBookings_AssignedSalesId_ScheduledAt.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[TestDriveBookings]'', N''U'') AND i.name = N''IX_TestDriveBookings_CarVariantId'' AND i.is_unique = 0 AND i.is_disabled = 0 AND i.is_hypothetical = 0 AND i.type = 2 AND NOT EXISTS (SELECT 1 FROM sys.index_columns extra WHERE extra.object_id = i.object_id AND extra.index_id = i.index_id AND (extra.is_included_column = 1 OR (extra.key_ordinal > 0 AND extra.is_descending_key = 1))) AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''CarVariantId'' AND i.has_filter = 0)
    THROW 51000, N''Index definition mismatch: TestDriveBookings.IX_TestDriveBookings_CarVariantId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.indexes i WHERE i.object_id = OBJECT_ID(N''[dbo].[TestDriveBookings]'', N''U'') AND i.name = N''IX_TestDriveBookings_UserId'' AND i.is_unique = 0 AND i.is_disabled = 0 AND i.is_hypothetical = 0 AND i.type = 2 AND NOT EXISTS (SELECT 1 FROM sys.index_columns extra WHERE extra.object_id = i.object_id AND extra.index_id = i.index_id AND (extra.is_included_column = 1 OR (extra.key_ordinal > 0 AND extra.is_descending_key = 1))) AND (SELECT STRING_AGG(CONVERT(nvarchar(max), c.name), N''|'') WITHIN GROUP (ORDER BY ic.key_ordinal) FROM sys.index_columns ic JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.key_ordinal > 0) = N''UserId'' AND i.has_filter = 0)
    THROW 51000, N''Index definition mismatch: TestDriveBookings.IX_TestDriveBookings_UserId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys f WHERE f.parent_object_id = OBJECT_ID(N''[dbo].[TestDriveBookings]'', N''U'') AND f.name = N''FK_TestDriveBookings_AspNetUsers_AssignedSalesId'' AND f.referenced_object_id = OBJECT_ID(N''[dbo].[AspNetUsers]'') AND f.is_disabled = 0 AND f.is_not_trusted = 0 AND f.delete_referential_action = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), pc.name + N'':'' + rc.name), N''|'') WITHIN GROUP (ORDER BY fc.constraint_column_id) FROM sys.foreign_key_columns fc JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id WHERE fc.constraint_object_id = f.object_id) = N''AssignedSalesId:Id'')
    THROW 51000, N''Foreign key mismatch: FK_TestDriveBookings_AspNetUsers_AssignedSalesId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys f WHERE f.parent_object_id = OBJECT_ID(N''[dbo].[TestDriveBookings]'', N''U'') AND f.name = N''FK_TestDriveBookings_AspNetUsers_UserId'' AND f.referenced_object_id = OBJECT_ID(N''[dbo].[AspNetUsers]'') AND f.is_disabled = 0 AND f.is_not_trusted = 0 AND f.delete_referential_action = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), pc.name + N'':'' + rc.name), N''|'') WITHIN GROUP (ORDER BY fc.constraint_column_id) FROM sys.foreign_key_columns fc JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id WHERE fc.constraint_object_id = f.object_id) = N''UserId:Id'')
    THROW 51000, N''Foreign key mismatch: FK_TestDriveBookings_AspNetUsers_UserId.'', 1;
IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys f WHERE f.parent_object_id = OBJECT_ID(N''[dbo].[TestDriveBookings]'', N''U'') AND f.name = N''FK_TestDriveBookings_CarVariants_CarVariantId'' AND f.referenced_object_id = OBJECT_ID(N''[dbo].[CarVariants]'') AND f.is_disabled = 0 AND f.is_not_trusted = 0 AND f.delete_referential_action = 0 AND (SELECT STRING_AGG(CONVERT(nvarchar(max), pc.name + N'':'' + rc.name), N''|'') WITHIN GROUP (ORDER BY fc.constraint_column_id) FROM sys.foreign_key_columns fc JOIN sys.columns pc ON pc.object_id = fc.parent_object_id AND pc.column_id = fc.parent_column_id JOIN sys.columns rc ON rc.object_id = fc.referenced_object_id AND rc.column_id = fc.referenced_column_id WHERE fc.constraint_object_id = f.object_id) = N''CarVariantId:Id'')
    THROW 51000, N''Foreign key mismatch: FK_TestDriveBookings_CarVariants_CarVariantId.'', 1;


-- Record history after ALL schema checks.
IF NOT EXISTS (
    SELECT * FROM [dbo].[__EFMigrationsHistory]
    WHERE [MigrationId] = N''20261030041022_InitialCreate''
)
BEGIN
    INSERT INTO [dbo].[__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N''20261030041022_InitialCreate'', N''8.0.31'');
END;
';
    COMMIT TRANSACTION;
    PRINT N'AutoCarDB schema verified; migration history committed. Existing data preserved.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO
