using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;
using Grooming.Core.Services;
using Grooming.Core.Constants;

namespace GroomingWebApp.Pages.Dev;

public class ProbeModel(FirestoreService firestoreService) : PageModel
{
    public string TenantId => DevConstants.LocalDevTenantId;
    public int RecordCount { get; set; }

    public async Task OnGetAsync()
    {
        RecordCount = await firestoreService.GetTenantRecordCountAsync(TenantId);
    }

    public async Task<IActionResult> OnPostWipeAsync()
    {
        await firestoreService.WipeTenantDataAsync(TenantId);
        return RedirectToPage();
    }
}