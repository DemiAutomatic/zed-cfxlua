# Zed CfxLua

CitizenFX (Cfx) Lua support for [Zed](https://zed.dev). Cfx Lua is the dialect used
by both **FiveM** (GTA V) and **RedM** (RDR2), and the stock Lua grammar chokes on a
lot of it. This extension adds a **CfxLua** language backed by a forked Tree-sitter
grammar that actually understands that syntax. It also bundles `lua-language-server`,
highlights LuaCATS annotations, and pulls in
[fivem-lls-addon](https://github.com/overextended/fivem-lls-addon) on first run for
cfx native type definitions and diagnostics. Framework types like ox stay your call
through `.luarc.json`.

It sits next to the built-in **Lua** extension, so you don't have to uninstall
anything. You just route `.lua` to it per project or globally.

Syntax the stock grammar renders as plain white text, which this handles:

- Compound assignment: `+=`, `-=`, `*=`, `/=`, `^=`, `&=`, `|=`, `<<=`, `>>=`
- Safe navigation: `value?.field`, `value?[key]`
- Backtick hash literals: `` `prop_name` ``
- C-style block comments: `/* ... */`
- Set-constructor shorthand: `{ .a, .b }`
- Local unpacking: `local a, b in t`
- `defer ... end`
- Lua 5.4 attributes: `local x <const>`, `local x <close>`

Grammar lives in [tree-sitter-cfxlua](https://github.com/DemiAutomatic/tree-sitter-cfxlua).
The extension is a fork of [zed-extensions/lua](https://github.com/zed-extensions/lua).

## Install

### From the Zed extension registry

Open `zed: extensions`, search for **CfxLua**, and install it. No toolchain needed;
Zed serves a prebuilt binary.

### As a dev extension (local, or before it hits the registry)

Only this path needs the Rust toolchain, since it compiles the language-server adapter:

```sh
# install Rust first if you don't have it. On Windows: winget install Rustlang.Rustup
rustup default stable
rustup target add wasm32-wasip1
git clone https://github.com/DemiAutomatic/zed-cfxlua
```

Then run `zed: install dev extension` and pick the cloned folder. Restart Zed fully
afterward so it sees `cargo` on PATH and compiles the adapter. The first build takes a
minute or two.

You don't need to set up a `lua-language-server` binary yourself. The extension
downloads and manages it.

Once installed, restart Zed and add the `file_types` route below.

## Route `.lua` to CfxLua

The built-in Lua extension also claims `.lua`, so you have to tell Zed to use
**CfxLua** instead.

Per project is the cleanest option. Stock Lua stays the default everywhere else, and
you opt your FiveM repos in. Add this to the repo's `.zed/settings.json`:

```json
{
  "file_types": { "CfxLua": ["lua", "**/*.lua"] }
}
```

Non-FiveM projects keep using the built-in Lua extension, untouched.

If you'd rather route every `.lua` file everywhere, put the same line in your global
`settings.json`:

```json
"file_types": { "CfxLua": ["lua", "**/*.lua"] }
```

The CfxLua grammar is a superset of standard Lua, so ordinary Lua files still parse
fine under it.

You can also skip `file_types` entirely and pick **CfxLua** from the status-bar
language selector whenever you want it on a single file.

## What you get without any config

On first run the extension grabs the pinned fivem-lls-addon and hands it to
`lua-language-server`, so you don't need a `.luarc.json` to get going:

- `runtime.version` is set to `Lua 5.4`, and `nonstandardSymbol` covers the compound
  operators, backtick hashes, and `/* */`, so none of those get flagged.
- The addon's `plugin.lua` rewrites the rest (`?.`, `?[`, set shorthand,
  `local ... in t`) so they're accepted too.
- The addon's `library` supplies the cfx native type definitions, so natives
  autocomplete.

If you set your own `lsp.cfxlua-language-server` settings or add a project `.luarc.json`,
those win. LuaLS gives `.luarc.json` precedence.

## Framework types (ox and friends)

The bundle only covers cfx natives. For ox (`lib.*`, `Ox.*`, and so on) point a project
`.luarc.json` at its definitions:

```json
{
  "$schema": "https://raw.githubusercontent.com/LuaLS/vscode-lua/master/setting/schema.json",
  "workspace.library": ["~/Dev/lua-addons/ox_types/library"]
}
```

```sh
git clone https://github.com/overextended/ox_types ~/Dev/lua-addons/ox_types
```

One gotcha: setting `workspace.library` in `.luarc.json` **replaces** the bundled cfx
native library rather than adding to it, because LuaLS gives `.luarc.json` precedence.
If you want to keep natives, clone
[fivem-lls-addon](https://github.com/overextended/fivem-lls-addon) too and list its
`library` next to ox.

The [overextended Lua types guide](https://overextended.dev/resources/guides/lua-types)
covers this in more depth.

## Checking it works

Open a `.lua` file and look for:

- The status bar (bottom right) reading **CfxLua**.
- cfx syntax staying highlighted instead of going white: `x += 1`, `a?.b`,
  `` `hash` ``, `local x <close> = ...`.
- `---@param name type` annotations getting colored (LuaCATS via emmyluadoc).
- Completions when you hover a native or type `lib.` (the framework-types step is
  needed for `lib.`).

## Troubleshooting

**Status bar still says "Lua".** The `file_types` route isn't applied. Make sure it's
in the active `settings.json` and restart Zed fully.

**No completions or annotation colors.** `lua-language-server` didn't attach. Restart
Zed; on the first run it downloads LuaLS, so watch the status bar. If it's still off,
check `%LOCALAPPDATA%\Zed\logs\Zed.log`.

**Dev build fails.** Confirm `rustup target add wasm32-wasip1` ran, and that you
launched Zed from a shell where `cargo` is on PATH. Restart Zed after installing Rust.

**Some syntax is still white.** Probably a cfx form the grammar doesn't cover yet. Open
an issue with the snippet; fixes go in
[tree-sitter-cfxlua](https://github.com/DemiAutomatic/tree-sitter-cfxlua).

## License

Apache-2.0. See [`LICENSE`](LICENSE) and [`NOTICE`](NOTICE). The language-server
adapter and several queries are derived from
[zed-extensions/lua](https://github.com/zed-extensions/lua) (Apache-2.0). The
[cfxlua grammar](https://github.com/DemiAutomatic/tree-sitter-cfxlua) is a fork of
[tree-sitter-grammars/tree-sitter-lua](https://github.com/tree-sitter-grammars/tree-sitter-lua)
(MIT).
