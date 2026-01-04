---
layout: default
title: Resend Email
---

# Resend Email

Transactional email service for web applications.

## Setup

### 1. Create Account

1. Sign up at [resend.com](https://resend.com)
2. Verify your domain (or use onboarding@resend.dev for testing)
3. Create API key

### 2. Install

```bash
npm install resend
```

### 3. Environment Variables

```bash
# .env.local
RESEND_API_KEY=re_xxxxx
```

## Basic Usage

```typescript
// lib/email.ts
import { Resend } from 'resend';

const resend = new Resend(process.env.RESEND_API_KEY);

export async function sendEmail({
  to,
  subject,
  html,
}: {
  to: string;
  subject: string;
  html: string;
}) {
  const { data, error } = await resend.emails.send({
    from: 'noreply@yourdomain.com',  // Must be verified domain
    to,
    subject,
    html,
  });

  if (error) {
    throw new Error(error.message);
  }

  return data;
}
```

## API Route

```typescript
// app/api/send-email/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { Resend } from 'resend';

const resend = new Resend(process.env.RESEND_API_KEY);

export async function POST(request: NextRequest) {
  const { to, subject, html } = await request.json();

  try {
    const { data, error } = await resend.emails.send({
      from: 'noreply@yourdomain.com',
      to,
      subject,
      html,
    });

    if (error) {
      return NextResponse.json({ error: error.message }, { status: 400 });
    }

    return NextResponse.json({ id: data?.id });
  } catch (error) {
    return NextResponse.json({ error: 'Failed to send email' }, { status: 500 });
  }
}
```

## Email Templates

### Simple HTML Template

```typescript
export function welcomeEmail(name: string) {
  return `
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
    </head>
    <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333;">
      <div style="max-width: 600px; margin: 0 auto; padding: 20px;">
        <h1 style="color: #2563eb;">Welcome, ${name}!</h1>
        <p>Thank you for signing up. We're excited to have you on board.</p>
        <p>
          <a href="https://yourdomain.com/dashboard"
             style="display: inline-block; padding: 12px 24px; background-color: #2563eb; color: white; text-decoration: none; border-radius: 6px;">
            Get Started
          </a>
        </p>
        <p style="color: #666; font-size: 14px; margin-top: 40px;">
          If you have any questions, reply to this email.
        </p>
      </div>
    </body>
    </html>
  `;
}
```

### React Email (Advanced)

```bash
npm install @react-email/components react-email
```

```tsx
// emails/WelcomeEmail.tsx
import {
  Body,
  Button,
  Container,
  Head,
  Heading,
  Html,
  Preview,
  Section,
  Text,
} from '@react-email/components';

interface WelcomeEmailProps {
  name: string;
}

export function WelcomeEmail({ name }: WelcomeEmailProps) {
  return (
    <Html>
      <Head />
      <Preview>Welcome to our platform!</Preview>
      <Body style={main}>
        <Container style={container}>
          <Heading style={h1}>Welcome, {name}!</Heading>
          <Text style={text}>
            Thank you for signing up. We're excited to have you on board.
          </Text>
          <Section style={buttonContainer}>
            <Button style={button} href="https://yourdomain.com/dashboard">
              Get Started
            </Button>
          </Section>
          <Text style={footer}>
            If you have any questions, reply to this email.
          </Text>
        </Container>
      </Body>
    </Html>
  );
}

const main = {
  backgroundColor: '#f6f9fc',
  fontFamily: 'Arial, sans-serif',
};

const container = {
  backgroundColor: '#ffffff',
  margin: '0 auto',
  padding: '40px',
  borderRadius: '8px',
};

const h1 = {
  color: '#1a1a1a',
  fontSize: '24px',
};

const text = {
  color: '#4a4a4a',
  fontSize: '16px',
  lineHeight: '24px',
};

const buttonContainer = {
  textAlign: 'center' as const,
  marginTop: '32px',
};

const button = {
  backgroundColor: '#2563eb',
  borderRadius: '6px',
  color: '#fff',
  fontSize: '16px',
  padding: '12px 24px',
  textDecoration: 'none',
};

const footer = {
  color: '#8898aa',
  fontSize: '14px',
  marginTop: '40px',
};

export default WelcomeEmail;
```

### Using React Email with Resend

```typescript
import { Resend } from 'resend';
import { render } from '@react-email/render';
import WelcomeEmail from '@/emails/WelcomeEmail';

const resend = new Resend(process.env.RESEND_API_KEY);

export async function sendWelcomeEmail(to: string, name: string) {
  const html = render(<WelcomeEmail name={name} />);

  await resend.emails.send({
    from: 'noreply@yourdomain.com',
    to,
    subject: 'Welcome to Our Platform!',
    html,
  });
}
```

## Common Email Types

### Password Reset

```typescript
export async function sendPasswordResetEmail(to: string, resetLink: string) {
  const html = `
    <h1>Reset Your Password</h1>
    <p>Click the link below to reset your password:</p>
    <p>
      <a href="${resetLink}" style="padding: 12px 24px; background: #2563eb; color: white; text-decoration: none; border-radius: 6px;">
        Reset Password
      </a>
    </p>
    <p style="color: #666; font-size: 14px;">
      This link expires in 1 hour. If you didn't request this, ignore this email.
    </p>
  `;

  await resend.emails.send({
    from: 'noreply@yourdomain.com',
    to,
    subject: 'Reset Your Password',
    html,
  });
}
```

### Order Confirmation

```typescript
interface Order {
  id: string;
  items: { name: string; quantity: number; price: number }[];
  total: number;
}

export async function sendOrderConfirmation(to: string, order: Order) {
  const itemsHtml = order.items
    .map(item => `<tr>
      <td>${item.name}</td>
      <td>${item.quantity}</td>
      <td>$${item.price.toFixed(2)}</td>
    </tr>`)
    .join('');

  const html = `
    <h1>Order Confirmed!</h1>
    <p>Order ID: ${order.id}</p>
    <table style="width: 100%; border-collapse: collapse;">
      <thead>
        <tr>
          <th style="text-align: left; border-bottom: 1px solid #ddd; padding: 8px;">Item</th>
          <th style="text-align: left; border-bottom: 1px solid #ddd; padding: 8px;">Qty</th>
          <th style="text-align: left; border-bottom: 1px solid #ddd; padding: 8px;">Price</th>
        </tr>
      </thead>
      <tbody>
        ${itemsHtml}
      </tbody>
    </table>
    <p style="font-size: 18px; font-weight: bold; margin-top: 20px;">
      Total: $${order.total.toFixed(2)}
    </p>
  `;

  await resend.emails.send({
    from: 'orders@yourdomain.com',
    to,
    subject: `Order Confirmed - #${order.id}`,
    html,
  });
}
```

### Newsletter

```typescript
export async function sendNewsletter(
  recipients: string[],
  subject: string,
  content: string
) {
  // Resend supports batch sending
  const emails = recipients.map(to => ({
    from: 'newsletter@yourdomain.com',
    to,
    subject,
    html: `
      <div style="max-width: 600px; margin: 0 auto;">
        ${content}
        <hr style="margin: 40px 0; border: none; border-top: 1px solid #eee;">
        <p style="color: #999; font-size: 12px;">
          <a href="{{unsubscribe_url}}">Unsubscribe</a>
        </p>
      </div>
    `,
  }));

  // Send in batches of 100
  for (let i = 0; i < emails.length; i += 100) {
    const batch = emails.slice(i, i + 100);
    await resend.batch.send(batch);
  }
}
```

## Attachments

```typescript
import { readFileSync } from 'fs';

