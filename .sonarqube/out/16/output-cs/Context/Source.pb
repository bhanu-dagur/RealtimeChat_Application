�
xD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Message.API\Controllers\AdminMessageController.cs�using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ConnectHub.Message.API.Services;
using ConnectHub.Shared.Models;
using ConnectHub.Message.API.DTOs;

namespace ConnectHub.Message.API.Controllers;

[ApiController]
[Route("api/messages/admin")]
[Authorize(Roles = "Admin")]
public class AdminMessageController : ControllerBase
{
    private readonly IMessageService _service;

    public AdminMessageController(IMessageService service)
    {
        _service = service;
    }

    [HttpGet("messages")]
    public async Task<IActionResult> GetAllMessages(
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 50)
    {
        var result = await _service.GetAllMessagesAdminAsync(page, pageSize);
        return Ok(ApiResponse<PagedResult<MessageResponseDto>>.Ok(result));
    }

    [HttpDelete("messages/{messageId}")]
    public async Task<IActionResult> DeleteMessage(int messageId)
    {
        var success = await _service.DeleteMessageAdminAsync(messageId);
        if (!success)
            return NotFound(ApiResponse<string>.Fail("Message not found.", 404));

        return Ok(ApiResponse<string>.Ok("Message successfully permanently deleted."));
    }

    [HttpGet("analytics/messages")]
    public async Task<IActionResult> GetMessageCount()
    {
        var count = await _service.CountMessagesAsync();
        return Ok(ApiResponse<int>.Ok(count));
    }
}
ParseOptions.0.json�9
sD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Message.API\Controllers\MessageController.cs�8using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ConnectHub.Message.API.DTOs;
using ConnectHub.Message.API.Services;
using ConnectHub.Shared.Models;

namespace ConnectHub.Message.API.Controllers;

[ApiController]
[Route("api/messages")]
[Authorize]
public class MessageController : ControllerBase
{
    private readonly IMessageService _service;

    public MessageController(IMessageService service)
    {
        _service = service;
    }

    // POST api/messages/send
    [HttpPost("send")]
    public async Task<IActionResult> Send([FromBody] SendMessageDto dto)
    {
        try
        {
            var result = await _service.SendMessageAsync(dto);
            return Ok(ApiResponse<MessageResponseDto>.Ok(result, "Message sent."));
        }
        catch (ArgumentException ex)
        {
            return BadRequest(ApiResponse<string>.Fail(ex.Message));
        }
    }

    // GET api/messages/direct?userId1=1&userId2=2&page=1&pageSize=20
    [HttpGet("direct")]
    public async Task<IActionResult> GetDirect(
        [FromQuery] int userId1,
        [FromQuery] int userId2,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var result = await _service.GetDirectMessagesAsync(userId1, userId2, page, pageSize);
        return Ok(ApiResponse<PagedResult<MessageResponseDto>>.Ok(result));
    }

    // GET api/messages/room/{roomId}?page=1&pageSize=20
    [HttpGet("room/{roomId:int}")]
    public async Task<IActionResult> GetRoomMessages(
        int roomId,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20)
    {
        var result = await _service.GetRoomMessagesAsync(roomId, page, pageSize);
        return Ok(ApiResponse<PagedResult<MessageResponseDto>>.Ok(result));
    }

    // GET api/messages/unread/{receiverId}
    [HttpGet("unread/{receiverId:int}")]
    public async Task<IActionResult> GetUnread(int receiverId)
    {
        var result = await _service.GetUnreadMessagesAsync(receiverId);
        return Ok(ApiResponse<IList<MessageResponseDto>>.Ok(result));
    }

    // GET api/messages/unread/{receiverId}/count
    [HttpGet("unread/{receiverId:int}/count")]
    public async Task<IActionResult> GetUnreadCount(int receiverId)
    {
        var count = await _service.GetUnreadCountAsync(receiverId);
        return Ok(ApiResponse<int>.Ok(count));
    }

    // PUT api/messages/{messageId}/edit
    [HttpPut("{messageId:int}/edit")]
    public async Task<IActionResult> Edit(int messageId, [FromBody] EditMessageDto dto)
    {
        try
        {
            var result = await _service.EditMessageAsync(messageId, dto);
            return Ok(ApiResponse<MessageResponseDto>.Ok(result, "Message edited."));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse<string>.Fail(ex.Message, 404));
        }
    }

    // PUT api/messages/mark-read?senderId=1&receiverId=2
    // Returns the count of rows actually flipped so the client can detect
    // no-op cases (already-all-read) and skip the corresponding SignalR
    // BroadcastMessagesRead — saves a needless fan-out when nothing changed.
    [HttpPut("mark-read")]
    public async Task<IActionResult> MarkRead(
        [FromQuery] int senderId,
        [FromQuery] int receiverId)
    {
        var count = await _service.MarkAllReadAsync(senderId, receiverId);
        return Ok(ApiResponse<int>.Ok(count, "Messages marked as read."));
    }

    // DELETE api/messages/{messageId}
    // "Delete for everyone" — soft-deletes server-side; both sender and receiver
    // see "This message was deleted." after the SignalR broadcast.
    [HttpDelete("{messageId:int}")]
    public async Task<IActionResult> Delete(int messageId)
    {
        var success = await _service.DeleteMessageAsync(messageId);
        if (!success)
            return NotFound(ApiResponse<string>.Fail("Message not found.", 404));
        return Ok(ApiResponse<string>.Ok("Message deleted."));
    }

    // DELETE api/messages/{messageId}/for-me?userId=5
    // "Delete for me" — only hides the row for that one user. Other participants
    // continue to see it untouched. No SignalR broadcast.
    [HttpDelete("{messageId:int}/for-me")]
    public async Task<IActionResult> DeleteForMe(int messageId, [FromQuery] int userId)
    {
        var success = await _service.DeleteForMeAsync(messageId, userId);
        if (!success)
            return NotFound(ApiResponse<string>.Fail("Message not found.", 404));
        return Ok(ApiResponse<string>.Ok("Hidden from your view."));
    }

    // PUT api/messages/{messageId}/delivered?recipientId=5
    // Recipient-only ack. Returns the updated row so the SignalR broadcast carries
    // the canonical DeliveredAt timestamp.
    [HttpPut("{messageId:int}/delivered")]
    public async Task<IActionResult> MarkDelivered(int messageId, [FromQuery] int recipientId)
    {
        var updated = await _service.MarkDeliveredAsync(messageId, recipientId);
        if (updated is null)
            return NotFound(ApiResponse<string>.Fail("Message not found or recipient mismatch.", 404));
        return Ok(ApiResponse<MessageResponseDto>.Ok(updated, "Marked delivered."));
    }

    // PUT api/messages/mark-all-delivered?recipientId=5
    // Bulk-ack on (re)connect: when a user comes online we flip every undelivered
    // direct message addressed to them. Returns the list of just-delivered
    // messages so the recipient's client can SignalR-broadcast each flip back
    // to the original sender — without the list, senders' ticks stay ✓ until
    // they hard-refresh.
    [HttpPut("mark-all-delivered")]
    public async Task<IActionResult> MarkAllDelivered([FromQuery] int recipientId)
    {
        var delivered = await _service.MarkAllDeliveredAsync(recipientId);
        return Ok(ApiResponse<IList<DeliveredMessageDto>>.Ok(delivered, "Bulk delivery acked."));
    }

    // GET api/messages/search?userId=1&keyword=hello
    [HttpGet("search")]
    public async Task<IActionResult> Search(
        [FromQuery] int userId,
        [FromQuery] string keyword)
    {
        var result = await _service.SearchMessagesAsync(userId, keyword);
        return Ok(ApiResponse<IList<MessageResponseDto>>.Ok(result));
    }

    // GET api/messages/search/room/{roomId}?keyword=hello
    [HttpGet("search/room/{roomId:int}")]
    public async Task<IActionResult> SearchRoom(int roomId, [FromQuery] string keyword)
    {
        var result = await _service.SearchRoomMessagesAsync(roomId, keyword);
        return Ok(ApiResponse<IList<MessageResponseDto>>.Ok(result));
    }

    // GET api/messages/recent/{userId}
    // One row per DM partner with last-message preview + unread count, ordered newest first.
    [HttpGet("recent/{userId:int}")]
    public async Task<IActionResult> Recent(int userId)
    {
        var result = await _service.GetRecentConversationsAsync(userId);
        return Ok(ApiResponse<IList<ConversationSummaryDto>>.Ok(result));
    }
}ParseOptions.0.json�
kD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Message.API\Data\MessageDbContext.cs�using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;
using ConnectHub.Message.API.Models;

