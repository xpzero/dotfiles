return {
  {
    "folke/sidekick.nvim",
    keys = {
      -- Example of a keybinding to open Claude directly
      {
        "<leader>ao",
        function()
          require("sidekick.cli").toggle({ name = "opencode", focus = true })
        end,
        desc = "Sidekick Toggle opencode",
      },
    },
  },
}
