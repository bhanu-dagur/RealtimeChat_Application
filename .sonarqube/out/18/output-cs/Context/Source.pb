�
nD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Auth.API\Controllers\AdminController.cs�using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ConnectHub.Auth.API.Services;
using ConnectHub.Shared.Models;
using ConnectHub.Auth.API.DTOs;

namespace ConnectHub.Auth.API.Controllers;

[ApiController]
[Route("api/users/admin")]
[Authorize(Roles = "Admin")]
public class AdminController : ControllerBase
{
    private readonly IUserService _service;

    public AdminController(IUserService service)
    {
        _service = service;
    }

    [HttpGet("users")]
    public async Task<IActionResult> GetAllUsers()
    {
        var users = await _service.GetAllUsersAdminAsync();
        return Ok(ApiResponse<IList<UserProfileDto>>.Ok(users));
    }

    [HttpPut("users/{userId}/suspend")]
    public async Task<IActionResult> SuspendUser(int userId)
    {
        var success = await _service.SuspendUserAsync(userId);
        if (!success)
            return NotFound(ApiResponse<string>.Fail("User not found.", 404));

        return Ok(ApiResponse<string>.Ok("User account suspended."));
    }

    [HttpDelete("users/{userId}")]
    public async Task<IActionResult> DeleteUser(int userId)
    {
        var success = await _service.DeleteUserAsync(userId);
        if (!success)
            return NotFound(ApiResponse<string>.Fail("User not found.", 404));

        return Ok(ApiResponse<string>.Ok("User account permanently deleted."));
    }

    [HttpGet("analytics/users")]
    public async Task<IActionResult> GetUserCount()
    {
        var count = await _service.CountUsersAsync();
        return Ok(ApiResponse<int>.Ok(count));
    }
}
ParseOptions.0.json�+
nD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Auth.API\Controllers\UserControllers.cs�*using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ConnectHub.Auth.API.DTOs;
using ConnectHub.Auth.API.Services;
using ConnectHub.Shared.Models;

namespace ConnectHub.Auth.API.Controllers;

[ApiController]
[Route("api/users")]
public class UserController : ControllerBase
{
    private readonly IUserService _service;

    public UserController(IUserService service)
    {
        _service = service;
    }

    // POST api/users/register
    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterDto dto)
    {
        try
        {
            var result = await _service.RegisterAsync(dto);
            return Ok(ApiResponse<AuthResponseDto>.Ok(result, "Registration successful."));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ApiResponse<string>.Fail(ex.Message));
        }
    }

    // POST api/users/login
    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginDto dto)
    {
        try
        {
            var result = await _service.LoginAsync(dto);
            return Ok(ApiResponse<AuthResponseDto>.Ok(result, "Login successful."));
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(ApiResponse<string>.Fail(ex.Message, 401));
        }
    }

    // POST api/users/google-login
    [HttpPost("google-login")]
    public async Task<IActionResult> GoogleLogin([FromBody] GoogleLoginDto dto)
    {
        if (string.IsNullOrWhiteSpace(dto.IdToken))
            return BadRequest(ApiResponse<string>.Fail("Missing Google ID token."));

        try
        {
            var result = await _service.LoginWithGoogleAsync(dto.IdToken);
            return Ok(ApiResponse<AuthResponseDto>.Ok(result, "Google login successful."));
        }
        catch (UnauthorizedAccessException ex)
        {
            return Unauthorized(ApiResponse<string>.Fail(ex.Message, 401));
        }
        catch (InvalidOperationException ex)
        {
            return BadRequest(ApiResponse<string>.Fail(ex.Message));
        }
    }

    // GET api/users/{id}
    [HttpGet("{id:int}")]
    [Authorize]
    public async Task<IActionResult> GetById(int id)
    {
        var user = await _service.GetUserByIdAsync(id);
        if (user is null)
            return NotFound(ApiResponse<string>.Fail("User not found.", 404));
        return Ok(ApiResponse<UserProfileDto>.Ok(user));
    }

    // GET api/users/search?q=ali
    [HttpGet("search")]
    [Authorize]
    public async Task<IActionResult> Search([FromQuery] string q)
    {
        var results = await _service.SearchUsersAsync(q);
        return Ok(ApiResponse<IList<UserProfileDto>>.Ok(results));
    }

    // GET api/users/active
    [HttpGet("active")]
    [Authorize]
    public async Task<IActionResult> GetActive()
    {
        var users = await _service.GetAllActiveUsersAsync();
        return Ok(ApiResponse<IList<UserProfileDto>>.Ok(users));
    }

    // PUT api/users/{id}/profile
    [HttpPut("{id:int}/profile")]
    [Authorize]
    public async Task<IActionResult> UpdateProfile(int id, [FromBody] UpdateProfileDto dto)
    {
        try
        {
            var updated = await _service.UpdateProfileAsync(id, dto);
            return Ok(ApiResponse<UserProfileDto>.Ok(updated, "Profile updated."));
        }
        catch (KeyNotFoundException ex)
        {
            return NotFound(ApiResponse<string>.Fail(ex.Message, 404));
        }
    }

    // PUT api/users/{id}/change-password
    [HttpPut("{id:int}/change-password")]
    [Authorize]
    public async Task<IActionResult> ChangePassword(int id,
        [FromBody] ChangePasswordDto dto)
    {
        var success = await _service.ChangePasswordAsync(id, dto.OldPassword, dto.NewPassword);
        if (!success)
            return BadRequest(ApiResponse<string>.Fail("Old password is incorrect."));
        return Ok(ApiResponse<string>.Ok("Password changed."));
    }

    // DELETE api/users/{id}/deactivate
    [HttpDelete("{id:int}/deactivate")]
    [Authorize]
    public async Task<IActionResult> Deactivate(int id)
    {
        var success = await _service.DeactivateAccountAsync(id);
        if (!success)
            return NotFound(ApiResponse<string>.Fail("User not found.", 404));
        return Ok(ApiResponse<string>.Ok("Account deactivated."));
    }

    // PUT api/users/{id}/online-status
    // Called by the Hub.API service-to-service. Explicitly anonymous so the hub
    // doesn't have to forge a user JWT just to flip an online flag.
    [HttpPut("{id:int}/online-status")]
    [AllowAnonymous]
    public async Task<IActionResult> UpdateOnlineStatus(int id, [FromBody] UpdateOnlineStatusDto dto)
    {
        await _service.SetOnlineStatusAsync(id, dto.IsOnline);
        return Ok(ApiResponse<string>.Ok("Online status updated."));
    }

    // GET api/users/by-username/{username}
    [HttpGet("by-username/{username}")]
    [Authorize]
    public async Task<IActionResult> GetByUserName(string username)
    {
        var user = await _service.GetUserByUserNameAsync(username);
        if (user is null)
            return NotFound(ApiResponse<string>.Fail("User not found.", 404));
        return Ok(ApiResponse<UserProfileDto>.Ok(user));
    }
}ParseOptions.0.json�
eD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Auth.API\Data\AuthDbContext.cs�using Microsoft.EntityFrameworkCore;
using ConnectHub.Auth.API.Models;

