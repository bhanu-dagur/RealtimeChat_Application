�

rD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Room.API\Controllers\AdminRoomController.cs�	using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ConnectHub.Room.API.Services;
using ConnectHub.Shared.Models;
using ConnectHub.Room.API.DTOs;

namespace ConnectHub.Room.API.Controllers;

[ApiController]
[Route("api/rooms/admin")]
[Authorize(Roles = "Admin")]
public class AdminRoomController : ControllerBase
{
    private readonly IChatRoomService _service;

    public AdminRoomController(IChatRoomService service)
    {
        _service = service;
    }

    [HttpGet("rooms")]
    public async Task<IActionResult> GetAllRooms()
    {
        var rooms = await _service.GetAllRoomsAdminAsync();
        return Ok(ApiResponse<IList<ChatRoomResponseDto>>.Ok(rooms));
    }

    [HttpDelete("rooms/{roomId}")]
    public async Task<IActionResult> DeleteRoom(int roomId)
    {
        var success = await _service.DeleteRoomAsync(roomId);
        if (!success)
            return NotFound(ApiResponse<string>.Fail("Room not found.", 404));

        return Ok(ApiResponse<string>.Ok("Room successfully deleted."));
    }

    [HttpGet("analytics/rooms")]
    public async Task<IActionResult> GetRoomCount()
    {
        var count = await _service.CountRoomsAsync();
        return Ok(ApiResponse<int>.Ok(count));
    }
}
ParseOptions.0.json�2
qD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Room.API\Controllers\ChatRoomController.cs�1using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ConnectHub.Room.API.DTOs;
using ConnectHub.Room.API.Services;
using ConnectHub.Shared.Models;

namespace ConnectHub.Room.API.Controllers;

[ApiController]
[Route("api/rooms")]
[Authorize]
public class ChatRoomController : ControllerBase
{
    private readonly IChatRoomService _service;

    public ChatRoomController(IChatRoomService service)
    {
        _service = service;
    }

    private int CurrentUserId()
    {
        var raw = User.FindFirstValue(ClaimTypes.NameIdentifier) ?? User.FindFirstValue("sub");
        return int.TryParse(raw, out var id) ? id : 0;
    }

    // POST api/rooms/create
    [HttpPost("create")]
    public async Task<IActionResult> Create([FromBody] CreateRoomDto dto)
    {
        try
        {
            var result = await _service.CreateRoomAsync(dto);
            return Ok(ApiResponse<ChatRoomResponseDto>.Ok(result, "Room created successfully."));
        }
        catch (Exception ex)
        {
            return BadRequest(ApiResponse<string>.Fail(ex.Message));
        }
    }

    // GET api/rooms/{roomId}
    [HttpGet("{roomId:int}")]
    public async Task<IActionResult> GetById(int roomId)
    {
        var room = await _service.GetRoomByIdAsync(roomId);
        if (room is null)
            return NotFound(ApiResponse<string>.Fail("Room nahi mili.", 404));
        return Ok(ApiResponse<ChatRoomResponseDto>.Ok(room));
    }

    // GET api/rooms/public
    [HttpGet("public")]
    public async Task<IActionResult> GetPublic()
    {
        var rooms = await _service.GetPublicRoomsAsync();
        return Ok(ApiResponse<IList<ChatRoomResponseDto>>.Ok(rooms));
    }

    // GET api/rooms/user/{userId}
    [HttpGet("user/{userId:int}")]
    public async Task<IActionResult> GetByUser(int userId)
    {
        var rooms = await _service.GetRoomsByUserIdAsync(userId);
        return Ok(ApiResponse<IList<ChatRoomResponseDto>>.Ok(rooms));
    }