namespace ConnectHub.Message.API.Data;

public class MessageDbContext : DbContext
{
    public MessageDbContext(DbContextOptions<MessageDbContext> options) : base(options) { }

    public DbSet<MessageEntity> Messages => Set<MessageEntity>();

    // Stores values as UTC; reads them back as DateTime with Kind=Utc so
    // System.Text.Json appends the trailing 'Z' on serialization.
    private static readonly ValueConverter<DateTime, DateTime> UtcConverter = new(
        toDb => toDb.Kind == DateTimeKind.Utc ? toDb : toDb.ToUniversalTime(),
        fromDb => DateTime.SpecifyKind(fromDb, DateTimeKind.Utc));

    private static readonly ValueConverter<DateTime?, DateTime?> NullableUtcConverter = new(
        toDb => toDb.HasValue
            ? (toDb.Value.Kind == DateTimeKind.Utc ? toDb : toDb.Value.ToUniversalTime())
            : (DateTime?)null,
        fromDb => fromDb.HasValue
            ? DateTime.SpecifyKind(fromDb.Value, DateTimeKind.Utc)
            : (DateTime?)null);

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<MessageEntity>(entity =>
        {
            entity.HasKey(m => m.MessageId);

            entity.Property(m => m.Content)
                  .IsRequired()
                  .HasMaxLength(2000);

            entity.Property(m => m.SentAt).HasConversion(UtcConverter);
            entity.Property(m => m.ReadAt).HasConversion(NullableUtcConverter);
            entity.Property(m => m.EditedAt).HasConversion(NullableUtcConverter);

            entity.HasIndex(m => new { m.SenderId, m.ReceiverId })
                  .HasDatabaseName("IX_Messages_Direct");

            entity.HasIndex(m => new { m.RoomId, m.SentAt })
                  .HasDatabaseName("IX_Messages_Room");

            entity.HasQueryFilter(m => !m.IsDeleted);
        });
    }

    // Belt-and-braces: force UTC on every save in case any code path bypasses
    // the converter (e.g. raw SQL with .NET DateTime fed in).
    public override int SaveChanges()
    {
        NormalizeUtc();
        return base.SaveChanges();
    }

    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        NormalizeUtc();
        return base.SaveChangesAsync(cancellationToken);
    }

    private void NormalizeUtc()
    {
        foreach (var entry in ChangeTracker.Entries<MessageEntity>())
        {
            if (entry.State is EntityState.Added or EntityState.Modified)
            {
                if (entry.Entity.SentAt.Kind != DateTimeKind.Utc)
                    entry.Entity.SentAt = DateTime.SpecifyKind(entry.Entity.SentAt, DateTimeKind.Utc);
                if (entry.Entity.ReadAt.HasValue && entry.Entity.ReadAt.Value.Kind != DateTimeKind.Utc)
                    entry.Entity.ReadAt = DateTime.SpecifyKind(entry.Entity.ReadAt.Value, DateTimeKind.Utc);
                if (entry.Entity.EditedAt.HasValue && entry.Entity.EditedAt.Value.Kind != DateTimeKind.Utc)
                    entry.Entity.EditedAt = DateTime.SpecifyKind(entry.Entity.EditedAt.Value, DateTimeKind.Utc);
            }
        }
    }
}ParseOptions.0.json�
qD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Message.API\DTOs\ConversationSummaryDto.cs�using ConnectHub.Shared.Enums;

namespace ConnectHub.Message.API.DTOs;

// One row per "conversation partner" for the sidebar:
//   - PartnerId   = the *other* user in the DM
//   - LastMessage = preview of the most recent message (truncated server-side)
//   - LastSentAt  = UTC timestamp of that message (used for ordering on the client)
//   - UnreadCount = number of unread messages addressed to the requesting user
public class ConversationSummaryDto
{
    public int PartnerId { get; set; }
    public int? LastMessageId { get; set; }
    public string? LastMessage { get; set; }
    public MessageType LastMessageType { get; set; }
    public int? LastSenderId { get; set; }
    public DateTime? LastSentAt { get; set; }
    public int UnreadCount { get; set; }
}
ParseOptions.0.json�
iD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Message.API\DTOs\EditMessageDto.cs�using System.ComponentModel.DataAnnotations;

namespace ConnectHub.Message.API.DTOs;

public class EditMessageDto
{
    [Required,MaxLength(2000)]
    public string Content { get; set; } = string.Empty;
}ParseOptions.0.json�
jD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Message.API\DTOs\MessageQueryDto.cs�namespace ConnectHub.Message.API.DTOs;

public class MessageQueryDto
{
    public int Page { get; set; } = 1;
    public int PageSize { get; set; } = 20;
    public string? Keyword { get; set; }
}ParseOptions.0.json�
mD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Message.API\DTOs\MessageResponseDto.cs�using ConnectHub.Shared.Enums;

namespace ConnectHub.Message.API.DTOs;

