# ``SendGridKit/SendGridWebhookEvent``

## Overview

`SendGridWebhookEvent` is the main event type that encompasses all webhook events sent by SendGrid. This enum provides a type-safe way to handle different categories of events, including delivery events, engagement events, account status changes, and received events.

### Event Types

SendGrid webhooks can deliver four main categories of events:

- **Delivery Events**: Status updates about email delivery (bounces, delivered, dropped, etc.)
- **Engagement Events**: User interactions with emails (opens, clicks, unsubscribes, etc.)
- **Account Status Change Events**: Changes to account status or settings
- **Received Events**: Information about emails received via Inbound Parse

### Basic Usage

```swift
import SendGridKit
import Foundation
import NIOFoundationCompat

// Decode webhook events from request body
let jsonData = Data(/* your webhook payload */)
// OR ByteBuffer
// let jsonData = try await response.body.collect(upTo: 1024 * 1024)
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .secondsSince1970

do {
    let events = try decoder.decode([SendGridWebhookEvent].self, from: jsonData)
    
    for event in events {
        switch event {
        case .delivery(let deliveryEvent):
            await handleDeliveryEvent(deliveryEvent)
        case .engagement(let engagementEvent):
            await handleEngagementEvent(engagementEvent)
        case .accountStatusChange(let statusEvent):
            await handleStatusChangeEvent(statusEvent)
        case .received(let receivedEvent):
            await handleReceivedEvent(receivedEvent)
        }
    }
} catch {
    print("Failed to decode webhook events: \(error)")
}
```

### Handling Delivery Events

Delivery events track the status of email delivery and include events like bounces, deferrals, and successful deliveries:

```swift
func handleDeliveryEvent(_ event: SendGridDeliveryEvent) async {
    print("Email to \(event.email) - Event: \(event.event.rawValue)")
    
    switch event.event {
    case .bounce:
        print("Bounce reason: \(event.reason ?? "Unknown")")
        print("Bounce classification: \(event.bounceClassification ?? "Unknown")")
        await markEmailAsBounced(event.email)
        
    case .delivered:
        print("Email successfully delivered")
        await markEmailAsDelivered(event.email)
        
    case .dropped:
        print("Email was dropped. Reason: \(event.reason ?? "Unknown")")
        await handleDroppedEmail(event.email, reason: event.reason)
        
    case .deferred:
        print("Email deferred. Response: \(event.response ?? "Unknown")")
        
    case .processed:
        print("Email processed and ready for delivery")
        
    case .blocked:
        print("Email blocked. Reason: \(event.reason ?? "Unknown")")
        await handleBlockedEmail(event.email)
    }
    
    // Access additional metadata
    if let categories = event.category {
        print("Email categories: \(categories.joined(separator: ", "))")
    }
    
    if let campaignId = event.marketingCampaignID {
        print("Marketing campaign ID: \(campaignId)")
    }
}
```

### Handling Engagement Events

Engagement events track user interactions with your emails:

```swift
func handleEngagementEvent(_ event: SendGridEngagementEvent) async {
    print("Engagement from \(event.email) - Event: \(event.event.rawValue)")
    
    switch event.event {
    case .open:
        print("Email opened")
        if let machineOpen = event.sgMachineOpen, machineOpen {
            print("This was likely a machine/automated open")
        }
        await trackEmailOpen(event.email)
        
    case .click:
        if let url = event.url {
            print("Link clicked: \(url)")
            if let urlOffset = event.urlOffset {
                print("Link position: index \(urlOffset.index), type: \(urlOffset.type)")
            }
        }
        await trackEmailClick(event.email, url: event.url)
        
    case .unsubscribe:
        print("User unsubscribed")
        await processUnsubscribe(event.email)
        
    case .groupUnsubscribe:
        if let groupId = event.asmGroupID {
            print("User unsubscribed from group: \(groupId)")
            await processGroupUnsubscribe(event.email, groupId: groupId)
        }
        
    case .groupResubscribe:
        if let groupId = event.asmGroupID {
            print("User resubscribed to group: \(groupId)")
            await processGroupResubscribe(event.email, groupId: groupId)
        }
        
    case .spamreport:
        print("Email marked as spam")
        await handleSpamReport(event.email)
    }
    
    // Access user agent for opens and clicks
    if let userAgent = event.useragent {
        print("User agent: \(userAgent)")
    }
}
```

### Handling Account Status Changes

Account status change events notify you of changes to your SendGrid account:

```swift
func handleStatusChangeEvent(_ event: SendGridAccountStatusChangeEvent) async {
    print("Account status change: \(event.event)")
    
    switch event.type {
    case .accountDeactivated:
        print("Account has been deactivated")
        await handleAccountDeactivation()
        
    case .accountReactivated:
        print("Account has been reactivated")
        await handleAccountReactivation()
        
    case .accountUnderReview:
        print("Account is under review")
        await notifyAccountReview()
    }
}
```

