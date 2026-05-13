�
pD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Hub.API\Controllers\PresenceController.cs�using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ConnectHub.Hub.API.Models;
using ConnectHub.Hub.API.Services;
using ConnectHub.Shared.Models;

namespace ConnectHub.Hub.API.Controllers;

[ApiController]
[Route("api/presence")]
[Authorize]
public class PresenceController : ControllerBase
{
    private readonly IPresenceService _presence;

    public PresenceController(IPresenceService presence)
    {
        _presence = presence;
    }

    // GET api/presence/online
    [HttpGet("online")]
    public async Task<IActionResult> GetOnlineUsers()
    {
        var users = await _presence.GetOnlineUserIdsAsync();
        return Ok(ApiResponse<IList<int>>.Ok(users));
    }

    // GET api/presence/online/count
    [HttpGet("online/count")]
    public async Task<IActionResult> GetOnlineCount()
    {
        var count = await _presence.GetOnlineCountAsync();
        return Ok(ApiResponse<int>.Ok(count));
    }

    // GET api/presence/online/info
    [HttpGet("online/info")]
    public async Task<IActionResult> GetOnlineUsersInfo()
    {
        var info = await _presence.GetOnlineUsersInfoAsync();
        return Ok(ApiResponse<IList<UserConnection>>.Ok(info));
    }

    // GET api/presence/isonline/{userId}
    [HttpGet("isonline/{userId:int}")]
    public async Task<IActionResult> IsOnline(int userId)
    {
        var online = await _presence.IsUserOnlineAsync(userId);
        return Ok(ApiResponse<bool>.Ok(online));
    }

    // GET api/presence/connections/{userId}
    [HttpGet("connections/{userId:int}")]
    public async Task<IActionResult> GetConnections(int userId)
    {
        var connections = await _presence.GetConnectionsByUserIdAsync(userId);
        return Ok(ApiResponse<IList<string>>.Ok(connections));
    }
}ParseOptions.0.json�v
^D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Hub.API\Hubs\ChatHub.cs�uusing Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using System.Security.Claims;
using ConnectHub.Hub.API.Models;
using ConnectHub.Hub.API.Services;
namespace ConnectHub.Hub.API.Hubs;

[Authorize]
public class ChatHub : Microsoft.AspNetCore.SignalR.Hub
{
    private readonly IPresenceService _presence;
    private readonly IUserStatusService _userStatus;
    private readonly ILogger<ChatHub> _logger;

    public ChatHub(IPresenceService presence, IUserStatusService userStatus, ILogger<ChatHub> logger)
    {
        _presence = presence;
        _userStatus = userStatus;
        _logger = logger;
    }

    // ── Connection Events ─────────────────────────────────────────

    public override async Task OnConnectedAsync()
    {
        var userId = GetUserId();
        var userName = GetUserName();

        if (userId == 0)
        {
            _logger.LogWarning("Anonymous SignalR connection rejected. ConnectionId: {ConnectionId}", Context.ConnectionId);
            Context.Abort();
            return;
        }

        // Was the user already online via another tab? Used below to decide whether
        // to broadcast UserOnline (avoid spamming presence flicker on multi-tab).
        var wasAlreadyOnline = await _presence.IsUserOnlineAsync(userId);

        await _presence.UserConnectedAsync(userId, userName, Context.ConnectionId);

        // Database flag — fire-and-forget; failures never block the chat.
        _ = _userStatus.UpdateUserOnlineStatusAsync(userId, true);

        _logger.LogInformation(
            "User {UserId} ({UserName}) connected. ConnectionId: {ConnectionId}",
            userId, userName, Context.ConnectionId);

        if (!wasAlreadyOnline)
        {
            await Clients.Others.SendAsync("UserOnline", new
            {
                UserId = userId,
                UserName = userName,
                ConnectedAt = DateTime.UtcNow
            });
        }

        // Hand the caller the current online roster, excluding self — the client
        // already knows it's online and would otherwise render "you are online" badges.
        var onlineUsers = (await _presence.GetOnlineUserIdsAsync())
            .Where(id => id != userId)
            .ToList();
        await Clients.Caller.SendAsync("OnlineUsers", onlineUsers);

        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        var userId = GetUserId();
        var userName = GetUserName();

        if (userId == 0)
        {
            await base.OnDisconnectedAsync(exception);
            return;
        }

        await _presence.UserDisconnectedAsync(userId, Context.ConnectionId);

        _logger.LogInformation(
            "User {UserId} ({UserName}) disconnected. ConnectionId: {ConnectionId}",
            userId, userName, Context.ConnectionId);

        // Multi-tab: only flip to offline + broadcast when the LAST tab closes.
        var remainingConnections = await _presence.GetConnectionsByUserIdAsync(userId);
        if (remainingConnections.Count == 0)
        {
            _ = _userStatus.UpdateUserOnlineStatusAsync(userId, false);

            await Clients.Others.SendAsync("UserOffline", new
            {
                UserId = userId,
                UserName = userName,
                LastSeen = DateTime.UtcNow
            });
        }

        await base.OnDisconnectedAsync(exception);
    }

