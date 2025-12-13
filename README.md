<div align="center">
    <img src="https://avatars.githubusercontent.com/u/26165732?s=200&v=4" width="100" height="100" alt="avatar" />
    <h1>SendGridKit</h1>
    <a href="https://swiftpackageindex.com/vapor-community/sendgrid-kit/documentation">
        <img src="https://design.vapor.codes/images/readthedocs.svg" alt="Documentation">
    </a>
    <a href="https://discord.gg/vapor"><img src="https://design.vapor.codes/images/discordchat.svg" alt="Team Chat"></a>
    <a href="LICENSE"><img src="https://design.vapor.codes/images/mitlicense.svg" alt="MIT License"></a>
    <a href="https://github.com/vapor-community/sendgrid-kit/actions/workflows/test.yml">
        <img src="https://img.shields.io/github/actions/workflow/status/vapor-community/sendgrid-kit/test.yml?event=push&style=plastic&logo=github&label=tests&logoColor=%23ccc" alt="Continuous Integration">
    </a>
    <a href="https://codecov.io/github/vapor-community/sendgrid-kit">
        <img src="https://img.shields.io/codecov/c/github/vapor-community/sendgrid-kit?style=plastic&logo=codecov&label=codecov">
    </a>
    <a href="https://swift.org">
        <img src="https://design.vapor.codes/images/swift60up.svg" alt="Swift 6.0+">
    </a>
</div>
<br>

📧 SendGridKit is a Swift package that helps you communicate with the SendGrid API in your Server Side Swift applications.