### Handling Received Events (Inbound Parse)

Received events are generated when emails are sent to your Inbound Parse webhook:

```swift
func handleReceivedEvent(_ event: SendGridReceivedEvent) async {
    print("Received email with message ID: \(event.recvMsgID)")
    
    if let recipientCount = event.recipientCount {
        print("Recipients: \(recipientCount)")
    }
    
    if let size = event.size {
        print("Email size: \(size) bytes")
    }
    
    // Access API payload details if available
    if let payload = event.v3PayloadDetails {
        print("Email content details:")
        if let textPlain = payload.textPlain {
            print("  Plain text characters: \(textPlain)")
        }
        if let textHtml = payload.textHtml {
            print("  HTML characters: \(textHtml)")
        }
        if let attachmentsBytes = payload.attachmentsBytes {
            print("  Attachments size: \(attachmentsBytes) bytes")
        }
    }
    
    await processInboundEmail(event)
}
```

### Working with Custom Arguments

Many webhook events include custom arguments that were passed when sending the email:

```swift
func processCustomArguments(_ event: SendGridDeliveryEvent) {
    guard let uniqueArgs = event.uniqueArgs else {
        print("No custom arguments found")
        return
    }
    
    for (key, value) in uniqueArgs {
        print("Custom argument \(key): \(value)")
    }
    
    // Example: Track user ID from custom arguments
    if let userId = uniqueArgs["user_id"] {
        print("Event for user: \(userId)")
    }
    
    // Example: Track campaign from custom arguments
    if let campaign = uniqueArgs["campaign"] {
        print("Campaign: \(campaign)")
    }
}
```

### Event Filtering and Processing

You can filter and process events based on their properties:

```swift
func processWebhookEvents(_ events: [SendGridWebhookEvent]) async {
    // Filter delivery events
    let deliveryEvents = events.compactMap { event in
        if case .delivery(let delivery) = event {
            return delivery
        }
        return nil
    }
    
    // Process bounces separately
    let bounces = deliveryEvents.filter { $0.event == .bounce }
    for bounce in bounces {
        await handleBounce(bounce)
    }
    
    // Filter engagement events for a specific campaign
    let campaignEngagements = events.compactMap { event -> SendGridEngagementEvent? in
        if case .engagement(let engagement) = event,
           engagement.marketingCampaignID == 12345 {
            return engagement
        }
        return nil
    }
    
    print("Campaign 12345 had \(campaignEngagements.count) engagement events")
}
```

### Best Practices

1. **Handle All Event Types**: Always include a default case or handle all enum cases to future-proof your code
2. **Use Timestamps**: Event timestamps help you understand the timing and sequence of events
3. **Check for Optional Fields**: Many event properties are optional, so always check for nil values
4. **Process Asynchronously**: Webhook processing should be fast; consider queuing heavy operations
5. **Implement Idempotency**: Use event IDs (`sgEventID`) to prevent duplicate processing

### Integration Example

Here's a complete example of a webhook handler:

```swift
import SendGridKit
import Foundation
import NIOFoundationCompat

class WebhookProcessor {
    func processWebhook(buffer: ByteBuffer) async throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        
        let events = try decoder.decode([SendGridWebhookEvent].self, from: buffer)
        
        for event in events {
            await processEvent(event)
        }
    }
    
    private func processEvent(_ event: SendGridWebhookEvent) async {
        // Log all events
        await logEvent(event)
        
        switch event {
        case .delivery(let delivery):
            await updateEmailStatus(delivery)
            
        case .engagement(let engagement):
            await trackUserEngagement(engagement)
            
        case .accountStatusChange(let status):
            await handleAccountChange(status)
            
        case .received(let received):
            await processInboundMail(received)
        }
    }
    
    private func logEvent(_ event: SendGridWebhookEvent) async {
        let eventType = switch event {
        case .delivery(let e): "delivery:\(e.event.rawValue)"
        case .engagement(let e): "engagement:\(e.event.rawValue)"
        case .accountStatusChange(let e): "status:\(e.event)"
        case .received(let e): "received:\(e.event)"
        }
        
        print("[\(Date())] Webhook event: \(eventType)")
    }
}
```

## Topics

### Event Types
- ``SendGridDeliveryEvent``
- ``SendGridEngagementEvent`` 
- ``SendGridAccountStatusChangeEvent``
- ``SendGridReceivedEvent``

### Shared Components
- ``EventType``
- ``Pool``
- ``Newsletter``

### Signature Verification
- ``verifySignature(payload:signature:timestamp:publicKey:tolerance:)``
