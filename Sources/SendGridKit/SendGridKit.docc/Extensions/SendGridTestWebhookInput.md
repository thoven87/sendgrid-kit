# ``SendGridKit/SendGridTestWebhookInput``

## Overview

`SendGridTestWebhookInput` is used to configure test webhook requests through the SendGrid API. This allows you to validate your webhook endpoint configuration before going live by sending sample webhook events to your specified URL.

### Basic Usage

```swift
import SendGridKit

let testInput = SendGridTestWebhookInput(
    id: "webhook-id-to-test",
    url: "https://your-app.com/webhook/test",
    oauthClientId: nil,
    oauthClientSecret: nil,
    oauthTokenUrl: nil
)

let webhookClient = SendGridWebhookClient(httpClient: httpClient, apiKey: apiKey)

do {
    try await webhookClient.testEventWebhook(testInput)
    print("Test webhook sent successfully")
} catch {
    print("Test webhook failed: \(error)")
}
```

### Testing Different Endpoints

You can test different URLs without modifying your actual webhook configuration:

```swift
// Test your staging endpoint
let stagingTest = SendGridTestWebhookInput(
    id: "your-webhook-id",
    url: "https://staging.your-app.com/webhook/sendgrid",
    oauthClientId: nil,
    oauthClientSecret: nil,
    oauthTokenUrl: nil
)

try await webhookClient.testEventWebhook(stagingTest)

// Test your local development endpoint
let localTest = SendGridTestWebhookInput(
    id: "your-webhook-id",
    url: "https://ngrok-tunnel.ngrok.io/webhook/sendgrid",
    oauthClientId: nil,
    oauthClientSecret: nil,
    oauthTokenUrl: nil
)

try await webhookClient.testEventWebhook(localTest)
```

### OAuth Testing

When your webhook uses OAuth authentication, you can test the OAuth flow:

```swift
let oauthTest = SendGridTestWebhookInput(
    id: "your-webhook-id",
    url: "https://your-app.com/webhook/sendgrid",
    oauthClientId: "test-client-id",
    oauthClientSecret: "test-client-secret",
    oauthTokenUrl: "https://auth.your-app.com/oauth/token"
)

do {
    try await webhookClient.testEventWebhook(oauthTest)
    print("OAuth webhook test successful")
} catch {
    print("OAuth webhook test failed: \(error)")
    // Check your OAuth configuration
}
```

### Integration with Development Workflow

#### Local Development with ngrok

```swift
import SendGridKit

class WebhookTester {
    let webhookClient: SendGridWebhookClient
    
    init(httpClient: HTTPClient, apiKey: String) {
        self.webhookClient = SendGridWebhookClient(httpClient: httpClient, apiKey: apiKey)
    }
    
    func testLocalWebhook(webhookId: String, ngrokUrl: String) async throws {
        let testInput = SendGridTestWebhookInput(
            id: webhookId,
            url: "\(ngrokUrl)/webhook/sendgrid",
            oauthClientId: nil,
            oauthClientSecret: nil,
            oauthTokenUrl: nil
        )
        
        print("Testing webhook against local endpoint: \(testInput.url)")
        
        try await webhookClient.testEventWebhook(testInput)
        
        print("✅ Test webhook sent successfully!")
        print("Check your local server logs for the test event.")
    }
}

// Usage
let tester = WebhookTester(httpClient: httpClient, apiKey: apiKey)
try await tester.testLocalWebhook(
    webhookId: "your-webhook-id",
    ngrokUrl: "https://abc123.ngrok.io"
)
```

#### Automated Testing

```swift
import SendGridKit
import Foundation

class WebhookEndpointValidator {
    let webhookClient: SendGridWebhookClient
    
    init(httpClient: HTTPClient, apiKey: String) {
        self.webhookClient = SendGridWebhookClient(httpClient: httpClient, apiKey: apiKey)
    }
    
    func validateEndpoints(_ endpoints: [String], webhookId: String) async {
        for endpoint in endpoints {
            print("Testing endpoint: \(endpoint)")
            
            let testInput = SendGridTestWebhookInput(
                id: webhookId,
                url: endpoint,
                oauthClientId: nil,
                oauthClientSecret: nil,
                oauthTokenUrl: nil
            )
            
            do {
                try await webhookClient.testEventWebhook(testInput)
                print("✅ \(endpoint) - Test successful")
            } catch {
                print("❌ \(endpoint) - Test failed: \(error)")
            }
            
            // Wait between tests to avoid rate limiting
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        }
    }
}

// Usage
let validator = WebhookEndpointValidator(httpClient: httpClient, apiKey: apiKey)
let testEndpoints = [
    "https://staging.your-app.com/webhook/sendgrid",
    "https://dev.your-app.com/webhook/sendgrid",
    "https://test-branch.your-app.com/webhook/sendgrid"
]

await validator.validateEndpoints(testEndpoints, webhookId: "your-webhook-id")
```

