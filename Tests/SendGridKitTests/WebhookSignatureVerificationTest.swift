import Crypto
import Foundation
import NIO
import NIOFoundationCompat
import SendGridKit
import Testing

@Suite("SendGrid Webhook Signature Verification Tests")
struct WebhookSignatureVerificationTests {

    // Test payload
    let jsonPayload = """
        {
            "email": "test@example.com",
            "timestamp": 1513299569,
            "event": "delivered",
            "sg_event_id": "test-event-id",
            "sg_message_id": "test-message-id"
        }
        """

    // Helper to create test key pair
    func createTestKeyPair() -> (privateKey: P256.Signing.PrivateKey, publicKeyBase64: String) {
        let privateKey = P256.Signing.PrivateKey()
        let publicKey = privateKey.publicKey
        let publicKeyBase64 = publicKey.x963Representation.base64EncodedString()
        return (privateKey, publicKeyBase64)
    }

    @Test("Verify valid ECDSA signature")
    func verifyValidSignature() throws {
        let (testPrivateKey, testPublicKeyBase64) = createTestKeyPair()
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let payloadBuffer = ByteBuffer(string: jsonPayload)

        // Create signature
        let signedPayload = timestamp + jsonPayload
        let signedData = signedPayload.data(using: .utf8)!
        let signature = try testPrivateKey.signature(for: SHA256.hash(data: signedData))
        let signatureBase64 = signature.rawRepresentation.base64EncodedString()

        // Verify signature - should not throw
        #expect(throws: Never.self) {
            try SendGridWebhookEvent.verifySignature(
                payload: payloadBuffer,
                signature: signatureBase64,
                timestamp: timestamp,
                publicKey: testPublicKeyBase64,
                tolerance: 300
            )
        }
    }

    @Test("Reject invalid signature")
    func rejectInvalidSignature() throws {
        let (testPrivateKey, testPublicKeyBase64) = createTestKeyPair()
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let payloadBuffer = ByteBuffer(string: jsonPayload)

        // Create signature with different data
        let wrongData = "wrong data".data(using: .utf8)!
        let signature = try testPrivateKey.signature(for: SHA256.hash(data: wrongData))
        let signatureBase64 = signature.rawRepresentation.base64EncodedString()

        // Verify signature - should throw noMatchingSignatureFound
        #expect(throws: SendGridWebhookSignatureError.noMatchingSignatureFound) {
            try SendGridWebhookEvent.verifySignature(
                payload: payloadBuffer,
                signature: signatureBase64,
                timestamp: timestamp,
                publicKey: testPublicKeyBase64,
                tolerance: 300
            )
        }
    }

    @Test("Reject expired timestamp")
    func rejectExpiredTimestamp() throws {
        let (testPrivateKey, testPublicKeyBase64) = createTestKeyPair()
        // Create timestamp that's 10 minutes old (600 seconds)
        let oldTimestamp = String(Int(Date().timeIntervalSince1970) - 600)
        let payloadBuffer = ByteBuffer(string: jsonPayload)

        // Create valid signature
        let signedPayload = oldTimestamp + jsonPayload
        let signedData = signedPayload.data(using: .utf8)!
        let signature = try testPrivateKey.signature(for: SHA256.hash(data: signedData))
        let signatureBase64 = signature.rawRepresentation.base64EncodedString()

        // Verify with 300 second tolerance - should throw timestampNotTolerated
        #expect(throws: SendGridWebhookSignatureError.timestampNotTolerated) {
            try SendGridWebhookEvent.verifySignature(
                payload: payloadBuffer,
                signature: signatureBase64,
                timestamp: oldTimestamp,
                publicKey: testPublicKeyBase64,
                tolerance: 300
            )
        }
    }

    @Test("Accept timestamp within tolerance")
    func acceptTimestampWithinTolerance() throws {
        let (testPrivateKey, testPublicKeyBase64) = createTestKeyPair()
        // Create timestamp that's 2 minutes old (120 seconds)
        let recentTimestamp = String(Int(Date().timeIntervalSince1970) - 120)
        let payloadBuffer = ByteBuffer(string: jsonPayload)

        // Create valid signature
        let signedPayload = recentTimestamp + jsonPayload
        let signedData = signedPayload.data(using: .utf8)!
        let signature = try testPrivateKey.signature(for: SHA256.hash(data: signedData))
        let signatureBase64 = signature.rawRepresentation.base64EncodedString()

        // Verify with 300 second tolerance - should not throw
        #expect(throws: Never.self) {
            try SendGridWebhookEvent.verifySignature(
                payload: payloadBuffer,
                signature: signatureBase64,
                timestamp: recentTimestamp,
                publicKey: testPublicKeyBase64,
                tolerance: 300
            )
        }
    }

    @Test("Reject invalid base64 signature")
    func rejectInvalidBase64Signature() throws {
        let (_, testPublicKeyBase64) = createTestKeyPair()
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let payloadBuffer = ByteBuffer(string: jsonPayload)
        let invalidSignature = "invalid-base64-signature!"

        // Should throw invalidSignature
        #expect(throws: SendGridWebhookSignatureError.invalidSignature) {
            try SendGridWebhookEvent.verifySignature(
                payload: payloadBuffer,
                signature: invalidSignature,
                timestamp: timestamp,
                publicKey: testPublicKeyBase64,
                tolerance: 300
            )
        }
    }

    @Test("Reject invalid base64 public key")
    func rejectInvalidBase64PublicKey() throws {
        let (testPrivateKey, _) = createTestKeyPair()
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let payloadBuffer = ByteBuffer(string: jsonPayload)
        let invalidPublicKey = "invalid-base64-public-key!"

        // Create valid signature
        let signedPayload = timestamp + jsonPayload
        let signedData = signedPayload.data(using: .utf8)!
        let signature = try testPrivateKey.signature(for: SHA256.hash(data: signedData))
        let signatureBase64 = signature.rawRepresentation.base64EncodedString()

        // Should throw invalidPublicKey
        #expect(throws: SendGridWebhookSignatureError.invalidPublicKey) {
            try SendGridWebhookEvent.verifySignature(
                payload: payloadBuffer,
                signature: signatureBase64,
                timestamp: timestamp,
                publicKey: invalidPublicKey,
                tolerance: 300
            )
        }
    }

    @Test("Reject invalid timestamp format")
    func rejectInvalidTimestampFormat() throws {
        let (testPrivateKey, testPublicKeyBase64) = createTestKeyPair()
        let payloadBuffer = ByteBuffer(string: jsonPayload)
        let invalidTimestamp = "not-a-timestamp"

        // Create valid signature
        let signedPayload = invalidTimestamp + jsonPayload
        let signedData = signedPayload.data(using: .utf8)!
        let signature = try testPrivateKey.signature(for: SHA256.hash(data: signedData))
        let signatureBase64 = signature.rawRepresentation.base64EncodedString()

        // Should throw unableToParseHeader
        #expect(throws: SendGridWebhookSignatureError.unableToParseHeader) {
            try SendGridWebhookEvent.verifySignature(
                payload: payloadBuffer,
                signature: signatureBase64,
                timestamp: invalidTimestamp,
                publicKey: testPublicKeyBase64,
                tolerance: 300
            )
        }
    }

    @Test("Verify with zero tolerance (no timestamp check)")
    func verifyWithZeroTolerance() throws {
        let (testPrivateKey, testPublicKeyBase64) = createTestKeyPair()
        // Create very old timestamp (1 hour old)
        let oldTimestamp = String(Int(Date().timeIntervalSince1970) - 3600)
        let payloadBuffer = ByteBuffer(string: jsonPayload)

        // Create valid signature
        let signedPayload = oldTimestamp + jsonPayload
        let signedData = signedPayload.data(using: .utf8)!
        let signature = try testPrivateKey.signature(for: SHA256.hash(data: signedData))
        let signatureBase64 = signature.rawRepresentation.base64EncodedString()

        // Verify with zero tolerance - should not throw (timestamp check disabled)
        #expect(throws: Never.self) {
            try SendGridWebhookEvent.verifySignature(
                payload: payloadBuffer,
                signature: signatureBase64,
                timestamp: oldTimestamp,
                publicKey: testPublicKeyBase64,
                tolerance: 0
            )
        }
    }

    @Test("Verify with negative tolerance (no timestamp check)")
    func verifyWithNegativeTolerance() throws {
        let (testPrivateKey, testPublicKeyBase64) = createTestKeyPair()
        // Create very old timestamp (1 hour old)
        let oldTimestamp = String(Int(Date().timeIntervalSince1970) - 3600)
        let payloadBuffer = ByteBuffer(string: jsonPayload)

        // Create valid signature
        let signedPayload = oldTimestamp + jsonPayload
        let signedData = signedPayload.data(using: .utf8)!
        let signature = try testPrivateKey.signature(for: SHA256.hash(data: signedData))
        let signatureBase64 = signature.rawRepresentation.base64EncodedString()

        // Verify with negative tolerance - should not throw (timestamp check disabled)
        #expect(throws: Never.self) {
            try SendGridWebhookEvent.verifySignature(
                payload: payloadBuffer,
                signature: signatureBase64,
                timestamp: oldTimestamp,
                publicKey: testPublicKeyBase64,
                tolerance: -1
            )
        }
    }

    @Test("Verify with different public key formats")
    func verifyDifferentPublicKeyFormats() throws {
        let (testPrivateKey, _) = createTestKeyPair()
        let testPublicKey = testPrivateKey.publicKey
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let payloadBuffer = ByteBuffer(string: jsonPayload)

        // Create signature
        let signedPayload = timestamp + jsonPayload
        let signedData = signedPayload.data(using: .utf8)!
        let signature = try testPrivateKey.signature(for: SHA256.hash(data: signedData))
        let signatureBase64 = signature.rawRepresentation.base64EncodedString()

        // Test x963 representation (default)
        let x963PublicKey = testPublicKey.x963Representation.base64EncodedString()
        #expect(throws: Never.self) {
            try SendGridWebhookEvent.verifySignature(
                payload: payloadBuffer,
                signature: signatureBase64,
                timestamp: timestamp,
                publicKey: x963PublicKey,
                tolerance: 300
            )
        }

        // Test DER representation
        let derPublicKey = testPublicKey.derRepresentation.base64EncodedString()
        #expect(throws: Never.self) {
            try SendGridWebhookEvent.verifySignature(
                payload: payloadBuffer,
                signature: signatureBase64,
                timestamp: timestamp,
                publicKey: derPublicKey,
                tolerance: 300
            )
        }
    }
}
