using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using UserService.Infrastructure.Data;
using UserService.Modules.Entities;
using UserService.Modules.Interfaces;

namespace UserService.Infrastructure.Repositories
{
    public class UserRepository : IUserRepository
    {
        private readonly UserDbContext _context;

        public UserRepository (UserDbContext context)
        {
            _context = context;
        }
        //----------------------------------------------------------------------------
        public async Task<User?> GetUserById(Guid id)
        {
            return await _context.Users.FindAsync(id);
        }
        //----------------------------------------------------------------------------
        public async Task<User?> GetUserByEmail(string email)
        {
            return await _context.Users.FirstOrDefaultAsync(u => u.Email == email);
        }
        //---------------------------------------------------------------------------
        public async Task<User?> GetUserByVerificationToken(string token)
        {
            return await _context.Users
                .FirstOrDefaultAsync(u => u.EmailVerificationToken == token);
        }
        //---------------------------------------------------------------------------

        public async Task<List<User>> GetAllUsers(int page, int pageSize)
        { 
            return await _context.Users
        .Where(u => u.IsActive)
        .OrderBy(u => u.CreatedAt)
        .Skip((page - 1) * pageSize)
        .Take(pageSize)
        .ToListAsync();
        }
        //---------------------------------------------------------------------------

        public async Task<int> GetTotalCount()
        {
            return await _context.Users.Where(u => u.IsActive).CountAsync();
        }
        //---------------------------------------------------------------------------

        public async Task<User> CreateUser(User user)
        {
            _context.Users.Add(user);
            await _context.SaveChangesAsync();
            return user;
        }
        //---------------------------------------------------------------------------

        public async Task<User> UpdateUser(User user)
        {
            _context.Users.Update(user);
            await _context.SaveChangesAsync();
            return user;
        }
        //---------------------------------------------------------------------------

        public async Task DeleteUser(Guid id)
        {
            var user = await GetUserById(id);
            if (user != null)
            {
                user.IsActive = false; // soft delete
                await _context.SaveChangesAsync();
            }
        }
        //---------------------------------------------------------------------------

        public async Task<User?> GetUserByResetToken(string token)
    => await _context.Users.FirstOrDefaultAsync(u => u.PasswordResetToken == token);

    }
}
