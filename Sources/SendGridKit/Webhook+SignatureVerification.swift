import Crypto
import Foundation
import NIO

public enum SendGridWebhookSignatureError: Error, Equatable {
    case unableToParseHeader
    case noMatchingSignatureFound
    case timestampNotTolerated
    case invalidPublicKey
    case invalidSignature
}

extension SendGridWebhookEvent {
    /// Verify an ECDSA signature from SendGrid
    /// - Parameters:
    ///   - payload: The JSON payload as `ByteBuffer`
    ///   - signature: The `X-Twilio-Email-Event-Webhook-Signature` HTTP-Header value
    ///   - timestamp: The `X-Twilio-Email-Event-Webhook-Timestamp` HTTP-Header value
    ///   - publicKey: The ECDSA public key from SendGrid (base64 encoded)
    ///   - tolerance: In seconds the time difference tolerance to prevent replay attacks: Default 300 seconds
    static public func verifySignature(
        payload: ByteBuffer,
        signature: String,
        timestamp: String,
        publicKey: String,
        tolerance: Double = 300
    ) throws {
        // Verify timestamp tolerance
        guard let timestampValue = Double(timestamp) else {
            throw SendGridWebhookSignatureError.unableToParseHeader
        }

        let timeDifference = Date().timeIntervalSince(Date(timeIntervalSince1970: timestampValue))

        if tolerance > 0 && timeDifference > tolerance {
            throw SendGridWebhookSignatureError.timestampNotTolerated
        }

        // Convert payload to string
        guard let payloadString = payload.getString(at: 0, length: payload.readableBytes) else {
            throw SendGridWebhookSignatureError.unableToParseHeader
        }

        // Create the signed payload: timestamp + payload
        let signedPayload = timestamp + payloadString
        guard let signedData = signedPayload.data(using: String.Encoding.utf8) else {
            throw SendGridWebhookSignatureError.unableToParseHeader
        }

        // Decode the base64 signature
        guard let signatureData = Data(base64Encoded: signature) else {
            throw SendGridWebhookSignatureError.invalidSignature
        }

        // Decode the base64 public key
        guard let publicKeyData = Data(base64Encoded: publicKey) else {
            throw SendGridWebhookSignatureError.invalidPublicKey
        }

        // Convert public key data to ECDSA public key
        let ecdsaPublicKey: P256.Signing.PublicKey
        do {
            // Try different formats for the public key
            if let key = try? P256.Signing.PublicKey(rawRepresentation: publicKeyData) {
                ecdsaPublicKey = key
            } else if let key = try? P256.Signing.PublicKey(derRepresentation: publicKeyData) {
                ecdsaPublicKey = key
            } else {
                // Try x963 representation
                ecdsaPublicKey = try P256.Signing.PublicKey(x963Representation: publicKeyData)
            }
        } catch {
            throw SendGridWebhookSignatureError.invalidPublicKey
        }

        // Verify the signature
        let ecdsaSignature: P256.Signing.ECDSASignature
        do {
            ecdsaSignature = try P256.Signing.ECDSASignature(rawRepresentation: signatureData)
        } catch {
            throw SendGridWebhookSignatureError.invalidSignature
        }

        // Perform signature verification
        let isValid = ecdsaPublicKey.isValidSignature(ecdsaSignature, for: SHA256.hash(data: signedData))

        if !isValid {
            throw SendGridWebhookSignatureError.noMatchingSignatureFound
        }
    }
}

extension String {
    /// Helper to convert hex string to Data
    var hexData: Data? {
        let hexStr = self.dropFirst(self.hasPrefix("0x") ? 2 : 0)

        guard hexStr.count % 2 == 0 else { return nil }

        var data = Data()
        var index = hexStr.startIndex

        while index < hexStr.endIndex {
            let nextIndex = hexStr.index(index, offsetBy: 2)
            let byteString = hexStr[index..<nextIndex]

            guard let byte = UInt8(byteString, radix: 16) else { return nil }
            data.append(byte)

            index = nextIndex
        }

        return data
    }
}

extension Data {
    /// Helper to convert Data to hex string
    var hexString: String {
        return self.map { String(format: "%02x", $0) }.joined()
    }
}