    // ── Direct Message ────────────────────────────────────────────

    public async Task SendDirectMessage(ChatMessage message)
    {
        var senderId = GetUserId();
        message.SenderId = senderId;
        message.SenderName = GetUserName();
        // Trust SentAt from the saved DB record — only stamp now if the client didn't.
        if (message.SentAt == default) message.SentAt = DateTime.UtcNow;

        _logger.LogInformation(
            "Direct message from {SenderId} to {ReceiverId} (MessageId: {MessageId})",
            senderId, message.ReceiverId, message.MessageId);

        // Send to every connection of both sender and receiver so multi-tab works.
        // Clients.User(...) targets all of that user's connections; Clients.Users(...) unions both.
        var targets = new List<string> { senderId.ToString() };
        if (message.ReceiverId.HasValue && message.ReceiverId.Value != senderId)
            targets.Add(message.ReceiverId.Value.ToString());

        try
        {
            await Clients.Users(targets).SendAsync("ReceiveDirectMessage", message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex,
                "SendDirectMessage failed for sender {SenderId} → receiver {ReceiverId} (MessageId: {MessageId})",
                senderId, message.ReceiverId, message.MessageId);
        }
    }

    // ── Edit/Delete Broadcasts ────────────────────────────────────
    // Called by clients after a successful PUT /edit or DELETE — pushes the updated row
    // (or just the id+isDeleted=true) to everyone affected so each open tab can patch its UI.

    public async Task BroadcastMessageEdited(ChatMessage message)
    {
        if (message.RoomId.HasValue)
        {
            await Clients.Group(message.RoomId.Value.ToString())
                .SendAsync("MessageEdited", message);
            return;
        }

        var senderId = GetUserId();
        var targets = new List<string> { senderId.ToString() };
        if (message.ReceiverId.HasValue && message.ReceiverId.Value != senderId)
            targets.Add(message.ReceiverId.Value.ToString());
        await Clients.Users(targets).SendAsync("MessageEdited", message);
    }

    public async Task BroadcastMessageDeleted(int messageId, int? receiverId, int? roomId)
    {
        var payload = new { MessageId = messageId, RoomId = roomId, ReceiverId = receiverId };

        if (roomId.HasValue)
        {
            await Clients.Group(roomId.Value.ToString())
                .SendAsync("MessageDeleted", payload);
            return;
        }

        var senderId = GetUserId();
        var targets = new List<string> { senderId.ToString() };
        if (receiverId.HasValue && receiverId.Value != senderId)
            targets.Add(receiverId.Value.ToString());
        await Clients.Users(targets).SendAsync("MessageDeleted", payload);
    }

    // Recipient-side ack: invoked from the receiver's tab right after it inserts an
    // incoming direct message into its UI. Pushes "MessageDelivered" back to the
    // original sender so their bubble flips ✓ → ✓✓ in real time. The actual DB
    // flag flip already happened via the REST PUT /api/messages/{id}/delivered;
    // this method only fans the event out across SignalR.
    public async Task BroadcastMessageDelivered(int messageId, int senderId, DateTime deliveredAt)
    {
        var ackerId = GetUserId();
        if (ackerId == 0) return;

        var payload = new
        {
            MessageId = messageId,
            DeliveredBy = ackerId,
            DeliveredAt = deliveredAt == default ? DateTime.UtcNow : deliveredAt
        };

        await Clients.User(senderId.ToString()).SendAsync("MessageDelivered", payload);
    }

    // Recipient opened the chat → backend bulk-marked everything from `senderId`
    // as read. Fan a "MessagesRead" event back to the sender's tabs so every bubble
    // they sent flips to ✓✓ blue at once. Receiver invokes this AFTER the
    // /mark-read REST call completes.
    public async Task BroadcastMessagesRead(int senderId)
    {
        var readerId = GetUserId();
        if (readerId == 0) return;

        var payload = new
        {
            ReaderId = readerId,
            PartnerId = senderId,
            ReadAt = DateTime.UtcNow
        };

        // Tell the original sender's tabs (and the reader's other tabs too,
        // so their unread badge clears across devices).
        await Clients.Users(new[] { senderId.ToString(), readerId.ToString() })
            .SendAsync("MessagesRead", payload);
    }

