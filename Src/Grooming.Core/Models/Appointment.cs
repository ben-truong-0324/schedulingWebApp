using Google.Cloud.Firestore;

namespace Grooming.Core.Models
{
    [FirestoreData]
    public class Appointment
    {
        [FirestoreDocumentId]
        public required string Id { get; set; }

        [FirestoreProperty]
        public required string TenantId { get; set; }

        [FirestoreProperty]
        public required string PetName { get; set; }

        [FirestoreProperty]
        public required string ServiceType { get; set; }

        [FirestoreProperty]
        public DateTime AppointmentDate { get; set; }
    }
}
