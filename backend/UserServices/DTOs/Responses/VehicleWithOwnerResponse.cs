using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace UserService.Services.DTOs.Responses
{
    public class VehicleWithOwnerResponse
    {

        public VehicleResponse Vehicle { get; set; }
        public OwnerInfoResponse Owner { get; set; }
    }   

        public class OwnerInfoResponse
        {
            public Guid Id { get; set; }
            public string FirstName { get; set; }
            public string LastName { get; set; }
            public string Email { get; set; }
            public string? PhoneNumber { get; set; }
        }
    
}
