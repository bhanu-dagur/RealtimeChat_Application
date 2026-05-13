using ConnectHub.Hub.API.Hubs;
using ConnectHub.Hub.API.Models;
using ConnectHub.Hub.API.Services;
using Microsoft.AspNetCore.SignalR;
using Microsoft.Extensions.Logging;
using Moq;
using NUnit.Framework;
using System.Security.Claims;

namespace ConnectHub.Hub.API.Tests.Hubs
{
    [TestFixture]
    public class ChatHubTests
    {
        private Mock<IPresenceService> _presenceMock;
        private Mock<IUserStatusService> _userStatusMock;
        private Mock<ILogger<ChatHub>> _loggerMock;
        private Mock<IHubCallerClients> _clientsMock;
        private Mock<IClientProxy> _clientProxyMock;
        private Mock<ISingleClientProxy> _singleClientProxyMock;
        private Mock<HubCallerContext> _contextMock;
        private ChatHub _chatHub;

        [SetUp]
        public void Setup()
        {
            _presenceMock = new Mock<IPresenceService>();
            _userStatusMock = new Mock<IUserStatusService>();
            _loggerMock = new Mock<ILogger<ChatHub>>();
            _clientsMock = new Mock<IHubCallerClients>();
            _clientProxyMock = new Mock<IClientProxy>();
            _singleClientProxyMock = new Mock<ISingleClientProxy>();
            _contextMock = new Mock<HubCallerContext>();

            _chatHub = new ChatHub(_presenceMock.Object, _userStatusMock.Object, _loggerMock.Object)
            {
                Context = _contextMock.Object,
                Clients = _clientsMock.Object
            };
        }

        [TearDown]
        public void TearDown()
        {
            _chatHub?.Dispose();
        }

        [Test]
        public async Task OnConnectedAsync_ShouldUpdatePresenceAndNotifyOthers()
        {
            // Arrange
            var userId = 1;
            var userName = "testuser";
            var connectionId = "conn1";

            var claims = new[]
            {
                new Claim(ClaimTypes.NameIdentifier, userId.ToString()),
                new Claim("username", userName)
            };
            var identity = new ClaimsIdentity(claims, "TestAuthType");
            var principal = new ClaimsPrincipal(identity);

            _contextMock.Setup(c => c.User).Returns(principal);
            _contextMock.Setup(c => c.ConnectionId).Returns(connectionId);
            _presenceMock.Setup(p => p.IsUserOnlineAsync(userId)).ReturnsAsync(false);
            _presenceMock.Setup(p => p.GetOnlineUserIdsAsync()).ReturnsAsync(new List<int>());
            
            _clientsMock.Setup(c => c.Others).Returns(_clientProxyMock.Object);
            _clientsMock.Setup(c => c.Caller).Returns(_singleClientProxyMock.Object);
            _clientsMock.Setup(c => c.User(It.IsAny<string>())).Returns(_singleClientProxyMock.Object);

            // Act
            await _chatHub.OnConnectedAsync();

            // Assert
            _presenceMock.Verify(p => p.UserConnectedAsync(userId, userName, connectionId), Times.Once);
            _userStatusMock.Verify(u => u.UpdateUserOnlineStatusAsync(userId, true), Times.Once);
            _clientProxyMock.Verify(c => c.SendCoreAsync("UserOnline", It.IsAny<object[]>(), default), Times.Once);
            _singleClientProxyMock.Verify(c => c.SendCoreAsync("OnlineUsers", It.IsAny<object[]>(), default), Times.Once);
        }

        [Test]
        public async Task SendDirectMessage_ShouldSendToBothSenderAndReceiver()
        {
            // Arrange
            var senderId = 1;
            var receiverId = 2;
            var message = new ChatMessage { ReceiverId = receiverId, Content = "Hello" };

            var claims = new[] { new Claim(ClaimTypes.NameIdentifier, senderId.ToString()) };
            var identity = new ClaimsIdentity(claims);
            _contextMock.Setup(c => c.User).Returns(new ClaimsPrincipal(identity));

            _clientsMock.Setup(c => c.Users(It.IsAny<IReadOnlyList<string>>())).Returns(_clientProxyMock.Object);

            // Act
            await _chatHub.SendDirectMessage(message);

            // Assert
            _clientsMock.Verify(c => c.Users(It.Is<IReadOnlyList<string>>(l => l.Contains("1") && l.Contains("2"))), Times.Once);
            _clientProxyMock.Verify(c => c.SendCoreAsync("ReceiveDirectMessage", It.IsAny<object[]>(), default), Times.Once);
        }
    }
}