    // PUT api/rooms/{roomId}
    [HttpPut("{roomId:int}")]
    public async Task<IActionResult> Update(int roomId, [FromBody] UpdateRoomDto dto)
    {
        try
        {
            var updated = await _service.UpdateRoomAsync(roomId, dto);
            return Ok(ApiResponse<ChatRoomResponseDto>.Ok(updated, "Room updated successfully."));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse<string>.Fail(ex.Message, 404));
        }
    }

    // DELETE api/rooms/{roomId}
    [HttpDelete("{roomId:int}")]
    public async Task<IActionResult> Delete(int roomId)
    {
        var success = await _service.DeleteRoomAsync(roomId);
        if (!success)
            return NotFound(ApiResponse<string>.Fail("Room not found.", 404));
        return Ok(ApiResponse<string>.Ok("Room deleted successfully."));
    }

    // ── Member Endpoints ──────────────────────────────────────────

    // POST api/rooms/members/add
    [HttpPost("members/add")]
    public async Task<IActionResult> AddMember([FromBody] AddMemberDto dto)
    {
        try
        {
            var member = await _service.AddMemberAsync(dto, CurrentUserId());
            return Ok(ApiResponse<RoomMemberDto>.Ok(member, "Member added successfully."));
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(403, ApiResponse<string>.Fail(ex.Message, 403));
        }
        catch (Exception ex)
        {
            return BadRequest(ApiResponse<string>.Fail(ex.Message));
        }
    }

    // GET api/rooms/{roomId}/members
    [HttpGet("{roomId:int}/members")]
    public async Task<IActionResult> GetMembers(int roomId)
    {
        var members = await _service.GetMembersAsync(roomId);
        return Ok(ApiResponse<IList<RoomMemberDto>>.Ok(members));
    }

    // PUT api/rooms/members/role
    [HttpPut("members/role")]
    public async Task<IActionResult> UpdateRole([FromBody] UpdateMemberRoleDto dto)
    {
        try
        {
            var updated = await _service.UpdateMemberRoleAsync(dto, CurrentUserId());
            return Ok(ApiResponse<RoomMemberDto>.Ok(updated, "Role updated successfully."));
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(403, ApiResponse<string>.Fail(ex.Message, 403));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ApiResponse<string>.Fail(ex.Message));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse<string>.Fail(ex.Message, 404));
        }
    }

    // DELETE api/rooms/{roomId}/members/{userId}/remove
    [HttpDelete("{roomId:int}/members/{userId:int}/remove")]
    public async Task<IActionResult> RemoveMember(int roomId, int userId)
    {
        try
        {
            var success = await _service.RemoveMemberAsync(roomId, userId, CurrentUserId());
            if (!success)
                return NotFound(ApiResponse<string>.Fail("Member not found.", 404));
            return Ok(ApiResponse<string>.Ok("Member removed successfully."));
        }
        catch (UnauthorizedAccessException ex)
        {
            return StatusCode(403, ApiResponse<string>.Fail(ex.Message, 403));
        }
    }

    // DELETE api/rooms/{roomId}/leave/{userId}
    [HttpDelete("{roomId:int}/leave/{userId:int}")]
    public async Task<IActionResult> Leave(int roomId, int userId)
    {
        var success = await _service.LeaveRoomAsync(roomId, userId);
        if (!success)
            return NotFound(ApiResponse<string>.Fail("Member not found.", 404));
        return Ok(ApiResponse<string>.Ok("Room left successfully."));
    }

    // GET api/rooms/{roomId}/ismember/{userId}
    [HttpGet("{roomId:int}/ismember/{userId:int}")]
    public async Task<IActionResult> IsMember(int roomId, int userId)
    {
        var result = await _service.IsUserInRoomAsync(roomId, userId);
        return Ok(ApiResponse<bool>.Ok(result));
    }
}ParseOptions.0.json�
eD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Room.API\Data\RoomDbContext.cs�using Microsoft.EntityFrameworkCore;
using ConnectHub.Room.API.Models;

namespace ConnectHub.Room.API.Data;

public class RoomDbContext : DbContext
{
    public RoomDbContext(DbContextOptions<RoomDbContext> options) : base(options) { }