await resend.emails.send({
  from: 'noreply@yourdomain.com',
  to: 'user@example.com',
  subject: 'Your Report',
  html: '<p>Please find your report attached.</p>',
  attachments: [
    {
      filename: 'report.pdf',
      content: readFileSync('./report.pdf'),
    },
  ],
});
```

## Error Handling

```typescript
import { Resend } from 'resend';

const resend = new Resend(process.env.RESEND_API_KEY);

export async function sendEmailSafe(params: {
  to: string;
  subject: string;
  html: string;
}) {
  try {
    const { data, error } = await resend.emails.send({
      from: 'noreply@yourdomain.com',
      ...params,
    });

    if (error) {
      console.error('Resend error:', error);
      return { success: false, error: error.message };
    }

    return { success: true, id: data?.id };
  } catch (error) {
    console.error('Failed to send email:', error);
    return { success: false, error: 'Failed to send email' };
  }
}
```

## Domain Verification

1. Add domain in Resend dashboard
2. Add DNS records:
   - TXT record for SPF
   - TXT record for DKIM
   - MX record (optional, for replies)

Example DNS records:
```
Type: TXT
Name: @
Value: v=spf1 include:_spf.resend.com ~all

Type: TXT
Name: resend._domainkey
Value: [provided by Resend]
```

## Testing

Use test email for development:
```typescript
const from = process.env.NODE_ENV === 'production'
  ? 'noreply@yourdomain.com'
  : 'onboarding@resend.dev';
```

---

[← Back to Home](../)
