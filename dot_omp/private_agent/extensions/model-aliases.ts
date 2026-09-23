export default function modelAliases(pi) {
  // Mirrors modelRoles in ~/.omp/agent/config.yml. `thinking` must be explicit:
  // resolving a role does not apply its thinking suffix.
  const aliases = {
    solmedium: { spec: "@solmedium", thinking: "medium" },
    solhigh: { spec: "@solhigh", thinking: "high" },
    lunamax: { spec: "@lunamax", thinking: "max" },
    astralight: { spec: "@astralight", thinking: "low" },
    astramedium: { spec: "@astramedium", thinking: "medium" },
    astrahigh: { spec: "@astrahigh", thinking: "high" },
    astraxhigh: { spec: "@astraxhigh", thinking: "xhigh" },
    astramax: { spec: "@astramax", thinking: "max" },
    fablehigh: { spec: "@fablehigh", thinking: "high", anthropicTier: "standard" },
    opusmedium: { spec: "@opusmedium", thinking: "medium", anthropicTier: "standard" },
    opushigh: { spec: "@opushigh", thinking: "high", anthropicTier: "standard" },
    opusfast: { spec: "@opushigh", thinking: "high", anthropicTier: "priority" },
    sonnethigh: { spec: "@sonnethigh", thinking: "high", anthropicTier: "standard" },
    sonnetfast: { spec: "@sonnethigh", thinking: "high", anthropicTier: "priority" },
  };

  for (const [name, config] of Object.entries(aliases)) {
    pi.registerCommand(name, {
      description: `Switch to ${name}`,
      handler: async (_args, ctx) => {
        const model = ctx.models.resolve(config.spec);
        if (!model) {
          ctx.ui.notify(`Could not resolve ${name} (${config.spec})`, "error");
          return;
        }
        const ok = await pi.setModel(model);
        if (!ok) {
          ctx.ui.notify(`No credentials for ${name}`, "error");
          return;
        }
        if (config.thinking) {
          await pi.setThinkingLevel(config.thinking);
        }
        if (config.anthropicTier) {
          await pi.setServiceTier(
            "anthropic",
            config.anthropicTier === "priority" ? "priority" : undefined,
          );
        }
        const tier = config.anthropicTier === "priority" ? " [fast]" : "";
        const thinking = config.thinking ? ` [${config.thinking}]` : "";
        ctx.ui.notify(
          `${name} → ${model.provider}/${model.id}${thinking}${tier}`,
          "info",
        );
      },
    });
  }
}