public class MessageResponseDto
{
    public int MessageId { get; set; }
    public int SenderId { get; set; }
    public int? ReceiverId { get; set; }
    public int? RoomId { get; set; }
    public string Content { get; set; } = string.Empty;
    public MessageType MessageType { get; set; }
    public bool IsRead { get; set; }
    public bool IsDelivered { get; set; }
    public bool IsEdited { get; set; }
    public DateTime SentAt { get; set; }
    public DateTime? DeliveredAt { get; set; }
    public DateTime? ReadAt { get; set; }
    public DateTime? EditedAt { get; set; }
    public string? MediaUrl { get; set; }
    public int? ReplyToMessageId { get; set; }
    public bool IsDeleted { get; set; }
}ParseOptions.0.json�
iD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Message.API\DTOs\SendMessageDto.cs�using System.ComponentModel.DataAnnotations;
using ConnectHub.Shared.Enums;

namespace ConnectHub.Message.API.DTOs;

public class SendMessageDto
{
    [Required]
    public int SenderId { get; set; }

    // Ek hi hoga — ya ReceiverId ya RoomId
    public int? ReceiverId { get; set; }
    public int? RoomId { get; set; }

    [Required, MaxLength(2000)]
    public string Content { get; set; } = string.Empty;

    public MessageType MessageType { get; set; } = MessageType.TEXT;

    public string? MediaUrl { get; set; }

    public int? ReplyToMessageId { get; set; }
}ParseOptions.0.json�
D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Message.API\Migrations\20260501085737_InitialPostgres.cs�using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace ConnectHub.Message.API.Migrations
{
    /// <inheritdoc />
    public partial class InitialPostgres : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Messages",
                columns: table => new
                {
                    MessageId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    SenderId = table.Column<int>(type: "integer", nullable: false),
                    ReceiverId = table.Column<int>(type: "integer", nullable: true),
                    RoomId = table.Column<int>(type: "integer", nullable: true),
                    Content = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: false),
                    MessageType = table.Column<int>(type: "integer", nullable: false),
                    IsRead = table.Column<bool>(type: "boolean", nullable: false),
                    IsDeleted = table.Column<bool>(type: "boolean", nullable: false),
                    IsEdited = table.Column<bool>(type: "boolean", nullable: false),
                    IsDelivered = table.Column<bool>(type: "boolean", nullable: false),
                    SentAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    DeliveredAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    ReadAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    EditedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    MediaUrl = table.Column<string>(type: "text", nullable: true),
                    ReplyToMessageId = table.Column<int>(type: "integer", nullable: true),
                    DeletedForUserIds = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Messages", x => x.MessageId);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Messages_Direct",
                table: "Messages",
                columns: new[] { "SenderId", "ReceiverId" });

            migrationBuilder.CreateIndex(
                name: "IX_Messages_Room",
                table: "Messages",
                columns: new[] { "RoomId", "SentAt" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Messages");
        }
    }
}
ParseOptions.0.json�
�D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Message.API\Migrations\20260501085737_InitialPostgres.Designer.cs�// <auto-generated />
using System;
using ConnectHub.Message.API.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace ConnectHub.Message.API.Migrations
{
    [DbContext(typeof(MessageDbContext))]
    [Migration("20260501085737_InitialPostgres")]
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

            modelBuilder.Entity("ConnectHub.Message.API.Models.MessageEntity", b =>
                {
                    b.Property<int>("MessageId")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("integer");

                    NpgsqlPropertyBuilderExtensions.UseIdentityByDefaultColumn(b.Property<int>("MessageId"));

                    b.Property<string>("Content")
                        .IsRequired()
                        .HasMaxLength(2000)
                        .HasColumnType("character varying(2000)");

                    b.Property<string>("DeletedForUserIds")
                        .HasMaxLength(500)
                        .HasColumnType("character varying(500)");

                    b.Property<DateTime?>("DeliveredAt")
                        .HasColumnType("timestamp with time zone");

                    b.Property<DateTime?>("EditedAt")
                        .HasColumnType("timestamp with time zone");

                    b.Property<bool>("IsDeleted")
                        .HasColumnType("boolean");

                    b.Property<bool>("IsDelivered")
                        .HasColumnType("boolean");

                    b.Property<bool>("IsEdited")
                        .HasColumnType("boolean");

                    b.Property<bool>("IsRead")
                        .HasColumnType("boolean");

                    b.Property<string>("MediaUrl")
                        .HasColumnType("text");

                    b.Property<int>("MessageType")
                        .HasColumnType("integer");

                    b.Property<DateTime?>("ReadAt")
                        .HasColumnType("timestamp with time zone");

                    b.Property<int?>("ReceiverId")
                        .HasColumnType("integer");

                    b.Property<int?>("ReplyToMessageId")
                        .HasColumnType("integer");

                    b.Property<int?>("RoomId")
                        .HasColumnType("integer");

                    b.Property<int>("SenderId")
                        .HasColumnType("integer");

                    b.Property<DateTime>("SentAt")
                        .HasColumnType("timestamp with time zone");

                    b.HasKey("MessageId");

                    b.HasIndex("RoomId", "SentAt")
                        .HasDatabaseName("IX_Messages_Room");

                    b.HasIndex("SenderId", "ReceiverId")
                        .HasDatabaseName("IX_Messages_Direct");

                    b.ToTable("Messages");
                });
#pragma warning restore 612, 618
        }
    }
}
ParseOptions.0.json�
~D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Message.API\Migrations\MessageDbContextModelSnapshot.cs�// <auto-generated />
using System;
using ConnectHub.Message.API.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace ConnectHub.Message.API.Migrations
{
    [DbContext(typeof(MessageDbContext))]
    partial class MessageDbContextModelSnapshot : ModelSnapshot
    {
        protected override void BuildModel(ModelBuilder modelBuilder)
        {
#pragma warning disable 612, 618
            modelBuilder
                .HasAnnotation("ProductVersion", "8.0.10")
                .HasAnnotation("Relational:MaxIdentifierLength", 63);

            NpgsqlModelBuilderExtensions.UseIdentityByDefaultColumns(modelBuilder);

            modelBuilder.Entity("ConnectHub.Message.API.Models.MessageEntity", b =>
                {
                    b.Property<int>("MessageId")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("integer");

                    NpgsqlPropertyBuilderExtensions.UseIdentityByDefaultColumn(b.Property<int>("MessageId"));

                    b.Property<string>("Content")
                        .IsRequired()
                        .HasMaxLength(2000)
                        .HasColumnType("character varying(2000)");

                    b.Property<string>("DeletedForUserIds")
                        .HasMaxLength(500)
                        .HasColumnType("character varying(500)");

                    b.Property<DateTime?>("DeliveredAt")
                        .HasColumnType("timestamp with time zone");

                    b.Property<DateTime?>("EditedAt")
                        .HasColumnType("timestamp with time zone");

                    b.Property<bool>("IsDeleted")
                        .HasColumnType("boolean");

                    b.Property<bool>("IsDelivered")
                        .HasColumnType("boolean");

                    b.Property<bool>("IsEdited")
                        .HasColumnType("boolean");

                    b.Property<bool>("IsRead")
                        .HasColumnType("boolean");

                    b.Property<string>("MediaUrl")
                        .HasColumnType("text");

                    b.Property<int>("MessageType")
                        .HasColumnType("integer");

                    b.Property<DateTime?>("ReadAt")
                        .HasColumnType("timestamp with time zone");

                    b.Property<int?>("ReceiverId")
                        .HasColumnType("integer");

                    b.Property<int?>("ReplyToMessageId")
                        .HasColumnType("integer");

                    b.Property<int?>("RoomId")
                        .HasColumnType("integer");

                    b.Property<int>("SenderId")
                        .HasColumnType("integer");

                    b.Property<DateTime>("SentAt")
                        .HasColumnType("timestamp with time zone");

                    b.HasKey("MessageId");

                    b.HasIndex("RoomId", "SentAt")
                        .HasDatabaseName("IX_Messages_Room");

                    b.HasIndex("SenderId", "ReceiverId")
                        .HasDatabaseName("IX_Messages_Direct");

                    b.ToTable("Messages");
                });
#pragma warning restore 612, 618
        }
    }
}
ParseOptions.0.json�
jD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Message.API\Models\MessageEntity.cs�using System.ComponentModel.DataAnnotations;
using ConnectHub.Shared.Enums;