    public DbSet<ChatRoom> ChatRooms => Set<ChatRoom>();
    public DbSet<RoomMember> RoomMembers => Set<RoomMember>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<ChatRoom>(entity =>
        {
            entity.HasKey(r => r.RoomId);

            entity.Property(r => r.RoomName)
                  .IsRequired()
                  .HasMaxLength(100);

            entity.HasIndex(r => r.RoomName)
                  .HasDatabaseName("IX_ChatRooms_RoomName");

            // Soft delete filter
            entity.HasQueryFilter(r => r.IsActive);

            // One room — many members
            entity.HasMany(r => r.Members)
                  .WithOne(m => m.ChatRoom)
                  .HasForeignKey(m => m.RoomId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<RoomMember>(entity =>
        {
            entity.HasKey(m => m.MemberId);

            // Ek user ek room mein sirf ek baar — duplicate nahi
            entity.HasIndex(m => new { m.RoomId, m.UserId })
                  .IsUnique()
                  .HasDatabaseName("IX_RoomMembers_RoomId_UserId");

            // Soft delete filter
            entity.HasQueryFilter(m => m.IsActive);
        });
    }
}ParseOptions.0.json�
cD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Room.API\DTOs\AddMemerDto.cs�using System.ComponentModel.DataAnnotations;

namespace ConnectHub.Room.API.DTOs;

public class AddMemberDto
{
    [Required]
    public int UserId { get; set; }
    
    [Required]
    public int RoomId { get; set; }
}ParseOptions.0.json�
kD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Room.API\DTOs\ChatRoomResponseDto.cs�using ConnectHub.Shared.Enums;

namespace ConnectHub.Room.API.DTOs;

public class ChatRoomResponseDto
{
    public int RoomId { get; set; }
    public string RoomName { get; set; } = string.Empty;
    public string? Description { get; set; }
    public RoomType RoomType { get; set; }
    public string? AvatarUrl { get; set; }
    public int CreatedBy { get; set; }
    public DateTime CreatedAt { get; set; }
    public int MaxMembers { get; set; }
    public int MemberCount { get; set; }
}ParseOptions.0.json�
eD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Room.API\DTOs\CreateRoomDto.cs�using System.ComponentModel.DataAnnotations;
using ConnectHub.Shared.Enums;

namespace ConnectHub.Room.API.DTOs;

public class CreateRoomDto
{
    [Required, MaxLength(100)]
    public string RoomName { get; set; } = string.Empty;

    [MaxLength(500)]
    public string? Description { get; set; }

    public RoomType RoomType { get; set; } = RoomType.PUBLIC;

    public string? AvatarUrl { get; set; }

    [Required]
    public int CreatedBy { get; set; }

    // Optional member list to add at creation time. Creator is always added as ADMIN
    // automatically; these get role MEMBER. Duplicates and the creator's own id are de-duped.
    public List<int>? InitialMemberIds { get; set; }
}ParseOptions.0.json�
eD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Room.API\DTOs\RoomMemberDto.cs�using ConnectHub.Shared.Enums;

namespace ConnectHub.Room.API.DTOs;

public class RoomMemberDto
{
    public int MemberId { get; set; }
    public int RoomId { get; set; }
    public int UserId { get; set; }
    public MemberRole Role { get; set; }
    public DateTime JoinedAt { get; set; }
}ParseOptions.0.json�
kD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Room.API\DTOs\UpdateMemberRoleDto.cs�using System.ComponentModel.DataAnnotations;
using ConnectHub.Shared.Enums;

namespace ConnectHub.Room.API.DTOs;

public class UpdateMemberRoleDto
{
    [Required]
    public int UserId {get; set;}

    [Required]
    public int RoomId {get; set;}

    [Required]
    public MemberRole NewRole {get; set;}
}ParseOptions.0.json�
eD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Room.API\DTOs\UpdateRoomDto.cs�using System.ComponentModel.DataAnnotations;

namespace ConnectHub.Room.API.DTOs;

public class UpdateRoomDto
{
    [MaxLength(100)]
    public string? RoomName { get; set; }

    [MaxLength(500)]
    public string? Description { get; set; }

    public string? AvatarUrl { get; set; }
}ParseOptions.0.json�
|D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Room.API\Migrations\20260501085842_InitialPostgres.cs�using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace ConnectHub.Room.API.Migrations
{
    /// <inheritdoc />
    public partial class InitialPostgres : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "ChatRooms",
                columns: table => new
                {
                    RoomId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    RoomName = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Description = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    RoomType = table.Column<int>(type: "integer", nullable: false),
                    AvatarUrl = table.Column<string>(type: "text", nullable: true),
                    CreatedBy = table.Column<int>(type: "integer", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    MaxMembers = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ChatRooms", x => x.RoomId);
                });

            migrationBuilder.CreateTable(
                name: "RoomMembers",
                columns: table => new
                {
                    MemberId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    RoomId = table.Column<int>(type: "integer", nullable: false),
                    UserId = table.Column<int>(type: "integer", nullable: false),
                    Role = table.Column<int>(type: "integer", nullable: false),
                    JoinedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RoomMembers", x => x.MemberId);
                    table.ForeignKey(
                        name: "FK_RoomMembers_ChatRooms_RoomId",
                        column: x => x.RoomId,
                        principalTable: "ChatRooms",
                        principalColumn: "RoomId",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ChatRooms_RoomName",
                table: "ChatRooms",
                column: "RoomName");

            migrationBuilder.CreateIndex(
                name: "IX_RoomMembers_RoomId_UserId",
                table: "RoomMembers",
                columns: new[] { "RoomId", "UserId" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "RoomMembers");

            migrationBuilder.DropTable(
                name: "ChatRooms");
        }
    }
}
ParseOptions.0.json�#
�D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Room.API\Migrations\20260501085842_InitialPostgres.Designer.cs�"// <auto-generated />
using System;
using ConnectHub.Room.API.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace ConnectHub.Room.API.Migrations
{
    [DbContext(typeof(RoomDbContext))]
    [Migration("20260501085842_InitialPostgres")]
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

            modelBuilder.Entity("ConnectHub.Room.API.Models.ChatRoom", b =>
                {
                    b.Property<int>("RoomId")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("integer");

                    NpgsqlPropertyBuilderExtensions.UseIdentityByDefaultColumn(b.Property<int>("RoomId"));

                    b.Property<string>("AvatarUrl")
                        .HasColumnType("text");

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("timestamp with time zone");

                    b.Property<int>("CreatedBy")
                        .HasColumnType("integer");

                    b.Property<string>("Description")
                        .HasMaxLength(500)
                        .HasColumnType("character varying(500)");

                    b.Property<bool>("IsActive")
                        .HasColumnType("boolean");

                    b.Property<int>("MaxMembers")
                        .HasColumnType("integer");

                    b.Property<string>("RoomName")
                        .IsRequired()
                        .HasMaxLength(100)
                        .HasColumnType("character varying(100)");

                    b.Property<int>("RoomType")
                        .HasColumnType("integer");

                    b.HasKey("RoomId");

                    b.HasIndex("RoomName")
                        .HasDatabaseName("IX_ChatRooms_RoomName");

                    b.ToTable("ChatRooms");
                });

            modelBuilder.Entity("ConnectHub.Room.API.Models.RoomMember", b =>
                {
                    b.Property<int>("MemberId")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("integer");

                    NpgsqlPropertyBuilderExtensions.UseIdentityByDefaultColumn(b.Property<int>("MemberId"));

                    b.Property<bool>("IsActive")
                        .HasColumnType("boolean");

                    b.Property<DateTime>("JoinedAt")
                        .HasColumnType("timestamp with time zone");

                    b.Property<int>("Role")
                        .HasColumnType("integer");

                    b.Property<int>("RoomId")
                        .HasColumnType("integer");

                    b.Property<int>("UserId")
                        .HasColumnType("integer");

                    b.HasKey("MemberId");

                    b.HasIndex("RoomId", "UserId")
                        .IsUnique()
                        .HasDatabaseName("IX_RoomMembers_RoomId_UserId");

                    b.ToTable("RoomMembers");
                });

            modelBuilder.Entity("ConnectHub.Room.API.Models.RoomMember", b =>
                {
                    b.HasOne("ConnectHub.Room.API.Models.ChatRoom", "ChatRoom")
                        .WithMany("Members")
                        .HasForeignKey("RoomId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.Navigation("ChatRoom");
                });

            modelBuilder.Entity("ConnectHub.Room.API.Models.ChatRoom", b =>
                {
                    b.Navigation("Members");
                });
#pragma warning restore 612, 618
        }
    }
}
ParseOptions.0.json�"
xD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Room.API\Migrations\RoomDbContextModelSnapshot.cs�!// <auto-generated />
using System;
using ConnectHub.Room.API.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace ConnectHub.Room.API.Migrations
{
    [DbContext(typeof(RoomDbContext))]
    partial class RoomDbContextModelSnapshot : ModelSnapshot
    {
        protected override void BuildModel(ModelBuilder modelBuilder)
        {
#pragma warning disable 612, 618
            modelBuilder
                .HasAnnotation("ProductVersion", "8.0.10")
                .HasAnnotation("Relational:MaxIdentifierLength", 63);

            NpgsqlModelBuilderExtensions.UseIdentityByDefaultColumns(modelBuilder);

            modelBuilder.Entity("ConnectHub.Room.API.Models.ChatRoom", b =>
                {
                    b.Property<int>("RoomId")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("integer");

                    NpgsqlPropertyBuilderExtensions.UseIdentityByDefaultColumn(b.Property<int>("RoomId"));

                    b.Property<string>("AvatarUrl")
                        .HasColumnType("text");

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("timestamp with time zone");

                    b.Property<int>("CreatedBy")
                        .HasColumnType("integer");

                    b.Property<string>("Description")
                        .HasMaxLength(500)
                        .HasColumnType("character varying(500)");

                    b.Property<bool>("IsActive")
                        .HasColumnType("boolean");

                    b.Property<int>("MaxMembers")
                        .HasColumnType("integer");

                    b.Property<string>("RoomName")
                        .IsRequired()
                        .HasMaxLength(100)
                        .HasColumnType("character varying(100)");

                    b.Property<int>("RoomType")
                        .HasColumnType("integer");

                    b.HasKey("RoomId");

                    b.HasIndex("RoomName")
                        .HasDatabaseName("IX_ChatRooms_RoomName");

                    b.ToTable("ChatRooms");
                });

            modelBuilder.Entity("ConnectHub.Room.API.Models.RoomMember", b =>
                {
                    b.Property<int>("MemberId")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("integer");

                    NpgsqlPropertyBuilderExtensions.UseIdentityByDefaultColumn(b.Property<int>("MemberId"));

                    b.Property<bool>("IsActive")
                        .HasColumnType("boolean");

                    b.Property<DateTime>("JoinedAt")
                        .HasColumnType("timestamp with time zone");

                    b.Property<int>("Role")
                        .HasColumnType("integer");

                    b.Property<int>("RoomId")
                        .HasColumnType("integer");

                    b.Property<int>("UserId")
                        .HasColumnType("integer");

                    b.HasKey("MemberId");

                    b.HasIndex("RoomId", "UserId")
                        .IsUnique()
                        .HasDatabaseName("IX_RoomMembers_RoomId_UserId");

                    b.ToTable("RoomMembers");
                });

            modelBuilder.Entity("ConnectHub.Room.API.Models.RoomMember", b =>
                {
                    b.HasOne("ConnectHub.Room.API.Models.ChatRoom", "ChatRoom")
                        .WithMany("Members")
                        .HasForeignKey("RoomId")
                        .OnDelete(DeleteBehavior.Cascade)
                        .IsRequired();

                    b.Navigation("ChatRoom");
                });

            modelBuilder.Entity("ConnectHub.Room.API.Models.ChatRoom", b =>
                {
                    b.Navigation("Members");
                });
#pragma warning restore 612, 618
        }
    }
}
ParseOptions.0.json�
bD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Room.API\Models\ChatRoom.cs�using System.ComponentModel.DataAnnotations;
using ConnectHub.Shared.Enums;

namespace ConnectHub.Room.API.Models;

public class ChatRoom
{
    public int RoomId { get; set; }

    [Required, MaxLength(100)]
    public string RoomName { get; set; } = string.Empty;

    [MaxLength(500)]
    public string? Description { get; set; }

    public RoomType RoomType { get; set; } = RoomType.PUBLIC;

    public string? AvatarUrl { get; set; }

    // Room banane wala user
    public int CreatedBy { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public bool IsActive { get; set; } = true;

    // Max 500 members allowed
    public int MaxMembers { get; set; } = 500;

    // Navigation property
    public ICollection<RoomMember> Members { get; set; } = new List<RoomMember>();
}ParseOptions.0.json�
dD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Room.API\Models\RoomMember.cs�using ConnectHub.Shared.Enums;

namespace ConnectHub.Room.API.Models;

public class RoomMember
{
    public int MemberId { get; set; }

    public int RoomId { get; set; }

    public int UserId { get; set; }

    public MemberRole Role { get; set; } = MemberRole.MEMBER;

    public DateTime JoinedAt { get; set; } = DateTime.UtcNow;

    public bool IsActive { get; set; } = true;

    // Navigation property
    public ChatRoom? ChatRoom { get; set; }
}ParseOptions.0.json�,
ZD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Room.API\Program.cs�+using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Serilog;
using ConnectHub.Room.API.Data;
using ConnectHub.Room.API.Repositories;
using ConnectHub.Room.API.Services;

var builder = WebApplication.CreateBuilder(args);

// ── Serilog ───────────────────────────────────────────────────────
Log.Logger = new LoggerConfiguration()
    .WriteTo.Console()
    .CreateLogger();
builder.Host.UseSerilog();

// ── Database ──────────────────────────────────────────────────────
// Postgres on Neon — see Auth.API/Program.cs for the rationale on the
// per-service migrations-history table.
builder.Services.AddDbContext<RoomDbContext>(options =>
{
    var connectionString = (builder.Configuration.GetConnectionString("DefaultConnection")
        ?? builder.Configuration["DATABASE_URL"] ?? "").Trim();
    options.UseNpgsql(connectionString,
        npgsql => npgsql.MigrationsHistoryTable("__EFMigrationsHistory_Room"));
});

// ── DI ────────────────────────────────────────────────────────────
builder.Services.AddScoped<IChatRoomRepository, ChatRoomRepository>();
builder.Services.AddScoped<IChatRoomService, ChatRoomService>();

// Service-to-service: Notification.API client. Calls go DIRECT (not via the
// gateway) so an internal best-effort dispatch doesn't cross the rate limiter.
// Inbound JWT is forwarded by NotificationClient via IHttpContextAccessor.
builder.Services.AddHttpContextAccessor();
builder.Services.AddHttpClient<INotificationClient, NotificationClient>(client =>
{
    var url = builder.Configuration["Services:NotificationApi:Url"]
        ?? "http://localhost:5005";
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
    });

builder.Services.AddAuthorization();
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.Converters.Add(
            new System.Text.Json.Serialization.JsonStringEnumConverter());
    });

// ── Swagger ───────────────────────────────────────────────────────
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "ConnectHub Room API",
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
    var db = scope.ServiceProvider.GetRequiredService<RoomDbContext>();
    try
    {
        db.Database.Migrate();
    }
    catch (Exception ex)
    {
        Console.WriteLine($"[Migration Skipped] {ex.Message}");
    }
}

