�
}D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Notification.API\Controllers\NotificationController.cs�using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ConnectHub.Notification.API.DTOs;
using ConnectHub.Notification.API.Services;
using ConnectHub.Shared.Models;

namespace ConnectHub.Notification.API.Controllers;

[ApiController]
[Route("api/notifications")]
[Authorize]
public class NotificationController : ControllerBase
{
    private readonly INotificationService _service;

    public NotificationController(INotificationService service)
    {
        _service = service;
    }

    // POST api/notifications/send
    [HttpPost("send")]
    public async Task<IActionResult> Send([FromBody] SendNotificationDto dto)
    {
        var result = await _service.SendAsync(dto);
        return Ok(ApiResponse<NotificationResponseDto>.Ok(
            result, "Notification sent successfully."));
    }

    // POST api/notifications/broadcast
    [HttpPost("broadcast")]
    public async Task<IActionResult> Broadcast([FromBody] BroadcastNotificationDto dto)
    {
        var result = await _service.SendBulkAsync(dto);
        return Ok(ApiResponse<IList<NotificationResponseDto>>.Ok(
            result, "Broadcast sent successfully."));
    }

    // GET api/notifications/recipient/{recipientId}
    [HttpGet("recipient/{recipientId:int}")]
    public async Task<IActionResult> GetByRecipient(int recipientId)
    {
        var result = await _service.GetByRecipientAsync(recipientId);
        return Ok(ApiResponse<IList<NotificationResponseDto>>.Ok(result));
    }

    // GET api/notifications/unread/{recipientId}
    [HttpGet("unread/{recipientId:int}")]
    public async Task<IActionResult> GetUnread(int recipientId)
    {
        var result = await _service.GetUnreadAsync(recipientId);
        return Ok(ApiResponse<IList<NotificationResponseDto>>.Ok(result));
    }

    // GET api/notifications/unread/{recipientId}/count
    [HttpGet("unread/{recipientId:int}/count")]
    public async Task<IActionResult> GetUnreadCount(int recipientId)
    {
        var count = await _service.GetUnreadCountAsync(recipientId);
        return Ok(ApiResponse<int>.Ok(count));
    }

    // PUT api/notifications/{notificationId}/read
    [HttpPut("{notificationId:int}/read")]
    public async Task<IActionResult> MarkAsRead(int notificationId)
    {
        try
        {
            var result = await _service.MarkAsReadAsync(notificationId);
            return Ok(ApiResponse<NotificationResponseDto>.Ok(
                result, "Notification marked as read."));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse<string>.Fail(ex.Message, 404));
        }
    }

    // PUT api/notifications/read-all/{recipientId}
    [HttpPut("read-all/{recipientId:int}")]
    public async Task<IActionResult> MarkAllRead(int recipientId)
    {
        await _service.MarkAllReadAsync(recipientId);
        return Ok(ApiResponse<string>.Ok("All notifications marked as read."));
    }

    // DELETE api/notifications/{notificationId}
    [HttpDelete("{notificationId:int}")]
    public async Task<IActionResult> Delete(int notificationId)
    {
        var success = await _service.DeleteAsync(notificationId);
        if (!success)
            return NotFound(ApiResponse<string>.Fail("Notification not found.", 404));
        return Ok(ApiResponse<string>.Ok("Notification deleted successfully."));
    }

    // GET api/notifications/all?page=1&pageSize=20
    [HttpGet("all")]
    public async Task<IActionResult> GetAll(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var result = await _service.GetAllAsync(page, pageSize);
        return Ok(ApiResponse<PagedResult<NotificationResponseDto>>.Ok(result));
    }
}ParseOptions.0.json�

uD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Notification.API\Data\NotificationDbContext.cs�	using Microsoft.EntityFrameworkCore;
using ConnectHub.Notification.API.Models;

namespace ConnectHub.Notification.API.Data;

public class NotificationDbContext : DbContext
{
    public NotificationDbContext(DbContextOptions<NotificationDbContext> options)
        : base(options) { }

