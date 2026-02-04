# Git Rebase Interactive

## Overview

`git rebase --interactive` (or `git rebase -i`) allows you to rewrite commit history interactively. It enables you to clean up, reorganize, and modify/edit commits before pushing them to a shared repository.

## Key Features

### Interactive Mode
When you run `git rebase -i`, Git opens an editor with a list of commits you're about to rebase. Each commit has an action associated with it that you can modify.

### Common Actions

- **pick (p)**: Use the commit as-is
- **reword (r)**: Use the commit, but edit the commit message
- **edit (e)**: Use the commit, but stop for amending
- **squash (s)**: Use the commit, but meld into the previous commit
- **fixup (f)**: Like squash, but discard this commit's log message
- **drop (d)**: Remove the commit from history
- **exec (x)**: Run shell command

## Basic Usage

```bash
# Start interactive rebase for the last N commits
git rebase -i HEAD~N
```

## Common Use Cases

### 1. Squashing Commits
Combine multiple commits into one for a cleaner history.

```bash
git rebase -i HEAD~3

or

git rebase -i <commit-hash>
```

### 2. Reordering Commits
Rearrange the order of commits by moving lines in the editor.

### 3. Editing Commit Messages
Use `reword` to fix typos or improve clarity in commit messages.

### 4. Removing Commits
Use `drop` to eliminate commits from the history.

### 5. Splitting Commits
Use `edit` to stop at a commit and break it into multiple smaller commits.

## Important Notes

- **Never rebase public commits**: Only rebase commits that haven't been pushed or are on your own branch
- **Use with caution**: Rewriting history can cause conflicts with team members
- **Abort if needed**: Use `git rebase --abort` to cancel a rebase in progress
- **Conflicts**: If conflicts arise during rebase, resolve them and use `git rebase --continue`

## Safety Tips

1. Create a backup branch before rebasing complex histories
2. Test the rebase locally before pushing
3. Communicate with your team about rebasing shared work
4. Use `--force-with-lease` instead of `--force` when pushing after rebase

## Example Workflow:

### Scenario
You're working on the `feature/login` branch with 6 commits. You need to edit the 3rd commit before pushing to remote.

### Step-by-Step

**1. Check your current branch and commits**
```bash
git log --oneline

# a1f5d8c (HEAD -> feature/login) Add login error handling
# b2c6e9d Add password validation
# c3d7f0e Add username field validation  # <- This is the 3rd commit we want to edit
# d4e8g1f Add login form layout
# e5f9h2g Add authentication service
# f6g0i3h Initial login component
```

**2. Start interactive rebase for the last 6 commits**
```bash
git rebase -i HEAD~6

or

git rebase -i f6g0i3h
```

**3. The editor opens showing all 6 commits**
```
pick f6g0i3h Initial login component
pick e5f9h2g Add authentication service
pick d4e8g1f Add login form layout
pick c3d7f0e Add username field validation
pick b2c6e9d Add password validation
pick a1f5d8c Add login error handling
```

**4. Change `pick` to `edit` for the 3rd commit**

**Change to edit in VIM:**
- Move cursor into the commit we want to change/edit.
- Press `i` to enter `insert` mode.
- Change the 3rd commit from `pick` to `edit`.

```
pick f6g0i3h Initial login component
pick e5f9h2g Add authentication service
pick d4e8g1f Add login form layout
edit c3d7f0e Add username field validation  # <- Changed from "pick" to "edit"
pick b2c6e9d Add password validation
pick a1f5d8c Add login error handling
```

**Save and exit VIM:**
- Press `Escape` to ensure you're in command mode
- Type `:wq` (write and quit)
- Press `Enter` to confirm and exit the editor

**5. Save and exit the editor**
Git stops at the 3rd commit, allowing you to make changes:
```
Stopped at c3d7f0e... Add username field validation
You can amend the commit now, with
  git commit --amend
Follow up with
  git rebase --continue
```

**6. Make your changes to the files**

**7. Stage your changes**
```bash
git add .
```

**8. Amend the commit**
```bash
git commit --amend --no-edit
# Use --no-edit to keep the original commit message
# Or omit --no-edit to change the message as well
```

**9. Continue the rebase**
```bash
git rebase --continue
```

**10. If conflicts occur with subsequent commits**
```bash
# Resolve conflicts in your editor
git add .
git rebase --continue
```

**11. Once rebase is complete, push to remote**
```bash
git push origin feature/login --force-with-lease
```

### Result
Your `feature/login` branch now has an updated 3rd commit with your changes, and all subsequent commits are replayed on top with a clean history.
