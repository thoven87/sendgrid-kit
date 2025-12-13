# ``SendGridKit/SendGridWebhookClient``

## Overview

The `SendGridWebhookClient` provides a comprehensive interface for managing SendGrid Event Webhooks and Inbound Parse Webhooks. This client allows you to create, configure, test, and manage webhooks that receive real-time notifications about email events.

### Basic Setup

```swift
import AsyncHTTPClient
import SendGridKit

let httpClient = HTTPClient(...)
let webhookClient = SendGridWebhookClient(
    httpClient: httpClient, 
    apiKey: "YOUR_API_KEY"
)
```

### Creating an Event Webhook

Event Webhooks notify your application when events occur with your emails, such as when they are delivered, opened, clicked, or bounced.

```swift
import SendGridKit

let webhookInput = EventWebhookInput(
    enabled: true,
    url: "https://your-app.com/webhook/sendgrid",
    groupResubscribe: true,
    delivered: true,
    groupUnsubscribe: true,
    spamReport: true,
    bounce: true,
    deferred: true,
    unsubscribe: true,
    processed: true,
    open: true,
    click: true,
    dropped: true,
    friendlyName: "My App Webhook",
    oauthClientId: nil,
    oauthClientSecret: nil,
    oauthTokenUrl: nil
)

do {
    let webhook = try await webhookClient.createEventWebhook(webhookInput)
    print("Webhook created with ID: \(webhook.id)")
} catch {
    print("Failed to create webhook: \(error)")
}
```

### Managing Event Webhooks

#### Get All Webhooks
```swift
let allWebhooks = try await webhookClient.getAllEventWebhooks(
    includeAccountStatusChange: true
)
print("You have \(allWebhooks.webhooks.count) webhooks configured")
```

#### Get Specific Webhook
```swift
let webhook = try await webhookClient.getEventWebhook(
    id: "webhook-id",
    includeAccountStatusChange: true
)
print("Webhook URL: \(webhook.url)")
```

#### Update Webhook
```swift
let updatedInput = EventWebhookInput(
    enabled: true,
    url: "https://your-app.com/webhook/sendgrid/v2",
    // ... other properties
)

let updatedWebhook = try await webhookClient.updateEventWebhook(
    id: "webhook-id",
    input: updatedInput,
    includeAccountStatusChange: true
)
```

#### Delete Webhook
```swift
try await webhookClient.deleteEventWebhook(id: "webhook-id")
```

### Testing Webhooks

Before going live, you can test your webhook endpoint:

```swift
let testInput = SendGridTestWebhookInput(
    id: "webhook-id",
    url: "https://your-app.com/webhook/test",
    oauthClientId: nil,
    oauthClientSecret: nil,
    oauthTokenUrl: nil
)

do {
    try await webhookClient.testEventWebhook(testInput)
    print("Test webhook sent successfully")
} catch {
    print("Test webhook failed: \(error)")
}
```

### Signature Verification

Enable signature verification for enhanced security:

```swift
// Enable signature verification
let keyResponse = try await webhookClient.toggleEventWebhookSignatureVerification(
    id: "webhook-id",
    enabled: true
)

print("Public key for verification: \(keyResponse.publicKey)")

// Get the current public key
let publicKey = try await webhookClient.getSignedEventWebhookPublicKey(id: "webhook-id")
```

### Inbound Parse Webhooks

The client also supports managing Inbound Parse Webhooks for processing incoming emails:

#### Get Parse Settings
```swift
let parseSettings = try await webhookClient.getParseWebhookSettings()
for setting in parseSettings {
    print("Parse webhook: \(setting.url) for hostname: \(setting.hostname)")
}
```

#### Get Parse Statistics
```swift
let startDate = Date().addingTimeInterval(-86400 * 7) // 7 days ago
let stats = try await webhookClient.getParseWebhookStatistics(
    limit: 100,
    offset: 0,
    aggregatedBy: .day,
    startDate: startDate,
    endDate: Date()
)

for stat in stats {
    print("Date: \(stat.date), Received: \(stat.stats.first?.received ?? 0)")
}
```

### Regional API Support

For EU regional subusers, initialize the client with the `forEU` parameter:

```swift
let webhookClient = SendGridWebhookClient(
    httpClient: httpClient,
    apiKey: "YOUR_API_KEY",
    forEU: true // Uses api.eu.sendgrid.com
)
```

### Error Handling

The webhook client follows the same error handling patterns as other SendGrid clients:

```swift
do {
    let webhook = try await webhookClient.createEventWebhook(webhookInput)
    // Handle success
} catch let error as SendGridError {
    print("SendGrid API error: \(error.errors)")
} catch {
    print("Other error: \(error)")
}
```

## Topics

### Creating and Managing Webhooks
- ``createEventWebhook(_:onbehalfOf:)``
- ``getAllEventWebhooks(includeAccountStatusChange:onbehalfOf:)``
- ``getEventWebhook(id:includeAccountStatusChange:onbehalfOf:)``
- ``updateEventWebhook(id:input:includeAccountStatusChange:onbehalfOf:)``
- ``deleteEventWebhook(id:onbehalfOf:)``

### Testing and Verification
- ``testEventWebhook(_:onbehalfOf:)``
- ``toggleEventWebhookSignatureVerification(id:enabled:onbehalfOf:)``
- ``getSignedEventWebhookPublicKey(id:onbehalfOf:)``

### Inbound Parse Webhooks
- ``getParseWebhookSettings(onbehalfOf:)``
- ``getParseWebhookStatistics(limit:offset:aggregatedBy:startDate:endDate:onbehalfOf:)``
