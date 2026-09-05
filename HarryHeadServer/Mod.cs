using System.Reflection;
using SPTarkov.DI.Annotations;
using SPTarkov.Server.Core.DI;
using SPTarkov.Server.Core.Models.Spt.Mod;

namespace Manimal.HarryHead.Server;

public record ModMetadata : IModMetadata
{
    public string ModGuid { get; init; } = "com.manimal.harryhead";
    public string Name { get; init; } = "HarryHead";
    public string Author { get; init; } = "Manimal";
    public List<string>? Contributors { get; init; }
    public SemanticVersioning.Version Version { get; init; } =
        new(typeof(ModMetadata).Assembly.GetName().Version!.ToString(3));
    public SemanticVersioning.Range SptVersion { get; init; } = new("~4.1.3");
    public List<string>? Incompatibilities { get; init; }
    public Dictionary<string, SemanticVersioning.Range>? ModDependencies { get; init; } = new()
    {
        { "com.wtt.commonlib", new SemanticVersioning.Range("~3.0.0") },
    };
    public string? Url { get; init; }
    public string License { get; init; } = "MIT";
    public bool HasPrepatcher { get; init; } = false;
}

// Register customization before profiles load, after WTT's Preload initialization.
[Injectable(TypePriority = OnLoadOrder.Preload + 2)]
public sealed class HarryHeadServer(WTTServerCommonLib.WTTServerCommonLib wttCommon) : IOnLoad
{
    public async Task OnLoadAsync(CancellationToken cancellationToken)
    {
        cancellationToken.ThrowIfCancellationRequested();
        // WTT 3.0.0 does not expose a cancellation-token argument here.
        await wttCommon.CustomHeadService.CreateCustomHeads(Assembly.GetExecutingAssembly());
        cancellationToken.ThrowIfCancellationRequested();
    }
}