namespace ConnectHub.Auth.API.Data;

public class AuthDbContext : DbContext
{
    public AuthDbContext(DbContextOptions<AuthDbContext> options) : base(options) { }

    public DbSet<User> Users => Set<User>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(u => u.UserId);
            entity.HasIndex(u => u.Email).IsUnique();
            entity.HasIndex(u => u.UserName).IsUnique();

            entity.Property(u => u.UserName).IsRequired().HasMaxLength(50);
            entity.Property(u => u.Email).IsRequired().HasMaxLength(150);
            entity.Property(u => u.DisplayName).IsRequired().HasMaxLength(100);
        });
    }
}ParseOptions.0.json�
gD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Auth.API\DTOs\AuthResponseDto.cs�namespace ConnectHub.Auth.API.DTOs;

public class AuthResponseDto
{
    public int UserId { get; set; }
    public string UserName { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
    public string Token { get; set; } = string.Empty;
    public DateTime TokenExpiry { get; set; }
}ParseOptions.0.json�
iD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Auth.API\DTOs\ChangePasswordDto.cs�using System.ComponentModel.DataAnnotations;

namespace ConnectHub.Auth.API.DTOs;

public class ChangePasswordDto
{
    [Required]
    public string OldPassword { get; set; } = string.Empty;

    [Required, MinLength(6)]
    public string NewPassword { get; set; } = string.Empty;
}ParseOptions.0.json�
fD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Auth.API\DTOs\GoogleLoginDto.cs�namespace ConnectHub.Auth.API.DTOs;

public class GoogleLoginDto
{
    public string IdToken { get; set; } = string.Empty;
}
ParseOptions.0.json�
`D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Auth.API\DTOs\LoginDto.cs�using System.ComponentModel.DataAnnotations;

namespace ConnectHub.Auth.API.DTOs;

public class LoginDto
{
    [Required, EmailAddress]
    public string Email { get; set; } = string.Empty;

    [Required]
    public string Password { get; set; } = string.Empty;
}ParseOptions.0.json�
cD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Auth.API\DTOs\RegisterDto.cs�using System.ComponentModel.DataAnnotations;

namespace ConnectHub.Auth.API.DTOs;

public class RegisterDto
{
    [Required, MaxLength(50)]
    public string UserName { get; set; } = string.Empty;

    [Required, MaxLength(100)]
    public string DisplayName { get; set; } = string.Empty;

    [Required, EmailAddress]
    public string Email { get; set; } = string.Empty;

    [Required, MinLength(6)]
    public string Password { get; set; } = string.Empty;
}ParseOptions.0.json�
mD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Auth.API\DTOs\UpdateOnlineStatusDto.csynamespace ConnectHub.Auth.API.DTOs;

public class UpdateOnlineStatusDto
{
    public bool IsOnline { get; set; }
}
ParseOptions.0.json�
hD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Auth.API\DTOs\UpdateProfileDto.cs�using System.ComponentModel.DataAnnotations;

namespace ConnectHub.Auth.API.DTOs;

public class UpdateProfileDto
{
    [MaxLength(100)]
    public string? DisplayName { get; set; }

    [MaxLength(300)]
    public string? Bio { get; set; }

    public string? AvatarUrl { get; set; }
}ParseOptions.0.json�
fD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Auth.API\DTOs\UserProfileDto.cs�namespace ConnectHub.Auth.API.DTOs;

public class UserProfileDto
{
    public int UserId { get; set; }
    public string UserName { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string? AvatarUrl { get; set; }
    public string? Bio { get; set; }
    public bool IsOnline { get; set; }
    public DateTime? LastSeen { get; set; }
    public DateTime CreatedAt { get; set; }
}ParseOptions.0.json�
|D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Auth.API\Migrations\20260501085652_InitialPostgres.cs�using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace ConnectHub.Auth.API.Migrations
{
    /// <inheritdoc />
    public partial class InitialPostgres : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Users",
                columns: table => new
                {
                    UserId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    UserName = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    DisplayName = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    Email = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                    PasswordHash = table.Column<string>(type: "text", nullable: false),
                    AvatarUrl = table.Column<string>(type: "text", nullable: true),
                    Bio = table.Column<string>(type: "character varying(300)", maxLength: 300, nullable: true),
                    IsOnline = table.Column<bool>(type: "boolean", nullable: false),
                    LastSeen = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    IsActive = table.Column<bool>(type: "boolean", nullable: false),
                    GoogleId = table.Column<string>(type: "text", nullable: true),
                    GitHubId = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Users", x => x.UserId);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Users_Email",
                table: "Users",
                column: "Email",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_Users_UserName",
                table: "Users",
                column: "UserName",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Users");
        }
    }
}
ParseOptions.0.json�
�D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Auth.API\Migrations\20260501085652_InitialPostgres.Designer.cs�// <auto-generated />
using System;
using ConnectHub.Auth.API.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace ConnectHub.Auth.API.Migrations
{
    [DbContext(typeof(AuthDbContext))]
    [Migration("20260501085652_InitialPostgres")]
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

            modelBuilder.Entity("ConnectHub.Auth.API.Models.User", b =>
                {
                    b.Property<int>("UserId")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("integer");

                    NpgsqlPropertyBuilderExtensions.UseIdentityByDefaultColumn(b.Property<int>("UserId"));

                    b.Property<string>("AvatarUrl")
                        .HasColumnType("text");

                    b.Property<string>("Bio")
                        .HasMaxLength(300)
                        .HasColumnType("character varying(300)");

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("timestamp with time zone");

                    b.Property<string>("DisplayName")
                        .IsRequired()
                        .HasMaxLength(100)
                        .HasColumnType("character varying(100)");

                    b.Property<string>("Email")
                        .IsRequired()
                        .HasMaxLength(150)
                        .HasColumnType("character varying(150)");

                    b.Property<string>("GitHubId")
                        .HasColumnType("text");

                    b.Property<string>("GoogleId")
                        .HasColumnType("text");

                    b.Property<bool>("IsActive")
                        .HasColumnType("boolean");

                    b.Property<bool>("IsOnline")
                        .HasColumnType("boolean");

                    b.Property<DateTime?>("LastSeen")
                        .HasColumnType("timestamp with time zone");

                    b.Property<string>("PasswordHash")
                        .IsRequired()
                        .HasColumnType("text");

                    b.Property<string>("UserName")
                        .IsRequired()
                        .HasMaxLength(50)
                        .HasColumnType("character varying(50)");

                    b.HasKey("UserId");

                    b.HasIndex("Email")
                        .IsUnique();

                    b.HasIndex("UserName")
                        .IsUnique();

                    b.ToTable("Users");
                });
#pragma warning restore 612, 618
        }
    }
}
ParseOptions.0.json�
D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Auth.API\Migrations\20260508205414_AddSystemAdminRole.cs�using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ConnectHub.Auth.API.Migrations
{
    /// <inheritdoc />
    public partial class AddSystemAdminRole : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "IsSystemAdmin",
                table: "Users",
                type: "boolean",
                nullable: false,
                defaultValue: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IsSystemAdmin",
                table: "Users");
        }
    }
}
ParseOptions.0.json�
�D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Auth.API\Migrations\20260508205414_AddSystemAdminRole.Designer.cs�// <auto-generated />
using System;
using ConnectHub.Auth.API.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace ConnectHub.Auth.API.Migrations
{
    [DbContext(typeof(AuthDbContext))]
    [Migration("20260508205414_AddSystemAdminRole")]
    partial class AddSystemAdminRole
    {
        /// <inheritdoc />
        protected override void BuildTargetModel(ModelBuilder modelBuilder)
        {
#pragma warning disable 612, 618
            modelBuilder
                .HasAnnotation("ProductVersion", "8.0.10")
                .HasAnnotation("Relational:MaxIdentifierLength", 63);

            NpgsqlModelBuilderExtensions.UseIdentityByDefaultColumns(modelBuilder);

            modelBuilder.Entity("ConnectHub.Auth.API.Models.User", b =>
                {
                    b.Property<int>("UserId")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("integer");

                    NpgsqlPropertyBuilderExtensions.UseIdentityByDefaultColumn(b.Property<int>("UserId"));

                    b.Property<string>("AvatarUrl")
                        .HasColumnType("text");

                    b.Property<string>("Bio")
                        .HasMaxLength(300)
                        .HasColumnType("character varying(300)");

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("timestamp with time zone");

                    b.Property<string>("DisplayName")
                        .IsRequired()
                        .HasMaxLength(100)
                        .HasColumnType("character varying(100)");

                    b.Property<string>("Email")
                        .IsRequired()
                        .HasMaxLength(150)
                        .HasColumnType("character varying(150)");

                    b.Property<string>("GitHubId")
                        .HasColumnType("text");

                    b.Property<string>("GoogleId")
                        .HasColumnType("text");

                    b.Property<bool>("IsActive")
                        .HasColumnType("boolean");

                    b.Property<bool>("IsOnline")
                        .HasColumnType("boolean");

                    b.Property<bool>("IsSystemAdmin")
                        .HasColumnType("boolean");

                    b.Property<DateTime?>("LastSeen")
                        .HasColumnType("timestamp with time zone");

                    b.Property<string>("PasswordHash")
                        .IsRequired()
                        .HasColumnType("text");

                    b.Property<string>("UserName")
                        .IsRequired()
                        .HasMaxLength(50)
                        .HasColumnType("character varying(50)");

                    b.HasKey("UserId");

                    b.HasIndex("Email")
                        .IsUnique();

                    b.HasIndex("UserName")
                        .IsUnique();

                    b.ToTable("Users");
                });
#pragma warning restore 612, 618
        }
    }
}
ParseOptions.0.json�
xD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Auth.API\Migrations\AuthDbContextModelSnapshot.cs�// <auto-generated />
using System;
using ConnectHub.Auth.API.Data;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Storage.ValueConversion;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace ConnectHub.Auth.API.Migrations
{
    [DbContext(typeof(AuthDbContext))]
    partial class AuthDbContextModelSnapshot : ModelSnapshot
    {
        protected override void BuildModel(ModelBuilder modelBuilder)
        {
#pragma warning disable 612, 618
            modelBuilder
                .HasAnnotation("ProductVersion", "8.0.10")
                .HasAnnotation("Relational:MaxIdentifierLength", 63);

            NpgsqlModelBuilderExtensions.UseIdentityByDefaultColumns(modelBuilder);

            modelBuilder.Entity("ConnectHub.Auth.API.Models.User", b =>
                {
                    b.Property<int>("UserId")
                        .ValueGeneratedOnAdd()
                        .HasColumnType("integer");

                    NpgsqlPropertyBuilderExtensions.UseIdentityByDefaultColumn(b.Property<int>("UserId"));

                    b.Property<string>("AvatarUrl")
                        .HasColumnType("text");

                    b.Property<string>("Bio")
                        .HasMaxLength(300)
                        .HasColumnType("character varying(300)");

                    b.Property<DateTime>("CreatedAt")
                        .HasColumnType("timestamp with time zone");

                    b.Property<string>("DisplayName")
                        .IsRequired()
                        .HasMaxLength(100)
                        .HasColumnType("character varying(100)");

                    b.Property<string>("Email")
                        .IsRequired()
                        .HasMaxLength(150)
                        .HasColumnType("character varying(150)");

                    b.Property<string>("GitHubId")
                        .HasColumnType("text");

                    b.Property<string>("GoogleId")
                        .HasColumnType("text");

                    b.Property<bool>("IsActive")
                        .HasColumnType("boolean");

                    b.Property<bool>("IsOnline")
                        .HasColumnType("boolean");

                    b.Property<bool>("IsSystemAdmin")
                        .HasColumnType("boolean");

                    b.Property<DateTime?>("LastSeen")
                        .HasColumnType("timestamp with time zone");

                    b.Property<string>("PasswordHash")
                        .IsRequired()
                        .HasColumnType("text");

                    b.Property<string>("UserName")
                        .IsRequired()
                        .HasMaxLength(50)
                        .HasColumnType("character varying(50)");

                    b.HasKey("UserId");

                    b.HasIndex("Email")
                        .IsUnique();

                    b.HasIndex("UserName")
                        .IsUnique();

                    b.ToTable("Users");
                });
#pragma warning restore 612, 618
        }
    }
}
ParseOptions.0.json�
^D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Auth.API\Models\User.cs�using System.ComponentModel.DataAnnotations;

namespace ConnectHub.Auth.API.Models;

public class User
{
    public int UserId { get; set; }

    [Required, MaxLength(50)]
    public string UserName { get; set; } = string.Empty;

    [Required, MaxLength(100)]
    public string DisplayName { get; set; } = string.Empty;

    [Required, MaxLength(150)]
    public string Email { get; set; } = string.Empty;

    public string PasswordHash { get; set; } = string.Empty;

    public string? AvatarUrl { get; set; }

    [MaxLength(300)]
    public string? Bio { get; set; }

    public bool IsOnline { get; set; } = false;

    public DateTime? LastSeen { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public bool IsActive { get; set; } = true;
    public bool IsSystemAdmin { get; set; } = false;

    // OAuth provider info
    public string? GoogleId { get; set; }
    public string? GitHubId { get; set; }
}ParseOptions.0.json�8
ZD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Auth.API\Program.cs�7using System.Text;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;

using ConnectHub.Auth.API.Data;
using ConnectHub.Auth.API.Repositories;
using ConnectHub.Auth.API.Services;

var builder = WebApplication.CreateBuilder(args);


// ── Controllers ────────────────────────────────────────────────
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.Converters.Add(
            new System.Text.Json.Serialization.JsonStringEnumConverter());
    });


// ── Swagger ────────────────────────────────────────────────────
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "JWT Bearer token — paste: Bearer {token}",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });

    options.AddSecurityRequirement(new OpenApiSecurityRequirement
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
            new string[] {}
        }
    });
});


// ── Database ───────────────────────────────────────────────────
// Postgres on Neon. All four services share a single `neondb`, so each one
// needs its own migrations-history table to avoid clobbering the others on
// auto-migrate. Without `MigrationsHistoryTable`, every context would race
// to write the default `__EFMigrationsHistory` table and the second start-up
// would think the wrong migrations had already been applied.
builder.Services.AddDbContext<AuthDbContext>(options =>
{
    var connectionString = (builder.Configuration.GetConnectionString("DefaultConnection")
        ?? builder.Configuration["DATABASE_URL"] ?? "").Trim();
    options.UseNpgsql(connectionString,
        npgsql => npgsql.MigrationsHistoryTable("__EFMigrationsHistory_Auth"));
});


// ── Dependency Injection ───────────────────────────────────────
builder.Services.AddScoped<IUserRepository, UserRepository>();
builder.Services.AddScoped<IUserService, UserService>();


// ── JWT Setup ──────────────────────────────────────────────────
var key = Encoding.UTF8.GetBytes(
    builder.Configuration["Jwt:Key"] 
    ?? throw new Exception("JWT Key missing in appsettings.json")
);

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
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

        IssuerSigningKey = new SymmetricSecurityKey(key)
    };
    options.Events = new JwtBearerEvents
    {
        OnAuthenticationFailed = context =>
        {
            Console.WriteLine("JWT Error: " + context.Exception.Message);
            return Task.CompletedTask;
        }
    };
});

builder.Services.AddAuthorization();

// ── CORS ──────────────────────────────────────────────────────────
// Origins from Cors:AllowedOrigins (semicolon-separated). Entries starting with
// "*." treated as suffix wildcards (e.g. "*.vercel.app").
var corsOrigins = builder.Configuration["Cors:AllowedOrigins"]
    ?.Split(';', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
    ?? new[] { "http://localhost:4200", "*.vercel.app" };

var exactOrigins = corsOrigins.Where(o => !o.Contains("*.")).ToHashSet(StringComparer.OrdinalIgnoreCase);
var wildcardSuffixes = corsOrigins
    .Where(o => o.Contains("*."))
    .Select(o => o[(o.IndexOf("*.") + 1)..])
    .ToList();

bool IsAllowedOrigin(string origin) =>
    exactOrigins.Contains(origin) ||
    (Uri.TryCreate(origin, UriKind.Absolute, out var uri) &&
     wildcardSuffixes.Any(suf => uri.Host.EndsWith(suf, StringComparison.OrdinalIgnoreCase)));

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend",
        policy => policy
            .SetIsOriginAllowed(IsAllowedOrigin)
            .AllowAnyHeader()
            .AllowAnyMethod()
            .AllowCredentials());
});

// ── Build App ──────────────────────────────────────────────────
var app = builder.Build();


// ── Middleware ─────────────────────────────────────────────────
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

// app.UseHttpsRedirection();
app.UseCors("AllowFrontend");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

// ── Auto Migration ────────────────────────────────────────────────
// Without this, fresh deploys (especially `docker-compose up`) start with an
// empty Auth DB → /api/users/login and every downstream call returns 500.
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AuthDbContext>();
    try
    {
        db.Database.Migrate();

        // ── Seed Admin User ──
        var adminEmail = "rohit@gmail.com";
        var adminUser = db.Users.FirstOrDefault(u => u.Email == adminEmail);
        if (adminUser != null && !adminUser.IsSystemAdmin)
        {
            adminUser.IsSystemAdmin = true;
            db.SaveChanges();
            Console.WriteLine($"[Admin Seed] Promoted {adminEmail} to SystemAdmin.");
        }
    }
    catch (Exception ex)
    {
        Console.WriteLine($"[Migration/Seed Skipped] {ex.Message}");
    }
}

app.Run();ParseOptions.0.json�
oD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Auth.API\Repositories\IUserRepository.cs�using ConnectHub.Auth.API.Models;

namespace ConnectHub.Auth.API.Repositories;

public interface IUserRepository
{
    Task<User?> FindByEmailAsync(string email);
    Task<User?> FindByUserIdAsync(int userId);
    Task<User?> FindByUserNameAsync(string userName);
    Task<User?> FindByGoogleIdAsync(string googleId);
    Task<bool> ExistsByEmailAsync(string email);
    Task<bool> ExistsByUserNameAsync(string userName);
    Task<IList<User>> FindAllActiveAsync();
    Task<IList<User>> SearchUsersAsync(string query);
    Task<User> CreateAsync(User user);
    Task<User> UpdateAsync(User user);
    Task UpdateOnlineStatusAsync(int userId, bool isOnline);
    Task<IList<User>> FindAllIncludingInactiveAsync();
    Task<User?> FindAnyByIdAsync(int userId);
    Task<bool> HardDeleteAsync(int userId);
    Task<int> CountUsersAsync();
}ParseOptions.0.json�
nD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Auth.API\Repositories\UserRepository.cs�using Microsoft.EntityFrameworkCore;
using ConnectHub.Auth.API.Data;
using ConnectHub.Auth.API.Models;

namespace ConnectHub.Auth.API.Repositories;

public class UserRepository : IUserRepository
{
    private readonly AuthDbContext _context;

    public UserRepository(AuthDbContext context)
    {
        _context = context;
    }

    public async Task<User?> FindByEmailAsync(string email) =>
        await _context.Users.FirstOrDefaultAsync(u => u.Email == email && u.IsActive);

    public async Task<User?> FindByUserIdAsync(int userId) =>
        await _context.Users.FirstOrDefaultAsync(u => u.UserId == userId && u.IsActive);

    public async Task<User?> FindByUserNameAsync(string userName) =>
        await _context.Users.FirstOrDefaultAsync(u => u.UserName == userName && u.IsActive);

    public async Task<User?> FindByGoogleIdAsync(string googleId) =>
        await _context.Users.FirstOrDefaultAsync(u => u.GoogleId == googleId && u.IsActive);

    public async Task<bool> ExistsByEmailAsync(string email) =>
        await _context.Users.AnyAsync(u => u.Email == email);

    public async Task<bool> ExistsByUserNameAsync(string userName) =>
        await _context.Users.AnyAsync(u => u.UserName == userName);

    public async Task<IList<User>> FindAllActiveAsync() =>
        await _context.Users.Where(u => u.IsActive).ToListAsync();

    public async Task<IList<User>> SearchUsersAsync(string query) =>
        await _context.Users
            .Where(u => u.IsActive &&
                (u.UserName.Contains(query) || u.DisplayName.Contains(query)))
            .ToListAsync();

    public async Task<User> CreateAsync(User user)
    {
        _context.Users.Add(user);
        await _context.SaveChangesAsync();
        return user;
    }

    public async Task<User> UpdateAsync(User user)
    {
        _context.Users.Update(user);
        await _context.SaveChangesAsync();
        return user;
    }

    public async Task UpdateOnlineStatusAsync(int userId, bool isOnline)
    {
        var user = await _context.Users.FindAsync(userId);
        if (user is null) return;

        user.IsOnline = isOnline;
        user.LastSeen = DateTime.UtcNow;
        await _context.SaveChangesAsync();
    }

    public async Task<IList<User>> FindAllIncludingInactiveAsync() =>
        await _context.Users.ToListAsync();

    public async Task<User?> FindAnyByIdAsync(int userId) =>
        await _context.Users.FirstOrDefaultAsync(u => u.UserId == userId);

    public async Task<bool> HardDeleteAsync(int userId)
    {
        var user = await _context.Users.FindAsync(userId);
        if (user is null) return false;
        
        _context.Users.Remove(user);
        await _context.SaveChangesAsync();
        return true;
    }

    public async Task<int> CountUsersAsync() =>
        await _context.Users.CountAsync();
}ParseOptions.0.json�	
hD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Auth.API\Services\IUserService.cs�using ConnectHub.Auth.API.DTOs;
using ConnectHub.Auth.API.Models;

namespace ConnectHub.Auth.API.Services;

public interface IUserService
{
    Task<AuthResponseDto> RegisterAsync(RegisterDto dto);
    Task<AuthResponseDto> LoginAsync(LoginDto dto);
    Task<AuthResponseDto> LoginWithGoogleAsync(string idToken);
    Task<UserProfileDto?> GetUserByIdAsync(int userId);
    Task<UserProfileDto?> GetUserByUserNameAsync(string userName);
    Task<UserProfileDto> UpdateProfileAsync(int userId, UpdateProfileDto dto);
    Task<bool> ChangePasswordAsync(int userId, string oldPassword, string newPassword);
    Task<IList<UserProfileDto>> SearchUsersAsync(string query);
    Task SetOnlineStatusAsync(int userId, bool isOnline);
    Task<IList<UserProfileDto>> GetAllActiveUsersAsync();
    Task<bool> DeactivateAccountAsync(int userId);
    
    // Admin ops
    Task<IList<UserProfileDto>> GetAllUsersAdminAsync();
    Task<bool> SuspendUserAsync(int userId);
    Task<bool> DeleteUserAsync(int userId);
    Task<int> CountUsersAsync();
}ParseOptions.0.json�R
gD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Auth.API\Services\UserService.cs�Qusing System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Google.Apis.Auth;
using Microsoft.AspNetCore.Identity;
using Microsoft.IdentityModel.Tokens;
using ConnectHub.Auth.API.DTOs;
using ConnectHub.Auth.API.Models;
using ConnectHub.Auth.API.Repositories;

namespace ConnectHub.Auth.API.Services;

public class UserService : IUserService
{
    private readonly IUserRepository _repo;
    private readonly IConfiguration _config;
    private readonly PasswordHasher<User> _hasher = new();

    public UserService(IUserRepository repo, IConfiguration config)
    {
        _repo = repo;
        _config = config;
    }

    public async Task<AuthResponseDto> RegisterAsync(RegisterDto dto)
    {
        if (await _repo.ExistsByEmailAsync(dto.Email))
            throw new InvalidOperationException("Email already registered.");

        if (await _repo.ExistsByUserNameAsync(dto.UserName))
            throw new InvalidOperationException("Username already taken.");

        var user = new User
        {
            UserName = dto.UserName,
            DisplayName = dto.DisplayName,
            Email = dto.Email
        };
        user.PasswordHash = _hasher.HashPassword(user, dto.Password);

        var created = await _repo.CreateAsync(user);
        return BuildAuthResponse(created);
    }

    public async Task<AuthResponseDto> LoginAsync(LoginDto dto)
    {
        var user = await _repo.FindByEmailAsync(dto.Email)
            ?? throw new UnauthorizedAccessException("Invalid email or password.");

        var result = _hasher.VerifyHashedPassword(user, user.PasswordHash, dto.Password);
        if (result == PasswordVerificationResult.Failed)
            throw new UnauthorizedAccessException("Invalid email or password.");

        await _repo.UpdateOnlineStatusAsync(user.UserId, true);
        return BuildAuthResponse(user);
    }

    public async Task<AuthResponseDto> LoginWithGoogleAsync(string idToken)
    {
        var clientId = _config["Google:ClientId"];
        if (string.IsNullOrWhiteSpace(clientId))
            throw new InvalidOperationException("Google Client ID is not configured.");

        // Verifies signature, expiry, issuer, AND that the audience matches
        // *our* OAuth client id — otherwise an attacker could replay a token
        // issued for a different app and we'd happily mint a session.
        var settings = new GoogleJsonWebSignature.ValidationSettings
        {
            Audience = new[] { clientId }
        };

        GoogleJsonWebSignature.Payload payload;
        try
        {
            payload = await GoogleJsonWebSignature.ValidateAsync(idToken, settings);
        }
        catch (InvalidJwtException)
        {
            throw new UnauthorizedAccessException("Invalid Google token.");
        }

        // 1. Match by GoogleId (cheapest, primary path on returning sign-in).
        // 2. Else match by email — links a Google sign-in to an existing
        //    email/password account so the same person doesn't end up with
        //    two rows when they later try one method after the other.
        // 3. Else create a fresh account.
        var user = await _repo.FindByGoogleIdAsync(payload.Subject);
        if (user is null)
        {
            user = await _repo.FindByEmailAsync(payload.Email);
            if (user is not null)
            {
                user.GoogleId = payload.Subject;
                if (string.IsNullOrEmpty(user.AvatarUrl) && !string.IsNullOrEmpty(payload.Picture))
                    user.AvatarUrl = payload.Picture;
                user = await _repo.UpdateAsync(user);
            }
        }

        if (user is null)
        {
            var userName = await GenerateUniqueUserNameAsync(payload.Email);
            user = new User
            {
                Email = payload.Email,
                UserName = userName,
                DisplayName = payload.Name ?? userName,
                AvatarUrl = payload.Picture,
                GoogleId = payload.Subject,
                // Empty password hash — a Google-only user has no local password.
                // They can set one later via the password-reset flow.
                PasswordHash = string.Empty
            };
            user = await _repo.CreateAsync(user);
        }

        await _repo.UpdateOnlineStatusAsync(user.UserId, true);
        return BuildAuthResponse(user);
    }

    public async Task<UserProfileDto?> GetUserByIdAsync(int userId)
    {
        var user = await _repo.FindByUserIdAsync(userId);
        return user is null ? null : MapToProfile(user);
    }

    public async Task<UserProfileDto?> GetUserByUserNameAsync(string userName)
    {
        var user = await _repo.FindByUserNameAsync(userName);
        return user is null ? null : MapToProfile(user);
    }

    public async Task<UserProfileDto> UpdateProfileAsync(int userId, UpdateProfileDto dto)
    {
        var user = await _repo.FindByUserIdAsync(userId)
            ?? throw new KeyNotFoundException("User not found.");

        if (dto.DisplayName is not null) user.DisplayName = dto.DisplayName;
        if (dto.Bio is not null) user.Bio = dto.Bio;
        if (dto.AvatarUrl is not null) user.AvatarUrl = dto.AvatarUrl;

        var updated = await _repo.UpdateAsync(user);
        return MapToProfile(updated);
    }

    public async Task<bool> ChangePasswordAsync(int userId, string oldPassword, string newPassword)
    {
        var user = await _repo.FindByUserIdAsync(userId)
            ?? throw new KeyNotFoundException("User not found.");

        var result = _hasher.VerifyHashedPassword(user, user.PasswordHash, oldPassword);
        if (result == PasswordVerificationResult.Failed) return false;

        user.PasswordHash = _hasher.HashPassword(user, newPassword);
        await _repo.UpdateAsync(user);
        return true;
    }

    public async Task<IList<UserProfileDto>> SearchUsersAsync(string query)
    {
        var users = await _repo.SearchUsersAsync(query);
        return users.Select(MapToProfile).ToList();
    }

    public async Task SetOnlineStatusAsync(int userId, bool isOnline) =>
        await _repo.UpdateOnlineStatusAsync(userId, isOnline);

    public async Task<IList<UserProfileDto>> GetAllActiveUsersAsync()
    {
        var users = await _repo.FindAllActiveAsync();
        return users.Select(MapToProfile).ToList();
    }

    public async Task<bool> DeactivateAccountAsync(int userId)
    {
        var user = await _repo.FindByUserIdAsync(userId);
        if (user is null) return false;
        user.IsActive = false;
        await _repo.UpdateAsync(user);
        return true;
    }

    // ── Admin ────────────────────────────────────────────────────
    public async Task<IList<UserProfileDto>> GetAllUsersAdminAsync()
    {
        var users = await _repo.FindAllIncludingInactiveAsync();
        return users.Select(MapToProfile).ToList();
    }

    public async Task<bool> SuspendUserAsync(int userId)
    {
        var user = await _repo.FindAnyByIdAsync(userId);
        if (user is null) return false;
        
        user.IsActive = false;
        await _repo.UpdateAsync(user);
        return true;
    }

    public async Task<bool> DeleteUserAsync(int userId)
    {
        return await _repo.HardDeleteAsync(userId);
    }

    public async Task<int> CountUsersAsync() =>
        await _repo.CountUsersAsync();

    // ── Private helpers ──────────────────────────────────────────

    // Derives a unique username from the email's local-part (e.g. "alice.smith"
    // → "alicesmith", suffixing "1", "2", ... until free). Avoids forcing
    // first-time Google users through a username-picker before they can chat.
    private async Task<string> GenerateUniqueUserNameAsync(string email)
    {
        var basePart = email.Split('@')[0]
            .ToLowerInvariant()
            .Replace(".", "")
            .Replace("+", "");
        if (string.IsNullOrWhiteSpace(basePart)) basePart = "user";

        var candidate = basePart;
        var suffix = 0;
        while (await _repo.ExistsByUserNameAsync(candidate))
        {
            suffix++;
            candidate = $"{basePart}{suffix}";
        }
        return candidate;
    }

    private AuthResponseDto BuildAuthResponse(User user)
    {
        var expiry = DateTime.UtcNow.AddMinutes(60);
        return new AuthResponseDto
        {
            UserId = user.UserId,
            UserName = user.UserName,
            DisplayName = user.DisplayName,
            Email = user.Email,
            AvatarUrl = user.AvatarUrl,
            Token = GenerateJwt(user, expiry),
            TokenExpiry = expiry
        };
    }

    private string GenerateJwt(User user, DateTime expiry)
    {
        var key = new SymmetricSecurityKey(
            Encoding.UTF8.GetBytes(_config["Jwt:Key"]!));

        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, user.UserId.ToString()),
            new Claim(JwtRegisteredClaimNames.Email, user.Email),
            new Claim("username", user.UserName),
            new Claim(JwtRegisteredClaimNames.Jti, Guid.NewGuid().ToString())
        };

        if (user.IsSystemAdmin)
        {
            claims.Add(new Claim(ClaimTypes.Role, "Admin"));
        }

        var token = new JwtSecurityToken(
            issuer: _config["Jwt:Issuer"],
            audience: _config["Jwt:Audience"],
            claims: claims,
            expires: expiry,
            signingCredentials: new SigningCredentials(key, SecurityAlgorithms.HmacSha256)
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    private static UserProfileDto MapToProfile(User u) => new()
    {
        UserId = u.UserId,
        UserName = u.UserName,
        DisplayName = u.DisplayName,
        Email = u.Email,
        AvatarUrl = u.AvatarUrl,
        Bio = u.Bio,
        IsOnline = u.IsOnline,
        LastSeen = u.LastSeen,
        CreatedAt = u.CreatedAt
    };
}ParseOptions.0.json�
�D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Auth.API\obj\Debug\net8.0\ConnectHub.Auth.API.GlobalUsings.g.cs�// <auto-generated/>
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
�D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Auth.API\obj\Debug\net8.0\.NETCoreApp,Version=v8.0.AssemblyAttributes.cs�// <autogenerated />
using System;
using System.Reflection;
[assembly: global::System.Runtime.Versioning.TargetFrameworkAttribute(".NETCoreApp,Version=v8.0", FrameworkDisplayName = ".NET 8.0")]
ParseOptions.0.json�
�D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Auth.API\obj\Debug\net8.0\ConnectHub.Auth.API.AssemblyInfo.cs�//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated by a tool.
//
//     Changes to this file may cause incorrect behavior and will be lost if
//     the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

using System;
using System.Reflection;

[assembly: System.Reflection.AssemblyCompanyAttribute("ConnectHub.Auth.API")]
[assembly: System.Reflection.AssemblyConfigurationAttribute("Debug")]
[assembly: System.Reflection.AssemblyFileVersionAttribute("1.0.0.0")]
[assembly: System.Reflection.AssemblyInformationalVersionAttribute("1.0.0")]
[assembly: System.Reflection.AssemblyProductAttribute("ConnectHub.Auth.API")]
[assembly: System.Reflection.AssemblyTitleAttribute("ConnectHub.Auth.API")]
[assembly: System.Reflection.AssemblyVersionAttribute("1.0.0.0")]

// Generated by the MSBuild WriteCodeFragment class.

ParseOptions.0.json�
�D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Auth.API\obj\Debug\net8.0\ConnectHub.Auth.API.MvcApplicationPartsAssemblyInfo.cs�//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated by a tool.
//
//     Changes to this file may cause incorrect behavior and will be lost if
//     the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

using System;
using System.Reflection;

[assembly: Microsoft.AspNetCore.Mvc.ApplicationParts.ApplicationPartAttribute("Swashbuckle.AspNetCore.SwaggerGen")]

// Generated by the MSBuild WriteCodeFragment class.

ParseOptions.0.json