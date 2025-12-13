# ``SendGridKit/EventWebhookInput``

## Overview

`EventWebhookInput` defines the configuration structure for creating and updating SendGrid Event Webhooks. This structure allows you to specify which events you want to receive, the destination URL, authentication settings, and other webhook properties.

### Basic Configuration

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
    friendlyName: "Production Webhook",
    oauthClientId: nil,
    oauthClientSecret: nil,
    oauthTokenUrl: nil
)
```

### Event Type Configuration

You can selectively enable or disable specific event types based on your application's needs:

#### Essential Events Only
```swift
let essentialWebhook = EventWebhookInput(
    enabled: true,
    url: "https://your-app.com/webhook/essential",
    groupResubscribe: false,
    delivered: true,      // Track successful deliveries
    groupUnsubscribe: false,
    spamReport: true,     // Important for reputation
    bounce: true,         // Critical for list hygiene
    deferred: false,
    unsubscribe: true,    // Required for compliance
    processed: false,
    open: false,
    click: false,
    dropped: true,        // Important for debugging
    friendlyName: "Essential Events",
    oauthClientId: nil,
    oauthClientSecret: nil,
    oauthTokenUrl: nil
)
```

#### Engagement Tracking Only
```swift
let engagementWebhook = EventWebhookInput(
    enabled: true,
    url: "https://analytics.your-app.com/webhook/engagement",
    groupResubscribe: true,   // Subscription management
    delivered: false,
    groupUnsubscribe: true,   // Subscription management
    spamReport: false,
    bounce: false,
    deferred: false,
    unsubscribe: true,        // Subscription management
    processed: false,
    open: true,              // User engagement
    click: true,             // User engagement
    dropped: false,
    friendlyName: "Engagement Analytics",
    oauthClientId: nil,
    oauthClientSecret: nil,
    oauthTokenUrl: nil
)
```

### OAuth Authentication

For enhanced security, you can configure OAuth authentication for your webhook endpoint:

```swift
let oauthWebhook = EventWebhookInput(
    enabled: true,
    url: "https://secure.your-app.com/webhook/sendgrid",
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
    friendlyName: "Secure OAuth Webhook",
    oauthClientId: "your-oauth-client-id",
    oauthClientSecret: "your-oauth-client-secret",
    oauthTokenUrl: "https://auth.your-app.com/oauth/token"
)
```

### Using with SendGridWebhookClient

#### Creating a New Webhook
```swift
let webhookClient = SendGridWebhookClient(httpClient: httpClient, apiKey: apiKey)

do {
    let webhook = try await webhookClient.createEventWebhook(webhookInput)
    print("Created webhook with ID: \(webhook.id)")
    print("Webhook URL: \(webhook.url)")
    print("Enabled events:")
    
    if webhook.delivered { print("  - Delivered") }
    if webhook.bounce { print("  - Bounce") }
    if webhook.click { print("  - Click") }
    if webhook.open { print("  - Open") }
    // ... other events
    
} catch {
    print("Failed to create webhook: \(error)")
}
```

#### Updating an Existing Webhook
```swift
// Modify the configuration
let updatedInput = EventWebhookInput(
    enabled: true,
    url: "https://new-endpoint.your-app.com/webhook/sendgrid",
    groupResubscribe: webhookInput.groupResubscribe,
    delivered: webhookInput.delivered,
    groupUnsubscribe: webhookInput.groupUnsubscribe,
    spamReport: webhookInput.spamReport,
    bounce: webhookInput.bounce,
    deferred: webhookInput.deferred,
    unsubscribe: webhookInput.unsubscribe,
    processed: webhookInput.processed,
    open: true,  // Enable open tracking
    click: true, // Enable click tracking
    dropped: webhookInput.dropped,
    friendlyName: "Updated Webhook",
    oauthClientId: webhookInput.oauthClientId,
    oauthClientSecret: webhookInput.oauthClientSecret,
    oauthTokenUrl: webhookInput.oauthTokenUrl
)

