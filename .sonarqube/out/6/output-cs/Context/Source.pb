£"
bD:\Projects\RealtimeChatApplication\ConnectHub\tests\ConnectHub.Hub.API.Tests\Hubs\ChatHubTests.csß!using ConnectHub.Hub.API.Hubs;
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
ParseOptions.0.json˝
nD:\Projects\RealtimeChatApplication\ConnectHub\tests\ConnectHub.Hub.API.Tests\Services\PresenceServiceTests.csıusing ConnectHub.Hub.API.Services;
using NUnit.Framework;

namespace ConnectHub.Hub.API.Tests.Services
{
    [TestFixture]
    public class PresenceServiceTests
    {
        private PresenceService _presenceService;

        [SetUp]
        public void Setup()
        {
            _presenceService = new PresenceService();
        }

        [Test]
        public async Task UserConnectedAsync_ShouldMarkUserAsOnline()
        {
            // Arrange
            int userId = 1;
            string userName = "testuser";
            string connectionId = "conn1";

            // Act
            await _presenceService.UserConnectedAsync(userId, userName, connectionId);
            bool isOnline = await _presenceService.IsUserOnlineAsync(userId);

            // Assert
            Assert.IsTrue(isOnline);
        }

        [Test]
        public async Task UserDisconnectedAsync_ShouldRemoveUserWhenLastConnectionIsClosed()
        {
            // Arrange
            int userId = 1;
            string userName = "testuser";
            string conn1 = "conn1";
            string conn2 = "conn2";

            await _presenceService.UserConnectedAsync(userId, userName, conn1);
            await _presenceService.UserConnectedAsync(userId, userName, conn2);

            // Act
            await _presenceService.UserDisconnectedAsync(userId, conn1);
            bool isStillOnline = await _presenceService.IsUserOnlineAsync(userId);
            
            await _presenceService.UserDisconnectedAsync(userId, conn2);
            bool isOffline = !(await _presenceService.IsUserOnlineAsync(userId));

            // Assert
            Assert.IsTrue(isStillOnline);
            Assert.IsTrue(isOffline);
        }

        [Test]
        public async Task GetOnlineUserIdsAsync_ShouldReturnCorrectIds()
        {
            // Arrange
            await _presenceService.UserConnectedAsync(1, "user1", "c1");
            await _presenceService.UserConnectedAsync(2, "user2", "c2");

            // Act
            var onlineIds = await _presenceService.GetOnlineUserIdsAsync();

            // Assert
            Assert.That(onlineIds.Count, Is.EqualTo(2));
            Assert.That(onlineIds, Does.Contain(1));
            Assert.That(onlineIds, Does.Contain(2));
        }
    }
}
ParseOptions.0.json¥
ZD:\Projects\RealtimeChatApplication\ConnectHub\tests\ConnectHub.Hub.API.Tests\UnitTest1.cs¿namespace ConnectHub.Hub.API.Tests;

public class Tests
{
    [SetUp]
    public void Setup()
    {
    }

    [Test]
    public void Test1()
    {
        Assert.Pass();
    }
}ParseOptions.0.json‚
qC:\Users\dell\.nuget\packages\microsoft.net.test.sdk\17.8.0\build\netcoreapp3.1\Microsoft.NET.Test.Sdk.Program.cs◊// <auto-generated> This file has been auto generated. </auto-generated>
using System;
[Microsoft.VisualStudio.TestPlatform.TestSDKAutoGeneratedCode]
class AutoGeneratedProgram {static void Main(string[] args){}}ParseOptions.0.json≤
âD:\Projects\RealtimeChatApplication\ConnectHub\tests\ConnectHub.Hub.API.Tests\obj\Debug\net8.0\ConnectHub.Hub.API.Tests.GlobalUsings.g.csé// <auto-generated/>
global using NUnit.Framework;
global using System;
global using System.Collections.Generic;
global using System.IO;
global using System.Linq;
global using System.Net.Http;
global using System.Threading;
global using System.Threading.Tasks;
ParseOptions.0.jsonÓ
çD:\Projects\RealtimeChatApplication\ConnectHub\tests\ConnectHub.Hub.API.Tests\obj\Debug\net8.0\.NETCoreApp,Version=v8.0.AssemblyAttributes.cs∆// <autogenerated />
using System;
using System.Reflection;
[assembly: global::System.Runtime.Versioning.TargetFrameworkAttribute(".NETCoreApp,Version=v8.0", FrameworkDisplayName = ".NET 8.0")]
ParseOptions.0.jsonè	
áD:\Projects\RealtimeChatApplication\ConnectHub\tests\ConnectHub.Hub.API.Tests\obj\Debug\net8.0\ConnectHub.Hub.API.Tests.AssemblyInfo.csÌ//------------------------------------------------------------------------------
// <auto-generated>
//     This code was generated by a tool.
//
//     Changes to this file may cause incorrect behavior and will be lost if
//     the code is regenerated.
// </auto-generated>
//------------------------------------------------------------------------------

using System;
using System.Reflection;

[assembly: System.Reflection.AssemblyCompanyAttribute("ConnectHub.Hub.API.Tests")]
[assembly: System.Reflection.AssemblyConfigurationAttribute("Debug")]
[assembly: System.Reflection.AssemblyFileVersionAttribute("1.0.0.0")]
[assembly: System.Reflection.AssemblyInformationalVersionAttribute("1.0.0")]
[assembly: System.Reflection.AssemblyProductAttribute("ConnectHub.Hub.API.Tests")]
[assembly: System.Reflection.AssemblyTitleAttribute("ConnectHub.Hub.API.Tests")]
[assembly: System.Reflection.AssemblyVersionAttribute("1.0.0.0")]

// Generated by the MSBuild WriteCodeFragment class.

ParseOptions.0.json