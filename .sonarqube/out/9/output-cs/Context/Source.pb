�
zD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Media.API\BackgroundServices\MediaCleanupService.cs�using ConnectHub.Media.API.Repositories;
using ConnectHub.Media.API.Services;

namespace ConnectHub.Media.API.BackgroundServices;

// Har roz chalega — expired files Cloudinary + DB dono se delete karega
public class MediaCleanupService : BackgroundService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<MediaCleanupService> _logger;

    // Har 24 ghante mein chale
    private readonly TimeSpan _interval = TimeSpan.FromHours(24);

    public MediaCleanupService(
        IServiceProvider serviceProvider,
        ILogger<MediaCleanupService> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("Media Cleanup Service shuru ho gaya.");

        while (!stoppingToken.IsCancellationRequested)
        {
            await CleanupExpiredFilesAsync();

            // 24 ghante wait karo
            await Task.Delay(_interval, stoppingToken);
        }
    }

    private async Task CleanupExpiredFilesAsync()
    {
        _logger.LogInformation(
            "Expired files cleanup shuru: {Time}", DateTime.UtcNow);

        try
        {
            // Scoped services ke liye scope banao
            using var scope = _serviceProvider.CreateScope();
            var repo = scope.ServiceProvider.GetRequiredService<IMediaRepository>();
            var cloudinary = scope.ServiceProvider
                .GetRequiredService<ICloudinaryService>();

            // Aaj se pehle expire hone wali files
            var expiredFiles = await repo.FindExpiredFilesAsync(DateTime.UtcNow);

            _logger.LogInformation(
                "{Count} expired files mili", expiredFiles.Count);

            int deleted = 0;
            foreach (var file in expiredFiles)
            {
                try
                {
                    // Cloudinary se delete karo
                    await cloudinary.DeleteAsync(file.CloudinaryPublicId);

                    // DB mein soft delete karo
                    await repo.SoftDeleteAsync(file.FileId);

                    deleted++;
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex,
                        "File delete karne mein error: {FileId}", file.FileId);
                }
            }

            _logger.LogInformation(
                "Cleanup complete: {Deleted}/{Total} files delete hue",
                deleted, expiredFiles.Count);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Cleanup service mein error aaya.");
        }
    }
}ParseOptions.0.json�
oD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Media.API\Controllers\MediaController.cs�using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ConnectHub.Media.API.DTOs;
using ConnectHub.Media.API.Services;
using ConnectHub.Shared.Models;

namespace ConnectHub.Media.API.Controllers;

[ApiController]
[Route("api/media")]
[Authorize]
public class MediaController : ControllerBase
{
    private readonly IMediaService _service;

    public MediaController(IMediaService service)
    {
        _service = service;
    }

    // POST api/media/upload
    [HttpPost("upload")]
    [RequestSizeLimit(52_428_800)] // 50MB max
    public async Task<IActionResult> Upload(
        [FromForm] IFormFile file,
        [FromQuery] int uploadedBy,
        [FromQuery] int? messageId = null,
        [FromQuery] int? roomId = null,
        [FromQuery] bool isPermanent = false)
    {
        try
        {
            var result = await _service.UploadFileAsync(
                file, uploadedBy, messageId, roomId, isPermanent);

            return Ok(ApiResponse<UploadResponseDto>.Ok(
                result, "File uploaded successfully."));
        }
        catch (ArgumentException ex)
        {
            return BadRequest(ApiResponse<string>.Fail(ex.Message));
        }
        catch (Exception ex)
        {
            return StatusCode(500,
                ApiResponse<string>.Fail($"Upload failed: {ex.Message}", 500));
        }
    }

    // GET api/media/{fileId}
    [HttpGet("{fileId:guid}")]
    public async Task<IActionResult> GetById(Guid fileId)
    {
        var file = await _service.GetFileByIdAsync(fileId);
        if (file is null)
            return NotFound(ApiResponse<string>.Fail("File not found.", 404));

        return Ok(ApiResponse<MediaFileResponseDto>.Ok(file));
    }

    // GET api/media/user/{userId}
    [HttpGet("user/{userId:int}")]
    public async Task<IActionResult> GetByUser(int userId)
    {
        var files = await _service.GetFilesByUserAsync(userId);
        return Ok(ApiResponse<IList<MediaFileResponseDto>>.Ok(files));
    }

    // GET api/media/room/{roomId}
    [HttpGet("room/{roomId:int}")]
    public async Task<IActionResult> GetByRoom(int roomId)
    {
        var files = await _service.GetFilesByRoomAsync(roomId);
        return Ok(ApiResponse<IList<MediaFileResponseDto>>.Ok(files));
    }

    // DELETE api/media/{fileId}
    [HttpDelete("{fileId:guid}")]
    public async Task<IActionResult> Delete(Guid fileId)
    {
        var success = await _service.DeleteFileAsync(fileId);
        if (!success)
            return NotFound(ApiResponse<string>.Fail("File not found.", 404));

        return Ok(ApiResponse<string>.Ok(
            "File deleted from both Cloudinary and database successfully."));
    }