    // ── Room Message ──────────────────────────────────────────────

    public async Task SendRoomMessage(ChatMessage message)
    {
        var senderId = GetUserId();
        message.SenderId = senderId;
        message.SenderName = GetUserName();
        if (message.SentAt == default) message.SentAt = DateTime.UtcNow;

        if (!message.RoomId.HasValue)
        {
            await Clients.Caller.SendAsync("Error", "RoomId is required.");
            return;
        }

        _logger.LogInformation(
            "Room message from {SenderId} to Room {RoomId}",
            senderId, message.RoomId);

        // Room ke saare members ko message bhejo
        try
        {
            await Clients.Group(message.RoomId.Value.ToString())
                .SendAsync("ReceiveRoomMessage", message);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex,
                "SendRoomMessage failed for room {RoomId} from sender {SenderId} (MessageId: {MessageId})",
                message.RoomId.Value, senderId, message.MessageId);
        }
    }

    // ── Room Join / Leave ─────────────────────────────────────────

    public async Task JoinRoom(int roomId)
    {
        var userId = GetUserId();
        var userName = GetUserName();

        // SignalR group mein add karo
        await Groups.AddToGroupAsync(Context.ConnectionId, roomId.ToString());

        _logger.LogInformation(
            "User {UserId} joined Room {RoomId}", userId, roomId);

        // Room ke baaki members ko batao
        await Clients.OthersInGroup(roomId.ToString())
            .SendAsync("UserJoinedRoom", new
            {
                RoomId = roomId,
                UserId = userId,
                UserName = userName,
                JoinedAt = DateTime.UtcNow
            });

        // Caller ko confirm karo
        await Clients.Caller.SendAsync("JoinedRoom", roomId);
    }

    public async Task LeaveRoom(int roomId)
    {
        var userId = GetUserId();
        var userName = GetUserName();

        // SignalR group se remove karo
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, roomId.ToString());

        _logger.LogInformation(
            "User {UserId} left Room {RoomId}", userId, roomId);

        // Room ke baaki members ko batao
        await Clients.OthersInGroup(roomId.ToString())
            .SendAsync("UserLeftRoom", new
            {
                RoomId = roomId,
                UserId = userId,
                UserName = userName,
                LeftAt = DateTime.UtcNow
            });

        await Clients.Caller.SendAsync("LeftRoom", roomId);
    }

    // ── Typing Indicator ──────────────────────────────────────────

    public async Task TypingIndicator(int? receiverId, int? roomId, bool isTyping)
    {
        var senderId = GetUserId();
        var senderName = GetUserName();

        var payload = new
        {
            SenderId = senderId,
            SenderName = senderName,
            IsTyping = isTyping,
            Timestamp = DateTime.UtcNow
        };

        if (receiverId.HasValue)
        {
            // Direct message typing
            await Clients.User(receiverId.Value.ToString())
                .SendAsync("UserTyping", payload);
        }
        else if (roomId.HasValue)
        {
            // Room typing — sender ko chhodkar baaki sab ko
            await Clients.OthersInGroup(roomId.Value.ToString())
                .SendAsync("UserTyping", payload);
        }
    }

    // ── Read Receipt ──────────────────────────────────────────────

    public async Task MarkMessageRead(int messageId, int senderId)
    {
        var readerId = GetUserId();

        // Message sender ko batao ki message padh liya gaya
        await Clients.User(senderId.ToString())
            .SendAsync("MessageRead", new
            {
                MessageId = messageId,
                ReadBy = readerId,
                ReadAt = DateTime.UtcNow
            });
    }

    // ── Media Message ─────────────────────────────────────────────

    public async Task SendMediaMessage(ChatMessage message)
    {
        var senderId = GetUserId();
        message.SenderId = senderId;
        message.SenderName = GetUserName();
        message.SentAt = DateTime.UtcNow;

        if (message.RoomId.HasValue)
        {
            await Clients.Group(message.RoomId.Value.ToString())
                .SendAsync("ReceiveRoomMessage", message);
        }
        else if (message.ReceiverId.HasValue)
        {
            await Clients.User(message.ReceiverId.Value.ToString())
                .SendAsync("ReceiveDirectMessage", message);

            await Clients.User(senderId.ToString())
                .SendAsync("ReceiveDirectMessage", message);
        }
    }

    // ── Notification Push ─────────────────────────────────────────

    public async Task SendNotification(int recipientId, string title, string messageText)
    {
        await Clients.User(recipientId.ToString())
            .SendAsync("ReceiveNotification", new
            {
                Title = title,
                Message = messageText,
                SentAt = DateTime.UtcNow
            });
    }

    // ── Private Helpers ───────────────────────────────────────────

    private int GetUserId()
    {
        var claim = Context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value
                 ?? Context.User?.FindFirst("sub")?.Value;

        return int.TryParse(claim, out var id) ? id : 0;
    }

    private string GetUserName()
    {
        return Context.User?.FindFirst("username")?.Value
            ?? Context.User?.Identity?.Name
            ?? "Unknown";
    }
}ParseOptions.0.json�
eD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Hub.API\Hubs\UserIdProvider.cs�using Microsoft.AspNetCore.SignalR;
using System.Security.Claims;