namespace ConnectHub.Message.API.Models;

public class MessageEntity
{
    public int MessageId { get; set; }
    
    [Required]
    public int SenderId { get; set; }

    // Direct message ke liye — Room message ho toh null
    public int? ReceiverId { get; set; }

    // Room message ke liye — Direct message ho toh null
    public int? RoomId { get; set; }

    [Required, MaxLength(2000)]
    public string Content { get; set; } = string.Empty;

    public MessageType MessageType { get; set; } = MessageType.TEXT;

    public bool IsRead { get; set; } = false;

    public bool IsDeleted { get; set; } = false;

    public bool IsEdited { get; set; } = false;

    // Delivered ≠ read. Set the moment any of the recipient's connected tabs
    // ack receipt of the SignalR push (or when the recipient comes online and
    // pulls history). Drives the second grey ✓✓ tick on the sender side.
    public bool IsDelivered { get; set; } = false;

    public DateTime SentAt { get; set; } = DateTime.UtcNow;

    public DateTime? DeliveredAt { get; set; }

    public DateTime? ReadAt { get; set; }

    public DateTime? EditedAt { get; set; }

    public string? MediaUrl { get; set; }

    // Reply feature ke liye
    public int? ReplyToMessageId { get; set; }

    // Comma-separated list of user ids who chose "Delete for me". Cheap and good
    // enough for chat scale; if it ever grows we can normalise into a join table.
    [MaxLength(500)]
    public string? DeletedForUserIds { get; set; }
}ParseOptions.0.json�+
]D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Message.API\Program.cs�*using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Serilog;
using ConnectHub.Message.API.Data;
using ConnectHub.Message.API.Repositories;
using ConnectHub.Message.API.Services;

var builder = WebApplication.CreateBuilder(args);

// ── Serilog ───────────────────────────────────────────────────────
Log.Logger = new LoggerConfiguration()
    .WriteTo.Console()
    .CreateLogger();
builder.Host.UseSerilog();

// ── Database ──────────────────────────────────────────────────────
// Postgres on Neon — see Auth.API/Program.cs for the rationale on the
// per-service migrations-history table.
builder.Services.AddDbContext<MessageDbContext>(options =>
{
    var connectionString = (builder.Configuration.GetConnectionString("DefaultConnection")
        ?? builder.Configuration["DATABASE_URL"] ?? "").Trim();
    options.UseNpgsql(connectionString,
        npgsql => npgsql.MigrationsHistoryTable("__EFMigrationsHistory_Message"));
});

// ── DI ────────────────────────────────────────────────────────────
builder.Services.AddScoped<IMessageRepository, MessageRepository>();
builder.Services.AddScoped<IMessageService, MessageService>();

builder.Services.AddHttpContextAccessor();
builder.Services.AddHttpClient<INotificationClient, NotificationClient>(client =>
{
    var url = builder.Configuration["Services:NotificationApi:Url"]
        ?? "http://localhost:5005";
    client.BaseAddress = new Uri(url);
    client.Timeout = TimeSpan.FromSeconds(5);
});

builder.Services.AddHttpClient<IAuthClient, AuthClient>(client =>
{
    var url = builder.Configuration["Services:AuthApi:Url"]
        ?? "http://localhost:5001";
    client.BaseAddress = new Uri(url);
    client.Timeout = TimeSpan.FromSeconds(5);
});

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
options.Events = new JwtBearerEvents
{
OnAuthenticationFailed = context =>
{
Console.WriteLine("AUTH FAILED: " + context.Exception.Message);
return Task.CompletedTask;
},
OnTokenValidated = context =>
{
Console.WriteLine("TOKEN VALID");
return Task.CompletedTask;
}
};
});


builder.Services.AddAuthorization();
builder.Services.AddControllers();
builder.Services.AddSignalR();

