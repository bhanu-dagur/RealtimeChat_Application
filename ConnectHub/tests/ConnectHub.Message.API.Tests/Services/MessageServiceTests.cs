using ConnectHub.Message.API.DTOs;
using ConnectHub.Message.API.Models;
using ConnectHub.Message.API.Repositories;
using ConnectHub.Message.API.Services;
using ConnectHub.Shared.Enums;
using Moq;
using NUnit.Framework;

namespace ConnectHub.Message.API.Tests.Services
{
    [TestFixture]
    public class MessageServiceTests
    {
        private Mock<IMessageRepository> _repoMock;
        private Mock<INotificationClient> _notifMock;
        private Mock<IAuthClient> _authMock;
        private MessageService _messageService;

        [SetUp]
        public void Setup()
        {
            _repoMock = new Mock<IMessageRepository>();
            _notifMock = new Mock<INotificationClient>();
            _authMock = new Mock<IAuthClient>();
            _messageService = new MessageService(_repoMock.Object, _notifMock.Object, _authMock.Object);
        }

        [Test]
        public async Task SendMessageAsync_ShouldCreateMessageAndNotify_WhenDirectMessage()
        {
            // Arrange
            var dto = new SendMessageDto
            {
                SenderId = 1,
                ReceiverId = 2,
                Content = "Hello",
                MessageType = MessageType.TEXT
            };

            var createdEntity = new MessageEntity
            {
                MessageId = 100,
                SenderId = dto.SenderId,
                ReceiverId = dto.ReceiverId,
                Content = dto.Content,
                SentAt = DateTime.UtcNow
            };

            _repoMock.Setup(r => r.CreateAsync(It.IsAny<MessageEntity>())).ReturnsAsync(createdEntity);

            // Act
            var result = await _messageService.SendMessageAsync(dto);

            // Assert
            Assert.That(result.MessageId, Is.EqualTo(100));
            _repoMock.Verify(r => r.CreateAsync(It.Is<MessageEntity>(m => m.Content == dto.Content)), Times.Once);
            _notifMock.Verify(n => n.SendAsync(
                dto.ReceiverId.Value, 
                dto.SenderId, 
                NotificationType.MESSAGE, 
                It.IsAny<string>(), 
                It.IsAny<string>(), 
                100, 
                It.IsAny<CancellationToken>()), Times.Once);
        }

        [Test]
        public async Task SendMessageAsync_ShouldHandleMentions_WhenRoomMessage()
        {
            // Arrange
            var dto = new SendMessageDto
            {
                SenderId = 1,
                RoomId = 10,
                Content = "Hello @rohit",
                MessageType = MessageType.TEXT
            };

            var createdEntity = new MessageEntity { MessageId = 101, SenderId = 1, RoomId = 10, Content = dto.Content };

            _repoMock.Setup(r => r.CreateAsync(It.IsAny<MessageEntity>())).ReturnsAsync(createdEntity);
            _authMock.Setup(a => a.GetUserIdByUserNameAsync("rohit", It.IsAny<CancellationToken>())).ReturnsAsync(2);

            // Act
            await _messageService.SendMessageAsync(dto);

            // Assert
            _authMock.Verify(a => a.GetUserIdByUserNameAsync("rohit", It.IsAny<CancellationToken>()), Times.Once);
            _notifMock.Verify(n => n.SendAsync(
                2, 
                1, 
                NotificationType.MENTION, 
                It.IsAny<string>(), 
                It.IsAny<string>(), 
                10, 
                It.IsAny<CancellationToken>()), Times.Once);
        }

        [Test]
        public void SendMessageAsync_ShouldThrowException_WhenNoRecipient()
        {
            // Arrange
            var dto = new SendMessageDto { Content = "Hello" };

            // Act & Assert
            Assert.ThrowsAsync<ArgumentException>(async () => await _messageService.SendMessageAsync(dto));
        }
    }
}
