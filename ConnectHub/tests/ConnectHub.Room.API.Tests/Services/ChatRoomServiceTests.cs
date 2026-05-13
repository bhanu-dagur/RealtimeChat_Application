using ConnectHub.Room.API.DTOs;
using ConnectHub.Room.API.Models;
using ConnectHub.Room.API.Repositories;
using ConnectHub.Room.API.Services;
using ConnectHub.Shared.Enums;
using Moq;
using NUnit.Framework;

namespace ConnectHub.Room.API.Tests.Services
{
    [TestFixture]
    public class ChatRoomServiceTests
    {
        private Mock<IChatRoomRepository> _repoMock;
        private Mock<INotificationClient> _notifMock;
        private ChatRoomService _roomService;

        [SetUp]
        public void Setup()
        {
            _repoMock = new Mock<IChatRoomRepository>();
            _notifMock = new Mock<INotificationClient>();
            _roomService = new ChatRoomService(_repoMock.Object, _notifMock.Object);
        }

        [Test]
        public async Task CreateRoomAsync_ShouldCreateRoomAndAddCreatorAsAdmin()
        {
            // Arrange
            var dto = new CreateRoomDto
            {
                RoomName = "Test Room",
                CreatedBy = 1,
                RoomType = RoomType.PUBLIC
            };

            var createdRoom = new ChatRoom { RoomId = 1, RoomName = dto.RoomName, CreatedBy = dto.CreatedBy };
            _repoMock.Setup(r => r.CreateAsync(It.IsAny<ChatRoom>())).ReturnsAsync(createdRoom);
            _repoMock.Setup(r => r.CountMembersAsync(1)).ReturnsAsync(1);

            // Act
            var result = await _roomService.CreateRoomAsync(dto);

            // Assert
            Assert.That(result.RoomId, Is.EqualTo(createdRoom.RoomId));
            _repoMock.Verify(r => r.AddMemberAsync(It.Is<RoomMember>(m => m.UserId == dto.CreatedBy && m.Role == MemberRole.ADMIN)), Times.Once);
        }

        [Test]
        public async Task AddMemberAsync_ShouldFail_WhenRoomIsFull()
        {
            // Arrange
            var roomId = 1;
            var userId = 2;
            var actingUserId = 1;

            _repoMock.Setup(r => r.FindByIdAsync(roomId)).ReturnsAsync(new ChatRoom { RoomId = roomId, MaxMembers = 2 });
            _repoMock.Setup(r => r.CountMembersAsync(roomId)).ReturnsAsync(2);
            _repoMock.Setup(r => r.FindMemberAsync(roomId, actingUserId)).ReturnsAsync(new RoomMember { Role = MemberRole.ADMIN });

            var dto = new AddMemberDto { RoomId = roomId, UserId = userId };

            // Act & Assert
            var ex = Assert.ThrowsAsync<InvalidOperationException>(async () => await _roomService.AddMemberAsync(dto, actingUserId));
            Assert.That(ex.Message, Does.Contain("Room is full"));
        }

        [Test]
        public async Task EnsureAdminAsync_ShouldThrow_WhenUserIsNotAdmin()
        {
            // Arrange
            _repoMock.Setup(r => r.FindMemberAsync(1, 10)).ReturnsAsync(new RoomMember { Role = MemberRole.MEMBER });

            // Act & Assert
            Assert.ThrowsAsync<UnauthorizedAccessException>(async () => await _roomService.EnsureAdminAsync(1, 10));
        }
    }
}
