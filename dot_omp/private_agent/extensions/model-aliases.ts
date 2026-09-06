export default function modelAliases(pi) {
  const aliases = {
    sol: { spec: "@sol" },
    luna: { spec: "@luna" },
    astra: { spec: "@astra", thinking: "medium" },
    astrahigh: { spec: "@astrahigh", thinking: "high" },
    astralight: { spec: "@astralight", thinking: "low" },
    fable: { spec: "@fable", anthropicTier: "standard" },
    opus: { spec: "@opus", anthropicTier: "standard" },
    opusfast: { spec: "@opus", anthropicTier: "priority" },
    sonnet: { spec: "@sonnet", anthropicTier: "standard" },
    sonnetfast: { spec: "@sonnet", anthropicTier: "priority" },
    composer: { spec: "@composer" },
    composerfast: { spec: "@composerfast" },
    grok: { spec: "@grok" },
    grokfast: { spec: "@grokfast" },
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