### What to Expect from Test Webhooks

When you send a test webhook, SendGrid will deliver sample webhook events to your specified URL. The test payload typically includes:

- Sample delivery events (delivered, bounce, etc.)
- Sample engagement events (open, click, etc.)
- Realistic but fake email addresses and data
- Current timestamps

Example of handling test webhooks in your endpoint:

```swift
import Vapor
import SendGridKit

func webhookHandler(req: Request) async throws -> HTTPStatus {
    let events = try req.content.decode([SendGridWebhookEvent].self)
    
    for event in events {
        switch event {
        case .delivery(let deliveryEvent):
            print("Test delivery event: \(deliveryEvent.event.rawValue) for \(deliveryEvent.email)")
            
        case .engagement(let engagementEvent):
            print("Test engagement event: \(engagementEvent.event.rawValue) for \(engagementEvent.email)")
            
        default:
            print("Other test event received")
        }
    }
    
    return .ok
}
```

### Testing Best Practices

1. **Test Before Production**: Always test your webhook endpoint before enabling it for live traffic
2. **Validate Response Handling**: Ensure your endpoint correctly processes all event types
3. **Check Error Handling**: Verify your endpoint handles malformed or unexpected payloads gracefully
4. **Test OAuth Flow**: If using OAuth, test the authentication flow thoroughly
5. **Monitor Response Times**: Ensure your endpoint responds quickly (within 10 seconds)
6. **Test Idempotency**: Verify your system handles duplicate events correctly

### Troubleshooting Test Webhooks

#### Common Issues

**Timeout Errors**
```swift
// Your webhook endpoint should respond quickly
func webhookHandler(req: Request) async throws -> HTTPStatus {
    // Process events asynchronously if needed
    let events = try req.content.decode([SendGridWebhookEvent].self)
    
    // Queue for background processing instead of processing synchronously
    await eventQueue.enqueue(events)
    
    // Respond immediately
    return .ok
}
```

**SSL/TLS Issues**
```swift
// Ensure your test URL uses HTTPS
let testInput = SendGridTestWebhookInput(
    id: "webhook-id",
    url: "https://your-app.com/webhook", // ✅ HTTPS
    // url: "http://your-app.com/webhook", // ❌ HTTP not allowed
    oauthClientId: nil,
    oauthClientSecret: nil,
    oauthTokenUrl: nil
)
```

**OAuth Configuration Issues**
```swift
// Verify OAuth settings match your server configuration
let oauthTest = SendGridTestWebhookInput(
    id: "webhook-id",
    url: "https://your-app.com/webhook",
    oauthClientId: "correct-client-id",        // Must match server
    oauthClientSecret: "correct-client-secret", // Must match server
    oauthTokenUrl: "https://auth.your-app.com/oauth/token" // Must be accessible
)
```

#### Debugging Failed Tests

```swift
func debugWebhookTest(webhookId: String, testUrl: String) async {
    let testInput = SendGridTestWebhookInput(
        id: webhookId,
        url: testUrl,
        oauthClientId: nil,
        oauthClientSecret: nil,
        oauthTokenUrl: nil
    )
    
    do {
        try await webhookClient.testEventWebhook(testInput)
        print("✅ Test successful")
    } catch let error as SendGridError {
        print("❌ SendGrid API Error:")
        for apiError in error.errors {
            print("  - \(apiError.message)")
            if let field = apiError.field {
                print("    Field: \(field)")
            }
        }
    } catch {
        print("❌ Network or other error: \(error)")
    }
}
```

## Topics

### Configuration
- ``id``
- ``url``

### OAuth Configuration  
- ``oauthClientId``
- ``oauthClientSecret``
- ``oauthTokenUrl``

### Related Types
- ``SendGridWebhookClient/testEventWebhook(_:onbehalfOf:)``
