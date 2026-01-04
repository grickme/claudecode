# Claude Code Web App Guide

A comprehensive guide for building modern web applications with Claude Code using Google Cloud, Gemini AI, Next.js, and Firebase.

> **By using this guide, you agree to the [Disclaimer](DISCLAIMER.txt).** This guide is provided "as is" without warranty. No support is provided. You are responsible for all cloud costs and security. See full terms in [DISCLAIMER.txt](DISCLAIMER.txt).

---

## First Time Setup (Windows)

### Option A: One-Click Installer (Recommended)

Download and run the PowerShell installer that installs everything automatically:

#### 1. Download the installer
Download [install-dev-tools.ps1](install-dev-tools.ps1)

#### 2. Open the file location
Right click the downloaded file → Show in Folder

#### 3. Run the installer
Right-click the file → **Run with PowerShell** - you may get warnings but you can ignore those

If that does not work you can also start Powershell manually and then copy paste:
```
cd ~\Downloads
Set-ExecutionPolicy Bypass -Scope Process -Force
.\install-dev-tools.ps1
```

#### 4. Wait for installation
The installer will set up: Node.js, Git, Python, Google Cloud SDK, and Claude Code.

#### 5. Open a new terminal
Close the window and open a new terminal via Command Prompt.

---

### Option B: Manual Installation

If you prefer to install each tool manually:

#### 1. Install Node.js
Download and install from: https://nodejs.org/en/download

#### 2. Install Git
Download and install from: https://git-scm.com/download/win

#### 3. Install Python (optional, but you will most likely going to need this)
Download and install from: https://www.python.org/downloads/windows/

#### 4. Install Google Cloud SDK
1. Go to: https://cloud.google.com/sdk/docs/install
2. Click "Windows (64-bit)" to download the installer
3. Run the `.exe` installer and follow the prompts
4. Restart your terminal

#### 5. Install Claude Code
```bash
npm install -g @anthropic-ai/claude-code
```

---

When you installed above via either option A or B, then you can run Claude Code:

#### 6. Run Claude Code
Create a project folder and start Claude:
```bash
mkdir C:\Projects\my-app
cd C:\Projects\my-app
claude
```

First time it runs, Claude will ask for your preferences and login. This only happens once.

---

## Start Building Your App

Once Claude is running, paste this prompt:

```
Help me set up a new web app project following: https://grick.me/getting-started
```

Claude will read the guide and help you:
- Create a project configuration (CLAUDE.md)
- Set up Google Cloud billing and project
- Configure Firestore, Storage, and APIs
- Get API keys (Gemini, Firebase)
- Optionally set up GitHub

---

## Tech Stack

This guide primarily uses:

- **Google Cloud Platform** (Cloud Run, Firestore, GCS, Secret Manager)
- **Google AI** (Gemini, Vertex AI, Embeddings)
- **Next.js 14+** (App Router, API Routes)
- **Firebase Authentication**
- **Tailwind CSS + shadcn/ui**

---

## For Existing Projects

Add this to your project's `.claude/CLAUDE.md`:

```markdown
## Tech Stack
Follow guidelines from: https://grick.me/

Fetch specific guides as needed:
- Infrastructure: https://grick.me/infrastructure/firestore
- AI: https://grick.me/ai/gemini
- Auth: https://grick.me/auth/firebase-auth
```

Or copy a template:
- [Minimal Template](templates/claude-md-minimal.md)
- [Full Template](templates/claude-md-full.md)

---

## Guide Structure

| Section | Topics |
|---------|--------|
| [Getting Started](getting-started.md) | New project setup with Claude |
| [Infrastructure](infrastructure/) | GitHub, GCP, Cloud Run, Firestore, GCS, Secrets |
| [Security](security/) | Protecting secrets, API security, preventing scraping |
| [AI](ai/) | Gemini, Vertex AI, Embeddings |
| [Backend](backend/) | Local dev, Next.js API, PDF Processing/Creation, FastAPI |
| [Frontend](frontend/) | Next.js, Tailwind, shadcn/ui |
| [Auth](auth/) | Firebase Authentication |
| [Email](email/) | Resend, SMTP, IMAP |
| [Troubleshooting](troubleshooting.md) | Common errors and how to fix them |
| [Templates](templates/) | Ready-to-use CLAUDE.md files |

---

## Cost

Free tier includes:
- **Cloud Run**: 2M requests/month
- **Firestore**: 1GB storage, 50K reads/day
- **Cloud Storage**: 5GB
- **Gemini API**: Free tier for development

---

## License

[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) - Attribution: Martin Smit (martinsmit@grick.me)
