--------------------------------------------------------------------------------
-- opt
--------------------------------------------------------------------------------

vim.opt_local.tabstop = 4
vim.opt_local.shiftwidth = 4
vim.opt_local.softtabstop = 4

--------------------------------------------------------------------------------
-- LSP/DAPサーバーのパス解決
--------------------------------------------------------------------------------

local jdtls_bin = vim.env.HOME .. "/.local/share/nvim/mason/bin/jdtls"

local mason_root = vim.env.HOME .. "/.local/share/nvim/mason/packages"
local jdtls_root = mason_root .. '/jdtls'
local java_debug_adapter_root = mason_root .. '/java-debug-adapter'
local java_test_root = mason_root .. '/java-test'

local jdtls_jar = vim.fn.glob(jdtls_root .. '/plugins/org.eclipse.equinox.launcher_*.jar')
local lombok_jar = jdtls_root .. '/lombok.jar'

local bundles = {}
vim.list_extend(bundles,
  vim.split(
    vim.fn.glob(java_debug_adapter_root .. "/extension/server/com.microsoft.java.debug.plugin-*.jar"),
    "\n"
  )
)
vim.list_extend(bundles,
  vim.split(
    vim.fn.glob(java_test_root .. "/extension/server/*.jar"),
    "\n"
  )
)

--------------------------------------------------------------------------------
-- LSPの設定
--------------------------------------------------------------------------------

local init_options = { bundles = bundles }

local root_dir = require('jdtls.setup').find_root({ '.git', 'mvnw', 'gradlew' })

local project_name = vim.fn.fnamemodify(root_dir, ':p:h:t')

local workspace_dir = '/tmp/jdtls/' .. project_name

local capabilities = vim.g.lsp_default_capabilities

local on_attach = function(client, bufnr)
  vim.g.lsp_default_on_attach(client, bufnr)
  require 'jdtls'.setup_dap({
    hotcodereplace = 'auto',
    config_overrides = {
      javaExec = vim.env.JAVA17_HOME .. '/bin/java',
      vmArgs = vim.env.JAVA_OPTS,
    },
  })
  require 'jdtls.setup'.add_commands()
  -- mapping
  local bnmap = function(lhs, rhs)
    vim.keymap.set('n', lhs, rhs, {
      nowait = true,
      noremap = true,
      silent = true,
      buffer = bufnr,
    })
  end
  bnmap('<C-l>q', '<Cmd>lua require("jdtls.dap").setup_dap_main_class_configs()<CR>')
  bnmap('<F5>', '<Cmd>lua require("dap").continue()<CR>')
  bnmap('<F10>', '<Cmd>lua require("dap").step_over()<CR>')
  bnmap('<F11>', '<Cmd>lua require("dap").step_into()<CR>')
  bnmap('<F12>', '<Cmd>lua require("dap").step_out()<CR>')
  bnmap('<Leader>b', '<Cmd>lua require("dap").toggle_breakpoint()<CR>')
  bnmap('<Leader>B', '<Cmd>lua require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))<CR>')
  bnmap('<Leader>lp', '<Cmd>lua require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: "))<CR>')
  bnmap('<Leader>dr', '<Cmd>lua require("dap").repl.open()<CR>')
  bnmap('<Leader>dl', '<Cmd>lua require("dap").run_last()<CR>')
  bnmap('<Leader>du', '<Cmd>lua require("dapui").toggle()<CR>')
  bnmap('<Leader>df', '<Cmd>lua require("jdtls").test_class()<CR>')
  bnmap('<Leader>dn', '<Cmd>lua require("jdtls").test_nearest_method()<CR>')
  bnmap('<Leader>oi', '<Cmd>lua require("jdtls").organize_imports()<CR>')
end

local settings = {
  java = {
    home = vim.env.JAVA_HOME,
    configuration = {
      runtimes = {
        {
          name = "JavaSE-17",
          path = vim.env.JAVA17_HOME,
        },
        {
          name = "JavaSE-11",
          path = vim.env.JAVA11_HOME,
        },
        {
          default = true,
          name = "JavaSE-1.8",
          path = vim.env.JAVA8_HOME,
        },
      },
    },
    signatureHelp = { enabled = true },
    import = { gradle = { enabled = true } },
  },
}

local vmargs = {
  -- default
  "-XX:GCTimeRatio=4",
  "-XX:AdaptiveSizePolicyWeight=90",
  "-Dsun.zip.disableMemoryMapping=true",
  "-Djdk.attach.allowAttachSelf=true",
  -- custom
  "-Xms512m",
  "-Xmx512m",
  "-XX:+UseG1GC",
  "-XX:+UseStringDeduplication",
  -- "-javaagent:" .. lombok_jar,
  "-javaagent:" ..
      vim.env.HOME ..
      "/.gradle/caches/modules-2/files-2.1/org.jmockit/jmockit/1.34/fb816db2cdb251ebaa4349c6934905939ea1c0e7/jmockit-1.34.jar",
}
vim.list_extend(vmargs, vim.env.JAVA_OPTS and vim.split(vim.env.JAVA_OPTS, " ") or {})

-- jdtls.py requires that JAVA_HOME is pointed to java>=17
local cmd = {}
vim.list_extend(cmd, { "env" })
vim.list_extend(cmd, { "JAVA_HOME=" .. vim.env.JAVA17_HOME })
vim.list_extend(cmd, { jdtls_bin })
vim.list_extend(cmd, { "-data", workspace_dir })
vim.list_extend(cmd, vim.tbl_map(
  function(a) return "--jvm-arg=" .. a end,
  (vim.tbl_filter(function(a) return a ~= "" end, vmargs))
)
)

require('jdtls').start_or_attach({
  cmd = cmd,
  root_dir = root_dir,
  settings = settings,
  on_attach = on_attach,
  capabilities = capabilities,
  init_options = init_options,
})