    // GET api/media/stats
    [HttpGet("stats")]
    public async Task<IActionResult> GetStats()
    {
        var stats = await _service.GetStatsAsync();
        return Ok(ApiResponse<MediaStatsDto>.Ok(stats));
    }
}ParseOptions.0.json�
gD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Media.API\Data\MediaDbContext.cs�using Microsoft.EntityFrameworkCore;
using ConnectHub.Media.API.Models;

namespace ConnectHub.Media.API.Data;

public class MediaDbContext : DbContext
{
    public MediaDbContext(DbContextOptions<MediaDbContext> options)
        : base(options) { }

    public DbSet<MediaFile> MediaFiles => Set<MediaFile>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<MediaFile>(entity =>
        {
            entity.HasKey(m => m.FileId);

            entity.Property(m => m.FileName)
                  .IsRequired()
                  .HasMaxLength(255);

            entity.Property(m => m.ContentType)
                  .IsRequired()
                  .HasMaxLength(100);

            entity.Property(m => m.PublicUrl)
                  .IsRequired();

            entity.Property(m => m.CloudinaryPublicId)
                  .IsRequired();

            // User ke files dhundhne ke liye index
            entity.HasIndex(m => m.UploadedBy)
                  .HasDatabaseName("IX_MediaFiles_UploadedBy");

            // Expired files dhundhne ke liye index
            entity.HasIndex(m => m.ExpiresAt)
                  .HasDatabaseName("IX_MediaFiles_ExpiresAt");

            // Soft delete filter
            entity.HasQueryFilter(m => !m.IsDeleted);
        });
    }
}ParseOptions.0.json�
mD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Media.API\DTOs\MediaFileResponseDto.cs�namespace ConnectHub.Media.API.DTOs;

public class MediaFileResponseDto
{
    public Guid FileId { get; set; }
    public int UploadedBy { get; set; }
    public string FileName { get; set; } = string.Empty;
    public string ContentType { get; set; } = string.Empty;
    public long FileSizeKb { get; set; }
    public string PublicUrl { get; set; } = string.Empty;
    public string? ThumbnailUrl { get; set; }
    public int? MessageId { get; set; }
    public int? RoomId { get; set; }
    public DateTime UploadedAt { get; set; }
    public DateTime? ExpiresAt { get; set; }
}ParseOptions.0.json�
fD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Media.API\DTOs\MediaStatsDto.cs�namespace ConnectHub.Media.API.DTOs;

public class MediaStatsDto
{
    public int TotalFiles { get; set; }
    public long TotalSizeKb { get; set; }
    public int ImageCount { get; set; }
    public int DocumentCount { get; set; }
    public int AudioCount { get; set; }
    public int ExpiredCount { get; set; }
}ParseOptions.0.json�
jD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Media.API\DTOs\UpdateResponseDto.cs�namespace ConnectHub.Media.API.DTOs;