app.Run();ParseOptions.0.json� 
rD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Room.API\Repositories\ChatRoomRepository.cs�using Microsoft.EntityFrameworkCore;
using ConnectHub.Room.API.Data;
using ConnectHub.Room.API.Models;

namespace ConnectHub.Room.API.Repositories;

public class ChatRoomRepository : IChatRoomRepository
{
    private readonly RoomDbContext _context;

    public ChatRoomRepository(RoomDbContext context)
    {
        _context = context;
    }

    public async Task<ChatRoom?> FindByIdAsync(int roomId) =>
        await _context.ChatRooms
            .Include(r => r.Members)
            .FirstOrDefaultAsync(r => r.RoomId == roomId);

    public async Task<IList<ChatRoom>> FindPublicRoomsAsync() =>
        await _context.ChatRooms
            .Where(r => r.RoomType == ConnectHub.Shared.Enums.RoomType.PUBLIC)
            .Include(r => r.Members)
            .OrderBy(r => r.RoomName)
            .ToListAsync();

    public async Task<IList<ChatRoom>> FindRoomsByUserIdAsync(int userId) =>
        await _context.ChatRooms
            .Where(r => r.Members.Any(m => m.UserId == userId))
            .Include(r => r.Members)
            .ToListAsync();

    public async Task<ChatRoom> CreateAsync(ChatRoom room)
    {
        _context.ChatRooms.Add(room);
        await _context.SaveChangesAsync();
        return room;
    }