    public DbSet<NotificationEntity> Notifications => Set<NotificationEntity>();
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<NotificationEntity>(entity =>
        {
            entity.HasKey(n => n.NotificationId);

            entity.Property(n => n.Title)
                  .IsRequired()
                  .HasMaxLength(200);

            entity.Property(n => n.Message)
                  .IsRequired()
                  .HasMaxLength(1000);

            // RecipientId se fast query ke liye index
            entity.HasIndex(n => n.RecipientId)
                  .HasDatabaseName("IX_Notifications_RecipientId");

            // Unread notifications ke liye index
            entity.HasIndex(n => new { n.RecipientId, n.IsRead })
                  .HasDatabaseName("IX_Notifications_RecipientId_IsRead");
        });
    }
}ParseOptions.0.json�
xD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Notification.API\DTOs\BroadcastNotificationDto.cs�using System.ComponentModel.DataAnnotations;

namespace ConnectHub.Notification.API.DTOs;

// Admin ke liye — sabko ek saath notification
public class BroadcastNotificationDto
{
    [Required, MaxLength(200)]
    public string Title { get; set; } = string.Empty;

    [Required, MaxLength(1000)]
    public string Message { get; set; } = string.Empty;

    // Specific users ko bhejo — empty ho toh sabko
    public List<int> RecipientIds { get; set; } = new();
}ParseOptions.0.json�
tD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Notification.API\DTOs\EmailNotificationDto.cs�using System.ComponentModel.DataAnnotations;

namespace ConnectHub.Notification.API.DTOs;

public class EmailNotificationDto
{
    [Required, EmailAddress]
    public string ToEmail { get; set; } = string.Empty;

    [Required]
    public string ToName { get; set; } = string.Empty;

    [Required]
    public string Subject { get; set; } = string.Empty;

    [Required]
    public string Body { get; set; } = string.Empty;
}ParseOptions.0.json�
wD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Notification.API\DTOs\NotificationResponseDto.cs�using ConnectHub.Shared.Enums;

namespace ConnectHub.Notification.API.DTOs;

public class NotificationResponseDto
{
    public int NotificationId { get; set; }
    public int RecipientId { get; set; }
    public int? SenderId { get; set; }
    public NotificationType Type { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public int? RelatedId { get; set; }
    public bool IsRead { get; set; }
    public DateTime SentAt { get; set; }
    public DateTime? ReadAt { get; set; }
}ParseOptions.0.json�
sD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Notification.API\DTOs\SendNotificationDto.cs�using System.ComponentModel.DataAnnotations;
using ConnectHub.Shared.Enums;

namespace ConnectHub.Notification.API.DTOs;

public class SendNotificationDto
{
    [Required]
    public int RecipientId { get; set; }

    public int? SenderId { get; set; }

    public NotificationType Type { get; set; } = NotificationType.MESSAGE;

    [Required, MaxLength(200)]
    public string Title { get; set; } = string.Empty;

    [Required, MaxLength(1000)]
    public string Message { get; set; } = string.Empty;

    public int? RelatedId { get; set; }
}ParseOptions.0.json�	
oD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Notification.API\Hubs\NotificationHub.cs�using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace ConnectHub.Notification.API.Hubs;

[Authorize]
public class NotificationHub : Hub
{
    private readonly ILogger<NotificationHub> _logger;

    public NotificationHub(ILogger<NotificationHub> logger)
    {
        _logger = logger;
    }

