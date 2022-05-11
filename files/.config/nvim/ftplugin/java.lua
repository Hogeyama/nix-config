local jdtls_install_location = vim.env.HOME .. '/.local/share/nvim/lsp_servers/jdtls'
local jdtls_launcher = vim.fn.glob(jdtls_install_location .. '/plugins/org.eclipse.equinox.launcher_*.jar')
local lombok_jar = jdtls_install_location .. '/lombok.jar'

local bundles = {} -- TODO 環境変数で渡す？
vim.list_extend(bundles, vim.split(vim.fn.glob(vim.env.HOME .. "/repo/git/java-debug/com.microsoft.java.debug.plugin/target/com.microsoft.java.debug.plugin-*.jar"), "\n"))
vim.list_extend(bundles, vim.split(vim.fn.glob(vim.env.HOME .. "/repo/git/vscode-java-test/server/*.jar"), "\n"))
local init_options = { bundles = bundles }

local root_dir = require('jdtls.setup').find_root({'.git', 'mvnw', 'gradlew'})
local project_name = vim.fn.fnamemodify(root_dir, ':p:h:t')
local workspace_dir = '/tmp/jdtls/' .. project_name

local capabilities = vim.g.lsp_default_capabilities

local on_attach = function(client, bufnr)
  vim.g.lsp_default_on_attach(client,bufnr)
  vim.api.nvim_buf_set_keymap(bufnr, 'n', '<C-l>q' , '<cmd>lua require("jdtls.dap").setup_dap_main_class_configs()<CR>', { noremap=true, silent=false })
  require'jdtls'.setup_dap({
    hotcodereplace = 'auto',
    config_overrides = {
      javaExec = vim.env.JAVA_HOME .. '/bin/java',
      vmArgs = vim.env.JAVA_OPTS,
    },
  })
  require'jdtls.setup'.add_commands()
end

local cmd = { vim.env.JAVA11_HOME .. '/bin/java' }
vim.list_extend(cmd, {
  '-Declipse.application=org.eclipse.jdt.ls.core.id1',
  '-Dosgi.bundles.defaultStartLevel=4',
  '-Declipse.product=org.eclipse.jdt.ls.core.product',
  '-Dlog.protocol=true',
  '-Dlog.level=ALL',
  '-Xms1g',
  '--add-modules=ALL-SYSTEM',
  '--add-opens', 'java.base/java.util=ALL-UNNAMED',
  '--add-opens', 'java.base/java.lang=ALL-UNNAMED',
  '-jar', jdtls_launcher,
  '-configuration', jdtls_install_location .. '/config_linux',
  '-data', workspace_dir,
})

local vmargs = {
  -- default
  "-XX:+UseParallelGC",
  "-XX:GCTimeRatio=4",
  "-XX:AdaptiveSizePolicyWeight=90",
  "-Dsun.zip.disableMemoryMapping=true",
  -- custom
  "-Xms512m",
  "-Xmx512m",
  "-XX:+UseG1GC",
  "-XX:+UseStringDeduplication",
  "-javaagent:" .. lombok_jar,
}
vim.list_extend(vmargs, vim.env.JAVA_OPTS and vim.split(vim.env.JAVA_OPTS, " ") or {})
vim.g.tmp = table.concat(vmargs, " ")

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
    jdt = { ls = { vmargs = table.concat(vmargs, " ") } },
    ['jdt.ls.vmargs'] = table.concat(vmargs, " ")
  },
}

require('jdtls').start_or_attach({
  cmd = cmd,
  root_dir = root_dir,
  settings = settings,
  on_attach = on_attach,
  capabilities = capabilities,
  init_options = init_options,
})