let updatedWebhook = try await webhookClient.updateEventWebhook(
    id: existingWebhookId,
    input: updatedInput,
    includeAccountStatusChange: true
)
```

### Event Types Explained

#### Delivery Events
- **`delivered`**: Email was successfully delivered to the recipient's mail server
- **`bounce`**: Email bounced (hard or soft bounce)
- **`dropped`**: Email was dropped by SendGrid before delivery
- **`deferred`**: Email delivery was temporarily deferred
- **`processed`**: Email was processed and accepted by SendGrid

#### Engagement Events
- **`open`**: Recipient opened the email (requires open tracking)
- **`click`**: Recipient clicked a link in the email (requires click tracking)
- **`unsubscribe`**: Recipient unsubscribed via the unsubscribe link
- **`groupUnsubscribe`**: Recipient unsubscribed from a specific ASM group
- **`groupResubscribe`**: Recipient resubscribed to a specific ASM group
- **`spamReport`**: Recipient marked the email as spam

### Configuration Best Practices

1. **Start with Essential Events**: Begin with delivery and bounce events, then add others as needed
2. **Consider Your Infrastructure**: Ensure your webhook endpoint can handle the expected volume
3. **Use Friendly Names**: Descriptive names help identify webhooks in the dashboard
4. **Secure Your Endpoints**: Use HTTPS and consider OAuth for sensitive applications
5. **Test Before Going Live**: Use the test webhook functionality before enabling in production

### Common Configuration Patterns

#### E-commerce Application
```swift
let ecommerceWebhook = EventWebhookInput(
    enabled: true,
    url: "https://api.shop.com/webhooks/sendgrid",
    groupResubscribe: true,
    delivered: true,      // Track order confirmations
    groupUnsubscribe: true,
    spamReport: true,     // Reputation management
    bounce: true,         // Clean email lists
    deferred: false,
    unsubscribe: true,    // Customer preference management
    processed: false,
    open: true,          // Marketing analytics
    click: true,         // Track product links
    dropped: true,       // Debug delivery issues
    friendlyName: "E-commerce Events",
    oauthClientId: nil,
    oauthClientSecret: nil,
    oauthTokenUrl: nil
)
```

#### Newsletter/Marketing Platform
```swift
let marketingWebhook = EventWebhookInput(
    enabled: true,
    url: "https://analytics.newsletter.com/webhooks/engagement",
    groupResubscribe: true,   // Subscription management
    delivered: false,         // Not critical for marketing
    groupUnsubscribe: true,   // Subscription management
    spamReport: true,         // Campaign performance
    bounce: true,             // List hygiene
    deferred: false,
    unsubscribe: true,        // Subscription management
    processed: false,
    open: true,              // Engagement metrics
    click: true,             // Content performance
    dropped: false,
    friendlyName: "Marketing Analytics",
    oauthClientId: nil,
    oauthClientSecret: nil,
    oauthTokenUrl: nil
)
```

#### Transactional System
```swift
let transactionalWebhook = EventWebhookInput(
    enabled: true,
    url: "https://app.com/webhooks/transactional",
    groupResubscribe: false,  // Not relevant for transactional
    delivered: true,          // Confirm delivery
    groupUnsubscribe: false,
    spamReport: true,         // Monitor reputation
    bounce: true,             // Critical for user notifications
    deferred: true,           // Monitor delivery delays
    unsubscribe: false,       // Usually not applicable
    processed: true,          // Track acceptance
    open: false,              // Privacy-focused
    click: false,             // Privacy-focused
    dropped: true,            // Critical for debugging
    friendlyName: "Transactional Notifications",
    oauthClientId: nil,
    oauthClientSecret: nil,
    oauthTokenUrl: nil
)
```

## Topics

### Configuration Properties
- ``enabled``
- ``url``
- ``friendlyName``

### Event Types
- ``delivered``
- ``bounce``
- ``dropped``
- ``deferred``
- ``processed``
- ``open``
- ``click``
- ``unsubscribe``
- ``groupUnsubscribe``
- ``groupResubscribe``
- ``spamReport``

### OAuth Configuration
- ``oauthClientId``
- ``oauthClientSecret``
- ``oauthTokenUrl``