Send simple emails or leverage the full capabilities of [SendGrid's V3 API](https://www.twilio.com/docs/sendgrid/api-reference/mail-send/mail-send).

### Getting Started

Use the SPM string to easily include the dependendency in your `Package.swift` file

```swift
.package(url: "https://github.com/vapor-community/sendgrid-kit.git", from: "3.1.0"),
```

and add it to your target's dependencies:

```swift
.product(name: "SendGridKit", package: "sendgrid-kit"),
```

## Overview

Register the config and the provider.

```swift
import AsyncHTTPClient
import SendGridKit

let httpClient = HTTPClient(...)
let sendGridClient = SendGridClient(httpClient: httpClient, apiKey: "YOUR_API_KEY")
```

### Using the API

You can use all of the available parameters here to build your `SendGridEmail`.

Usage in a route closure would be as followed:

```swift
import SendGridKit

let email = SendGridEmail(...)
try await sendGridClient.send(email: email)
```

### Error handling

If the request to the API failed for any reason a `SendGridError` is thrown, which has an `errors` property that contains an array of errors returned by the API.

Simply ensure you catch errors thrown like any other throwing function.

```swift
import SendGridKit

do {
    try await sendGridClient.send(email: email)
} catch let error as SendGridError {
    print(error)
}
```

### Email Validation API

SendGridKit supports SendGrid's [Email Address Validation API](https://www.twilio.com/docs/sendgrid/ui/managing-contacts/email-address-validation), which provides detailed information on the validity of email addresses.

```swift
import SendGridKit

let sendGridClient = SendGridEmailValidationClient(httpClient: .shared, apiKey: "YOUR_API_KEY")

// Create a validation request
let validationRequest = EmailValidationRequest(email: "example@email.com")

// Validate the email
do {
    let validationResponse = try await sendGridClient.validateEmail(validationRequest)
    
    // Check if the email is valid
    if validationResponse.result?.verdict == .valid {
        print("Email is valid with score: \(validationResponse.result?.score)")
    } else {
        print("Email is invalid")
    }
    
    // Access detailed validation information
    if validationResponse.result?.checks?.domain?.isSuspectedDisposableAddress ?? true {
        print("Warning: This is probably a disposable email address")
    }
    
    if validationResponse.result?.checks?.localPart?.isSuspectedRoleAddress {
        print("Note: This is a role-based email address")
    }
} catch {
    print("Validation failed: \(error)")
}
```

#### Bulk Email Validation API

For validating multiple email addresses at once, SendGridKit provides access to SendGrid's Bulk Email Address Validation API. This requires uploading a CSV file with email addresses:

```swift
import SendGridKit
import Foundation

let sendGridClient = SendGridEmailValidationClient(httpClient: .shared, apiKey: "YOUR_API_KEY")

do {
    // Step 1: Create a CSV file with email addresses
    let csvContent = """
        emails
        user1@example.com
        user2@example.com
        user3@example.com
        """
    guard let csvData = csvContent.data(using: .utf8) else {
        throw SomeError.invalidCSV
    }

    // Step 2: Upload the CSV file
    let fileUpload = try await sendGridClient.uploadBulkEmailValidationFile(
        fileData: csvData,
        fileType: .csv
    )
    
    guard fileUpload.succeeded, let jobID = fileUpload.jobID else {
        throw SomeError.uploadError
    }
    
    // Step 4: Check job status (poll until completed)
    var jobStatus = try await sendGridClient.checkBulkEmailValidationJob(by: jobID)
    
    while jobStatus.status != .done {
        print("Job \(jobStatus.id) status: \(jobStatus.status) - \(jobStatus.segmentsProcessed)/\(jobStatus.segments) segments processed")
        
        // Wait before checking again (implement your own backoff strategy)
        try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
        
        jobStatus = try await sendGridClient.checkBulkEmailValidationJob(by: jobID)
    }
} catch {
    print("Bulk validation failed: \(error)")
}
```

### Webhook Event Processing

SendGridKit provides comprehensive support for processing SendGrid webhook events, which notify you about email delivery status and recipient engagement in real-time.

#### Webhook Event Types

SendGridKit supports all SendGrid webhook event types:

**Delivery Events:**
- `bounce` - Email bounced due to invalid address or delivery issues
- `delivered` - Email successfully delivered to recipient's inbox  
- `deferred` - Delivery temporarily delayed, will retry later
- `dropped` - Email dropped due to various reasons (bounced address, spam, etc.)
- `processed` - Email processed and ready for delivery
- `blocked` - Email blocked due to various reasons

**Engagement Events:**
- `click` - Recipient clicked a link in the email
- `open` - Recipient opened the email
- `spamreport` - Recipient marked email as spam
- `unsubscribe` - Recipient unsubscribed from emails
- `group_resubscribe` - Recipient resubscribed to a specific group
- `group_unsubscribe` - Recipient unsubscribed from a specific group

**Account Status Events:**
- `account_status_change` - Account status changed for compliance reasons

#### Processing Webhook Events

```swift
import SendGridKit
import Foundation

// Parse a single webhook event from JSON
let webhookData = """
    {
        "email": "user@example.com",
        "timestamp": 1513299569,
        "event": "delivered",
        "sg_event_id": "unique-event-id",
        "sg_message_id": "unique-message-id",
        "response": "250 OK"
    }
    """.data(using: .utf8)!

let event = try JSONDecoder().decode(SendGridWebhookEvent.self, from: webhookData)

switch event {
case .delivery(let deliveryEvent):
    print("Email \(deliveryEvent.event) to: \(deliveryEvent.email)")
    if deliveryEvent.event == .bounce {
        print("Bounce reason: \(deliveryEvent.reason ?? "Unknown")")
    }
    
case .engagement(let engagementEvent):
    print("User \(engagementEvent.event): \(engagementEvent.email)")
    if engagementEvent.event == .click, let url = engagementEvent.url {
        print("Clicked URL: \(url)")
    }
    
case .accountStatusChange(let statusEvent):
    print("Account status changed: \(statusEvent.type)")
}

// Parse multiple events from webhook payload (typical webhook format)
let eventsData = """
    [
        {"email": "user1@example.com", "event": "delivered", "timestamp": 1513299569, "sg_event_id": "event1", "sg_message_id": "msg1"},
        {"email": "user2@example.com", "event": "open", "timestamp": 1513299570, "sg_event_id": "event2", "sg_message_id": "msg2"}
    ]
    """.data(using: .utf8)!

let events = try JSONDecoder().decode([SendGridWebhookEvent].self, from: eventsData)

// Filter events by type
let deliveryEvents = events.compactMap { event in
    if case .delivery(let deliveryEvent) = event {
        return deliveryEvent
    }
    return nil
}

let engagementEvents = events.compactMap { event in
    if case .engagement(let engagementEvent) = event {
        return engagementEvent  
    }
    return nil
}
```

#### Working with Custom Arguments

SendGrid allows you to include custom arguments with your emails, which are then included in webhook events:

```swift
// Webhook event with custom arguments
let eventWithCustomArgs = """
    {
        "email": "customer@example.com",
        "timestamp": 1513299569,
        "event": "click",
        "sg_event_id": "click-event-123",
        "sg_message_id": "message-123",
        "url": "https://shop.example.com/product/123",
        "unique_args": {
            "user_id": "12345",
            "product_id": "PROD-123",
            "campaign_type": "abandoned_cart",
            "is_premium": "true"
        }
    }
    """.data(using: .utf8)!

let webhookEvent = try JSONDecoder().decode(SendGridWebhookEvent.self, from: eventWithCustomArgs)

if case .engagement(let event) = webhookEvent {
    // Extract custom arguments - all values are strings as per SendGrid documentation
    if let uniqueArgs = event.uniqueArgs {
        let userId = uniqueArgs["user_id"]
        let productId = uniqueArgs["product_id"]
        let isPremium = uniqueArgs["is_premium"] == "true"
        
        print("User \(userId ?? "unknown") clicked product \(productId ?? "unknown")")
        print("Premium user: \(isPremium)")
    }
}
```

#### Webhook Signature Verification

SendGrid webhooks can be secured using ECDSA signature verification to ensure the authenticity of incoming webhook requests:

```swift
import SendGridKit
import Vapor

// In your webhook handler (e.g., Vapor route handler)
func handleWebhook(_ req: Request) async throws -> HTTPStatus {
    // Extract headers
    guard let signature = req.headers.first(name: "X-Twilio-Email-Event-Webhook-Signature"),
          let timestamp = req.headers.first(name: "X-Twilio-Email-Event-Webhook-Timestamp") else {
        throw Abort(.badRequest, reason: "Missing signature headers")
    }
    
    // Get the raw body as ByteBuffer
    let body = req.bodyData
    // Your public key from SendGrid (base64 encoded)
    let publicKey = "YOUR_SENDGRID_PUBLIC_KEY"
    
    // Verify the signature
    do {
        try SendGridWebhookEvent.verifySignature(
            payload: body,
            signature: signature,
            timestamp: timestamp,
            publicKey: publicKey,
            tolerance: 300 // 5 minutes tolerance
        )
    } catch SendGridWebhookSignatureError.timestampNotTolerated {
        throw Abort(.badRequest, reason: "Webhook timestamp too old")
    } catch SendGridWebhookSignatureError.noMatchingSignatureFound {
        throw Abort(.unauthorized, reason: "Invalid webhook signature")
    } catch {
        throw Abort(.badRequest, reason: "Webhook verification failed")
    }
    
    // Parse and process the webhook events
    let events = try JSONDecoder().decode([SendGridWebhookEvent].self, from: body)
    
    for event in events {
        // Process each event...
    }
    
    return .ok
}
```

**Getting your SendGrid public key:**
1. Go to SendGrid Dashboard → Settings → Mail Settings
2. Find "Signed Event Webhook Requests" 
3. Generate or retrieve your verification key
4. Use the base64-encoded public key in your verification code

**Security considerations:**
- Always verify signatures before processing webhook data
- Use appropriate timestamp tolerance (default 300 seconds)
- Store your public key securely (environment variables, etc.)
- Consider rate limiting your webhook endpoints
- Log signature verification failures for monitoring