public class UploadResponseDto
{
    public Guid FileId { get; set; }
    public string FileName { get; set; } = string.Empty;
    public string ContentType { get; set; } = string.Empty;
    public long FileSizeKb { get; set; }
    public string PublicUrl { get; set; } = string.Empty;
    public string? ThumbnailUrl { get; set; }
    public string CloudinaryPublicId { get; set; } = string.Empty;
    public DateTime UploadedAt { get; set; }
}ParseOptions.0.json�
}D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Media.API\Migrations\20260502030038_InitialPostgres.cs�using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ConnectHub.Media.API.Migrations
{
    /// <inheritdoc />
    public partial class InitialPostgres : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "MediaFiles",
                columns: table => new
                {
                    FileId = table.Column<Guid>(type: "uuid", nullable: false),
                    UploadedBy = table.Column<int>(type: "integer", nullable: false),
                    FileName = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    ContentType = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    FileSizeKb = table.Column<long>(type: "bigint", nullable: false),
                    PublicUrl = table.Column<string>(type: "text", nullable: false),
                    CloudinaryPublicId = table.Column<string>(type: "text", nullable: false),
                    ThumbnailUrl = table.Column<string>(type: "text", nullable: true),
                    MessageId = table.Column<int>(type: "integer", nullable: true),
                    RoomId = table.Column<int>(type: "integer", nullable: true),
                    UploadedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ExpiresAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_MediaFiles", x => x.FileId);
                });

            migrationBuilder.CreateIndex(
                name: "IX_MediaFiles_ExpiresAt",
                table: "MediaFiles",
                column: "ExpiresAt");

            migrationBuilder.CreateIndex(
                name: "IX_MediaFiles_UploadedBy",
                table: "MediaFiles",
                column: "UploadedBy");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "MediaFiles");
        }
    }
}
ParseOptions.0.json�
�D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Media.API\Migrations\20260502030038_InitialPostgres.Designer.cs�// <auto-generated />
using System;
using ConnectHub.Media.API.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace ConnectHub.Media.API.Migrations
{
    [DbContext(typeof(MediaDbContext))]
    [Migration("20260502030038_InitialPostgres")]
    partial class InitialPostgres
    {
        /// <inheritdoc />
        protected override void BuildTargetModel(ModelBuilder modelBuilder)
        {
#pragma warning disable 612, 618
            modelBuilder
                .HasAnnotation("ProductVersion", "8.0.10")
                .HasAnnotation("Relational:MaxIdentifierLength", 63);

            NpgsqlModelBuilderExtensions.UseIdentityByDefaultColumns(modelBuilder);

            modelBuilder.Entity("ConnectHub.Media.API.Models.MediaFile", b =>
                {
                    b.Property<Guid>("FileId")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("uuid");

                    b.Property<string>("CloudinaryPublicId")
                        .IsRequired()
                        .HasColumnType("text");

                    b.Property<string>("ContentType")
                        .IsRequired()
                        .HasMaxLength(100)
                        .HasColumnType("character varying(100)");

                    b.Property<DateTime?>("ExpiresAt")
                        .HasColumnType("timestamp with time zone");

                    b.Property<string>("FileName")
                        .IsRequired()
                        .HasMaxLength(255)
                        .HasColumnType("character varying(255)");

                    b.Property<long>("FileSizeKb")
                        .HasColumnType("bigint");

                    b.Property<bool>("IsDeleted")
                        .HasColumnType("boolean");

                    b.Property<int?>("MessageId")
                        .HasColumnType("integer");

                    b.Property<string>("PublicUrl")
                        .IsRequired()
                        .HasColumnType("text");

                    b.Property<int?>("RoomId")
                        .HasColumnType("integer");

                    b.Property<string>("ThumbnailUrl")
                        .HasColumnType("text");

                    b.Property<DateTime>("UploadedAt")
                        .HasColumnType("timestamp with time zone");

                    b.Property<int>("UploadedBy")
                        .HasColumnType("integer");

                    b.HasKey("FileId");

                    b.HasIndex("ExpiresAt")
                        .HasDatabaseName("IX_MediaFiles_ExpiresAt");

                    b.HasIndex("UploadedBy")
                        .HasDatabaseName("IX_MediaFiles_UploadedBy");

                    b.ToTable("MediaFiles");
                });
#pragma warning restore 612, 618
        }
    }
}
ParseOptions.0.json�
zD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Media.API\Migrations\MediaDbContextModelSnapshot.cs�// <auto-generated />
using System;
using ConnectHub.Media.API.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace ConnectHub.Media.API.Migrations
{
    [DbContext(typeof(MediaDbContext))]
    partial class MediaDbContextModelSnapshot : ModelSnapshot
    {
        protected override void BuildModel(ModelBuilder modelBuilder)
        {
#pragma warning disable 612, 618
            modelBuilder
                .HasAnnotation("ProductVersion", "8.0.10")
                .HasAnnotation("Relational:MaxIdentifierLength", 63);

            NpgsqlModelBuilderExtensions.UseIdentityByDefaultColumns(modelBuilder);

            modelBuilder.Entity("ConnectHub.Media.API.Models.MediaFile", b =>
                {
                    b.Property<Guid>("FileId")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("uuid");

                    b.Property<string>("CloudinaryPublicId")
                        .IsRequired()
                        .HasColumnType("text");

                    b.Property<string>("ContentType")
                        .IsRequired()
                        .HasMaxLength(100)
                        .HasColumnType("character varying(100)");

                    b.Property<DateTime?>("ExpiresAt")
                        .HasColumnType("timestamp with time zone");

                    b.Property<string>("FileName")
                        .IsRequired()
                        .HasMaxLength(255)
                        .HasColumnType("character varying(255)");

                    b.Property<long>("FileSizeKb")
                        .HasColumnType("bigint");

                    b.Property<bool>("IsDeleted")
                        .HasColumnType("boolean");

                    b.Property<int?>("MessageId")
                        .HasColumnType("integer");

                    b.Property<string>("PublicUrl")
                        .IsRequired()
                        .HasColumnType("text");

                    b.Property<int?>("RoomId")
                        .HasColumnType("integer");

                    b.Property<string>("ThumbnailUrl")
                        .HasColumnType("text");

                    b.Property<DateTime>("UploadedAt")
                        .HasColumnType("timestamp with time zone");

                    b.Property<int>("UploadedBy")
                        .HasColumnType("integer");

                    b.HasKey("FileId");

                    b.HasIndex("ExpiresAt")
                        .HasDatabaseName("IX_MediaFiles_ExpiresAt");

                    b.HasIndex("UploadedBy")
                        .HasDatabaseName("IX_MediaFiles_UploadedBy");

                    b.ToTable("MediaFiles");
                });
#pragma warning restore 612, 618
        }
    }
}
ParseOptions.0.json�

dD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Media.API\Models\MediaFile.cs�	using System.ComponentModel.DataAnnotations;