// ── Swagger ───────────────────────────────────────────────────────
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
c.SwaggerDoc("v1", new OpenApiInfo
{
Title = "ConnectHub Message API",
Version = "v1"
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
    var db = scope.ServiceProvider.GetRequiredService<MessageDbContext>();
    db.Database.Migrate();
}

app.Run();ParseOptions.0.json�
uD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Message.API\Repositories\IMessageRepository.cs�using ConnectHub.Message.API.Models;
namespace ConnectHub.Message.API.Repositories;

public interface IMessageRepository
{
    Task<MessageEntity?> FindByIdAsync(int messageId);
    Task<IList<MessageEntity>> FindDirectMessagesAsync(int userId1, int userId2, int page, int pageSize);
    Task<int> CountDirectMessagesAsync(int userId1, int userId2);
    Task<IList<MessageEntity>> FindRoomMessagesAsync(int roomId, int page, int pageSize);
    Task<int> CountRoomMessagesAsync(int roomId);
    Task<IList<MessageEntity>> FindUnreadByReceiverIdAsync(int receiverId);
    Task<int> CountUnreadAsync(int receiverId);
    Task<IList<MessageEntity>> SearchMessagesAsync(int userId, string keyword);
    Task<IList<MessageEntity>> SearchRoomMessagesAsync(int roomId, string keyword);
    Task<int> CountUnreadFromAsync(int senderId, int receiverId);
    // For each DM partner of `userId`, returns the most recent message exchanged with them.
    Task<IList<MessageEntity>> FindLatestPerPartnerAsync(int userId);
    Task<MessageEntity> CreateAsync(MessageEntity message);
    Task<MessageEntity> UpdateAsync(MessageEntity message);
    // Flips IsRead=true on every unread DM from senderId → receiverId. Returns the
    // count of rows actually flipped so callers can short-circuit no-op responses.
    Task<int> MarkAllReadAsync(int senderId, int receiverId);
    // Returns the list of newly-delivered messages so the caller can SignalR-broadcast
    // each one's MessageDelivered event back to the original sender's tabs.
    Task<IList<MessageEntity>> MarkAllDeliveredForRecipientAsync(int recipientId);
    
    // Admin operations
    Task<IList<MessageEntity>> FindAllMessagesAdminAsync(int page, int pageSize);
    Task<int> CountAllMessagesAsync();
    Task<bool> HardDeleteAsync(int messageId);
}
ParseOptions.0.json�2
tD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Message.API\Repositories\MessageRepository.cs�1using Microsoft.EntityFrameworkCore;
using ConnectHub.Message.API.Data;
using ConnectHub.Message.API.Models;

namespace ConnectHub.Message.API.Repositories;

public class MessageRepository : IMessageRepository
{
    private readonly MessageDbContext _context;

    public MessageRepository(MessageDbContext context)
    {
        _context = context;
    }

    public async Task<MessageEntity?> FindByIdAsync(int messageId) =>
        await _context.Messages.FirstOrDefaultAsync(m => m.MessageId == messageId);

    public async Task<IList<MessageEntity>> FindDirectMessagesAsync(
        int userId1, int userId2, int page, int pageSize) =>
        await _context.Messages
            .Where(m =>
                (m.SenderId == userId1 && m.ReceiverId == userId2) ||
                (m.SenderId == userId2 && m.ReceiverId == userId1))
            .OrderByDescending(m => m.SentAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .OrderBy(m => m.SentAt)
            .ToListAsync();

    public async Task<int> CountDirectMessagesAsync(int userId1, int userId2) =>
        await _context.Messages
            .CountAsync(m =>
                (m.SenderId == userId1 && m.ReceiverId == userId2) ||
                (m.SenderId == userId2 && m.ReceiverId == userId1));

    public async Task<IList<MessageEntity>> FindRoomMessagesAsync(
        int roomId, int page, int pageSize) =>
        await _context.Messages
            .Where(m => m.RoomId == roomId)
            .OrderByDescending(m => m.SentAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .OrderBy(m => m.SentAt)
            .ToListAsync();

    public async Task<int> CountRoomMessagesAsync(int roomId) =>
        await _context.Messages.CountAsync(m => m.RoomId == roomId);

    public async Task<IList<MessageEntity>> FindUnreadByReceiverIdAsync(int receiverId) =>
        await _context.Messages
            .Where(m => m.ReceiverId == receiverId && !m.IsRead)
            .OrderBy(m => m.SentAt)
            .ToListAsync();

    public async Task<int> CountUnreadAsync(int receiverId) =>
        await _context.Messages
            .CountAsync(m => m.ReceiverId == receiverId && !m.IsRead);

    public async Task<IList<MessageEntity>> SearchMessagesAsync(int userId, string keyword) =>
        await _context.Messages
            .Where(m =>
                (m.SenderId == userId || m.ReceiverId == userId) &&
                m.Content.Contains(keyword))
            .OrderByDescending(m => m.SentAt)
            .Take(100)
            .ToListAsync();

    public async Task<IList<MessageEntity>> SearchRoomMessagesAsync(int roomId, string keyword) =>
        await _context.Messages
            .Where(m => m.RoomId == roomId && m.Content.Contains(keyword))
            .OrderByDescending(m => m.SentAt)
            .Take(100)
            .ToListAsync();

    public async Task<int> CountUnreadFromAsync(int senderId, int receiverId) =>
        await _context.Messages.CountAsync(m =>
            m.SenderId == senderId && m.ReceiverId == receiverId && !m.IsRead);

    public async Task<IList<MessageEntity>> FindLatestPerPartnerAsync(int userId)
    {
        var query =
            from m in _context.Messages
            where m.RoomId == null && (m.SenderId == userId || m.ReceiverId == userId)
            let partner = m.SenderId == userId ? m.ReceiverId : m.SenderId
            group m by partner into g
            select g.OrderByDescending(x => x.SentAt).First();

        return await query.ToListAsync();
    }

    public async Task<MessageEntity> CreateAsync(MessageEntity message)
    {
        _context.Messages.Add(message);
        await _context.SaveChangesAsync();
        return message;
    }

    public async Task<MessageEntity> UpdateAsync(MessageEntity message)
    {
        _context.Messages.Update(message);
        await _context.SaveChangesAsync();
        return message;
    }

    public async Task<int> MarkAllReadAsync(int senderId, int receiverId)
    {
        var unread = await _context.Messages
            .Where(m => m.SenderId == senderId &&
                        m.ReceiverId == receiverId &&
                        !m.IsRead)
            .ToListAsync();

        if (unread.Count == 0) return 0;

        var now = DateTime.UtcNow;
        foreach (var msg in unread)
        {
            msg.IsRead = true;
            msg.ReadAt = now;
            // NOTE: We deliberately do NOT auto-flip IsDelivered here. Delivered must
            // only become true via an explicit recipient-device ack (see
            // /api/messages/{id}/delivered). The frontend tick logic treats
            // isRead=true as the dominant state, so a "read but not delivered"
            // row still renders correctly as ✓✓ blue without polluting the
            // delivery audit trail.
        }

        await _context.SaveChangesAsync();
        return unread.Count;
    }

    public async Task<IList<MessageEntity>> MarkAllDeliveredForRecipientAsync(int recipientId)
    {
        var pending = await _context.Messages
            .Where(m => m.ReceiverId == recipientId && !m.IsDelivered && !m.IsDeleted)
            .ToListAsync();

        if (pending.Count == 0) return pending;

        var now = DateTime.UtcNow;
        foreach (var msg in pending)
        {
            msg.IsDelivered = true;
            msg.DeliveredAt = now;
        }
        await _context.SaveChangesAsync();
        return pending;
    }

    public async Task<IList<MessageEntity>> FindAllMessagesAdminAsync(int page, int pageSize) =>
        await _context.Messages
            .OrderByDescending(m => m.SentAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync();

    public async Task<int> CountAllMessagesAsync() =>
        await _context.Messages.CountAsync();

    public async Task<bool> HardDeleteAsync(int messageId)
    {
        var msg = await _context.Messages.FindAsync(messageId);
        if (msg == null) return false;
        
        _context.Messages.Remove(msg);
        await _context.SaveChangesAsync();
        return true;
    }
}
ParseOptions.0.json�
iD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Message.API\Services\AuthClient.cs�using System.Net.Http.Headers;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Http;
using ConnectHub.Shared.Models;

namespace ConnectHub.Message.API.Services;

public class AuthClient : IAuthClient
{
    private readonly HttpClient _http;
    private readonly IHttpContextAccessor _httpContext;
    private readonly ILogger<AuthClient> _logger;

    public AuthClient(
        HttpClient http,
        IHttpContextAccessor httpContext,
        ILogger<AuthClient> logger)
    {
        _http = http;
        _httpContext = httpContext;
        _logger = logger;
    }

    public async Task<int?> GetUserIdByUserNameAsync(string userName, CancellationToken ct = default)
    {
        var req = new HttpRequestMessage(HttpMethod.Get, $"/api/users/by-username/{userName}");

        // Forward token
        var auth = _httpContext.HttpContext?.Request.Headers["Authorization"].ToString();
        if (string.IsNullOrWhiteSpace(auth))
        {
            auth = _httpContext.HttpContext?.Request.Query["access_token"];
            if (!string.IsNullOrWhiteSpace(auth) && !auth.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
                auth = "Bearer " + auth;
        }

        if (!string.IsNullOrWhiteSpace(auth))
            req.Headers.Authorization = AuthenticationHeaderValue.Parse(auth);

        try
        {
            var res = await _http.SendAsync(req, ct);
            if (!res.IsSuccessStatusCode) return null;

            var result = await res.Content.ReadFromJsonAsync<ApiResponse<UserProfileDto>>(cancellationToken: ct);
            return result?.Data?.UserId;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to lookup user by username: {UserName}", userName);
            return null;
        }
    }
}

public class UserProfileDto
{
    public int UserId { get; set; }
    public string UserName { get; set; } = string.Empty;
}
ParseOptions.0.json�
jD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Message.API\Services\IAuthClient.cs�namespace ConnectHub.Message.API.Services;

public interface IAuthClient
{
    Task<int?> GetUserIdByUserNameAsync(string userName, CancellationToken ct = default);
}
ParseOptions.0.json�
nD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Message.API\Services\IMessageService.cs�using ConnectHub.Message.API.DTOs;
using ConnectHub.Shared.Models;

namespace ConnectHub.Message.API.Services;

// Bulk-delivery payload — one row per message that just flipped to
// IsDelivered=true. Returned by MarkAllDeliveredAsync so the recipient's
// client can SignalR-broadcast each tick flip back to the sender's tabs.
public record DeliveredMessageDto(int MessageId, int SenderId, DateTime DeliveredAt);

public interface IMessageService
{
    Task<MessageResponseDto> SendMessageAsync(SendMessageDto dto);
    Task<PagedResult<MessageResponseDto>> GetDirectMessagesAsync(int userId1, int userId2, int page, int pageSize);
    Task<PagedResult<MessageResponseDto>> GetRoomMessagesAsync(int roomId, int page, int pageSize);
    Task<IList<MessageResponseDto>> GetUnreadMessagesAsync(int receiverId);
    Task<int> GetUnreadCountAsync(int receiverId);
    Task<MessageResponseDto> EditMessageAsync(int messageId, EditMessageDto dto);
    Task<bool> DeleteMessageAsync(int messageId);
    Task<bool> DeleteForMeAsync(int messageId, int userId);
    Task<MessageResponseDto?> MarkDeliveredAsync(int messageId, int recipientId);
    // Returns the list of newly-delivered messages (id + senderId + deliveredAt)
    // so the recipient's client can fan out one SignalR MessageDelivered event
    // per affected sender. Without this, senders' ticks stay ✓ forever — the
    // server flipped IsDelivered=true but no one told the senders.
    Task<IList<DeliveredMessageDto>> MarkAllDeliveredAsync(int recipientId);
    Task<int> MarkAllReadAsync(int senderId, int receiverId);
    Task<IList<MessageResponseDto>> SearchMessagesAsync(int userId, string keyword);
    Task<IList<MessageResponseDto>> SearchRoomMessagesAsync(int roomId, string keyword);
    Task<IList<ConversationSummaryDto>> GetRecentConversationsAsync(int userId);

    // Admin operations
    Task<PagedResult<MessageResponseDto>> GetAllMessagesAdminAsync(int page, int pageSize);
    Task<bool> DeleteMessageAdminAsync(int messageId);
    Task<int> CountMessagesAsync();
}
ParseOptions.0.json�
rD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Message.API\Services\INotificationClient.cs�using ConnectHub.Shared.Enums;

namespace ConnectHub.Message.API.Services;

public interface INotificationClient
{
    Task SendAsync(
        int recipientId,
        int? senderId,
        NotificationType type,
        string title,
        string message,
        int? relatedId,
        CancellationToken ct = default);
}
ParseOptions.0.json�i
mD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Message.API\Services\MessageService.cs�husing ConnectHub.Message.API.DTOs;
using ConnectHub.Message.API.Models;
using ConnectHub.Message.API.Repositories;
using ConnectHub.Shared.Models;

namespace ConnectHub.Message.API.Services;

public class MessageService : IMessageService
{
    private readonly IMessageRepository _repo;
    private readonly INotificationClient _notifications;
    private readonly IAuthClient _auth;

    public MessageService(IMessageRepository repo, INotificationClient notifications, IAuthClient auth)
    {
        _repo = repo;
        _notifications = notifications;
        _auth = auth;
    }

    public async Task<MessageResponseDto> SendMessageAsync(SendMessageDto dto)
    {
        // Validation — ya ReceiverId ya RoomId hona chahiye
        if (dto.ReceiverId is null && dto.RoomId is null)
            throw new ArgumentException("Either ReceiverId or RoomId is required.");

        var message = new MessageEntity
        {
            SenderId = dto.SenderId,
            ReceiverId = dto.ReceiverId,
            RoomId = dto.RoomId,
            Content = dto.Content,
            MessageType = dto.MessageType,
            MediaUrl = dto.MediaUrl,
            ReplyToMessageId = dto.ReplyToMessageId,
            // UTC is canonical on the wire; clients format to local/IST.
            SentAt = DateTime.UtcNow
        };

        var created = await _repo.CreateAsync(message);

        // Notify if it's a direct message
        if (dto.ReceiverId.HasValue && dto.RoomId is null)
        {
            await _notifications.SendAsync(
                recipientId: dto.ReceiverId.Value,
                senderId: dto.SenderId,
                type: ConnectHub.Shared.Enums.NotificationType.MESSAGE,
                title: "New Message",
                message: "You have received a new direct message.",
                relatedId: created.MessageId);
        }

        // Check for mentions if it's a room message
        if (dto.RoomId.HasValue && !string.IsNullOrWhiteSpace(dto.Content))
        {
            // Support @username (e.g. @rohit)
            var matches = System.Text.RegularExpressions.Regex.Matches(dto.Content, @"@(\w+)");
            foreach (System.Text.RegularExpressions.Match match in matches)
            {
                var userName = match.Groups[1].Value;
                
                // Lookup UserId by UserName via Auth API
                var mentionedUserId = await _auth.GetUserIdByUserNameAsync(userName);
                
                if (mentionedUserId.HasValue && mentionedUserId.Value != dto.SenderId)
                {
                    await _notifications.SendAsync(
                        recipientId: mentionedUserId.Value,
                        senderId: dto.SenderId,
                        type: ConnectHub.Shared.Enums.NotificationType.MENTION,
                        title: "You were mentioned",
                        message: $"You were mentioned in a room.",
                        relatedId: dto.RoomId.Value);
                }
            }
        }

        return MapToDto(created);
    }

    public async Task<PagedResult<MessageResponseDto>> GetDirectMessagesAsync(
        int userId1, int userId2, int page, int pageSize)
    {
        var messages = await _repo.FindDirectMessagesAsync(userId1, userId2, page, pageSize);
        var total = await _repo.CountDirectMessagesAsync(userId1, userId2);

        // userId1 is "me" by frontend convention. Filter out anything they
        // chose "Delete for me" on, so it stays gone after a refresh.
        return new PagedResult<MessageResponseDto>
        {
            Items = messages
                .Where(m => !IsDeletedForUser(m, userId1))
                .Select(MapToDto)
                .ToList(),
            TotalCount = total,
            PageNumber = page,
            PageSize = pageSize
        };
    }

    public async Task<PagedResult<MessageResponseDto>> GetRoomMessagesAsync(
        int roomId, int page, int pageSize)
    {
        var messages = await _repo.FindRoomMessagesAsync(roomId, page, pageSize);
        var total = await _repo.CountRoomMessagesAsync(roomId);
        // Room messages can't be filtered server-side without knowing the caller —
        // we keep delete-for-me to direct chats for now (simpler + matches WhatsApp UX).
        return new PagedResult<MessageResponseDto>
        {
            Items = messages.Select(MapToDto).ToList(),
            TotalCount = total,
            PageNumber = page,
            PageSize = pageSize
        };
    }

    public async Task<IList<MessageResponseDto>> GetUnreadMessagesAsync(int receiverId)
    {
        var messages = await _repo.FindUnreadByReceiverIdAsync(receiverId);
        return messages.Select(MapToDto).ToList();
    }

    public async Task<int> GetUnreadCountAsync(int receiverId) =>
        await _repo.CountUnreadAsync(receiverId);

    public async Task<MessageResponseDto> EditMessageAsync(int messageId, EditMessageDto dto)
    {
        var message = await _repo.FindByIdAsync(messageId)
            ?? throw new KeyNotFoundException("Message not found.");

        message.Content = dto.Content;
        message.IsEdited = true;
        message.EditedAt = DateTime.UtcNow;

        var updated = await _repo.UpdateAsync(message);
        return MapToDto(updated);
    }

    public async Task<bool> DeleteMessageAsync(int messageId)
    {
        var message = await _repo.FindByIdAsync(messageId);
        if (message is null) return false;

        // "Delete for everyone" — soft delete; the row stays so reply-quotes still resolve,
        // and the client renders "This message was deleted." from the IsDeleted flag.
        message.IsDeleted = true;
        message.Content = "This message was deleted.";
        message.MediaUrl = null;
        await _repo.UpdateAsync(message);
        return true;
    }

    public async Task<bool> DeleteForMeAsync(int messageId, int userId)
    {
        var message = await _repo.FindByIdAsync(messageId);
        if (message is null) return false;

        var ids = (message.DeletedForUserIds ?? string.Empty)
            .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
            .ToHashSet();

        if (!ids.Add(userId.ToString())) return true; // already deleted-for-me — idempotent

        message.DeletedForUserIds = string.Join(",", ids);
        await _repo.UpdateAsync(message);
        return true;
    }

    public async Task<MessageResponseDto?> MarkDeliveredAsync(int messageId, int recipientId)
    {
        var message = await _repo.FindByIdAsync(messageId);
        if (message is null) return null;
        // Only the actual recipient can flip the flag — protects against forged events.
        if (message.ReceiverId != recipientId) return null;
        if (message.IsDelivered) return MapToDto(message);

        message.IsDelivered = true;
        message.DeliveredAt = DateTime.UtcNow;
        var saved = await _repo.UpdateAsync(message);
        return MapToDto(saved);
    }

    public async Task<IList<DeliveredMessageDto>> MarkAllDeliveredAsync(int recipientId)
    {
        var updated = await _repo.MarkAllDeliveredForRecipientAsync(recipientId);
        // Project to a thin payload — the recipient's client only needs the
        // tuple (messageId, senderId, deliveredAt) to fire a SignalR
        // BroadcastMessageDelivered per row. Skipping the full MessageEntity
        // keeps the response small even when hundreds of messages catch up
        // after a long offline window.
        return updated
            .Where(m => m.DeliveredAt.HasValue)
            .Select(m => new DeliveredMessageDto(m.MessageId, m.SenderId, AsUtc(m.DeliveredAt!.Value)))
            .ToList();
    }

    public Task<int> MarkAllReadAsync(int senderId, int receiverId) =>
        _repo.MarkAllReadAsync(senderId, receiverId);

    public async Task<IList<MessageResponseDto>> SearchMessagesAsync(int userId, string keyword)
    {
        if (string.IsNullOrWhiteSpace(keyword)) return new List<MessageResponseDto>();
        var messages = await _repo.SearchMessagesAsync(userId, keyword.Trim());
        return messages.Select(MapToDto).ToList();
    }

    public async Task<IList<MessageResponseDto>> SearchRoomMessagesAsync(int roomId, string keyword)
    {
        if (string.IsNullOrWhiteSpace(keyword)) return new List<MessageResponseDto>();
        var messages = await _repo.SearchRoomMessagesAsync(roomId, keyword.Trim());
        return messages.Select(MapToDto).ToList();
    }

    public async Task<IList<ConversationSummaryDto>> GetRecentConversationsAsync(int userId)
    {
        var latest = await _repo.FindLatestPerPartnerAsync(userId);
        var summaries = new List<ConversationSummaryDto>(latest.Count);
        foreach (var m in latest)
        {
            var partnerId = m.SenderId == userId ? (m.ReceiverId ?? 0) : m.SenderId;
            if (partnerId == 0) continue;

            var unread = await _repo.CountUnreadFromAsync(partnerId, userId);
            summaries.Add(new ConversationSummaryDto
            {
                PartnerId = partnerId,
                LastMessageId = m.MessageId,
                LastMessage = BuildPreview(m),
                LastMessageType = m.MessageType,
                LastSenderId = m.SenderId,
                // Mark Kind=Utc so System.Text.Json emits the trailing 'Z' and
                // the client doesn't accidentally parse the timestamp as local time.
                LastSentAt = AsUtc(m.SentAt),
                UnreadCount = unread
            });
        }
        return summaries.OrderByDescending(s => s.LastSentAt).ToList();
    }

    // Sidebar preview text. Lower-case "[image]" / "[file]" matches the client's
    // own preview generator so server-rendered and SignalR-rendered rows look
    // identical. Deleted rows always show the WhatsApp-style placeholder.
    private static string BuildPreview(MessageEntity m)
    {
        if (m.IsDeleted) return "This message was deleted.";
        if (m.MessageType == Shared.Enums.MessageType.TEXT)
        {
            var text = m.Content ?? string.Empty;
            return text.Length > 80 ? text[..80] + "…" : text;
        }
        return m.MessageType switch
        {
            Shared.Enums.MessageType.IMAGE => "[image]",
            Shared.Enums.MessageType.FILE  => "[file]",
            Shared.Enums.MessageType.AUDIO => "[audio]",
            _ => "[media]"
        };
    }

    // ── Private helpers ───────────────────────────────────────────
    private static bool IsDeletedForUser(MessageEntity m, int userId)
    {
        if (string.IsNullOrEmpty(m.DeletedForUserIds)) return false;
        var key = userId.ToString();
        foreach (var id in m.DeletedForUserIds.Split(',', StringSplitOptions.RemoveEmptyEntries))
            if (id.Trim() == key) return true;
        return false;
    }

    private static MessageResponseDto MapToDto(MessageEntity m) => new()
    {
        MessageId = m.MessageId,
        SenderId = m.SenderId,
        ReceiverId = m.ReceiverId,
        RoomId = m.RoomId,
        Content = m.Content,
        MessageType = m.MessageType,
        IsRead = m.IsRead,
        IsDelivered = m.IsDelivered,
        IsEdited = m.IsEdited,
        // EF Core hands these back as Kind=Unspecified after a round trip through
        // PostgreSQL. We force Utc so the JSON serializer writes "...Z" and the
        // browser parses them as UTC instead of silently shifting by local offset.
        SentAt = AsUtc(m.SentAt),
        DeliveredAt = AsUtcNullable(m.DeliveredAt),
        ReadAt = AsUtcNullable(m.ReadAt),
        EditedAt = AsUtcNullable(m.EditedAt),
        MediaUrl = m.MediaUrl,
        ReplyToMessageId = m.ReplyToMessageId,
        IsDeleted = m.IsDeleted
    };

    private static DateTime AsUtc(DateTime value) =>
        value.Kind == DateTimeKind.Utc ? value : DateTime.SpecifyKind(value, DateTimeKind.Utc);

    private static DateTime? AsUtcNullable(DateTime? value) =>
        value.HasValue ? AsUtc(value.Value) : null;

    // ── Admin ───────────────────────────────────────────────────
    public async Task<PagedResult<MessageResponseDto>> GetAllMessagesAdminAsync(int page, int pageSize)
    {
        var messages = await _repo.FindAllMessagesAdminAsync(page, pageSize);
        var total = await _repo.CountAllMessagesAsync();
        
        return new PagedResult<MessageResponseDto>
        {
            Items = messages.Select(MapToDto).ToList(),
            TotalCount = total,
            PageNumber = page,
            PageSize = pageSize
        };
    }

    public async Task<bool> DeleteMessageAdminAsync(int messageId)
    {
        return await _repo.HardDeleteAsync(messageId);
    }

    public async Task<int> CountMessagesAsync() =>
        await _repo.CountAllMessagesAsync();
}
ParseOptions.0.json�
qD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Message.API\Services\NotificationClient.cs�using System.Net.Http.Headers;
using System.Net.Http.Json;
using ConnectHub.Shared.Enums;
using Microsoft.AspNetCore.Http;

namespace ConnectHub.Message.API.Services;

public class NotificationClient : INotificationClient
{
    private readonly HttpClient _http;
    private readonly IHttpContextAccessor _httpContext;
    private readonly ILogger<NotificationClient> _logger;

    public NotificationClient(
        HttpClient http,
        IHttpContextAccessor httpContext,
        ILogger<NotificationClient> logger)
    {
        _http = http;
        _httpContext = httpContext;
        _logger = logger;
    }

    public async Task SendAsync(
        int recipientId,
        int? senderId,
        NotificationType type,
        string title,
        string message,
        int? relatedId,
        CancellationToken ct = default)
    {
        var req = new HttpRequestMessage(HttpMethod.Post, "/api/notifications/send")
        {
            Content = JsonContent.Create(new
            {
                recipientId,
                senderId,
                type = type.ToString(),
                title,
                message,
                relatedId
            })
        };

        // Forward the caller's JWT so Notification.API's [Authorize] accepts it.
        var auth = _httpContext.HttpContext?.Request.Headers["Authorization"].ToString();
        
        // If not in headers (e.g. SignalR hub call), check query string
        if (string.IsNullOrWhiteSpace(auth))
        {
            auth = _httpContext.HttpContext?.Request.Query["access_token"];
            if (!string.IsNullOrWhiteSpace(auth) && !auth.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
            {
                auth = "Bearer " + auth;
            }
        }

        if (!string.IsNullOrWhiteSpace(auth) && auth.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
        {
            req.Headers.Authorization = AuthenticationHeaderValue.Parse(auth);
        }

        try
        {
            var res = await _http.SendAsync(req, ct);
            if (!res.IsSuccessStatusCode)
            {
                var body = await res.Content.ReadAsStringAsync(ct);
                _logger.LogWarning(
                    "Notification dispatch failed for recipient {RecipientId}: {Status} {Body}",
                    recipientId, (int)res.StatusCode, body);
            }
        }
        catch (Exception ex)
        {
            // Notification is best-effort; never break the parent flow.
            _logger.LogWarning(ex,
                "Notification dispatch threw for recipient {RecipientId}", recipientId);
        }
    }
}
ParseOptions.0.json�
�D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Message.API\obj\Debug\net8.0\ConnectHub.Message.API.GlobalUsings.g.cs�// <auto-generated/>
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
�D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Message.API\obj\Debug\net8.0\.NETCoreApp,Version=v8.0.AssemblyAttributes.cs�// <autogenerated />
using System;
using System.Reflection;
[assembly: global::System.Runtime.Versioning.TargetFrameworkAttribute(".NETCoreApp,Version=v8.0", FrameworkDisplayName = ".NET 8.0")]
ParseOptions.0.json�	
�D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Message.API\obj\Debug\net8.0\ConnectHub.Message.API.AssemblyInfo.cs�//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated by a tool.
//
//     Changes to this file may cause incorrect behavior and will be lost if
//     the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

using System;
using System.Reflection;

[assembly: System.Reflection.AssemblyCompanyAttribute("ConnectHub.Message.API")]
[assembly: System.Reflection.AssemblyConfigurationAttribute("Debug")]
[assembly: System.Reflection.AssemblyFileVersionAttribute("1.0.0.0")]
[assembly: System.Reflection.AssemblyInformationalVersionAttribute("1.0.0")]
[assembly: System.Reflection.AssemblyProductAttribute("ConnectHub.Message.API")]
[assembly: System.Reflection.AssemblyTitleAttribute("ConnectHub.Message.API")]
[assembly: System.Reflection.AssemblyVersionAttribute("1.0.0.0")]

// Generated by the MSBuild WriteCodeFragment class.

ParseOptions.0.json�
�D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Message.API\obj\Debug\net8.0\ConnectHub.Message.API.MvcApplicationPartsAssemblyInfo.cs�//------------------------------------------------------------------------------
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