    public override async Task OnConnectedAsync()
    {
        var userId = Context.User?.FindFirst("sub")?.Value
                  ?? Context.User?.FindFirst(
                      System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;

        _logger.LogInformation(
            "User {UserId} connected to NotificationHub", userId);

        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        var userId = Context.User?.FindFirst("sub")?.Value;
        _logger.LogInformation(
            "User {UserId} disconnected from NotificationHub", userId);

        await base.OnDisconnectedAsync(exception);
    }
}ParseOptions.0.json�
nD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Notification.API\Hubs\UserIdProvider.cs�using Microsoft.AspNetCore.SignalR;
using System.Security.Claims;

namespace ConnectHub.Notification.API.Hubs;

public class UserIdProvider : IUserIdProvider
{
    public string? GetUserId(HubConnectionContext connection)
    {
        // Check for common JWT claims for user ID
        return connection.User?.FindFirst("sub")?.Value
            ?? connection.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? connection.User?.FindFirst("uid")?.Value;
    }
}
ParseOptions.0.json�
�D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Notification.API\Migrations\20260501085938_InitialPostgres.cs�using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace ConnectHub.Notification.API.Migrations
{
    /// <inheritdoc />
    public partial class InitialPostgres : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Notifications",
                columns: table => new
                {
                    NotificationId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    RecipientId = table.Column<int>(type: "integer", nullable: false),
                    SenderId = table.Column<int>(type: "integer", nullable: true),
                    Type = table.Column<int>(type: "integer", nullable: false),
                    Title = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    Message = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false),
                    RelatedId = table.Column<int>(type: "integer", nullable: true),
                    IsRead = table.Column<bool>(type: "boolean", nullable: false),
                    SentAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    ReadAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Notifications", x => x.NotificationId);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Notifications_RecipientId",
                table: "Notifications",
                column: "RecipientId");

            migrationBuilder.CreateIndex(
                name: "IX_Notifications_RecipientId_IsRead",
                table: "Notifications",
                columns: new[] { "RecipientId", "IsRead" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Notifications");
        }
    }
}
ParseOptions.0.json�
�D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Notification.API\Migrations\20260501085938_InitialPostgres.Designer.cs�// <auto-generated />
using System;
using ConnectHub.Notification.API.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace ConnectHub.Notification.API.Migrations
{
    [DbContext(typeof(NotificationDbContext))]
    [Migration("20260501085938_InitialPostgres")]
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

            modelBuilder.Entity("ConnectHub.Notification.API.Models.NotificationEntity", b =>
                {
                    b.Property<int>("NotificationId")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("integer");

                    NpgsqlPropertyBuilderExtensions.UseIdentityByDefaultColumn(b.Property<int>("NotificationId"));

                    b.Property<bool>("IsRead")
                        .HasColumnType("boolean");

                    b.Property<string>("Message")
                        .IsRequired()
                        .HasMaxLength(1000)
                        .HasColumnType("character varying(1000)");

                    b.Property<DateTime?>("ReadAt")
                        .HasColumnType("timestamp with time zone");

                    b.Property<int>("RecipientId")
                        .HasColumnType("integer");

                    b.Property<int?>("RelatedId")
                        .HasColumnType("integer");

                    b.Property<int?>("SenderId")
                        .HasColumnType("integer");

                    b.Property<DateTime>("SentAt")
                        .HasColumnType("timestamp with time zone");

                    b.Property<string>("Title")
                        .IsRequired()
                        .HasMaxLength(200)
                        .HasColumnType("character varying(200)");

                    b.Property<int>("Type")
                        .HasColumnType("integer");

                    b.HasKey("NotificationId");

                    b.HasIndex("RecipientId")
                        .HasDatabaseName("IX_Notifications_RecipientId");

                    b.HasIndex("RecipientId", "IsRead")
                        .HasDatabaseName("IX_Notifications_RecipientId_IsRead");

                    b.ToTable("Notifications");
                });
#pragma warning restore 612, 618
        }
    }
}
ParseOptions.0.json�
�D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Notification.API\Migrations\NotificationDbContextModelSnapshot.cs�// <auto-generated />
using System;
using ConnectHub.Notification.API.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace ConnectHub.Notification.API.Migrations
{
    [DbContext(typeof(NotificationDbContext))]
    partial class NotificationDbContextModelSnapshot : ModelSnapshot
    {
        protected override void BuildModel(ModelBuilder modelBuilder)
        {
#pragma warning disable 612, 618
            modelBuilder
                .HasAnnotation("ProductVersion", "8.0.10")
                .HasAnnotation("Relational:MaxIdentifierLength", 63);

            NpgsqlModelBuilderExtensions.UseIdentityByDefaultColumns(modelBuilder);

            modelBuilder.Entity("ConnectHub.Notification.API.Models.NotificationEntity", b =>
                {
                    b.Property<int>("NotificationId")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("integer");

                    NpgsqlPropertyBuilderExtensions.UseIdentityByDefaultColumn(b.Property<int>("NotificationId"));

                    b.Property<bool>("IsRead")
                        .HasColumnType("boolean");

                    b.Property<string>("Message")
                        .IsRequired()
                        .HasMaxLength(1000)
                        .HasColumnType("character varying(1000)");

                    b.Property<DateTime?>("ReadAt")
                        .HasColumnType("timestamp with time zone");

                    b.Property<int>("RecipientId")
                        .HasColumnType("integer");

                    b.Property<int?>("RelatedId")
                        .HasColumnType("integer");

                    b.Property<int?>("SenderId")
                        .HasColumnType("integer");

                    b.Property<DateTime>("SentAt")
                        .HasColumnType("timestamp with time zone");

                    b.Property<string>("Title")
                        .IsRequired()
                        .HasMaxLength(200)
                        .HasColumnType("character varying(200)");

                    b.Property<int>("Type")
                        .HasColumnType("integer");

                    b.HasKey("NotificationId");

                    b.HasIndex("RecipientId")
                        .HasDatabaseName("IX_Notifications_RecipientId");

                    b.HasIndex("RecipientId", "IsRead")
                        .HasDatabaseName("IX_Notifications_RecipientId_IsRead");

                    b.ToTable("Notifications");
                });
#pragma warning restore 612, 618
        }
    }
}
ParseOptions.0.json�
tD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Notification.API\Models\NotificationEntity.cs�using System.ComponentModel.DataAnnotations;
using ConnectHub.Shared.Enums;

