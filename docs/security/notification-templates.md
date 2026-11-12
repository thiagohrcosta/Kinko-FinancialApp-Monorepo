# Breach notification templates

Starting points for the notifications in [incident-response.md](incident-response.md) section 6. Fill every
`<placeholder>`, keep the language plain, and get privacy / legal approval before sending. Don't put personal data of
other people in any message.

## To affected users

**Subject:** Important information about your Kinko account

> Hi <first name>,
>
> On <date we became aware>, we found that <what happened, in one or two plain sentences>. It happened between
> <start> and <end>.
>
> **What information was involved:** <categories, e.g. your name, email and transaction history>. <What was not
> involved, e.g. your password and card details were not affected.>
>
> **What we've done:** <containment and fixes>.
>
> **What you can do:** <specific steps, e.g. log out of all devices, watch for emails pretending to be Kinko, review
> your recent transactions>. Kinko will never ask for your password by email or phone.
>
> **Questions:** reply to this email or write to <privacy@ contact>. <EU / UK users: you can also contact your data
> protection authority.>
>
> We're sorry this happened.
>
> <name>, <role>, Kinko

Required content to check:
- GDPR Art. 34: the nature of the breach, a contact point, the likely consequences, the measures taken and proposed
- US state laws: many also require the date or period of the breach, the types of information, and contacts for the
  credit reporting agencies and the FTC when government IDs (SSN) are involved

## To a supervisory authority (EU / UK)

Most authorities have an online form; this is the content it asks for (GDPR Art. 33(3)).

- **Controller:** Kinko, <address>, <contact / representative>
- **When:** became aware at <UTC>; breach period <start> to <end>; if after 72 hours, the reasons for the delay
- **What happened:** <description>
- **Categories and approximate number of people:** <e.g. 1,200 customers in Germany, France and Spain>
- **Categories and approximate number of records:** <e.g. names, emails, transaction history; 45,000 ledger entries>
- **Likely consequences:** <for the people involved>
- **Measures taken or proposed:** <containment, fixes, notifications to people>
- **Contact:** <name, email, phone>

Information that isn't known yet can be sent later, in phases.

## To merchants

**Subject:** Security notice about your Kinko integration

> Hi <merchant name>,
>
> On <date>, we found that <what happened>. Your integration is affected because <reason, e.g. your API key
> kinko_sk_…abcd was exposed>.
>
> **What we've done:** <e.g. revoked all API keys / disabled webhook deliveries / rotated signing secrets>.
>
> **What you need to do:**
> - <e.g. create a new API key in Merchant → API keys & webhooks and update your server>
> - <e.g. rotate your webhook signing secret in the dashboard and update your verification code>
> - <e.g. check your charges between <start> and <end> for anything you don't recognize>
>
> **Your customers:** <whether their data was involved, and whether we'll notify them or you need to>.
>
> Questions: <security@ contact>.

## To a US state attorney general

Each state publishes its own form or address. Usually: a description of the breach, the number of residents
affected, the date of the notice to residents with a copy of it, and the measures taken. California asks for a copy
of the notice sent to residents when more than 500 were notified.

## To the FTC (GLBA Safeguards Rule)

Through the FTC's online form, within 30 days of discovery when 500 or more consumers are involved: our name and
contact, a description of the event, the types of information involved, the date or period, the number of consumers
affected, and whether law enforcement asked to delay public notice.
