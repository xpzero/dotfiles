local M = {}

local function env(key, default)
  return vim.env[key] or default
end

M.opts = {
  adapters = {
    kimi = function()
      return require("codecompanion.adapters").extend("openai", {
        name = "kimi",
        env = {
          api_key = env("MOONSHOT_API_KEY"),
        },
        url = "https://api.moonshot.cn/v1/chat/completions", -- ✅ 干净 URL
        schema = {
          model = {
            default = "kimi-k2-turbo-preview",
          },
        },
      })
    end,
  },

  strategies = {
    chat = { adapter = "kimi" },
    inline = { adapter = "kimi" },
  },
}

return M.opts
