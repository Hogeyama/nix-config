-- nas の承認要求を nvim に取り込む。
--
-- 件数は nas-approval-watch が RPC で set_pending を呼んで渡す。要求の中身と
-- 応答は nas review が持つので、ここは通知と review の起動だけを担う。
local M = {}

local DOMAINS = { "hostexec", "network" }

local counts = { hostexec = 0, network = 0 }
local session_ids = {}

local function notifier_id(domain)
  return "nas-approval-" .. domain
end

--- 保留件数を受け取って通知を更新する。nas-approval-watch から RPC で呼ばれる。
function M.set_pending(domain, session_id, count)
  if counts[domain] == nil then
    return 0
  end
  counts[domain] = count
  session_ids[domain] = session_id
  vim.schedule(function()
    local id = notifier_id(domain)
    if count > 0 then
      Snacks.notifier.notify(
        ("%d pending %s approval%s (<leader>an)"):format(
          count,
          domain,
          count > 1 and "s" or ""
        ),
        "warn",
        { id = id, title = "nas", timeout = false }
      )
    else
      Snacks.notifier.hide(id)
    end
  end)
  return 0
end

local function open_review(domain)
  -- 自分のセッションに絞る。絞らないとそのユーザーの全セッションの要求が出る。
  Snacks.terminal.open(
    { "nas", domain, "review", "--session", session_ids[domain] },
    { win = { position = "float", border = "rounded" } }
  )
end

--- 保留のあるドメインの review を開く。両方にあれば先に選ばせる。
function M.review()
  local pending = {}
  for _, domain in ipairs(DOMAINS) do
    if counts[domain] > 0 then
      table.insert(pending, domain)
    end
  end

  if #pending == 0 then
    vim.notify("nas: no pending approvals", vim.log.levels.INFO)
  elseif #pending == 1 then
    open_review(pending[1])
  else
    vim.ui.select(pending, {
      prompt = "nas approvals",
      format_item = function(domain)
        return ("%s (%d)"):format(domain, counts[domain])
      end,
    }, function(choice)
      if choice then
        open_review(choice)
      end
    end)
  end
end

vim.api.nvim_create_user_command("NasApprovalReview", M.review, {})
vim.keymap.set("n", "<leader>an", M.review, { desc = "nas approval review" })

return M