namespace ConnectHub.Hub.API.Hubs;

// JWT token se UserId nikalta hai
// Isse Clients.User(userId) kaam karta hai
public class UserIdProvider : IUserIdProvider
{
    public string? GetUserId(HubConnectionContext connection)
    {
        // JWT mein "sub" claim mein UserId hota hai
        return connection.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value
            ?? connection.User?.FindFirst("sub")?.Value;
    }
}ParseOptions.0.json�
dD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Hub.API\Models\ChatMessage.cs�using ConnectHub.Shared.Enums;

namespace ConnectHub.Hub.API.Models;

// SignalR ke through jaane wala message model
public class ChatMessage
{
    public int MessageId { get; set; }
    public int SenderId { get; set; }
    public string SenderName { get; set; } = string.Empty;
    public int? ReceiverId { get; set; }
    public int? RoomId { get; set; }
    public string Content { get; set; } = string.Empty;
    public MessageType MessageType { get; set; } = MessageType.TEXT;
    public string? MediaUrl { get; set; }
    public int? ReplyToMessageId { get; set; }
    public bool IsEdited { get; set; }
    public bool IsDeleted { get; set; }
    public DateTime SentAt { get; set; } = DateTime.UtcNow;
    public DateTime? EditedAt { get; set; }
}ParseOptions.0.json�
gD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Hub.API\Models\UserConnection.cs�namespace ConnectHub.Hub.API.Models;

public class UserConnection
{
    public string ConnectionId { get; set; } = string.Empty;
    public int UserId { get; set; }
    public string UserName { get; set; } = string.Empty;
    public DateTime ConnectedAt { get; set; } = DateTime.UtcNow;
}ParseOptions.0.json�4
YD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Hub.API\Program.cs�3using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.SignalR;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using Serilog;
using ConnectHub.Hub.API.Hubs;
using ConnectHub.Hub.API.Services;

var builder = WebApplication.CreateBuilder(args);

// ── Serilog ───────────────────────────────────────────────────────
Log.Logger = new LoggerConfiguration()
    .WriteTo.Console()
    .CreateLogger();
builder.Host.UseSerilog();

// ── Presence Service (Singleton — saari app mein ek hi instance)──
builder.Services.AddSingleton<IPresenceService, PresenceService>();

// ── HttpClient for Auth API calls ────────────────────────────────
builder.Services.AddHttpClient<IUserStatusService, UserStatusService>(client =>
{
    var authApiUrl = builder.Configuration["Services:AuthApi:Url"] ?? "http://localhost:5001";
    client.BaseAddress = new Uri(authApiUrl);
    client.Timeout = TimeSpan.FromSeconds(10);
});

// ── Custom UserIdProvider — JWT se UserId nikalta hai ─────────────
builder.Services.AddSingleton<IUserIdProvider, UserIdProvider>();

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

        // SignalR ke saath JWT kaam kare — query string se token lo
        options.Events = new JwtBearerEvents
        {
            OnMessageReceived = context =>
            {
                var accessToken = context.Request.Query["access_token"];
                var path = context.HttpContext.Request.Path;

                // SignalR hub path par token query string se lo
                if (!string.IsNullOrEmpty(accessToken) &&
                    path.StartsWithSegments("/hubs/chat"))
                {
                    context.Token = accessToken;
                }
                return Task.CompletedTask;
            }
        };
    });

builder.Services.AddAuthorization();

