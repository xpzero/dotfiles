local M = {}

local function env(key, default)
  return vim.env[key] or default
end

M.opts = {
  adapters = {
    kimi = function()
      return require("codecompanion.adapters").extend("openai", {
        name = "kimi",
        formatted_name = "Moonshot",
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
    qinghua = function()
      return require("codecompanion.adapters").extend("openai", {
        name = "qinghua",
        formatted_name = "QH",
        env = {
          api_key = env("QH_API_KEY"),
        },
        url = "https://open.bigmodel.cn/api/paas/v4/chat/completions",
        schema = {
          model = {
            default = "glm-4.5",
          },
        },
      })
    end,
  },
  extensions = {
    mcphub = {
      callback = "mcphub.extensions.codecompanion",
      opts = {
        -- MCP Tools
        make_tools = true, -- Make individual tools (@server__tool) and server groups (@server) from MCP servers
        show_server_tools_in_chat = true, -- Show individual tools in chat completion (when make_tools=true)
        add_mcp_prefix_to_tool_names = false, -- Add mcp__ prefix (e.g `@mcp__github`, `@mcp__neovim__list_issues`)
        show_result_in_chat = true, -- Show tool results directly in chat buffer
        format_tool = nil, -- function(tool_name:string, tool: CodeCompanion.Agent.Tool) : string Function to format tool names to show in the chat buffer
        -- MCP Resources
        make_vars = true, -- Convert MCP resources to #variables for prompts
        -- MCP Prompts
        make_slash_commands = true, -- Add MCP prompts as /slash commands
      },
    },
  },
  strategies = {
    chat = { adapter = "qinghua" },
    inline = { adapter = "qinghua" },
  },
  prompt_library = {
    auto_greet = {
      strategy = "chat",
      description = "Write documentation for me",
      opts = {
        is_slash_cmd = false,
        auto_submit = true,
        short_name = "greet",
      },
      prompts = {
        {
          role = "user",
          content = [[
您是一位资深前端开发专家，精通 ReactJS、NextJS、JavaScript、TypeScript、HTML、CSS 和现代 UI/UX 框架（如 TailwindCSS、Shadcn、Radix）。您思维缜密，能提供细致入微的解答，并擅长逻辑推理。您会谨慎地给出准确、事实性且深思熟虑的答案，在推理方面堪称天才。

- 严格遵循用户需求: 完全按照用户的要求执行。
- 分步思考: 先用伪代码详细描述实现计划，逐步拆解。
- 确认后再编码: 确保逻辑无误后再编写实际代码。
- 代码质量: 
  - 遵循最佳实践和 DRY 原则（避免重复），确保代码无 bug、功能完整且符合以下《代码实现准则》。
  - 优先代码可读性，而非过度优化性能。
  - 完整实现所有功能，不留待办项（TODO）或缺失部分。
  - 彻底验证代码完整性。
  - 包含所有必要的导入，关键组件命名规范。
- 简洁性: 减少无关描述，保持回答简明。
- 诚实原则: 若问题无明确答案或您不确定，直接说明，不猜测。
- 不需要伪代码让我确认，直接执行你的决策，不要分步骤询问。
- 总是用中文返回的答案
- 如果linter error，只处理1次，如果没有解决就跳过

开发环境
用户提问涉及以下技术栈：
- ReactJS
- NextJS
- JavaScript
- TypeScript
- HTML
- CSS
- Sass

代码实现准则
编写代码时需遵守以下规则：
- 提前返回: 尽可能使用 early returns 提升可读性。
- 样式规范: 
  - 仅使用 Sass 类（禁用原生 CSS 或标签样式）。
  - 类名赋值优先用 class: 语法，而非三元运算符。
- 命名规范: 
  - 变量、函数/常量需描述性命名（如 userProfile 而非 data）。
  - 事件处理函数以 handle 前缀命名（如 handleClick、handleKeyDown）。
- 无障碍访问: 
  - 元素需包含无障碍属性（如 tabindex="0"、aria-label、on:click、on:keydown）。
- 函数与类型: 
  - 优先使用 const 声明函数（如 const toggle = () => {}）。
  - 尽可能定义类型。

git commit message use 中文
]],
        },
      },
    },
  },
}

return M.opts