    public async Task<ChatRoom> UpdateAsync(ChatRoom room)
    {
        _context.ChatRooms.Update(room);
        await _context.SaveChangesAsync();
        return room;
    }

    public async Task<bool> DeleteAsync(int roomId)
    {
        var room = await _context.ChatRooms.FindAsync(roomId);
        if (room is null) return false;
        room.IsActive = false;
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<IList<ChatRoom>> FindAllRoomsAdminAsync() =>
        await _context.ChatRooms.IgnoreQueryFilters().ToListAsync();

    public async Task<int> CountRoomsAsync() =>
        await _context.ChatRooms.IgnoreQueryFilters().CountAsync();

    // ── Member operations ─────────────────────────────────────────

    public async Task<RoomMember?> FindMemberAsync(int roomId, int userId) =>
        await _context.RoomMembers
            .FirstOrDefaultAsync(m => m.RoomId == roomId && m.UserId == userId);

    // Bypasses the IsActive query filter so we can reactivate a soft-deleted membership
    // row when a user rejoins (the unique index on (RoomId, UserId) is not filtered).
    public async Task<RoomMember?> FindMemberIncludingInactiveAsync(int roomId, int userId) =>
        await _context.RoomMembers
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(m => m.RoomId == roomId && m.UserId == userId);

    public async Task<IList<RoomMember>> FindMembersByRoomIdAsync(int roomId) =>
        await _context.RoomMembers
            .Where(m => m.RoomId == roomId)
            .ToListAsync();

    public async Task<bool> IsUserInRoomAsync(int roomId, int userId) =>
        await _context.RoomMembers
            .AnyAsync(m => m.RoomId == roomId && m.UserId == userId);

    public async Task<int> CountMembersAsync(int roomId) =>
        await _context.RoomMembers
            .CountAsync(m => m.RoomId == roomId);

    public async Task<RoomMember> AddMemberAsync(RoomMember member)
    {
        _context.RoomMembers.Add(member);
        await _context.SaveChangesAsync();
        return member;
    }

    public async Task<RoomMember> UpdateMemberAsync(RoomMember member)
    {
        _context.RoomMembers.Update(member);
        await _context.SaveChangesAsync();
        return member;
    }

    public async Task<bool> RemoveMemberAsync(int roomId, int userId)
    {
        var member = await _context.RoomMembers
            .FirstOrDefaultAsync(m => m.RoomId == roomId && m.UserId == userId);
        if (member is null) return false;
        member.IsActive = false;
        await _context.SaveChangesAsync();
        return true;
    }
}ParseOptions.0.json�	
sD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Room.API\Repositories\IChatRoomRepository.cs�using ConnectHub.Room.API.Models;

namespace ConnectHub.Room.API.Repositories;

public interface IChatRoomRepository
{
    Task<ChatRoom?> FindByIdAsync(int roomId);
    Task<IList<ChatRoom>> FindPublicRoomsAsync();
    Task<IList<ChatRoom>> FindRoomsByUserIdAsync(int userId);
    Task<ChatRoom> CreateAsync(ChatRoom room);
    Task<ChatRoom> UpdateAsync(ChatRoom room);
    Task<bool> DeleteAsync(int roomId);
    Task<IList<ChatRoom>> FindAllRoomsAdminAsync();
    Task<int> CountRoomsAsync();

