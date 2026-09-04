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

    /// Returns a fresh P-256 key pair with the public key base64-encoded in DER/SPKI format,
    /// matching the format SendGrid uses in the ``SendGridWebhookClient/getSignedEventWebhookPublicKey(id:onbehalfOf:)`` response.
    func createTestKeyPair() -> (privateKey: P256.Signing.PrivateKey, publicKeyBase64: String) {
        let privateKey = P256.Signing.PrivateKey()
        let publicKeyBase64 = privateKey.publicKey.derRepresentation.base64EncodedString()
        return (privateKey, publicKeyBase64)
    }

    // MARK: - Official SendGrid production fixture
    //
    // Taken verbatim from:
    //   https://github.com/sendgrid/sendgrid-python/blob/main/test/unit/test_eventwebhook.py
    //   https://github.com/sendgrid/sendgrid-nodejs/blob/main/packages/eventwebhook/src/eventwebhook.spec.js
    //
    // The signature is a base64-encoded DER/ASN.1 ECDSA P-256 signature of
    // (timestamp + payload) where payload is compact JSON followed by CRLF.

    let sgPublicKey = "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE83T4O/n84iotIvIW4mdBgQ/7dAfSmpqIM8kF9mN1flpVKS3GRqe62gw+2fNNRaINXvVpiglSI8eNEc6wEA3F+g=="
    let sgSignature = "MEUCIGHQVtGj+Y3LkG9fLcxf3qfI10QysgDWmMOVmxG0u6ZUAiEAyBiXDWzM+uOe5W0JuG+luQAbPIqHh89M15TluLtEZtM="
    let sgTimestamp = "1600112502"
    // Compact JSON (sorted keys, no spaces) + CRLF — exactly as SendGrid's server produces it.
    let sgPayload = "[{\"email\":\"hello@world.com\",\"event\":\"dropped\",\"reason\":\"Bounced Address\",\"sg_event_id\":\"ZHJvcC0xMDk5NDkxOS1MUnpYbF9OSFN0T0doUTRrb2ZTbV9BLTA\",\"sg_message_id\":\"LRzXl_NHStOGhQ4kofSm_A.filterdrecv-p3mdw1-756b745b58-kmzbl-18-5F5FC76C-9.0\",\"smtp-id\":\"<LRzXl_NHStOGhQ4kofSm_A@ismtpd0039p1iad1.sendgrid.net>\",\"timestamp\":1600112492}]\r\n"

    @Test("Verify known-good SendGrid production fixture (DER signature)")
    func verifySendGridProductionFixture() throws {
        // tolerance: 0 disables the timestamp window — this is a historical fixture.
        #expect(throws: Never.self) {
            try SendGridWebhookEvent.verifySignature(
                payload: ByteBuffer(string: sgPayload),
                signature: sgSignature,
                timestamp: sgTimestamp,
                publicKey: sgPublicKey,
                tolerance: 0
            )
        }
    }

    @Test("Reject production fixture with wrong payload")
    func rejectProductionFixtureWrongPayload() throws {
        #expect(throws: SendGridWebhookSignatureError.noMatchingSignatureFound) {
            try SendGridWebhookEvent.verifySignature(
                payload: ByteBuffer(string: "tampered payload"),
                signature: sgSignature,
                timestamp: sgTimestamp,
                publicKey: sgPublicKey,
                tolerance: 0
            )
        }
    }

    @Test("Reject production fixture with wrong signature")
    func rejectProductionFixtureWrongSignature() throws {
        // A different valid DER signature — should not verify against the correct payload.
        let badSignature = "MEUCIQCtIHJeH93Y+qpYeWrySphQgpNGNr/U+UyUlBkU6n7RAwIgJTz2C+8a8xonZGi6BpSzoQsbVRamr2nlxFDWYNH3j/0="
        #expect(throws: SendGridWebhookSignatureError.noMatchingSignatureFound) {
            try SendGridWebhookEvent.verifySignature(
                payload: ByteBuffer(string: sgPayload),
                signature: badSignature,
                timestamp: sgTimestamp,
                publicKey: sgPublicKey,
                tolerance: 0
            )
        }
    }

    @Test("Reject production fixture with wrong public key")
    func rejectProductionFixtureWrongPublicKey() throws {
        let wrongKey = "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEqTxd43gyp8IOEto2LdIfjRQrIbsd4SXZkLW6jDutdhXSJCWHw8REntlo7aNDthvj+y7GjUuFDb/R1NGe1OPzpA=="
        #expect(throws: SendGridWebhookSignatureError.noMatchingSignatureFound) {
            try SendGridWebhookEvent.verifySignature(
                payload: ByteBuffer(string: sgPayload),
                signature: sgSignature,
                timestamp: sgTimestamp,
                publicKey: wrongKey,
                tolerance: 0
            )
        }
    }

    // MARK: - Synthetic tests (DER signatures, matching production format)

    @Test("Verify valid ECDSA signature")
    func verifyValidSignature() throws {
        let (testPrivateKey, testPublicKeyBase64) = createTestKeyPair()
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let payloadBuffer = ByteBuffer(string: jsonPayload)

        let signedData = (timestamp + jsonPayload).data(using: .utf8)!
        // Use derRepresentation — the format SendGrid's server produces
        let signatureBase64 = try testPrivateKey.signature(for: SHA256.hash(data: signedData))
            .derRepresentation.base64EncodedString()

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

        // Signature over wrong data — should not match the payload
        let signatureBase64 = try testPrivateKey.signature(for: SHA256.hash(data: "wrong data".data(using: .utf8)!))
            .derRepresentation.base64EncodedString()

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
        let oldTimestamp = String(Int(Date().timeIntervalSince1970) - 600)   // 10 minutes ago
        let payloadBuffer = ByteBuffer(string: jsonPayload)

        let signedData = (oldTimestamp + jsonPayload).data(using: .utf8)!
        let signatureBase64 = try testPrivateKey.signature(for: SHA256.hash(data: signedData))
            .derRepresentation.base64EncodedString()

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
        let recentTimestamp = String(Int(Date().timeIntervalSince1970) - 120)  // 2 minutes ago
        let payloadBuffer = ByteBuffer(string: jsonPayload)

        let signedData = (recentTimestamp + jsonPayload).data(using: .utf8)!
        let signatureBase64 = try testPrivateKey.signature(for: SHA256.hash(data: signedData))
            .derRepresentation.base64EncodedString()

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

        #expect(throws: SendGridWebhookSignatureError.invalidSignature) {
            try SendGridWebhookEvent.verifySignature(
                payload: ByteBuffer(string: jsonPayload),
                signature: "not-valid-base64!",
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

        let signedData = (timestamp + jsonPayload).data(using: .utf8)!
        let signatureBase64 = try testPrivateKey.signature(for: SHA256.hash(data: signedData))
            .derRepresentation.base64EncodedString()

        #expect(throws: SendGridWebhookSignatureError.invalidPublicKey) {
            try SendGridWebhookEvent.verifySignature(
                payload: ByteBuffer(string: jsonPayload),
                signature: signatureBase64,
                timestamp: timestamp,
                publicKey: "not-valid-base64!",
                tolerance: 300
            )
        }
    }

    @Test("Reject invalid timestamp format")
    func rejectInvalidTimestampFormat() throws {
        let (testPrivateKey, testPublicKeyBase64) = createTestKeyPair()
        let invalidTimestamp = "not-a-timestamp"

        let signedData = (invalidTimestamp + jsonPayload).data(using: .utf8)!
        let signatureBase64 = try testPrivateKey.signature(for: SHA256.hash(data: signedData))
            .derRepresentation.base64EncodedString()

        #expect(throws: SendGridWebhookSignatureError.unableToParseHeader) {
            try SendGridWebhookEvent.verifySignature(
                payload: ByteBuffer(string: jsonPayload),
                signature: signatureBase64,
                timestamp: invalidTimestamp,
                publicKey: testPublicKeyBase64,
                tolerance: 300
            )
        }
    }

    @Test("Verify with zero tolerance (timestamp check disabled)")
    func verifyWithZeroTolerance() throws {
        let (testPrivateKey, testPublicKeyBase64) = createTestKeyPair()
        let oldTimestamp = String(Int(Date().timeIntervalSince1970) - 3600)  // 1 hour ago

        let signedData = (oldTimestamp + jsonPayload).data(using: .utf8)!
        let signatureBase64 = try testPrivateKey.signature(for: SHA256.hash(data: signedData))
            .derRepresentation.base64EncodedString()

        #expect(throws: Never.self) {
            try SendGridWebhookEvent.verifySignature(
                payload: ByteBuffer(string: jsonPayload),
                signature: signatureBase64,
                timestamp: oldTimestamp,
                publicKey: testPublicKeyBase64,
                tolerance: 0  // 0 disables the timestamp window entirely
            )
        }
    }

    @Test("Verify with negative tolerance (timestamp check disabled)")
    func verifyWithNegativeTolerance() throws {
        let (testPrivateKey, testPublicKeyBase64) = createTestKeyPair()
        let oldTimestamp = String(Int(Date().timeIntervalSince1970) - 3600)

        let signedData = (oldTimestamp + jsonPayload).data(using: .utf8)!
        let signatureBase64 = try testPrivateKey.signature(for: SHA256.hash(data: signedData))
            .derRepresentation.base64EncodedString()

        #expect(throws: Never.self) {
            try SendGridWebhookEvent.verifySignature(
                payload: ByteBuffer(string: jsonPayload),
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

        let signedData = (timestamp + jsonPayload).data(using: .utf8)!
        // DER-encoded signature, matching production format
        let signatureBase64 = try testPrivateKey.signature(for: SHA256.hash(data: signedData))
            .derRepresentation.base64EncodedString()

        // DER/SPKI format — the format SendGrid uses for public keys
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

        // x963 uncompressed point format — also accepted
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
    }
}