namespace ConnectHub.Notification.API.Models;

public class NotificationEntity
{
    public int NotificationId { get; set; }

    // Jise notification jaani hai
    [Required]
    public int RecipientId { get; set; }

    // Kisne bheja (system notification ho toh null)
    public int? SenderId { get; set; }

    public NotificationType Type { get; set; } = NotificationType.MESSAGE;

    [Required, MaxLength(200)]
    public string Title { get; set; } = string.Empty;

    [Required, MaxLength(1000)]
    public string Message { get; set; } = string.Empty;

    // Related entity ka Id — message, room, etc.
    public int? RelatedId { get; set; }

    public bool IsRead { get; set; } = false;

    public DateTime SentAt { get; set; } = DateTime.UtcNow;

    public DateTime? ReadAt { get; set; }
}ParseOptions.0.json�9
bD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Notification.API\Program.cs�8using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Serilog;
using ConnectHub.Notification.API.Data;
using ConnectHub.Notification.API.Hubs;
using ConnectHub.Notification.API.Repositories;
using ConnectHub.Notification.API.Services;

var builder = WebApplication.CreateBuilder(args);

// ── Serilog ───────────────────────────────────────────────────────
Log.Logger = new LoggerConfiguration()
    .WriteTo.Console()
    .CreateLogger();
builder.Host.UseSerilog();

// ── Database ──────────────────────────────────────────────────────
// Postgres on Neon — see Auth.API/Program.cs for the rationale on the
// per-service migrations-history table.
builder.Services.AddDbContext<NotificationDbContext>(options =>
{
    var connectionString = (builder.Configuration.GetConnectionString("DefaultConnection")
        ?? builder.Configuration["DATABASE_URL"] ?? "").Trim();
    options.UseNpgsql(connectionString,
        npgsql => npgsql.MigrationsHistoryTable("__EFMigrationsHistory_Notification"));
});

// ── DI ────────────────────────────────────────────────────────────
builder.Services.AddScoped<INotificationRepository, NotificationRepository>();
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddScoped<IEmailService, EmailService>();

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

        // SignalR ke liye query string se token lo
        options.Events = new JwtBearerEvents
        {
            OnMessageReceived = context =>
            {
                var accessToken = context.Request.Query["access_token"];
                var path = context.HttpContext.Request.Path;
                if (!string.IsNullOrEmpty(accessToken) &&
                    path.StartsWithSegments("/hubs/notifications"))
                {
                    context.Token = accessToken;
                }
                return Task.CompletedTask;
            }
        };
    });

builder.Services.AddAuthorization();