namespace ConnectHub.Media.API.Models;

public class MediaFile
{
    public Guid FileId { get; set; } = Guid.NewGuid();

    // Kisne upload kiya
    [Required]
    public int UploadedBy { get; set; }

    [Required, MaxLength(255)]
    public string FileName { get; set; } = string.Empty;

    [Required, MaxLength(100)]
    public string ContentType { get; set; } = string.Empty;

    public long FileSizeKb { get; set; }

    // Cloudinary ka public URL
    [Required]
    public string PublicUrl { get; set; } = string.Empty;

    // Cloudinary ka unique Public ID — delete ke liye zaroori
    [Required]
    public string CloudinaryPublicId { get; set; } = string.Empty;

    // Image ke liye thumbnail URL
    public string? ThumbnailUrl { get; set; }

    // Kis message se attached hai (optional)
    public int? MessageId { get; set; }

    // Kis room se attached hai (optional)
    public int? RoomId { get; set; }

    public DateTime UploadedAt { get; set; } = DateTime.UtcNow;

    // Cleanup ke liye — null ho toh permanent
    public DateTime? ExpiresAt { get; set; }

    public bool IsDeleted { get; set; } = false;
}ParseOptions.0.json�
mD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Media.API\Options\CloudinaryOptions.cs�namespace ConnectHub.Media.API.Options;

// appsettings.json se Cloudinary config yahan aayegi
public class CloudinaryOptions
{
    public string CloudName { get; set; } = string.Empty;
    public string ApiKey { get; set; } = string.Empty;
    public string ApiSecret { get; set; } = string.Empty;
}ParseOptions.0.json�0
[D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Media.API\Program.cs�/using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Serilog;
using ConnectHub.Media.API.BackgroundServices;
using ConnectHub.Media.API.Data;
using ConnectHub.Media.API.Options;
using ConnectHub.Media.API.Repositories;
using ConnectHub.Media.API.Services;

var builder = WebApplication.CreateBuilder(args);

// ── Serilog ───────────────────────────────────────────────────────
Log.Logger = new LoggerConfiguration()
    .WriteTo.Console()
    .CreateLogger();
builder.Host.UseSerilog();

// ── Cloudinary Options ────────────────────────────────────────────
builder.Services.Configure<CloudinaryOptions>(options =>
{
    var section = builder.Configuration.GetSection("Cloudinary");
    options.CloudName = (section["CloudName"] ?? builder.Configuration["CLOUDINARY_CLOUD_NAME"] ?? "").Trim();
    options.ApiKey = (section["ApiKey"] ?? builder.Configuration["CLOUDINARY_API_KEY"] ?? "").Trim();
    options.ApiSecret = (section["ApiSecret"] ?? builder.Configuration["CLOUDINARY_API_SECRET"] ?? "").Trim();
});

// ── Database ──────────────────────────────────────────────────────
builder.Services.AddDbContext<MediaDbContext>(options =>
{
    var connectionString = (builder.Configuration.GetConnectionString("DefaultConnection")
        ?? builder.Configuration["DATABASE_URL"] ?? "").Trim();
    options.UseNpgsql(connectionString,
        npg => npg.MigrationsHistoryTable("__EFMigrationsHistory_Media"));
});

// ── DI ────────────────────────────────────────────────────────────
builder.Services.AddScoped<IMediaRepository, MediaRepository>();
builder.Services.AddScoped<IMediaService, MediaService>();
builder.Services.AddScoped<ICloudinaryService, CloudinaryService>();

// ── Background Cleanup Service ────────────────────────────────────
builder.Services.AddHostedService<MediaCleanupService>();

// ── JWT Authentication ────────────────────────────────────────────
var jwtSecret = builder.Configuration["Jwt:Key"]!;
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"],
            ValidAudience = builder.Configuration["Jwt:Audience"],
            IssuerSigningKey = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(jwtSecret))
        };
    });

builder.Services.AddAuthorization();

// ── File Upload Size Limit ────────────────────────────────────────
builder.Services.Configure<Microsoft.AspNetCore.Http.Features.FormOptions>(options =>
{
    options.MultipartBodyLengthLimit = 52_428_800; // 50MB
});

builder.Services.AddControllers();

// ── Swagger ───────────────────────────────────────────────────────
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "ConnectHub Media API",
        Version = "v1",
        Description = "Cloudinary File Upload + Media Management"
    });
    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "JWT — paste: Bearer {token}",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });
    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

// ── CORS ──────────────────────────────────────────────────────────
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
        policy.AllowAnyOrigin().AllowAnyMethod().AllowAnyHeader());
});

var app = builder.Build();

// ── Middleware ────────────────────────────────────────────────────
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseSerilogRequestLogging();
app.UseCors("AllowAll");
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

// ── Auto Migration ────────────────────────────────────────────────
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<MediaDbContext>();
    try
    {
        db.Database.Migrate();
    }
    catch (Exception ex)
    {
        Console.WriteLine($"[Migration Skipped] {ex.Message}");
    }
}