// ── SignalR ───────────────────────────────────────────────────────
// If a Redis connection string is configured, use Redis as the SignalR backplane
// so we can scale Hub.API horizontally (multiple replicas behind the gateway).
// Without it, presence + group broadcasts only stay coherent inside one replica.
var signalRBuilder = builder.Services.AddSignalR(options =>
{
    options.EnableDetailedErrors = true;          // Dev mein detailed errors
    options.KeepAliveInterval = TimeSpan.FromSeconds(15);
    options.ClientTimeoutInterval = TimeSpan.FromSeconds(30);
    options.MaximumReceiveMessageSize = 1024 * 1024; // 1MB max message size
});

var redisConn = builder.Configuration["Redis:ConnectionString"];
if (!string.IsNullOrWhiteSpace(redisConn))
{
    signalRBuilder.AddStackExchangeRedis(redisConn, o =>
    {
        o.Configuration.ChannelPrefix = StackExchange.Redis.RedisChannel.Literal("ConnectHub.SignalR");
    });
    Log.Information("SignalR Redis backplane wired ({Conn})", redisConn);
}
else
{
    Log.Information("SignalR running in single-instance mode (no Redis backplane).");
}

// ── CORS ──────────────────────────────────────────────────────────
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
        policy
            .AllowAnyMethod()
            .AllowAnyHeader()
            .AllowCredentials()         // SignalR ke liye zaroori
            .SetIsOriginAllowed(_ => true));
});

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
        Title = "ConnectHub Hub API",
        Version = "v1",
        Description = "SignalR ChatHub + Presence API"
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
app.MapHub<ChatHub>("/hubs/chat");

app.Run();ParseOptions.0.json�
kD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Hub.API\Services\IPresenceService.cs�using ConnectHub.Hub.API.Models;

namespace ConnectHub.Hub.API.Services;

public interface IPresenceService
{
    // When User connected
    Task UserConnectedAsync(int userId, string userName, string connectionId);

    // When User disconnected
    Task UserDisconnectedAsync(int userId, string connectionId);

    // All Connection of the user (in case of multiple tabs)
    Task<IList<string>> GetConnectionsByUserIdAsync(int userId);

    // User is online or Not
    Task<bool> IsUserOnlineAsync(int userId);

    // List of all online users
    Task<IList<int>> GetOnlineUserIdsAsync();

    // Detail info of all online users
    Task<IList<UserConnection>> GetOnlineUsersInfoAsync();

    // Total online count
    Task<int> GetOnlineCountAsync();

    // clean all connections of the specific user
    Task ClearUserConnectionsAsync(int userId);
}ParseOptions.0.json�
mD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Hub.API\Services\IUserStatusService.cs�namespace ConnectHub.Hub.API.Services;

/// <summary>
/// Service to sync user online/offline status with Auth API database
/// </summary>
public interface IUserStatusService
{
    Task UpdateUserOnlineStatusAsync(int userId, bool isOnline);
}
ParseOptions.0.json�
jD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Hub.API\Services\PresenceService.cs�using System.Collections.Concurrent;
using ConnectHub.Hub.API.Models;

namespace ConnectHub.Hub.API.Services;

public class PresenceService : IPresenceService
{
    // UserId → set of connection ids. Inner ConcurrentDictionary<string, byte> gives us
    // a thread-safe set without taking a lock for every read — the previous HashSet
    // implementation would throw "Collection was modified" if a reader called .ToList()
    // while another thread mutated the set.
    private readonly ConcurrentDictionary<int, ConcurrentDictionary<string, byte>> _userConnections = new();
    private readonly ConcurrentDictionary<string, UserConnection> _connectionDetails = new();

    public Task UserConnectedAsync(int userId, string userName, string connectionId)
    {
        var bag = _userConnections.GetOrAdd(userId, _ => new ConcurrentDictionary<string, byte>());
        bag.TryAdd(connectionId, 0);

        _connectionDetails[connectionId] = new UserConnection
        {
            ConnectionId = connectionId,
            UserId = userId,
            UserName = userName,
            ConnectedAt = DateTime.UtcNow
        };

        return Task.CompletedTask;
    }

    public Task UserDisconnectedAsync(int userId, string connectionId)
    {
        if (_userConnections.TryGetValue(userId, out var bag))
        {
            bag.TryRemove(connectionId, out _);
            if (bag.IsEmpty)
                _userConnections.TryRemove(userId, out _);
        }
        _connectionDetails.TryRemove(connectionId, out _);
        return Task.CompletedTask;
    }

