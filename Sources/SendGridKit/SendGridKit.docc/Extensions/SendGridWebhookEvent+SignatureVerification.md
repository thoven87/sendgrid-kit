# ``SendGridKit/SendGridWebhookEvent``

## Signature Verification

SendGrid signs webhook payloads using ECDSA with the P-256 curve and SHA-256 hash function. The `SendGridWebhookEvent` extension provides signature verification functionality to ensure webhook authenticity and prevent replay attacks.

### Overview

Webhook signature verification is a critical security feature that allows you to verify that incoming webhook requests are actually from SendGrid and haven't been tampered with. SendGrid includes two headers in webhook requests:

- `X-Twilio-Email-Event-Webhook-Signature`: The ECDSA signature (base64 encoded)
- `X-Twilio-Email-Event-Webhook-Timestamp`: The Unix timestamp when the request was sent

### Custom Tolerance

By default, the verification allows for a 300-second (5-minute) tolerance to account for clock drift and network delays. You can customize this:

```swift
// Allow 10-minute tolerance
try SendGridWebhookEvent.verifySignature(
    payload: payload,
    signature: signature,
    timestamp: timestamp,
    publicKey: publicKey,
    tolerance: 600 // 10 minutes
)

// Disable timestamp checking (not recommended for production)
try SendGridWebhookEvent.verifySignature(
    payload: payload,
    signature: signature,
    timestamp: timestamp,
    publicKey: publicKey,
    tolerance: 0 // Disables timestamp validation
)
```

### Integration with Web Frameworks

#### Vapor Integration

```swift
import Vapor
import SendGridKit

func webhookHandler(req: Request) async throws -> HTTPStatus {
    guard let signature = req.headers.first(name:"X-Twilio-Email-Event-Webhook-Signature"),
          let timestamp = req.headers.first(name:"X-Twilio-Email-Event-Webhook-Timestamp") else {
        throw Abort(.badRequest, reason: "Missing signature headers")
    }
    
    let publicKey = Environment.get("SENDGRID_WEBHOOK_PUBLIC_KEY") ?? ""
    
    do {
        try SendGridWebhookEvent.verifySignature(
            payload: req.bodyData,
            signature: signature,
            timestamp: timestamp,
            publicKey: publicKey
        )
        
        // Parse and process the webhook events
        let events = try req.content.decode([SendGridWebhookEvent].self)
        
        for event in events {
            switch event {
            case .delivery(let deliveryEvent):
                await processDeliveryEvent(deliveryEvent)
            case .engagement(let engagementEvent):
                await processEngagementEvent(engagementEvent)
            case .accountStatusChange(let statusEvent):
                await processStatusChangeEvent(statusEvent)
            case .received(let receivedEvent):
                await processReceivedEvent(receivedEvent)
            }
        }
        
        return .ok
        
    } catch {
        req.logger.error("Webhook signature verification failed: \(error)")
        throw Abort(.unauthorized, reason: "Invalid signature")
    }
}
```

#### Hummingbird Integration

```swift
import Hummingbird
import SendGridKit

let env = try await Environment().merging(with: .dotEnv("some.env"))

func webhookHandler(request: Request) async throws -> HTTPResponse.Status {
    guard let signature = req.headers.first(where: { $0.name.rawName == "X-Twilio-Email-Event-Webhook-Signature" })?.value,
          let timestamp = req.headers.first(where: { $0.name.rawName == "X-Twilio-Email-Event-Webhook-Timestamp" })?.value else {
        throw HTTPError(.badRequest, message: "Missing signature headers")
    }
    
    let publicKey = env.get("SENDGRID_WEBHOOK_PUBLIC_KEY") ?? ""
    
    let payload = try await request.body.buffer.collect(upTo: 1024 * 1024)
    
    do {
        try SendGridWebhookEvent.verifySignature(
            payload: payload,
            signature: signature,
            timestamp: timestamp,
            publicKey: publicKey
        )
        
        // Process webhook events
        let jsonData = try await request.body.collect(upTo: 1024 * 1024)
        let events = try JSONDecoder().decode([SendGridWebhookEvent].self, from: jsonData)
        
        // Handle events...
        
        return .ok
    } catch {
        request.logger.error("Webhook signature verification failed: \(error)")
        throw HTTPError(.unauthorized, message: "Invalid signature")
    }
}
```

### Getting Your Public Key

You can retrieve your webhook's public key using the `SendGridWebhookClient`:

```swift
let webhookClient = SendGridWebhookClient(httpClient: httpClient, apiKey: "YOUR_API_KEY")

// Enable signature verification and get the public key
let keyResponse = try await webhookClient.toggleEventWebhookSignatureVerification(
    id: "your-webhook-id",
    enabled: true
)

print("Public key: \(keyResponse.publicKey)")

// Or retrieve an existing public key
let existingKey = try await webhookClient.getSignedEventWebhookPublicKey(id: "your-webhook-id")
```

### Error Types

The signature verification can throw the following specific errors:

- ``SendGridWebhookSignatureError/unableToParseHeader``: Invalid header format or encoding
- ``SendGridWebhookSignatureError/noMatchingSignatureFound``: Signature verification failed
- ``SendGridWebhookSignatureError/timestampNotTolerated``: Request timestamp is outside tolerance window
- ``SendGridWebhookSignatureError/invalidPublicKey``: The provided public key is malformed
- ``SendGridWebhookSignatureError/invalidSignature``: The signature data is malformed

### Security Best Practices

1. **Always verify signatures**: Never process webhook requests without signature verification in production
2. **Use appropriate tolerance**: The default 300-second tolerance is recommended for most use cases
3. **Store public keys securely**: Keep your webhook public keys in environment variables or secure configuration
4. **Handle errors gracefully**: Return appropriate HTTP status codes when verification fails
5. **Log verification failures**: Monitor failed verification attempts for potential security issues

### Troubleshooting

Common issues and solutions:

#### Verification Always Fails
- Ensure you're using the correct public key from SendGrid
- Verify that the payload hasn't been modified (no JSON formatting or parsing before verification)
- Check that you're using the raw request body as a ByteBuffer

#### Timestamp Errors
- Verify your server's clock is synchronized
- Consider increasing the tolerance if you have network latency issues
- Check that the timestamp header is being read correctly

#### Invalid Signature Format
- Ensure the signature is base64 encoded
- Verify the signature header name is exactly `X-Twilio-Email-Event-Webhook-Signature`

## Topics

### Signature Verification
- ``verifySignature(payload:signature:timestamp:publicKey:tolerance:)``

### Error Handling
- ``SendGridWebhookSignatureError``