app.Run();ParseOptions.0.json�
qD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Media.API\Repositories\IMediaRepository.cs�using ConnectHub.Media.API.Models;
using ConnectHub.Media.API.DTOs;

namespace ConnectHub.Media.API.Repositories;

public interface IMediaRepository
{
    Task<MediaFile?> FindByIdAsync(Guid fileId);
    Task<IList<MediaFile>> FindByUploadedByAsync(int userId);
    Task<IList<MediaFile>> FindByRoomIdAsync(int roomId);
    Task<IList<MediaFile>> FindByMessageIdAsync(int messageId);
    Task<IList<MediaFile>> FindExpiredFilesAsync(DateTime beforeDate);
    Task<MediaFile> CreateAsync(MediaFile file);
    Task<MediaFile> UpdateAsync(MediaFile file);
    Task<bool> SoftDeleteAsync(Guid fileId);
    Task<MediaStatsDto> GetStatsAsync();
}ParseOptions.0.json�
pD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Media.API\Repositories\MediaRepository.cs�using Microsoft.EntityFrameworkCore;
using ConnectHub.Media.API.Data;
using ConnectHub.Media.API.DTOs;
using ConnectHub.Media.API.Models;

namespace ConnectHub.Media.API.Repositories;

public class MediaRepository : IMediaRepository
{
    private readonly MediaDbContext _context;

    public MediaRepository(MediaDbContext context)
    {
        _context = context;
    }

    public async Task<MediaFile?> FindByIdAsync(Guid fileId) =>
        await _context.MediaFiles
            .FirstOrDefaultAsync(m => m.FileId == fileId);

    public async Task<IList<MediaFile>> FindByUploadedByAsync(int userId) =>
        await _context.MediaFiles
            .Where(m => m.UploadedBy == userId)
            .OrderByDescending(m => m.UploadedAt)
            .ToListAsync();

    public async Task<IList<MediaFile>> FindByRoomIdAsync(int roomId) =>
        await _context.MediaFiles
            .Where(m => m.RoomId == roomId)
            .OrderByDescending(m => m.UploadedAt)
            .ToListAsync();

    public async Task<IList<MediaFile>> FindByMessageIdAsync(int messageId) =>
        await _context.MediaFiles
            .Where(m => m.MessageId == messageId)
            .ToListAsync();

    public async Task<IList<MediaFile>> FindExpiredFilesAsync(DateTime beforeDate) =>
        await _context.MediaFiles
            .IgnoreQueryFilters() // Soft delete filter bypass karo
            .Where(m => m.ExpiresAt.HasValue &&
                        m.ExpiresAt < beforeDate &&
                        !m.IsDeleted)
            .ToListAsync();

    public async Task<MediaFile> CreateAsync(MediaFile file)
    {
        _context.MediaFiles.Add(file);
        await _context.SaveChangesAsync();
        return file;
    }

    public async Task<MediaFile> UpdateAsync(MediaFile file)
    {
        _context.MediaFiles.Update(file);
        await _context.SaveChangesAsync();
        return file;
    }

    public async Task<bool> SoftDeleteAsync(Guid fileId)
    {
        var file = await _context.MediaFiles
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(m => m.FileId == fileId);

        if (file is null) return false;

        file.IsDeleted = true;
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<MediaStatsDto> GetStatsAsync()
    {
        var files = await _context.MediaFiles.ToListAsync();
        var now = DateTime.UtcNow;

        return new MediaStatsDto
        {
            TotalFiles = files.Count,
            TotalSizeKb = files.Sum(f => f.FileSizeKb),
            ImageCount = files.Count(f => f.ContentType.StartsWith("image/")),
            DocumentCount = files.Count(f =>
                f.ContentType.Contains("pdf") ||
                f.ContentType.Contains("word") ||
                f.ContentType.Contains("document")),
            AudioCount = files.Count(f => f.ContentType.StartsWith("audio/")),
            ExpiredCount = files.Count(f =>
                f.ExpiresAt.HasValue && f.ExpiresAt < now)
        };
    }
}ParseOptions.0.json�-
nD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Media.API\Services\CloudinaryService.cs�,using CloudinaryDotNet;
using CloudinaryDotNet.Actions;
using Microsoft.AspNetCore.Http;
using ConnectHub.Media.API.Options;
using Microsoft.Extensions.Options;

namespace ConnectHub.Media.API.Services;

public class CloudinaryService : ICloudinaryService
{
    private readonly Cloudinary _cloudinary;
    private readonly ILogger<CloudinaryService> _logger;

    public CloudinaryService(
        IOptions<CloudinaryOptions> options,
        ILogger<CloudinaryService> logger)
    {
        _logger = logger;

        var opt = options.Value;

        // Cloudinary initialize karo
        var account = new Account(
            opt.CloudName,
            opt.ApiKey,
            opt.ApiSecret);

        _cloudinary = new Cloudinary(account);
        _cloudinary.Api.Secure = true; // HTTPS use karo
    }