    public Task<IList<string>> GetConnectionsByUserIdAsync(int userId)
    {
        if (_userConnections.TryGetValue(userId, out var bag))
            return Task.FromResult<IList<string>>(bag.Keys.ToList());
        return Task.FromResult<IList<string>>(new List<string>());
    }

    public Task<bool> IsUserOnlineAsync(int userId) =>
        Task.FromResult(_userConnections.ContainsKey(userId));

    public Task<IList<int>> GetOnlineUserIdsAsync() =>
        Task.FromResult<IList<int>>(_userConnections.Keys.ToList());

    public Task<IList<UserConnection>> GetOnlineUsersInfoAsync() =>
        Task.FromResult<IList<UserConnection>>(_connectionDetails.Values.ToList());

    public Task<int> GetOnlineCountAsync() =>
        Task.FromResult(_userConnections.Count);

    public Task ClearUserConnectionsAsync(int userId)
    {
        if (_userConnections.TryRemove(userId, out var bag))
        {
            foreach (var connId in bag.Keys)
                _connectionDetails.TryRemove(connId, out _);
        }
        return Task.CompletedTask;
    }
}
ParseOptions.0.json�
lD:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Hub.API\Services\UserStatusService.cs�namespace ConnectHub.Hub.API.Services;

public class UserStatusService : IUserStatusService
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<UserStatusService> _logger;

    public UserStatusService(HttpClient httpClient, ILogger<UserStatusService> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    public async Task UpdateUserOnlineStatusAsync(int userId, bool isOnline)
    {
        try
        {
            // PUT /api/users/{id}/online-status on Auth API.
            // The DTO property is `IsOnline` (PascalCase) — Auth API does not register
            // a camelCase JSON contract for input, so always serialize that exact name.
            var request = new HttpRequestMessage(HttpMethod.Put, $"/api/users/{userId}/online-status")
            {
                Content = JsonContent.Create(new { IsOnline = isOnline })
            };

            using var cts = new CancellationTokenSource(TimeSpan.FromSeconds(5));
            var response = await _httpClient.SendAsync(request, cts.Token);

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning(
                    "Auth API rejected online-status update for user {UserId}. Status: {StatusCode}",
                    userId, response.StatusCode);
            }
        }
        catch (TaskCanceledException)
        {
            _logger.LogWarning("Online-status update for user {UserId} timed out — Auth API slow or unreachable.", userId);
        }
        catch (HttpRequestException ex)
        {
            _logger.LogWarning(ex, "Online-status update for user {UserId} failed (Auth API unreachable).", userId);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unexpected error updating online status for user {UserId}", userId);
            // Never throw — presence in-memory still works even if DB sync fails.
        }
    }
}
ParseOptions.0.json�
�D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Hub.API\obj\Debug\net8.0\ConnectHub.Hub.API.GlobalUsings.g.cs�// <auto-generated/>
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
�D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Hub.API\obj\Debug\net8.0\.NETCoreApp,Version=v8.0.AssemblyAttributes.cs�// <autogenerated />
using System;
using System.Reflection;
[assembly: global::System.Runtime.Versioning.TargetFrameworkAttribute(".NETCoreApp,Version=v8.0", FrameworkDisplayName = ".NET 8.0")]
ParseOptions.0.json�
�D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Hub.API\obj\Debug\net8.0\ConnectHub.Hub.API.AssemblyInfo.cs�//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated by a tool.
//
//     Changes to this file may cause incorrect behavior and will be lost if
//     the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

using System;
using System.Reflection;

[assembly: System.Reflection.AssemblyCompanyAttribute("ConnectHub.Hub.API")]
[assembly: System.Reflection.AssemblyConfigurationAttribute("Debug")]
[assembly: System.Reflection.AssemblyFileVersionAttribute("1.0.0.0")]
[assembly: System.Reflection.AssemblyInformationalVersionAttribute("1.0.0")]
[assembly: System.Reflection.AssemblyProductAttribute("ConnectHub.Hub.API")]
[assembly: System.Reflection.AssemblyTitleAttribute("ConnectHub.Hub.API")]
[assembly: System.Reflection.AssemblyVersionAttribute("1.0.0.0")]

// Generated by the MSBuild WriteCodeFragment class.

ParseOptions.0.json�
�D:\Projects\RealtimeChatApplication\ConnectHub\src\Services\ConnectHub.Hub.API\obj\Debug\net8.0\ConnectHub.Hub.API.MvcApplicationPartsAssemblyInfo.cs�//------------------------------------------------------------------------------
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