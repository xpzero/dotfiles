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

-- Jupyter 用户内核目录（host python 的 data-dir + /kernels），所有项目的 kernelspec 都注册在这
function MoltenUserKernelDir()
  local cmd = vim.fn.shellescape(vim.g.python3_host_prog) .. " -m jupyter --data-dir"
  local ok, out = pcall(vim.fn.system, cmd)
  if not ok or vim.v.shell_error ~= 0 then
    return nil
  end
  local dir = (out or ""):gsub("%s+$", "")
  if dir == "" then
    return nil
  end
  return dir .. "/kernels"
end

-- venv 里没有 ipykernel 内核起不来；uv 建的 venv 默认没有 pip，优先走 uv 装
function MoltenEnsureIpykernel(py)
  vim.fn.system({ py, "-c", "import ipykernel" })
  if vim.v.shell_error == 0 then
    return true
  end
  vim.notify("Molten: 正在为 " .. py .. " 安装 ipykernel …", vim.log.levels.INFO)
  if vim.fn.executable("uv") == 1 then
    vim.fn.system({ "uv", "pip", "install", "-q", "--python", py, "ipykernel" })
    if vim.v.shell_error == 0 then
      return true
    end
  end
  vim.fn.system({ py, "-m", "pip", "install", "-q", "ipykernel" })
  if vim.v.shell_error == 0 then
    return true
  end
  vim.notify("Molten: 安装 ipykernel 失败，请手动安装后重试", vim.log.levels.ERROR)
  return false
end

-- 给项目 venv 注册 kernelspec，返回内核名。直接写 kernel.json 而不用
-- `ipykernel install --user`：后者的落盘位置取决于 venv 里 jupyter_core 的版本行为，
-- 可能写进 host jupyter 搜不到的目录
function MoltenRegisterVenvKernel(venv)
  venv = venv:gsub("/$", "")
  local py = venv .. "/bin/python"
  if not MoltenEnsureIpykernel(py) then
    return nil
  end
  local kernel_dir = MoltenUserKernelDir()
  if not kernel_dir then
    return nil
  end
  local project = vim.fs.basename(vim.fs.dirname(venv))
  local name = project:gsub("[^%w%-_%.]", "-"):lower()
  if name == "" then
    name = "venv"
  end
  local dir = kernel_dir .. "/" .. name
  -- 同名内核指向别的 venv 时加路径哈希后缀，避免覆盖别的项目
  local f = io.open(dir .. "/kernel.json", "r")
  if f then
    local content = f:read("*a")
    f:close()
    local ok, existing = pcall(vim.json.decode, content)
    local existing_py = ok and existing and existing.argv and existing.argv[1] or nil
    if existing_py and existing_py ~= py then
      name = name .. "-" .. vim.fn.sha256(venv):sub(1, 6)
      dir = kernel_dir .. "/" .. name
    end
  end
  local spec = {
    argv = { py, "-Xfrozen_modules=off", "-m", "ipykernel_launcher", "-f", "{connection_file}" },
    display_name = "Python (" .. project .. ")",
    language = "python",
    interrupt_mode = "signal",
  }
  vim.fn.mkdir(dir, "p")
  if vim.fn.writefile({ vim.json.encode(spec) }, dir .. "/kernel.json") == -1 then
    vim.notify("Molten: 写入 kernelspec 失败: " .. dir, vim.log.levels.ERROR)
    return nil
  end
  return name
end

-- 从当前文件向上找项目 venv（.venv/venv），无需手动激活 venv
function MoltenFindProjectVenv(buf)
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
      return venv
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
      vim.g.molten_wrap_output = true -- 输出超宽自动折行
    end,
    keys = {
      {
        "<leader>mi",
        function()
          if vim.b.molten_attached_kernel then
            vim.notify("Molten: 当前 buffer 已绑定内核 " .. vim.b.molten_attached_kernel)
            return
          end
          local venv = os.getenv("VIRTUAL_ENV") or os.getenv("CONDA_PREFIX") or MoltenFindProjectVenv()
          if venv then
            local kernel = MoltenKernelForVenv(venv)
            local source = "已注册内核"
            if not kernel then
              kernel = MoltenRegisterVenvKernel(venv)
              source = "首次自动注册内核"
            end
            if kernel then
              vim.notify("Molten: 使用内核 " .. kernel .. "（" .. source .. "，" .. venv .. "）")
              vim.cmd("MoltenInit " .. kernel)
              return
            end
          end
          -- 没有 venv 或注册失败：退回手动选择
          vim.cmd("MoltenInit")
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
