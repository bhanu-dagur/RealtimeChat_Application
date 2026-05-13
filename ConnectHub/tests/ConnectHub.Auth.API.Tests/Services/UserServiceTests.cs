using ConnectHub.Auth.API.DTOs;
using ConnectHub.Auth.API.Models;
using ConnectHub.Auth.API.Repositories;
using ConnectHub.Auth.API.Services;
using Microsoft.Extensions.Configuration;
using Moq;
using NUnit.Framework;

namespace ConnectHub.Auth.API.Tests.Services
{
    [TestFixture]
    public class UserServiceTests
    {
        private Mock<IUserRepository> _repoMock;
        private Mock<IConfiguration> _configMock;
        private UserService _userService;

        [SetUp]
        public void Setup()
        {
            _repoMock = new Mock<IUserRepository>();
            _configMock = new Mock<IConfiguration>();
            
            // Setup default config for JWT
            _configMock.Setup(c => c["Jwt:Key"]).Returns("a_very_long_secret_key_for_testing_purposes_only_123456");
            _configMock.Setup(c => c["Jwt:Issuer"]).Returns("ConnectHub");
            _configMock.Setup(c => c["Jwt:Audience"]).Returns("ConnectHubUsers");

            _userService = new UserService(_repoMock.Object, _configMock.Object);
        }

        [Test]
        public async Task RegisterAsync_ShouldCreateUser_WhenDetailsAreValid()
        {
            // Arrange
            var dto = new RegisterDto 
            { 
                UserName = "newuser", 
                Email = "new@test.com", 
                Password = "Password123!", 
                DisplayName = "New User" 
            };

            _repoMock.Setup(r => r.ExistsByEmailAsync(dto.Email)).ReturnsAsync(false);
            _repoMock.Setup(r => r.ExistsByUserNameAsync(dto.UserName)).ReturnsAsync(false);
            _repoMock.Setup(r => r.CreateAsync(It.IsAny<User>())).ReturnsAsync(new User 
            { 
                UserId = 1, 
                UserName = dto.UserName, 
                Email = dto.Email, 
                DisplayName = dto.DisplayName 
            });

            // Act
            var result = await _userService.RegisterAsync(dto);

            // Assert
            Assert.That(result.UserName, Is.EqualTo(dto.UserName));
            Assert.That(result.Token, Is.Not.Null);
            _repoMock.Verify(r => r.CreateAsync(It.Is<User>(u => u.UserName == dto.UserName)), Times.Once);
        }

        [Test]
        public void RegisterAsync_ShouldThrowException_WhenEmailExists()
        {
            // Arrange
            var dto = new RegisterDto { Email = "existing@test.com" };
            _repoMock.Setup(r => r.ExistsByEmailAsync(dto.Email)).ReturnsAsync(true);

            // Act & Assert
            Assert.ThrowsAsync<InvalidOperationException>(async () => await _userService.RegisterAsync(dto));
        }

        [Test]
        public async Task LoginAsync_ShouldReturnAuthResponse_WhenCredentialsAreValid()
        {
            // Arrange
            var dto = new LoginDto { Email = "test@test.com", Password = "Password123!" };
            var user = new User 
            { 
                UserId = 1, 
                Email = dto.Email, 
                UserName = "testuser",
                PasswordHash = "" // Will be set below
            };
            // Use same hasher as service to set valid hash
            var hasher = new Microsoft.AspNetCore.Identity.PasswordHasher<User>();
            user.PasswordHash = hasher.HashPassword(user, dto.Password);

            _repoMock.Setup(r => r.FindByEmailAsync(dto.Email)).ReturnsAsync(user);

            // Act
            var result = await _userService.LoginAsync(dto);

            // Assert
            Assert.That(result.UserId, Is.EqualTo(user.UserId));
            Assert.That(result.Token, Is.Not.Null);
            _repoMock.Verify(r => r.UpdateOnlineStatusAsync(user.UserId, true), Times.Once);
        }
    }
}