    // Member operations
    Task<RoomMember?> FindMemberAsync(int roomId, int userId);
    Task<RoomMember?> FindMemberIncludingInactiveAsync(int roomId, int userId);
    Task<IList<RoomMember>> FindMembersByRoomIdAsync(int roomId);
    Task<bool> IsUserInRoomAsync(int roomId, int userId);
    Task<int> CountMembersAsync(int roomId);
    Task<RoomMember> AddMemberAsync(RoomMember member);
    Task<RoomMember> UpdateMemberAsync(RoomMember member);
    Task<bool> RemoveMemberAsync(int roomId, int userId);
}ParseOptions.0.json�^
kD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Room.API\Services\ChatRoomService.cs�]using ConnectHub.Room.API.DTOs;
using ConnectHub.Room.API.Models;
using ConnectHub.Room.API.Repositories;
using ConnectHub.Shared.Enums;

namespace ConnectHub.Room.API.Services;

public class ChatRoomService : IChatRoomService
{
    private readonly IChatRoomRepository _repo;
    private readonly INotificationClient _notifications;

    public ChatRoomService(IChatRoomRepository repo, INotificationClient notifications)
    {
        _repo = repo;
        _notifications = notifications;
    }

    public async Task<ChatRoomResponseDto> CreateRoomAsync(CreateRoomDto dto)
    {
        var room = new ChatRoom
        {
            RoomName = dto.RoomName,
            Description = dto.Description,
            RoomType = dto.RoomType,
            AvatarUrl = dto.AvatarUrl,
            CreatedBy = dto.CreatedBy
        };

        var created = await _repo.CreateAsync(room);

        // Creator is always ADMIN.
        await _repo.AddMemberAsync(new RoomMember
        {
            RoomId = created.RoomId,
            UserId = dto.CreatedBy,
            Role = MemberRole.ADMIN
        });

        // Bulk-add the initial members (de-duped, creator excluded).
        if (dto.InitialMemberIds is { Count: > 0 })
        {
            var seen = new HashSet<int> { dto.CreatedBy };
            foreach (var memberId in dto.InitialMemberIds)
            {
                if (!seen.Add(memberId)) continue;        // skip dupes / creator
                if (memberId <= 0) continue;
                await _repo.AddMemberAsync(new RoomMember
                {
                    RoomId = created.RoomId,
                    UserId = memberId,
                    Role = MemberRole.MEMBER
                });

                await NotifyAddedToRoomAsync(memberId, dto.CreatedBy, created);
            }
        }

        var memberCount = await _repo.CountMembersAsync(created.RoomId);
        return MapToDto(created, memberCount);
    }

    // Best-effort group-add notification. Failures are swallowed inside the
    // client so a flaky Notification.API never breaks the add-member flow.
    private Task NotifyAddedToRoomAsync(int recipientId, int actorId, ChatRoom room) =>
        _notifications.SendAsync(
            recipientId: recipientId,
            senderId: actorId,
            type: NotificationType.ROOM_INVITE,
            title: $"Added to {room.RoomName}",
            message: $"You were added to the group \"{room.RoomName}\".",
            relatedId: room.RoomId);

    public async Task<ChatRoomResponseDto?> GetRoomByIdAsync(int roomId)
    {
        var room = await _repo.FindByIdAsync(roomId);
        if (room is null) return null;
        var count = await _repo.CountMembersAsync(roomId);
        return MapToDto(room, count);
    }

    public async Task<IList<ChatRoomResponseDto>> GetPublicRoomsAsync()
    {
        var rooms = await _repo.FindPublicRoomsAsync();
        var result = new List<ChatRoomResponseDto>();
        foreach (var room in rooms)
        {
            var count = await _repo.CountMembersAsync(room.RoomId);
            result.Add(MapToDto(room, count));
        }
        return result;
    }

    public async Task<IList<ChatRoomResponseDto>> GetRoomsByUserIdAsync(int userId)
    {
        var rooms = await _repo.FindRoomsByUserIdAsync(userId);
        var result = new List<ChatRoomResponseDto>();
        foreach (var room in rooms)
        {
            var count = await _repo.CountMembersAsync(room.RoomId);
            result.Add(MapToDto(room, count));
        }
        return result;
    }

    public async Task<ChatRoomResponseDto> UpdateRoomAsync(int roomId, UpdateRoomDto dto)
    {
        var room = await _repo.FindByIdAsync(roomId)
            ?? throw new KeyNotFoundException("Room not found.");

        if (dto.RoomName is not null) room.RoomName = dto.RoomName;
        if (dto.Description is not null) room.Description = dto.Description;
        if (dto.AvatarUrl is not null) room.AvatarUrl = dto.AvatarUrl;

        var updated = await _repo.UpdateAsync(room);
        var count = await _repo.CountMembersAsync(roomId);
        return MapToDto(updated, count);
    }

