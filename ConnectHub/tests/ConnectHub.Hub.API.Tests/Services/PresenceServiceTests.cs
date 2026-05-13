using ConnectHub.Hub.API.Services;
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
