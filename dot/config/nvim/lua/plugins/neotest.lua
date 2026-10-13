return {
  {
    "nvim-neotest/neotest",
    dependencies = {
      "marilari88/neotest-vitest",
    },
    opts = {
      adapters = {
        ["neotest-vitest"] = {
          -- 默认会自动发现项目根目录的 vitest/vite 配置，一般无需改动。
          -- monorepo / 自定义命令示例：
          -- vitestCommand = "npx vitest",
          -- vitestConfigFile = "vitest.config.ts",
          -- env = { CI = true },
        },
      },
    },
  },
}
