# git.zsh dotfiles

This repository holds all my git and GitHub related zsh functions that let me
*blaze* through my workflow.

To use them, simply source all `.zsh` files from this repo in your `.zshrc`. I
do this by keeping this repository as a submodule in my
[dotfiles](https://github.com/jannis-baum/dotfiles.git). If you want to do
this, I recommend using my tool
[`sdf`](https://github.com/jannis-baum/sync-dotfiles.zsh) to manage your
dotfiles and their dependencies.

## Example features

- `gsi`: interactive git status viewer with diff viewer, (un)staging toggles,
  a commit button, and a file reset button
- `ghi`: interactive GitHub issue viewer with button to check out/create branch
  linked to issue, `ghio` to open issue for current branch, `ghir` to rename
  current branch & issue
- `ghpr`: create/open GitHub PR for current branch, automatically adds body text
  to close corresponding issue if applicable
- `gl`: interactive git log viewer with instant rebasing and both a summary and
  detailed diff viewer
- `gco`: interactive git checkout that automatically creates local from remote
  branches and abstracts away the difference between them
- `gpp`: git pull with automatic deletion of remote branches that no longer exist
- automatic copying of corresponding GitHub issue reference as [conventional
  commit](https://www.conventionalcommits.org/en/v1.0.0/) scope when committing
  so you can make your commits show up right in the issue timeline and stay
  super organized
- lots of small aliases & functions to save keystrokes on common commands such
  as opening the remote URL, non-interactive (un)staging & committing, `git
  rebase --continue`, `git stash [pop]`, `git push [-f]`, and many more

Check out the commented `.zsh` files for more detailed info!

## Requirements

To use these all features, you need to have the following tools installed and in
your `$PATH`.

- `git`, of course
- [`fzf`](https://github.com/junegunn/fzf)
- [the GitHub CLI](https://cli.github.com/)
- [ripgrep (`rg`)](https://github.com/BurntSushi/ripgrep)

On top of these, this plugin relies on you having your `$EDITOR` variable set to
whatever command you use to open your text editor. If you use
[si-vim](https://github.com/jannis-baum/si-vim.zsh) for example, you should have
`export EDITOR=siv` in your `.zshenv` file.
