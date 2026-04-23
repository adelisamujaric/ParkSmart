using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using UserService.Modules.Entities;

namespace UserService.Modules.Interfaces
{
    public interface IUserRepository
    {
        Task<User?> GetUserById(Guid id);
        Task<User?> GetUserByEmail(string email);
        Task<List<User>> GetAllUsers(int page, int pageSize);
        Task<User?> GetUserByVerificationToken(string token);
        Task<int> GetTotalCount();
        Task<User> UpdateUser(User user);
        Task DeleteUser(Guid id);
        Task<User?> GetUserByResetToken(string token);
        Task<User> CreateUser(User user);
    }
}