    public async Task<CloudinaryUploadResult> UploadAsync(IFormFile file, string folder)
    {
        _logger.LogInformation(
            "Cloudinary par upload ho raha hai: {FileName}", file.FileName);

        using var stream = file.OpenReadStream();

        // File type ke hisaab se upload params
        if (file.ContentType.StartsWith("image/"))
        {
            return await UploadImageAsync(stream, file.FileName, folder, file.Length);
        }
        else if (file.ContentType.StartsWith("video/"))
        {
            return await UploadVideoAsync(stream, file.FileName, folder, file.Length);
        }
        else
        {
            return await UploadRawAsync(stream, file.FileName, folder,
                file.Length, file.ContentType);
        }
    }

    private async Task<CloudinaryUploadResult> UploadImageAsync(
        Stream stream, string fileName, string folder, long fileSize)
    {
        var uploadParams = new ImageUploadParams
        {
            File = new FileDescription(fileName, stream),
            Folder = $"connecthub/{folder}",
            // Auto quality aur format optimize karo
            Transformation = new Transformation()
                .Quality("auto")
                .FetchFormat("auto"),
            UseFilename = true,
            UniqueFilename = true,
            Overwrite = false
        };

        var result = await _cloudinary.UploadAsync(uploadParams);

        if (result.Error is not null)
        {
            _logger.LogError("Cloudinary upload error: {Error}", result.Error.Message);
            throw new Exception($"Upload failed: {result.Error.Message}");
        }

        // Image ke liye thumbnail bhi banao
        var thumbnailUrl = GetThumbnailUrl(result.PublicId);

        return new CloudinaryUploadResult
        {
            PublicId = result.PublicId,
            PublicUrl = result.SecureUrl.ToString(),
            ThumbnailUrl = thumbnailUrl,
            FileSizeKb = fileSize / 1024,
            ContentType = "image/" + result.Format
        };
    }

    private async Task<CloudinaryUploadResult> UploadVideoAsync(
        Stream stream, string fileName, string folder, long fileSize)
    {
        var uploadParams = new VideoUploadParams
        {
            File = new FileDescription(fileName, stream),
            Folder = $"connecthub/{folder}",
            UseFilename = true,
            UniqueFilename = true,
            Overwrite = false
        };

        var result = await _cloudinary.UploadAsync(uploadParams);

        if (result.Error is not null)
        {
            _logger.LogError("Cloudinary video upload error: {Error}", result.Error.Message);
            throw new Exception($"Upload failed: {result.Error.Message}");
        }

        return new CloudinaryUploadResult
        {
            PublicId = result.PublicId,
            PublicUrl = result.SecureUrl.ToString(),
            ThumbnailUrl = null,
            FileSizeKb = fileSize / 1024,
            ContentType = "video/" + result.Format
        };
    }

    private async Task<CloudinaryUploadResult> UploadRawAsync(
        Stream stream, string fileName, string folder, long fileSize, string contentType)
    {
        var uploadParams = new RawUploadParams
        {
            File = new FileDescription(fileName, stream),
            Folder = $"connecthub/{folder}",
            UseFilename = true,
            UniqueFilename = true,
            Overwrite = false
        };

        var result = await _cloudinary.UploadAsync(uploadParams);

        if (result.Error is not null)
        {
            _logger.LogError("Cloudinary raw upload error: {Error}", result.Error.Message);
            throw new Exception($"Upload failed: {result.Error.Message}");
        }

        return new CloudinaryUploadResult
        {
            PublicId = result.PublicId,
            PublicUrl = result.SecureUrl.ToString(),
            ThumbnailUrl = null,
            FileSizeKb = fileSize / 1024,
            ContentType = contentType
        };
    }

    public async Task<bool> DeleteAsync(string publicId)
    {
        _logger.LogInformation("Cloudinary se delete ho raha hai: {PublicId}", publicId);

        var deleteParams = new DeletionParams(publicId);
        var result = await _cloudinary.DestroyAsync(deleteParams);

        return result.Result == "ok";
    }

