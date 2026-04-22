local function journal_path(client, offset)
  local ts = os.time() + ((offset or 0) * 24 * 60 * 60)
  local root = tostring(client:vault_root())
  local year = os.date("%Y", ts)
  local month_folder = os.date("%m %B", ts)
  local filename = string.format("™ %s.md", os.date("%Y-%m-%d", ts))

  return string.format("%s/01 Journals/%s Journals/%s/%s", root, year, month_folder, filename), ts
end

local function journal_template(ts, subtitle)
  local day_number = tostring(tonumber(os.date("%d", ts)))
  local subtitle_line = subtitle ~= "" and string.format("### *%s*", subtitle) or "### * *"

  return {
    "---",
    string.format("date: %s", os.date("%Y-%m-%d", ts)),
    string.format("day: %s", os.date("%A", ts)),
    "tags: [journal]",
    "mood: ",
    "---",
    "",
    string.format("# %s, %s %s, %s", os.date("%A", ts), os.date("%B", ts), day_number, os.date("%Y", ts)),
    subtitle_line,
    "",
    "---",
    "",
    "## Morning",
    "",
    "## Afternoon",
    "",
    "## Evening",
    "",
    "## Night",
    "",
    "---",
    "",
    "## Where This Lands",
    "",
  }
end

local function open_journal(offset)
  local client = require("obsidian").get_client()
  local path, ts = journal_path(client, offset)

  if vim.fn.filereadable(path) == 0 then
    vim.fn.mkdir(vim.fs.dirname(path), "p")
    local subtitle = vim.fn.input("Journal subtitle: ")
    vim.fn.writefile(journal_template(ts, vim.trim(subtitle)), path)
  end

  vim.cmd.edit(vim.fn.fnameescape(path))
end

local function inbox_path(client, title)
  local root = tostring(client:vault_root())
  local stamp = os.date("%Y-%m-%d %H%M")
  local safe_title = vim.trim(title):gsub("[/\\]", "-"):gsub("%s+", " ")

  return string.format("%s/00 Notes/Inbox/™ Idea %s — %s.md", root, stamp, safe_title)
end

local function inbox_template(title, captured_at, seed_text)
  local lines = {
    "---",
    "type: idea",
    string.format("captured: %s", captured_at),
    "tags: [idea, inbox]",
    "status: unprocessed",
    "---",
    "",
    string.format("# %s", title),
    "",
    "## The Spark",
    "",
  }

  if seed_text ~= "" then
    vim.list_extend(lines, vim.split(seed_text, "\n", { plain = true }))
    table.insert(lines, "")
  end

  vim.list_extend(lines, {
    "## Why This Might Matter",
    "",
    "## Adjacent Ideas / Connections",
    "",
    "## Next Move (If Any)",
    "",
    "- [ ] ",
    "",
  })

  return lines
end

local function capture_inbox_idea()
  local client = require("obsidian").get_client()
  local title = vim.trim(vim.fn.input("Idea title: "))

  if title == "" then
    vim.notify("Idea capture cancelled", vim.log.levels.WARN)
    return
  end

  local path = inbox_path(client, title)

  if vim.fn.filereadable(path) == 0 then
    local seed_text = vim.trim(vim.fn.input("Seed text (optional): "))
    local captured_at = os.date("%Y-%m-%d %H:%M")
    vim.fn.mkdir(vim.fs.dirname(path), "p")
    vim.fn.writefile(inbox_template(title, captured_at, seed_text), path)
  end

  vim.cmd.edit(vim.fn.fnameescape(path))
end

return {
  {
    "epwalsh/obsidian.nvim",
    version = "*",
    ft = "markdown",
    cmd = {
      "ObsidianOpen",
      "ObsidianQuickSwitch",
      "ObsidianSearch",
      "ObsidianBacklinks",
      "ObsidianTemplate",
      "ObsidianLinks",
      "ObsidianNew",
      "VaultJournal",
      "VaultInboxCapture",
    },
    keys = {
      {
        "<leader>oo",
        function()
          vim.cmd.ObsidianOpen()
        end,
        desc = "Open In Obsidian",
      },
      {
        "<leader>oq",
        function()
          vim.cmd.ObsidianQuickSwitch()
        end,
        desc = "Quick Switch Note",
      },
      {
        "<leader>os",
        function()
          vim.cmd.ObsidianSearch()
        end,
        desc = "Search Notes",
      },
      {
        "<leader>ob",
        function()
          vim.cmd.ObsidianBacklinks()
        end,
        desc = "Show Backlinks",
      },
      {
        "<leader>ot",
        function()
          vim.cmd.ObsidianTemplate()
        end,
        desc = "Insert Template",
      },
      {
        "<leader>ol",
        function()
          vim.cmd.ObsidianLinks()
        end,
        desc = "Show Note Links",
      },
      {
        "<leader>on",
        function()
          vim.cmd.ObsidianNew()
        end,
        desc = "New Note",
      },
      {
        "<leader>oj",
        function()
          open_journal(0)
        end,
        desc = "Open Today's Journal",
      },
      {
        "<leader>oi",
        function()
          capture_inbox_idea()
        end,
        desc = "Capture Inbox Idea",
      },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope.nvim",
      "hrsh7th/nvim-cmp",
    },
    opts = {
      workspaces = {
        {
          name = "ayaz-os",
          path = "~/Documents/Ayaz OS",
        },
      },
      completion = {
        nvim_cmp = true,
        min_chars = 2,
      },
      preferred_link_style = "wiki",
      new_notes_location = "current_dir",
      disable_frontmatter = true,
      templates = {
        folder = "99 Templates",
        date_format = "%Y-%m-%d",
        time_format = "%H:%M",
      },
      note_id_func = function(title)
        if title and title ~= "" then
          return title:gsub("[/\\]", "-"):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
        end

        return os.date("note-%Y%m%d%H%M%S")
      end,
      picker = {
        name = "telescope.nvim",
      },
      sort_by = "modified",
      sort_reversed = true,
      search_max_lines = 2000,
      open_notes_in = "current",
      follow_url_func = function(url)
        vim.ui.open(url)
      end,
      attachments = {
        img_folder = "00 Notes/Assets",
      },
    },
    config = function(_, opts)
      require("obsidian").setup(opts)

      vim.api.nvim_create_user_command("VaultJournal", function(command_opts)
        local offset = 0

        if command_opts.args ~= "" then
          offset = tonumber(command_opts.args)
          if offset == nil then
            vim.notify("VaultJournal offset must be an integer", vim.log.levels.ERROR)
            return
          end
        end

        open_journal(offset)
      end, {
        nargs = "?",
        desc = "Open a journal note by day offset",
      })

      vim.api.nvim_create_user_command("VaultInboxCapture", function()
        capture_inbox_idea()
      end, {
        desc = "Capture a new idea in the vault inbox",
      })
    end,
  },
}
