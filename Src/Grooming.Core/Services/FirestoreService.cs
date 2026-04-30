using Google.Cloud.Firestore;
using Grooming.Core.Models;

namespace Grooming.Core.Services
{
    public class FirestoreService
    {
        private readonly FirestoreDb _db;
        private const string CollectionName = "appointments";

        public FirestoreService(string projectId, string databaseId)
        {
            _db = new FirestoreDbBuilder
            {
                ProjectId = projectId,
                DatabaseId = databaseId ?? "(default)"
            }.Build();
        }

        public async Task AddAppointmentAsync(Appointment appointment)
        {
            CollectionReference colRef = _db.Collection(CollectionName);
            await colRef.AddAsync(appointment);
        }

        public async Task<List<Appointment>> GetAppointmentsByTenantAsync(string tenantId)
        {
            Query query = _db.Collection(CollectionName)
                            .WhereEqualTo("TenantId", tenantId)
                            .OrderByDescending("AppointmentDate");

            QuerySnapshot snapshot = await query.GetSnapshotAsync();
            return snapshot.Documents.Select(d => d.ConvertTo<Appointment>()).ToList();
        }

        public async Task<int> GetTenantRecordCountAsync(string tenantId)
        {
            var query = _db.Collection(CollectionName).WhereEqualTo("TenantId", tenantId);
            var snapshot = await query.GetSnapshotAsync();
            return snapshot.Count;
        }

        public async Task WipeTenantDataAsync(string tenantId)
        {
            // Safety: We only allow wiping the dev tenant for now
            if (tenantId != Constants.DevConstants.LocalDevTenantId)
            {
                throw new InvalidOperationException("Wipe operation restricted to development tenants.");
            }

            var collection = _db.Collection(CollectionName);
            var query = collection.WhereEqualTo("TenantId", tenantId);
            var snapshot = await query.GetSnapshotAsync();

            if (snapshot.Count == 0) return;

            var batch = _db.StartBatch();
            foreach (var doc in snapshot.Documents)
            {
                batch.Delete(doc.Reference);
            }

            await batch.CommitAsync();
        }

    }
}