---
layout: default
title: GitHub Setup
---

# GitHub Setup

Create a GitHub account, repository, and configure SSH for Claude Code.

## Create GitHub Account

1. Go to [github.com/signup](https://github.com/signup)
2. Enter email, password, and username
3. Verify your email address
4. Choose Free plan (sufficient for private repos)

## Create a Repository

### Via GitHub Web

1. Go to [github.com/new](https://github.com/new)
2. Enter repository name (e.g., `my-app`)
3. Choose **Private** (recommended) or Public
4. Skip "Initialize with README" if you have existing code
5. Click **Create repository**

### Via GitHub CLI

```bash
# Install GitHub CLI first: https://cli.github.com
gh auth login
gh repo create my-app --private
```

## SSH Key Setup (Required for Claude Code)

SSH keys let Claude Code push/pull without entering passwords.

### 1. Generate SSH Key

```bash
# Generate new SSH key (use your GitHub email)
ssh-keygen -t ed25519 -C "your-email@example.com"

# When prompted for file location, press Enter for default
# When prompted for passphrase, press Enter for no passphrase (easier for automation)
```

Default location: `~/.ssh/id_ed25519`

### 2. Add Key to GitHub

**Option A: Copy manually**
```bash
# Display your public key
cat ~/.ssh/id_ed25519.pub
```
1. Copy the output
2. Go to [github.com/settings/keys](https://github.com/settings/keys)
3. Click **New SSH key**
4. Paste the key, give it a title (e.g., "My Laptop")
5. Click **Add SSH key**

**Option B: Use GitHub CLI**
```bash
gh ssh-key add ~/.ssh/id_ed25519.pub --title "My Laptop"
```

### 3. Test Connection

```bash
ssh -T git@github.com
```

Expected output:
```
Hi username! You've successfully authenticated, but GitHub does not provide shell access.
```

### 4. Configure Git

```bash
git config --global user.name "Your Name"
git config --global user.email "your-email@example.com"
```

## Connect Existing Project to GitHub

```bash
cd /path/to/your/project

# Initialize git (if not already)
git init

# Add all files
git add .

# First commit
git commit -m "Initial commit"

# Add GitHub as remote (use SSH URL)
git remote add origin git@github.com:USERNAME/REPO.git

# Push to GitHub
git push -u origin main
```

## Multiple GitHub Accounts

If you have multiple GitHub accounts (personal + work), use SSH config aliases.

### 1. Generate Second Key

```bash
ssh-keygen -t ed25519 -C "work-email@company.com" -f ~/.ssh/id_ed25519_work
```

### 2. Add to Second GitHub Account

Add `~/.ssh/id_ed25519_work.pub` to your work GitHub account.

### 3. Configure SSH Config

Create/edit `~/.ssh/config`:

```
# Personal GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes

# Work GitHub
Host github-work
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_work
    IdentitiesOnly yes
```

### 4. Use Different Hosts

```bash
# Personal repos - use normal URL
git clone git@github.com:personal/repo.git

# Work repos - use alias
git clone git@github-work:company/repo.git
```

## Claude Code Git Workflow

### Initial Setup

Add to your project's `CLAUDE.md`:

```markdown
## Git Configuration
- Repository: git@github.com:USERNAME/REPO.git
- Default branch: main
- Auto-commit: Feature branches only
```

### Common Commands Claude Code Uses

```bash
# Check status
git status

# Stage and commit
git add .
git commit -m "feat: Add new feature"

# Push changes
git push origin main

# Create feature branch
git checkout -b feature/new-feature
git push -u origin feature/new-feature
```

### Recommended Git Workflow

1. **Main branch** - Production-ready code
2. **Feature branches** - `feature/description` for new work
3. **Commit messages** - Use conventional commits:
   - `feat:` - New feature
   - `fix:` - Bug fix
   - `docs:` - Documentation
   - `refactor:` - Code refactoring

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Permission denied (publickey) | SSH key not added to GitHub, or wrong key |
| Repository not found | Check URL, ensure you have access |
| Host key verification failed | Run `ssh-keyscan github.com >> ~/.ssh/known_hosts` |
| Multiple accounts conflict | Use SSH config with host aliases |

### Debug SSH Issues

```bash
# Verbose SSH connection
ssh -vT git@github.com

# List loaded SSH keys
ssh-add -l

# Add key to SSH agent
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

## Windows-Specific Notes

On Windows with Git Bash or WSL:

```bash
# Start SSH agent (Git Bash)
eval $(ssh-agent -s)
ssh-add ~/.ssh/id_ed25519

# Key location on Windows
# Git Bash: /c/Users/USERNAME/.ssh/
# WSL: /home/USERNAME/.ssh/
# Windows path: C:\Users\USERNAME\.ssh\
```

For persistent SSH agent on Windows, add to `~/.bashrc`:
```bash
eval $(ssh-agent -s) > /dev/null 2>&1
ssh-add ~/.ssh/id_ed25519 > /dev/null 2>&1
```

---

[← Back to Infrastructure](./index.md) | [GCP Setup →](./gcp-setup.md)