    public async Task<bool> DeleteRoomAsync(int roomId) =>
        await _repo.DeleteAsync(roomId);

    public async Task EnsureAdminAsync(int roomId, int actingUserId)
    {
        var actor = await _repo.FindMemberAsync(roomId, actingUserId)
            ?? throw new UnauthorizedAccessException("You are not a member of this room.");
        if (actor.Role != MemberRole.ADMIN)
            throw new UnauthorizedAccessException("Only room admins can perform this action.");
    }

    public async Task<RoomMemberDto> AddMemberAsync(AddMemberDto dto, int actingUserId)
    {
        // Self-join into a PUBLIC room is allowed; otherwise the acting user must be ADMIN.
        if (dto.UserId != actingUserId)
            await EnsureAdminAsync(dto.RoomId, actingUserId);
        else
        {
            var room = await _repo.FindByIdAsync(dto.RoomId)
                ?? throw new KeyNotFoundException("Room not found.");
            if (room.RoomType != Shared.Enums.RoomType.PUBLIC)
                await EnsureAdminAsync(dto.RoomId, actingUserId);
        }

        var result = await AddMemberCoreAsync(dto);

        // Only notify when an admin added someone else. Self-joins to a public
        // room are deliberate — no need to ping the user about their own action.
        if (dto.UserId != actingUserId)
        {
            var room = await _repo.FindByIdAsync(dto.RoomId);
            if (room is not null)
            {
                // 1. Notify the newcomer
                await NotifyAddedToRoomAsync(dto.UserId, actingUserId, room);

                // 2. Notify other members that someone joined
                var allMembers = await _repo.FindMembersByRoomIdAsync(dto.RoomId);
                foreach (var member in allMembers.Where(m => m.UserId != dto.UserId && m.IsActive))
                {
                    await _notifications.SendAsync(
                        recipientId: member.UserId,
                        senderId: dto.UserId,
                        type: NotificationType.ROOM_INVITE, // Or a dedicated JOINED type if available
                        title: "New member joined",
                        message: $"A new member joined \"{room.RoomName}\".",
                        relatedId: room.RoomId);
                }
            }
        }

        return result;
    }

    private async Task<RoomMemberDto> AddMemberCoreAsync(AddMemberDto dto)
    {
        var room = await _repo.FindByIdAsync(dto.RoomId)
            ?? throw new KeyNotFoundException("Room not found.");

        var currentCount = await _repo.CountMembersAsync(dto.RoomId);
        if (currentCount >= room.MaxMembers)
            throw new InvalidOperationException(
                $"Room is full. Maximum {room.MaxMembers} members allowed.");

        // Reactivate if a soft-deleted membership row already exists.
        // Without this the unique (RoomId, UserId) index throws on rejoin
        // because the index is not filtered on IsActive.
        var existing = await _repo.FindMemberIncludingInactiveAsync(dto.RoomId, dto.UserId);
        if (existing is not null)
        {
            if (existing.IsActive)
                throw new InvalidOperationException("User is already in this room.");

            existing.IsActive = true;
            existing.JoinedAt = DateTime.UtcNow;
            existing.Role = MemberRole.MEMBER;
            var reactivated = await _repo.UpdateMemberAsync(existing);
            return MapMemberToDto(reactivated);
        }

        var member = new RoomMember
        {
            RoomId = dto.RoomId,
            UserId = dto.UserId,
            Role = MemberRole.MEMBER
        };

        var added = await _repo.AddMemberAsync(member);
        return MapMemberToDto(added);
    }

    public async Task<bool> RemoveMemberAsync(int roomId, int userId, int actingUserId)
    {
        // Admins can remove anyone (including other admins); a member can only remove themselves
        // (which is `LeaveRoomAsync`'s job — keep them separate to make audit logs clearer).
        if (userId != actingUserId)
            await EnsureAdminAsync(roomId, actingUserId);
        return await _repo.RemoveMemberAsync(roomId, userId);
    }

    public async Task<bool> LeaveRoomAsync(int roomId, int userId) =>
        await _repo.RemoveMemberAsync(roomId, userId);

    public async Task<RoomMemberDto> UpdateMemberRoleAsync(UpdateMemberRoleDto dto, int actingUserId)
    {
        await EnsureAdminAsync(dto.RoomId, actingUserId);

        var member = await _repo.FindMemberAsync(dto.RoomId, dto.UserId)
            ?? throw new KeyNotFoundException("Member not found.");

        // Don't let the last admin demote themselves — would orphan the room.
        if (member.Role == MemberRole.ADMIN && dto.NewRole != MemberRole.ADMIN)
        {
            var allMembers = await _repo.FindMembersByRoomIdAsync(dto.RoomId);
            var otherAdmins = allMembers.Count(m => m.Role == MemberRole.ADMIN && m.UserId != dto.UserId);
            if (otherAdmins == 0)
                throw new InvalidOperationException("Cannot demote the last admin. Promote someone else first.");
        }

        member.Role = dto.NewRole;
        var updated = await _repo.UpdateMemberAsync(member);

        if (dto.NewRole == MemberRole.ADMIN)
        {
            var room = await _repo.FindByIdAsync(dto.RoomId);
            if (room != null)
            {
                await _notifications.SendAsync(
                    recipientId: dto.UserId,
                    senderId: actingUserId,
                    type: NotificationType.ROLE_CHANGE,
                    title: "Role Updated",
                    message: $"You are now an admin in \"{room.RoomName}\".",
                    relatedId: room.RoomId);
            }
        }

        return MapMemberToDto(updated);
    }

