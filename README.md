# MailGun-Emails-HTML-2.code-workspace

## Template placeholders

The `scripts/export_template_tokens.rb` helper inspects `mailgun_mailer.rb` and
the HTML templates to list every placeholder required by each Mailgun email.
Generate the Markdown reference with:

```bash
ruby scripts/export_template_tokens.rb -o docs/template_placeholders.md
```

The generated [`docs/template_placeholders.md`](docs/template_placeholders.md)
file summarises each template along with the variables you must provide when
delivering the email.