    public string GetThumbnailUrl(string publicId, int width = 200, int height = 200)
    {
        // Cloudinary transformation URL banao
        return _cloudinary.Api.UrlImgUp
            .Transform(new Transformation()
                .Width(width)
                .Height(height)
                .Crop("fill")
                .Quality("auto"))
            .BuildUrl(publicId);
    }
}ParseOptions.0.json�
oD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Media.API\Services\ICloudinaryService.cs�using Microsoft.AspNetCore.Http;

namespace ConnectHub.Media.API.Services;

public interface ICloudinaryService
{
    Task<CloudinaryUploadResult> UploadAsync(IFormFile file, string folder);
    Task<bool> DeleteAsync(string publicId);
    string GetThumbnailUrl(string publicId, int width = 200, int height = 200);
}

public class CloudinaryUploadResult
{
    public string PublicId { get; set; } = string.Empty;
    public string PublicUrl { get; set; } = string.Empty;
    public string? ThumbnailUrl { get; set; }
    public long FileSizeKb { get; set; }
    public string ContentType { get; set; } = string.Empty;
}ParseOptions.0.json�
jD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Media.API\Services\IMediaService.cs�using Microsoft.AspNetCore.Http;
using ConnectHub.Media.API.DTOs;

namespace ConnectHub.Media.API.Services;

public interface IMediaService
{
    Task<UploadResponseDto> UploadFileAsync(IFormFile file, int uploadedBy,
        int? messageId, int? roomId, bool isPermanent);
    Task<MediaFileResponseDto?> GetFileByIdAsync(Guid fileId);
    Task<IList<MediaFileResponseDto>> GetFilesByUserAsync(int userId);
    Task<IList<MediaFileResponseDto>> GetFilesByRoomAsync(int roomId);
    Task<bool> DeleteFileAsync(Guid fileId);
    Task<MediaStatsDto> GetStatsAsync();
}
ParseOptions.0.json�1
iD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Media.API\Services\MediaService.cs�0using ConnectHub.Media.API.DTOs;
using ConnectHub.Media.API.Models;
using ConnectHub.Media.API.Repositories;

namespace ConnectHub.Media.API.Services;

public class MediaService : IMediaService
{
    private readonly IMediaRepository _repo;
    private readonly ICloudinaryService _cloudinary;
    private readonly ILogger<MediaService> _logger;

    // File size limits
    private const long MaxImageSizeBytes = 10 * 1024 * 1024;   // 10 MB
    private const long MaxDocumentSizeBytes = 50 * 1024 * 1024; // 50 MB
    private const long MaxAudioSizeBytes = 25 * 1024 * 1024;    // 25 MB

    // Allowed file types
    private static readonly HashSet<string> AllowedImageTypes = new()
    {
        "image/jpeg", "image/png", "image/gif",
        "image/webp", "image/svg+xml"
    };

    private static readonly HashSet<string> AllowedDocumentTypes = new()
    {
        "application/pdf",
        "application/msword",
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        "text/plain"
    };

    private static readonly HashSet<string> AllowedAudioTypes = new()
    {
        "audio/mpeg", "audio/wav",
        "audio/ogg", "audio/mp4"
    };

    public MediaService(
        IMediaRepository repo,
        ICloudinaryService cloudinary,
        ILogger<MediaService> logger)
    {
        _repo = repo;
        _cloudinary = cloudinary;
        _logger = logger;
    }

    public async Task<UploadResponseDto> UploadFileAsync(
        IFormFile file,
        int uploadedBy,
        int? messageId,
        int? roomId,
        bool isPermanent)
    {
        // Validation
        ValidateFile(file);

        // Folder decide karo — image/audio/document
        var folder = GetFolder(file.ContentType);

        // Cloudinary par upload karo
        var uploadResult = await _cloudinary.UploadAsync(file, folder);

        // DB mein save karo
        var mediaFile = new MediaFile
        {
            UploadedBy = uploadedBy,
            FileName = file.FileName,
            ContentType = file.ContentType,
            FileSizeKb = uploadResult.FileSizeKb,
            PublicUrl = uploadResult.PublicUrl,
            CloudinaryPublicId = uploadResult.PublicId,
            ThumbnailUrl = uploadResult.ThumbnailUrl,
            MessageId = messageId,
            RoomId = roomId,
            // Permanent nahi hai toh 30 din baad expire
            ExpiresAt = isPermanent ? null : DateTime.UtcNow.AddDays(30)
        };

        var created = await _repo.CreateAsync(mediaFile);

        _logger.LogInformation(
            "File upload successful: {FileName} by User {UserId}",
            file.FileName, uploadedBy);

        return new UploadResponseDto
        {
            FileId = created.FileId,
            FileName = created.FileName,
            ContentType = created.ContentType,
            FileSizeKb = created.FileSizeKb,
            PublicUrl = created.PublicUrl,
            ThumbnailUrl = created.ThumbnailUrl,
            CloudinaryPublicId = created.CloudinaryPublicId,
            UploadedAt = created.UploadedAt
        };
    }

    public async Task<MediaFileResponseDto?> GetFileByIdAsync(Guid fileId)
    {
        var file = await _repo.FindByIdAsync(fileId);
        return file is null ? null : MapToDto(file);
    }

    public async Task<IList<MediaFileResponseDto>> GetFilesByUserAsync(int userId)
    {
        var files = await _repo.FindByUploadedByAsync(userId);
        return files.Select(MapToDto).ToList();
    }

    public async Task<IList<MediaFileResponseDto>> GetFilesByRoomAsync(int roomId)
    {
        var files = await _repo.FindByRoomIdAsync(roomId);
        return files.Select(MapToDto).ToList();
    }

