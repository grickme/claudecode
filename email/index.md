---
layout: default
title: Email
---

# Email & Communication

Email services for web applications - transactional email, SMTP sending, and IMAP inbox access.

## Guides

| Guide | Description |
|-------|-------------|
| [Resend](./resend.md) | Transactional email API, templates, attachments |

## SMTP (Sending Email)

Use SMTP when you have email server credentials (host, username, password).

### Setup

```bash
npm install nodemailer
```

### Basic SMTP Sending

```typescript
import nodemailer from 'nodemailer';

const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST,      // e.g., 'smtp.gmail.com'
  port: parseInt(process.env.SMTP_PORT || '587'),
  secure: false,                     // true for 465, false for 587
  auth: {
    user: process.env.SMTP_USER,     // your email
    pass: process.env.SMTP_PASS,     // your password or app password
  },
});

async function sendEmail(to: string, subject: string, html: string) {
  const info = await transporter.sendMail({
    from: process.env.SMTP_FROM || process.env.SMTP_USER,
    to,
    subject,
    html,
  });

  console.log('Message sent:', info.messageId);
  return info;
}

// Usage
await sendEmail(
  'recipient@example.com',
  'Welcome!',
  '<h1>Hello</h1><p>Welcome to our service.</p>'
);
```

### Common SMTP Providers

| Provider | Host | Port | Notes |
|----------|------|------|-------|
| Gmail | `smtp.gmail.com` | 587 | Requires App Password |
| Outlook/Hotmail | `smtp.office365.com` | 587 | |
| Yahoo | `smtp.mail.yahoo.com` | 587 | Requires App Password |
| Custom/Self-hosted | Your server | 587/465 | |

### Gmail App Password

For Gmail, create an App Password:
1. Go to [Google Account Security](https://myaccount.google.com/security)
2. Enable 2-Step Verification
3. Go to App Passwords
4. Generate password for "Mail"
5. Use this password as `SMTP_PASS`

### With Attachments

```typescript
await transporter.sendMail({
  from: process.env.SMTP_FROM,
  to: 'recipient@example.com',
  subject: 'Report attached',
  html: '<p>Please find the report attached.</p>',
  attachments: [
    {
      filename: 'report.pdf',
      content: pdfBuffer,
      contentType: 'application/pdf',
    },
    {
      filename: 'data.csv',
      path: '/path/to/data.csv',  // or use file path
    },
  ],
});
```

## IMAP (Reading Email)

Use IMAP to read emails from an inbox.

### Setup

```bash
npm install imap-simple mailparser
npm install -D @types/imap-simple
```

### Connect and Read Emails

```typescript
import imapSimple from 'imap-simple';
import { simpleParser } from 'mailparser';

const config = {
  imap: {
    user: process.env.IMAP_USER,
    password: process.env.IMAP_PASS,
    host: process.env.IMAP_HOST,     // e.g., 'imap.gmail.com'
    port: 993,
    tls: true,
    authTimeout: 10000,
  },
};

async function readInbox(limit = 10) {
  const connection = await imapSimple.connect(config);

  await connection.openBox('INBOX');

  // Search for unread emails
  const searchCriteria = ['UNSEEN'];
  const fetchOptions = {
    bodies: ['HEADER', 'TEXT', ''],
    markSeen: false,
  };

  const messages = await connection.search(searchCriteria, fetchOptions);

  const emails = [];
  for (const message of messages.slice(0, limit)) {
    const all = message.parts.find(p => p.which === '');
    if (all) {
      const parsed = await simpleParser(all.body);
      emails.push({
        id: message.attributes.uid,
        from: parsed.from?.text,
        subject: parsed.subject,
        date: parsed.date,
        text: parsed.text,
        html: parsed.html,
      });
    }
  }

  connection.end();
  return emails;
}

// Usage
const unreadEmails = await readInbox(5);
console.log(`Found ${unreadEmails.length} unread emails`);
```

### Common IMAP Providers

| Provider | Host | Port |
|----------|------|------|
| Gmail | `imap.gmail.com` | 993 |
| Outlook/Hotmail | `outlook.office365.com` | 993 |
| Yahoo | `imap.mail.yahoo.com` | 993 |

### Search Criteria Examples

```typescript
// Unread emails
const unread = ['UNSEEN'];

// From specific sender
const fromSender = [['FROM', 'sender@example.com']];

// Emails from last 7 days
const recent = [['SINCE', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)]];

// With specific subject
const bySubject = [['SUBJECT', 'Invoice']];

// Combine criteria (AND)
const combined = ['UNSEEN', ['FROM', 'important@example.com']];
```

### Mark as Read / Delete

```typescript
// Mark as read
await connection.addFlags(message.attributes.uid, '\Seen');

// Mark as unread
await connection.delFlags(message.attributes.uid, '\Seen');

// Delete (move to trash)
await connection.addFlags(message.attributes.uid, '\Deleted');
await connection.expunge();
```

## Environment Variables

```bash
# SMTP (Sending)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASS=your-app-password
SMTP_FROM="Your Name <your-email@gmail.com>"

# IMAP (Reading)
IMAP_HOST=imap.gmail.com
IMAP_USER=your-email@gmail.com
IMAP_PASS=your-app-password
```

## When to Use What

| Need | Solution |
|------|----------|
| Send transactional email (high volume) | [Resend](./resend.md) |
| Send email with existing credentials | SMTP (Nodemailer) |
| Read incoming emails | IMAP |
| Webhook on incoming email | Resend Inbound |

---

[← Back to Home](../)
