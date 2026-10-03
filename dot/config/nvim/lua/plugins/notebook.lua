-- 根据激活的 venv 找匹配的 Jupyter 内核：先按「内核名 == venv 目录名」匹配，
-- 再按「内核 cmdline 里的 python 是否落在该 venv 内」匹配（目录名叫 .venv 的项目）
function MoltenKernelForVenv(venv)
  if not venv or venv == "" then
    return nil
  end
  venv = venv:gsub("/$", "")
  local cmd = vim.fn.shellescape(vim.g.python3_host_prog) .. " -m jupyter kernelspec list --json"
  local ok, out = pcall(vim.fn.system, cmd)
  if not ok or vim.v.shell_error ~= 0 then
    return nil
  end
  local decoded = vim.json.decode(out)
  local specs = decoded and decoded.kernelspecs
  if not specs then
    return nil
  end
  local basename = venv:match("[^/]+$")
  if specs[basename] then
    return basename
  end
  for name, ks in pairs(specs) do
    local argv = ks.spec and ks.spec.argv
    local py = argv and argv[1]
    if py and py:sub(1, #venv + 1) == venv .. "/" then
      return name
    end
  end
  return nil
end

-- 从当前文件向上找项目 venv（.venv/venv），并匹配已注册的内核
-- 无需手动激活 venv，<leader>mi 即可自动选中项目内核
function MoltenFindProjectKernel(buf)
  local file = vim.api.nvim_buf_get_name(buf or 0)
  if file == "" then
    return nil
  end
  local matches = vim.fs.find({ ".venv", "venv" }, {
    upward = true,
    path = vim.fs.dirname(file),
    limit = 3,
    type = "directory",
  })
  for _, venv in ipairs(matches) do
    if vim.uv.fs_stat(venv .. "/bin/python") then
      local kernel = MoltenKernelForVenv(venv)
      if kernel then
        return kernel, venv
      end
    end
  end
  return nil
end

return {
  {
    "benlubas/molten-nvim",
    build = ":UpdateRemotePlugins",
    init = function()
      vim.g.molten_image_provider = "image.nvim"
      -- 图片只在输出浮窗渲染：内联（virt）模式的图片坐标计算在部分布局下会偏出屏幕
      vim.g.molten_image_location = "float"
      vim.g.molten_output_win_max_height = 24
      vim.g.molten_virt_text_output = true
      vim.g.molten_virt_lines_off_by_1 = true
    end,
    keys = {
      {
        "<leader>mi",
        function()
          if vim.b.molten_attached_kernel then
            vim.notify("Molten: 当前 buffer 已绑定内核 " .. vim.b.molten_attached_kernel)
            return
          end
          local kernel = MoltenKernelForVenv(os.getenv("VIRTUAL_ENV") or os.getenv("CONDA_PREFIX"))
          local source = kernel and "激活的 venv" or nil
          if not kernel then
            kernel, source = MoltenFindProjectKernel()
            source = kernel and ("项目 venv " .. (source or "")) or nil
          end
          if kernel then
            vim.notify("Molten: 使用内核 " .. kernel .. "（" .. (source or "手动") .. "）")
            vim.cmd("MoltenInit " .. kernel)
          else
            -- 未激活 venv 且项目里没有可匹配的 venv：退回手动选择
            vim.cmd("MoltenInit")
          end
        end,
        desc = "Notebook: Initialize Kernel (auto venv match)",
        ft = "python",
      },
      {
        "<leader>ma",
        function()
          vim.fn.MoltenEvaluateRange(1, vim.api.nvim_buf_line_count(0))
        end,
        desc = "Notebook: Run All",
        ft = "python",
      },
      { "<leader>ml", "<cmd>MoltenEvaluateLine<cr>", desc = "Notebook: Run Line", ft = "python" },
      { "<leader>mo", "<cmd>MoltenShowOutput<cr>", desc = "Notebook: Show Output", ft = "python" },
      { "<leader>mh", "<cmd>MoltenHideOutput<cr>", desc = "Notebook: Hide Output", ft = "python" },
      { "<leader>mr", "<cmd>MoltenRestart<cr>", desc = "Notebook: Restart Kernel", ft = "python" },
      { "<leader>mx", "<cmd>MoltenExportOutput<cr>", desc = "Notebook: Export Outputs to .ipynb", ft = "python" },
      {
        "<leader>mv",
        ":<C-u>MoltenEvaluateVisual<cr>gv",
        desc = "Notebook: Run Selection",
        mode = "v",
        ft = "python",
      },
    },
  },
  {
    -- kitty 后端即 kitty 图形协议，WezTerm 兼容实现；图片缩放依赖 brew 的 imagemagick
    "3rd/image.nvim",
    build = false,
    opts = {
      backend = "kitty",
      max_width = 100,
      max_height = 16,
      max_height_window_percentage = math.huge,
      window_overlap_clear_enabled = true,
    },
  },
  {
    -- Jupyter 内核补全，普通模式 <C-x><C-o> 触发 omnifunc
    -- 上游仅支持 nvim-cmp（plugin/ 里硬编码 require("cmp")），迁移 blink.cmp 后停用；
    -- 若上游适配 blink 或迁回 cmp，改回 enabled 即可
    "lkhphuc/jupyter-kernel.nvim",
    enabled = false,
    opts = {},
  },
  {
    "GCBallesteros/jupytext.nvim",
    lazy = false,
    opts = {
      force_ft = "python",
    },
  },
}