    public async Task<bool> DeleteFileAsync(Guid fileId)
    {
        var file = await _repo.FindByIdAsync(fileId);
        if (file is null) return false;

        // Cloudinary se bhi delete karo
        await _cloudinary.DeleteAsync(file.CloudinaryPublicId);

        // DB mein soft delete karo
        return await _repo.SoftDeleteAsync(fileId);
    }

    public async Task<MediaStatsDto> GetStatsAsync() =>
        await _repo.GetStatsAsync();

    // ── Private helpers ───────────────────────────────────────────

    private static void ValidateFile(IFormFile file)
    {
        if (file.Length == 0)
            throw new ArgumentException("File khali hai.");

        var contentType = file.ContentType.ToLower();

        if (AllowedImageTypes.Contains(contentType))
        {
            if (file.Length > MaxImageSizeBytes)
                throw new ArgumentException("Image 10MB se badi nahi honi chahiye.");
        }
        else if (AllowedDocumentTypes.Contains(contentType))
        {
            if (file.Length > MaxDocumentSizeBytes)
                throw new ArgumentException("Document 50MB se bada nahi hona chahiye.");
        }
        else if (AllowedAudioTypes.Contains(contentType))
        {
            if (file.Length > MaxAudioSizeBytes)
                throw new ArgumentException("Audio 25MB se bada nahi hona chahiye.");
        }
        else
        {
            throw new ArgumentException(
                $"File type allowed nahi hai: {contentType}");
        }
    }

    private static string GetFolder(string contentType) =>
        contentType switch
        {
            var t when t.StartsWith("image/") => "images",
            var t when t.StartsWith("audio/") => "audio",
            _ => "documents"
        };

    private static MediaFileResponseDto MapToDto(MediaFile m) => new()
    {
        FileId = m.FileId,
        UploadedBy = m.UploadedBy,
        FileName = m.FileName,
        ContentType = m.ContentType,
        FileSizeKb = m.FileSizeKb,
        PublicUrl = m.PublicUrl,
        ThumbnailUrl = m.ThumbnailUrl,
        MessageId = m.MessageId,
        RoomId = m.RoomId,
        UploadedAt = m.UploadedAt,
        ExpiresAt = m.ExpiresAt
    };
}ParseOptions.0.json�
�D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Media.API\obj\Debug\net8.0\ConnectHub.Media.API.GlobalUsings.g.cs�// <auto-generated/>
global using Microsoft.AspNetCore.Builder;
global using Microsoft.AspNetCore.Hosting;
global using Microsoft.AspNetCore.Http;
global using Microsoft.AspNetCore.Routing;
global using Microsoft.Extensions.Configuration;
global using Microsoft.Extensions.DependencyInjection;
global using Microsoft.Extensions.Hosting;
global using Microsoft.Extensions.Logging;
global using System;
global using System.Collections.Generic;
global using System.IO;
global using System.Linq;
global using System.Net.Http;
global using System.Net.Http.Json;
global using System.Threading;
global using System.Threading.Tasks;
ParseOptions.0.json�
�D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Media.API\obj\Debug\net8.0\.NETCoreApp,Version=v8.0.AssemblyAttributes.cs�// <autogenerated />
using System;
using System.Reflection;
[assembly: global::System.Runtime.Versioning.TargetFrameworkAttribute(".NETCoreApp,Version=v8.0", FrameworkDisplayName = ".NET 8.0")]
ParseOptions.0.json�	
�D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Media.API\obj\Debug\net8.0\ConnectHub.Media.API.AssemblyInfo.cs�//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated by a tool.
//
//     Changes to this file may cause incorrect behavior and will be lost if
//     the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

using System;
using System.Reflection;

[assembly: System.Reflection.AssemblyCompanyAttribute("ConnectHub.Media.API")]
[assembly: System.Reflection.AssemblyConfigurationAttribute("Debug")]
[assembly: System.Reflection.AssemblyFileVersionAttribute("1.0.0.0")]
[assembly: System.Reflection.AssemblyInformationalVersionAttribute("1.0.0")]
[assembly: System.Reflection.AssemblyProductAttribute("ConnectHub.Media.API")]
[assembly: System.Reflection.AssemblyTitleAttribute("ConnectHub.Media.API")]
[assembly: System.Reflection.AssemblyVersionAttribute("1.0.0.0")]

// Generated by the MSBuild WriteCodeFragment class.

ParseOptions.0.json�
�D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Media.API\obj\Debug\net8.0\ConnectHub.Media.API.MvcApplicationPartsAssemblyInfo.cs�//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated by a tool.
//
//     Changes to this file may cause incorrect behavior and will be lost if
//     the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

using System;
using System.Reflection;

[assembly: Microsoft.AspNetCore.Mvc.ApplicationParts.ApplicationPartAttribute("Microsoft.AspNetCore.OpenApi")]
[assembly: Microsoft.AspNetCore.Mvc.ApplicationParts.ApplicationPartAttribute("Swashbuckle.AspNetCore.SwaggerGen")]

// Generated by the MSBuild WriteCodeFragment class.

ParseOptions.0.json