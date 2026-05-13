using ConnectHub.Notification.API.DTOs;
using ConnectHub.Notification.API.Hubs;
using ConnectHub.Notification.API.Models;
using ConnectHub.Notification.API.Repositories;
using ConnectHub.Notification.API.Services;
using Microsoft.AspNetCore.SignalR;
using Microsoft.Extensions.Logging;
using Moq;
using NUnit.Framework;

namespace ConnectHub.Notification.API.Tests.Services
{
    [TestFixture]
    public class NotificationServiceTests
    {
        private Mock<INotificationRepository> _repoMock;
        private Mock<IHubContext<NotificationHub>> _hubContextMock;
        private Mock<IHubClients> _clientsMock;
        private Mock<IClientProxy> _clientProxyMock;
        private Mock<IEmailService> _emailMock;
        private Mock<ILogger<NotificationService>> _loggerMock;
        private NotificationService _notificationService;

        [SetUp]
        public void Setup()
        {
            _repoMock = new Mock<INotificationRepository>();
            _hubContextMock = new Mock<IHubContext<NotificationHub>>();
            _clientsMock = new Mock<IHubClients>();
            _clientProxyMock = new Mock<IClientProxy>();
            _emailMock = new Mock<IEmailService>();
            _loggerMock = new Mock<ILogger<NotificationService>>();

            _hubContextMock.Setup(h => h.Clients).Returns(_clientsMock.Object);
            _clientsMock.Setup(c => c.User(It.IsAny<string>())).Returns(_clientProxyMock.Object);

            _notificationService = new NotificationService(
                _repoMock.Object, 
                _hubContextMock.Object, 
                _emailMock.Object, 
                _loggerMock.Object);
        }

        [Test]
        public async Task SendAsync_ShouldSaveNotificationAndPushToSignalR()
        {
            // Arrange
            var dto = new SendNotificationDto
            {
                RecipientId = 1,
                Title = "Test Notif",
                Message = "Hello World"
            };

            var createdEntity = new NotificationEntity { NotificationId = 50, RecipientId = 1, Title = dto.Title };
            _repoMock.Setup(r => r.CreateAsync(It.IsAny<NotificationEntity>())).ReturnsAsync(createdEntity);
            _repoMock.Setup(r => r.CountUnreadByRecipientIdAsync(1)).ReturnsAsync(5);

            // Act
            var result = await _notificationService.SendAsync(dto);

            // Assert
            Assert.That(result.NotificationId, Is.EqualTo(50));
            _repoMock.Verify(r => r.CreateAsync(It.Is<NotificationEntity>(n => n.Title == dto.Title)), Times.Once);
            _clientProxyMock.Verify(c => c.SendCoreAsync("ReceiveNotification", It.IsAny<object[]>(), default), Times.Once);
        }

        [Test]
        public async Task MarkAsReadAsync_ShouldUpdateStatusAndPushCount()
        {
            // Arrange
            var notif = new NotificationEntity { NotificationId = 1, RecipientId = 1, IsRead = false };
            _repoMock.Setup(r => r.FindByIdAsync(1)).ReturnsAsync(notif);
            _repoMock.Setup(r => r.UpdateAsync(It.IsAny<NotificationEntity>())).ReturnsAsync(notif);
            _repoMock.Setup(r => r.CountUnreadByRecipientIdAsync(1)).ReturnsAsync(0);

            // Act
            await _notificationService.MarkAsReadAsync(1);

            // Assert
            Assert.IsTrue(notif.IsRead);
            _clientProxyMock.Verify(c => c.SendCoreAsync("NotificationCount", It.Is<object[]>(o => (int)o[0] == 0), default), Times.Once);
        }
    }
}