    public async Task<IList<RoomMemberDto>> GetMembersAsync(int roomId)
    {
        var members = await _repo.FindMembersByRoomIdAsync(roomId);
        return members.Select(MapMemberToDto).ToList();
    }

    public async Task<bool> IsUserInRoomAsync(int roomId, int userId) =>
        await _repo.IsUserInRoomAsync(roomId, userId);

    public async Task<IList<ChatRoomResponseDto>> GetAllRoomsAdminAsync()
    {
        var rooms = await _repo.FindAllRoomsAdminAsync();
        var result = new List<ChatRoomResponseDto>();
        foreach (var room in rooms)
        {
            var count = await _repo.CountMembersAsync(room.RoomId);
            result.Add(MapToDto(room, count));
        }
        return result;
    }

    public async Task<int> CountRoomsAsync() =>
        await _repo.CountRoomsAsync();

    // ── Private helpers ───────────────────────────────────────────

    private static ChatRoomResponseDto MapToDto(ChatRoom r, int memberCount) => new()
    {
        RoomId = r.RoomId,
        RoomName = r.RoomName,
        Description = r.Description,
        RoomType = r.RoomType,
        AvatarUrl = r.AvatarUrl,
        CreatedBy = r.CreatedBy,
        CreatedAt = r.CreatedAt,
        MaxMembers = r.MaxMembers,
        MemberCount = memberCount
    };

    private static RoomMemberDto MapMemberToDto(RoomMember m) => new()
    {
        MemberId = m.MemberId,
        RoomId = m.RoomId,
        UserId = m.UserId,
        Role = m.Role,
        JoinedAt = m.JoinedAt
    };
}ParseOptions.0.json�

lD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Room.API\Services\IChatRoomService.cs�	using ConnectHub.Room.API.DTOs;

namespace ConnectHub.Room.API.Services;

public interface IChatRoomService
{
    Task<ChatRoomResponseDto> CreateRoomAsync(CreateRoomDto dto);
    Task<ChatRoomResponseDto?> GetRoomByIdAsync(int roomId);
    Task<IList<ChatRoomResponseDto>> GetPublicRoomsAsync();
    Task<IList<ChatRoomResponseDto>> GetRoomsByUserIdAsync(int userId);
    Task<ChatRoomResponseDto> UpdateRoomAsync(int roomId, UpdateRoomDto dto);
    Task<bool> DeleteRoomAsync(int roomId);

    Task<RoomMemberDto> AddMemberAsync(AddMemberDto dto, int actingUserId);
    Task<bool> RemoveMemberAsync(int roomId, int userId, int actingUserId);
    Task<bool> LeaveRoomAsync(int roomId, int userId);
    Task<RoomMemberDto> UpdateMemberRoleAsync(UpdateMemberRoleDto dto, int actingUserId);
    Task<IList<RoomMemberDto>> GetMembersAsync(int roomId);
    Task<bool> IsUserInRoomAsync(int roomId, int userId);

    // Throws UnauthorizedAccessException if actingUserId is not ADMIN of the room.
    Task EnsureAdminAsync(int roomId, int actingUserId);

    // Admin operations
    Task<IList<ChatRoomResponseDto>> GetAllRoomsAdminAsync();
    Task<int> CountRoomsAsync();
}ParseOptions.0.json�
oD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Room.API\Services\INotificationClient.cs�using ConnectHub.Shared.Enums;

namespace ConnectHub.Room.API.Services;

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
ParseOptions.0.json�
nD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Room.API\Services\NotificationClient.cs�using System.Net.Http.Headers;
using System.Net.Http.Json;
using ConnectHub.Shared.Enums;
using Microsoft.AspNetCore.Http;

namespace ConnectHub.Room.API.Services;

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
�D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Room.API\obj\Debug\net8.0\ConnectHub.Room.API.GlobalUsings.g.cs�// <auto-generated/>
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
�D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Room.API\obj\Debug\net8.0\.NETCoreApp,Version=v8.0.AssemblyAttributes.cs�// <autogenerated />
using System;
using System.Reflection;
[assembly: global::System.Runtime.Versioning.TargetFrameworkAttribute(".NETCoreApp,Version=v8.0", FrameworkDisplayName = ".NET 8.0")]
ParseOptions.0.json�
�D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Room.API\obj\Debug\net8.0\ConnectHub.Room.API.AssemblyInfo.cs�//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated by a tool.
//
//     Changes to this file may cause incorrect behavior and will be lost if
//     the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

using System;
using System.Reflection;

[assembly: System.Reflection.AssemblyCompanyAttribute("ConnectHub.Room.API")]
[assembly: System.Reflection.AssemblyConfigurationAttribute("Debug")]
[assembly: System.Reflection.AssemblyFileVersionAttribute("1.0.0.0")]
[assembly: System.Reflection.AssemblyInformationalVersionAttribute("1.0.0")]
[assembly: System.Reflection.AssemblyProductAttribute("ConnectHub.Room.API")]
[assembly: System.Reflection.AssemblyTitleAttribute("ConnectHub.Room.API")]
[assembly: System.Reflection.AssemblyVersionAttribute("1.0.0.0")]

// Generated by the MSBuild WriteCodeFragment class.

ParseOptions.0.json�
�D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Room.API\obj\Debug\net8.0\ConnectHub.Room.API.MvcApplicationPartsAssemblyInfo.cs�//------------------------------------------------------------------------------
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