// ── Custom UserIdProvider — JWT se UserId nikalta hai ─────────────
builder.Services.AddSingleton<IUserIdProvider, UserIdProvider>();

// ── SignalR ───────────────────────────────────────────────────────
builder.Services.AddSignalR(options =>
{
    options.EnableDetailedErrors = true;
    options.KeepAliveInterval = TimeSpan.FromSeconds(15);
    options.ClientTimeoutInterval = TimeSpan.FromSeconds(30);
})
.AddJsonProtocol(options => {
    options.PayloadSerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
    options.PayloadSerializerOptions.Converters.Add(new System.Text.Json.Serialization.JsonStringEnumConverter());
});



// ── Swagger ───────────────────────────────────────────────────────
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "ConnectHub Notification API",
        Version = "v1",
        Description = "Notifications + Email + Real-time Badge"
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
        policy
            .AllowAnyMethod()
            .AllowAnyHeader()
            .AllowCredentials()
            .SetIsOriginAllowed(_ => true));
});

// 🔥 SignalR camelCase property names ensure frontend compatibility
builder.Services.AddControllers()
    .AddJsonOptions(options => {
        options.JsonSerializerOptions.PropertyNamingPolicy = System.Text.Json.JsonNamingPolicy.CamelCase;
        options.JsonSerializerOptions.Converters.Add(new System.Text.Json.Serialization.JsonStringEnumConverter());
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

// ── SignalR Hub Register ──────────────────────────────────────────
app.MapHub<NotificationHub>("/hubs/notifications");

// ── Auto Migration ────────────────────────────────────────────────
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<NotificationDbContext>();
    try
    {
        db.Database.Migrate();
    }
    catch (Exception ex)
    {
        Console.WriteLine($"[Migration Skipped] {ex.Message}");
    }
}

app.Run();ParseOptions.0.json�
D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Notification.API\Repositories\INotificationRepository.cs�using ConnectHub.Notification.API.Models;

namespace ConnectHub.Notification.API.Repositories;

public interface INotificationRepository
{
    Task<NotificationEntity?> FindByIdAsync(int notificationId);
    Task<IList<NotificationEntity>> FindUnreadByRecipientIdAsync(int recipientId);
    Task<IList<NotificationEntity>> FindByRecipientIdAsync(int recipientId);
    Task<int> CountUnreadByRecipientIdAsync(int recipientId);
    Task<IList<NotificationEntity>> FindAllAsync();
    Task<NotificationEntity> CreateAsync(NotificationEntity notification);
    Task<IList<NotificationEntity>> CreateManyAsync(IList<NotificationEntity> notifications);
    Task<NotificationEntity> UpdateAsync(NotificationEntity notification);
    Task MarkAllReadByRecipientIdAsync(int recipientId);
    Task<bool> DeleteAsync(int notificationId);
}ParseOptions.0.json�
~D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Notification.API\Repositories\NotificationRepository.cs�using Microsoft.EntityFrameworkCore;
using ConnectHub.Notification.API.Data;
using ConnectHub.Notification.API.Models;

namespace ConnectHub.Notification.API.Repositories;

public class NotificationRepository : INotificationRepository
{
    private readonly NotificationDbContext _context;

    public NotificationRepository(NotificationDbContext context)
    {
        _context = context;
    }
    public async Task<NotificationEntity?> FindByIdAsync(int notificationId) =>
        await _context.Notifications
            .FirstOrDefaultAsync(n => n.NotificationId == notificationId);

    public async Task<IList<NotificationEntity>> FindByRecipientIdAsync(int recipientId) =>
        await _context.Notifications
            .Where(n => n.RecipientId == recipientId)
            .OrderByDescending(n => n.SentAt)
            .ToListAsync();

    public async Task<IList<NotificationEntity>> FindUnreadByRecipientIdAsync(int recipientId) =>
        await _context.Notifications
            .Where(n => n.RecipientId == recipientId && !n.IsRead)
            .OrderByDescending(n => n.SentAt)
            .ToListAsync();

    public async Task<int> CountUnreadByRecipientIdAsync(int recipientId) =>
        await _context.Notifications
            .CountAsync(n => n.RecipientId == recipientId && !n.IsRead);

    public async Task<IList<NotificationEntity>> FindAllAsync() =>
        await _context.Notifications
            .OrderByDescending(n => n.SentAt)
            .ToListAsync();

    public async Task<NotificationEntity> CreateAsync(NotificationEntity notification)
    {
        _context.Notifications.Add(notification);
        await _context.SaveChangesAsync();
        return notification;
    }

    public async Task<IList<NotificationEntity>> CreateManyAsync(IList<NotificationEntity> notifications)
    {
        _context.Notifications.AddRange(notifications);
        await _context.SaveChangesAsync();
        return notifications;
    }

    public async Task<NotificationEntity> UpdateAsync(NotificationEntity notification)
    {
        _context.Notifications.Update(notification);
        await _context.SaveChangesAsync();
        return notification;
    }

    public async Task MarkAllReadByRecipientIdAsync(int recipientId)
    {
        var unread = await _context.Notifications
            .Where(n => n.RecipientId == recipientId && !n.IsRead)
            .ToListAsync();

        foreach (var n in unread)
        {
            n.IsRead = true;
            n.ReadAt = DateTime.UtcNow;
        }

        await _context.SaveChangesAsync();
    }

    public async Task<bool> DeleteAsync(int notificationId)
    {
        var notification = await _context.Notifications.FindAsync(notificationId);
        if (notification is null) return false;
        _context.Notifications.Remove(notification);
        await _context.SaveChangesAsync();
        return true;
    }
}ParseOptions.0.json�
pD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Notification.API\Services\EmailService.cs�using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;
using ConnectHub.Notification.API.DTOs;

namespace ConnectHub.Notification.API.Services;

public class EmailService : IEmailService
{
    private readonly IConfiguration _config;
    private readonly ILogger<EmailService> _logger;

    public EmailService(IConfiguration config, ILogger<EmailService> logger)
    {
        _config = config;
        _logger = logger;
    }

    public async Task SendEmailAsync(EmailNotificationDto dto)
    {
        try
        {
            var email = new MimeMessage();

            // From
            email.From.Add(new MailboxAddress(
                _config["Email:SenderName"] ?? "ConnectHub",
                _config["Email:SenderEmail"] ?? "noreply@connecthub.com"));

            // To
            email.To.Add(new MailboxAddress(dto.ToName, dto.ToEmail));

            email.Subject = dto.Subject;

            // HTML body
            var bodyBuilder = new BodyBuilder
            {
                HtmlBody = $@"
                    <div style='font-family: Arial, sans-serif; max-width: 600px;'>
                        <h2 style='color: #4F46E5;'>ConnectHub</h2>
                        <h3>{dto.Subject}</h3>
                        <p>{dto.Body}</p>
                        <hr/>
                        <small style='color: #888;'>
                            Yeh email ConnectHub ne bheja hai.
                        </small>
                    </div>",
                TextBody = dto.Body
            };

            email.Body = bodyBuilder.ToMessageBody();

            using var smtp = new SmtpClient();

            await smtp.ConnectAsync(
                _config["Email:SmtpHost"] ?? "smtp.gmail.com",
                int.Parse(_config["Email:SmtpPort"] ?? "587"),
                SecureSocketOptions.StartTls);

            await smtp.AuthenticateAsync(
                _config["Email:UserName"],
                _config["Email:Password"]);

            await smtp.SendAsync(email);
            await smtp.DisconnectAsync(true);

            _logger.LogInformation("Email sent to {Email}", dto.ToEmail);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Email bhejne mein error aaya: {Email}", dto.ToEmail);
            // Email fail hone par app crash na ho
        }
    }
}ParseOptions.0.json�
qD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Notification.API\Services\IEmailService.cs�using ConnectHub.Notification.API.DTOs;

namespace ConnectHub.Notification.API.Services;

public interface IEmailService
{
    Task SendEmailAsync(EmailNotificationDto dto);
}ParseOptions.0.json�
xD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Notification.API\Services\INotificationService.cs�using ConnectHub.Notification.API.DTOs;
using ConnectHub.Shared.Models;

namespace ConnectHub.Notification.API.Services;

public interface INotificationService
{
    Task<NotificationResponseDto> SendAsync(SendNotificationDto dto);
    Task<IList<NotificationResponseDto>> SendBulkAsync(BroadcastNotificationDto dto);
    Task<IList<NotificationResponseDto>> GetByRecipientAsync(int recipientId);
    Task<IList<NotificationResponseDto>> GetUnreadAsync(int recipientId);
    Task<int> GetUnreadCountAsync(int recipientId);
    Task<NotificationResponseDto> MarkAsReadAsync(int notificationId);
    Task MarkAllReadAsync(int recipientId);
    Task<bool> DeleteAsync(int notificationId);
    Task<PagedResult<NotificationResponseDto>> GetAllAsync(int page, int pageSize);
}ParseOptions.0.json�2
wD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Notification.API\Services\NotificationService.cs�1using Microsoft.AspNetCore.SignalR;
using ConnectHub.Notification.API.DTOs;
using ConnectHub.Notification.API.Hubs;
using ConnectHub.Notification.API.Models;
using ConnectHub.Notification.API.Repositories;
using ConnectHub.Shared.Enums;
using ConnectHub.Shared.Models;

namespace ConnectHub.Notification.API.Services;

public class NotificationService : INotificationService
{
    private readonly INotificationRepository _repo;
    private readonly IHubContext<NotificationHub> _hubContext;
    private readonly IEmailService _emailService;
    private readonly ILogger<NotificationService> _logger;

    public NotificationService(
        INotificationRepository repo,
        IHubContext<NotificationHub> hubContext,
        IEmailService emailService,
        ILogger<NotificationService> logger)
    {
        _repo = repo;
        _hubContext = hubContext;
        _emailService = emailService;
        _logger = logger;
    }

    public async Task<NotificationResponseDto> SendAsync(SendNotificationDto dto)
    {
        // Save to database
        var notification = new NotificationEntity
        {
            RecipientId = dto.RecipientId,
            SenderId = dto.SenderId,
            Type = dto.Type,
            Title = dto.Title,
            Message = dto.Message,
            RelatedId = dto.RelatedId
        };

        var created = await _repo.CreateAsync(notification);

        // Real-time push — update badge count via SignalR
        var unreadCount = await _repo.CountUnreadByRecipientIdAsync(dto.RecipientId);

        await _hubContext.Clients
            .User(dto.RecipientId.ToString())
            .SendAsync("ReceiveNotification", new
            {
                Notification = MapToDto(created),
                UnreadCount = unreadCount
            });

        _logger.LogInformation(
            "Notification sent to User {RecipientId}: {Title}",
            dto.RecipientId, dto.Title);

        return MapToDto(created);
    }

    public async Task<IList<NotificationResponseDto>> SendBulkAsync(
        BroadcastNotificationDto dto)
    {
        var notifications = new List<NotificationEntity>();

        // Specific users or everyone
        var recipientIds = dto.RecipientIds.Any()
            ? dto.RecipientIds
            : new List<int>(); // Yahan sab users ki list chahiye hogi

        foreach (var recipientId in recipientIds)
        {
            notifications.Add(new NotificationEntity
            {
                RecipientId = recipientId,
                Type = NotificationType.PLATFORM,
                Title = dto.Title,
                Message = dto.Message
            });
        }

        var created = await _repo.CreateManyAsync(notifications);

        // Real-time push — everyone at once
        foreach (var recipientId in recipientIds)
        {
            await _hubContext.Clients
                .User(recipientId.ToString())
                .SendAsync("ReceiveBroadcast", new
                {
                    Title = dto.Title,
                    Message = dto.Message,
                    SentAt = DateTime.UtcNow
                });
        }

        _logger.LogInformation(
            "Broadcast sent to {Count} users: {Title}",
            recipientIds.Count, dto.Title);

        return created.Select(MapToDto).ToList();
    }

    public async Task<IList<NotificationResponseDto>> GetByRecipientAsync(int recipientId)
    {
        var notifications = await _repo.FindByRecipientIdAsync(recipientId);
        return notifications.Select(MapToDto).ToList();
    }

    public async Task<IList<NotificationResponseDto>> GetUnreadAsync(int recipientId)
    {
        var notifications = await _repo.FindUnreadByRecipientIdAsync(recipientId);
        return notifications.Select(MapToDto).ToList();
    }

    public async Task<int> GetUnreadCountAsync(int recipientId) =>
        await _repo.CountUnreadByRecipientIdAsync(recipientId);

    public async Task<NotificationResponseDto> MarkAsReadAsync(int notificationId)
    {
        var notification = await _repo.FindByIdAsync(notificationId)
            ?? throw new KeyNotFoundException("Notification not found.");

        notification.IsRead = true;
        notification.ReadAt = DateTime.UtcNow;

        var updated = await _repo.UpdateAsync(notification);

        // Update badge count in real-time
        var unreadCount = await _repo.CountUnreadByRecipientIdAsync(
            notification.RecipientId);

        await _hubContext.Clients
            .User(notification.RecipientId.ToString())
            .SendAsync("NotificationCount", unreadCount);

        return MapToDto(updated);
    }

    public async Task MarkAllReadAsync(int recipientId)
    {
        await _repo.MarkAllReadByRecipientIdAsync(recipientId);

        // Reset badge count
        await _hubContext.Clients
            .User(recipientId.ToString())
            .SendAsync("NotificationCount", 0);
    }

    public async Task<bool> DeleteAsync(int notificationId) =>
        await _repo.DeleteAsync(notificationId);

    public async Task<PagedResult<NotificationResponseDto>> GetAllAsync(
        int page, int pageSize)
    {
        var all = await _repo.FindAllAsync();
        var paged = all
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .Select(MapToDto)
            .ToList();

        return new PagedResult<NotificationResponseDto>
        {
            Items = paged,
            TotalCount = all.Count,
            PageNumber = page,
            PageSize = pageSize
        };
    }

    // ── Private helper ────────────────────────────────────────────
    private static NotificationResponseDto MapToDto(NotificationEntity n) => new()
    {
        NotificationId = n.NotificationId,
        RecipientId = n.RecipientId,
        SenderId = n.SenderId,
        Type = n.Type,
        Title = n.Title,
        Message = n.Message,
        RelatedId = n.RelatedId,
        IsRead = n.IsRead,
        SentAt = n.SentAt,
        ReadAt = n.ReadAt
    };
}ParseOptions.0.json�
�D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Notification.API\obj\Debug\net8.0\ConnectHub.Notification.API.GlobalUsings.g.cs�// <auto-generated/>
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
�D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Notification.API\obj\Debug\net8.0\.NETCoreApp,Version=v8.0.AssemblyAttributes.cs�// <autogenerated />
using System;
using System.Reflection;
[assembly: global::System.Runtime.Versioning.TargetFrameworkAttribute(".NETCoreApp,Version=v8.0", FrameworkDisplayName = ".NET 8.0")]
ParseOptions.0.json�	
�D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Notification.API\obj\Debug\net8.0\ConnectHub.Notification.API.AssemblyInfo.cs�//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated by a tool.
//
//     Changes to this file may cause incorrect behavior and will be lost if
//     the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

using System;
using System.Reflection;

[assembly: System.Reflection.AssemblyCompanyAttribute("ConnectHub.Notification.API")]
[assembly: System.Reflection.AssemblyConfigurationAttribute("Debug")]
[assembly: System.Reflection.AssemblyFileVersionAttribute("1.0.0.0")]
[assembly: System.Reflection.AssemblyInformationalVersionAttribute("1.0.0")]
[assembly: System.Reflection.AssemblyProductAttribute("ConnectHub.Notification.API")]
[assembly: System.Reflection.AssemblyTitleAttribute("ConnectHub.Notification.API")]
[assembly: System.Reflection.AssemblyVersionAttribute("1.0.0.0")]

// Generated by the MSBuild WriteCodeFragment class.

ParseOptions.0.json�
�D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Notification.API\obj\Debug\net8.0\ConnectHub.Notification.API.MvcApplicationPartsAssemblyInfo.cs�//------------------------------------------------------------------------------
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