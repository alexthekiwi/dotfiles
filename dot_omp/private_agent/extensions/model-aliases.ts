export default function modelAliases(pi) {
  const aliases = {
    sol: "@sol",
    luna: "@luna",
    fable: "@fable",
    composer: "@composer",
    cfast: "@cfast",
    grok: "@grok",
    gfast: "@gfast",
  };

  for (const [name, spec] of Object.entries(aliases)) {
    pi.registerCommand(name, {
      description: `Switch to ${name}`,
      handler: async (_args, ctx) => {
        const model = ctx.models.resolve(spec);
        if (!model) {
          ctx.ui.notify(`Could not resolve ${name} (${spec})`, "error");
          return;
        }
        const ok = await pi.setModel(model);
        if (!ok) {
          ctx.ui.notify(`No credentials for ${name}`, "error");
          return;
        }
        ctx.ui.notify(`${name} → ${model.provider}/${model.id}`, "info");
      },
    });
  }
}
