import AsyncHTTPClient
import Foundation
import NIO
import NIOFoundationCompat
import NIOHTTP1

/// A client for SendGrid Event Webhook
public struct SendGridWebhookClient: Sendable {

    private let apiURL: String
    private let httpClient: HTTPClient
    private let apiKey: String

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        return encoder
    }()

    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        return decoder
    }()

    private let dailyDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    /// Initialize a new `SendGridClient`
    ///
    /// - Parameters:
    ///   - httpClient: The `HTTPClient` to use for sending requests
    ///   - apiKey: The SendGrid API key
    ///   - forEU: Whether to use the API endpoint for global users and subusers or for EU regional subusers
    public init(httpClient: HTTPClient, apiKey: String, forEU: Bool = false) {
        self.httpClient = httpClient
        self.apiKey = apiKey
        self.apiURL = forEU ? "https://api.eu.sendgrid.com/v3" : "https://api.sendgrid.com/v3"
    }

    /// This endpoint allows you to create a new Event Webhook.
    /// - Parameters:
    ///   - input: The request body
    ///   - onbehalfOf: The on-behalf-of header allows you to make API calls from a parent account on behalf of the parent's Subusers or customer accounts.
    public func createEventWebhook(_ input: EventWebhookInput, onbehalfOf: String? = nil) async throws -> WebhookSettingsResponse {
        var headers = HTTPHeaders()
        headers.add(name: "Authorization", value: "Bearer \(self.apiKey)")
        headers.add(name: "Content-Type", value: "application/json")
        headers.add(name: "User-Agent", value: "Swift SendGridKit/3.0.0")

        if let onbehalfOf = onbehalfOf {
            headers.add(name: "on-behalf-of", value: onbehalfOf)
        }

        var request = HTTPClientRequest(url: "\(self.apiURL)/user/webhooks/event/settings")
        request.method = .POST
        request.headers = headers
        request.body = try HTTPClientRequest.Body.bytes(self.encoder.encode(input))

        let response = try await self.httpClient.execute(request, timeout: .seconds(30))

        // If the request was accepted, simply return
        if (200...299).contains(response.status.code) {
            return try await self.decoder.decode(WebhookSettingsResponse.self, from: response.body.collect(upTo: 1024 * 1024))
        }

        // `JSONDecoder` will handle empty body by throwing decoding error
        throw try await self.decoder.decode(SendGridError.self, from: response.body.collect(upTo: 1024 * 1024))
    }

    /// This endpoint allows you to test an Event Webhook.
    /// - Parameters:
    ///   - input: The request body
    ///   - onbehalfOf: The on-behalf-of header allows you to make API calls from a parent account on behalf of the parent's Subusers or customer accounts.
    public func testEventWebhook(_ input: SendGridTestWebhookInput, onbehalfOf: String? = nil) async throws {
        var headers = HTTPHeaders()
        headers.add(name: "Authorization", value: "Bearer \(self.apiKey)")
        headers.add(name: "Content-Type", value: "application/json")
        headers.add(name: "User-Agent", value: "Swift SendGridKit/3.0.0")

        if let onbehalfOf = onbehalfOf {
            headers.add(name: "on-behalf-of", value: onbehalfOf)
        }

        var request = HTTPClientRequest(url: "\(self.apiURL)/user/webhooks/event/test")
        request.method = .POST
        request.headers = headers
        request.body = try HTTPClientRequest.Body.bytes(self.encoder.encode(input))

        let response = try await self.httpClient.execute(request, timeout: .seconds(30))

        // If the request was accepted, simply return
        if (200...299).contains(response.status.code) { return }

        // `JSONDecoder` will handle empty body by throwing decoding error
        throw try await self.decoder.decode(SendGridError.self, from: response.body.collect(upTo: 1024 * 1024))
    }

    /// This endpoint allows you to retrieve a single Event Webhook by ID.
    /// - Parameters:
    ///   - id: The ID of the Event Webhook you want to retrieve.
    ///   - includeAccountStatusChange: Use this to include optional fields in the response payload.
    ///   - onbehalfOf: The on-behalf-of header allows you to make API calls from a parent account on behalf of the parent's Subusers or customer accounts.
    public func getEventWebhook(
        id: String,
        includeAccountStatusChange: Bool,
        onbehalfOf: String? = nil
    ) async throws -> WebhookSettingsResponse {
        var headers = HTTPHeaders()
        headers.add(name: "Authorization", value: "Bearer \(self.apiKey)")
        headers.add(name: "Content-Type", value: "application/json")
        headers.add(name: "User-Agent", value: "Swift SendGridKit/3.0.0")

        if let onbehalfOf = onbehalfOf {
            headers.add(name: "on-behalf-of", value: onbehalfOf)
        }

        var url = "\(self.apiURL)/user/webhooks/event/settings/\(id)"

        if includeAccountStatusChange {
            url += "?include=account_status_change"
        }

        var request = HTTPClientRequest(url: url)
        request.headers = headers

        let response = try await self.httpClient.execute(request, timeout: .seconds(30))

        // If the request was accepted, simply return
        if (200...299).contains(response.status.code) {
            return try await self.decoder.decode(WebhookSettingsResponse.self, from: response.body.collect(upTo: 1024 * 1024))
        }

        // `JSONDecoder` will handle empty body by throwing decoding error
        throw try await self.decoder.decode(SendGridError.self, from: response.body.collect(upTo: 1024 * 1024))
    }

    /// This endpoint allows you to retrieve all of your Event Webhooks.
    /// - Parameters:
    ///   - id: The ID of the Event Webhook you want to retrieve.
    ///   - enabled: Enable or disable the webhook by setting this property to true or false, respectively.
    ///   - onbehalfOf: The on-behalf-of header allows you to make API calls from a parent account on behalf of the parent's Subusers or customer accounts.
    public func getAllEventWebhooks(includeAccountStatusChange: Bool, onbehalfOf: String? = nil) async throws -> AllEventWebhooks {
        var headers = HTTPHeaders()
        headers.add(name: "Authorization", value: "Bearer \(self.apiKey)")
        headers.add(name: "Content-Type", value: "application/json")
        headers.add(name: "User-Agent", value: "Swift SendGridKit/3.0.0")

        if let onbehalfOf = onbehalfOf {
            headers.add(name: "on-behalf-of", value: onbehalfOf)
        }

        var url = "\(self.apiURL)/user/webhooks/event/settings/all"

        if includeAccountStatusChange {
            url += "?include=account_status_change"
        }

        var request = HTTPClientRequest(url: url)
        request.headers = headers

        let response = try await self.httpClient.execute(request, timeout: .seconds(30))

        // If the request was accepted, simply return
        if (200...299).contains(response.status.code) {
            return try await self.decoder.decode(AllEventWebhooks.self, from: response.body.collect(upTo: 2 * 1024 * 1024))
        }

        // `JSONDecoder` will handle empty body by throwing decoding error
        throw try await self.decoder.decode(SendGridError.self, from: response.body.collect(upTo: 1024 * 1024))
    }

    /// This endpoint allows you to enable or disable signature verification for a single Event Webhook by ID.
    /// - Parameters:
    ///   - id: The ID of the Event Webhook you want to retrieve.
    ///   - enabled: Enable or disable the webhook by setting this property to true or false, respectively.
    ///   - onbehalfOf: The on-behalf-of header allows you to make API calls from a parent account on behalf of the parent's Subusers or customer accounts.
    public func toggleEventWebhookSignatureVerification(
        id: String,
        enabled: Bool,
        onbehalfOf: String? = nil
    ) async throws -> EventWebhookSignaturePublicKeyResponse {
        var headers = HTTPHeaders()
        headers.add(name: "Authorization", value: "Bearer \(self.apiKey)")
        headers.add(name: "Content-Type", value: "application/json")
        headers.add(name: "User-Agent", value: "Swift SendGridKit/3.0.0")

        if let onbehalfOf = onbehalfOf {
            headers.add(name: "on-behalf-of", value: onbehalfOf)
        }

        let url = "\(self.apiURL)/user/webhooks/event/settings/signed/\(id)"

        var request = HTTPClientRequest(url: url)
        request.headers = headers
        request.method = .PATCH
        request.body = try HTTPClientRequest.Body.bytes(
            self.encoder.encode(
                ToogleEventWebhookSignatureVerification(enabled: enabled)
            ))

        let response = try await self.httpClient.execute(request, timeout: .seconds(30))

        // If the request was accepted, simply return
        if (200...299).contains(response.status.code) {
            return try await self.decoder.decode(
                EventWebhookSignaturePublicKeyResponse.self, from: response.body.collect(upTo: 1024 * 1024))
        }

        // `JSONDecoder` will handle empty body by throwing decoding error
        throw try await self.decoder.decode(SendGridError.self, from: response.body.collect(upTo: 1024 * 1024))
    }

    /// This endpoint allows you to retrieve the public key for a single Event Webhook by ID.
    /// - Parameters:
    ///   - id: The ID of the Event Webhook you want to retrieve.
    ///   - onbehalfOf: The on-behalf-of header allows you to make API calls from a parent account on behalf of the parent's Subusers or customer accounts.
    public func getSignedEventWebhookPublicKey(
        id: String,
        onbehalfOf: String? = nil
    ) async throws -> EventWebhookSignaturePublicKeyResponse {
        var headers = HTTPHeaders()
        headers.add(name: "Authorization", value: "Bearer \(self.apiKey)")
        headers.add(name: "Content-Type", value: "application/json")
        headers.add(name: "User-Agent", value: "Swift SendGridKit/3.0.0")

        if let onbehalfOf = onbehalfOf {
            headers.add(name: "on-behalf-of", value: onbehalfOf)
        }

        let url = "\(self.apiURL)/user/webhooks/event/settings/signed/\(id)"

        var request = HTTPClientRequest(url: url)
        request.headers = headers

        let response = try await self.httpClient.execute(request, timeout: .seconds(30))

        // If the request was accepted, simply return
        if (200...299).contains(response.status.code) {
            return try await self.decoder.decode(
                EventWebhookSignaturePublicKeyResponse.self, from: response.body.collect(upTo: 1024 * 1024))
        }

        // `JSONDecoder` will handle empty body by throwing decoding error
        throw try await self.decoder.decode(SendGridError.self, from: response.body.collect(upTo: 1024 * 1024))
    }

    /// This endpoint allows you to update a single Event Webhook by ID.
    /// - Parameters:
    ///   - id: The ID of the Event Webhook you want to retrieve.
    ///   - input: The input body
    ///   - includeAccountStatusChange: Use this to include optional fields in the response payload.
    ///   - onbehalfOf: The on-behalf-of header allows you to make API calls from a parent account on behalf of the parent's Subusers or customer accounts.
    public func updateEventWebhook(
        id: String,
        input: EventWebhookInput,
        includeAccountStatusChange: Bool,
        onbehalfOf: String? = nil
    ) async throws -> WebhookSettingsResponse {
        var headers = HTTPHeaders()
        headers.add(name: "Authorization", value: "Bearer \(self.apiKey)")
        headers.add(name: "Content-Type", value: "application/json")
        headers.add(name: "User-Agent", value: "Swift SendGridKit/3.0.0")

        if let onbehalfOf = onbehalfOf {
            headers.add(name: "on-behalf-of", value: onbehalfOf)
        }

        var url = "\(self.apiURL)/user/webhooks/event/settings/\(id)"

        if includeAccountStatusChange {
            url += "?include=account_status_change"
        }

        var request = HTTPClientRequest(url: url)
        request.method = .PATCH
        request.headers = headers
        request.body = try HTTPClientRequest.Body.bytes(self.encoder.encode(input))

        let response = try await self.httpClient.execute(request, timeout: .seconds(30))

        // If the request was accepted, simply return
        if (200...299).contains(response.status.code) {
            return try await self.decoder.decode(WebhookSettingsResponse.self, from: response.body.collect(upTo: 1024 * 1024))
        }

        // `JSONDecoder` will handle empty body by throwing decoding error
        throw try await self.decoder.decode(SendGridError.self, from: response.body.collect(upTo: 1024 * 1024))
    }

    /// This endpoint allows you to delete a single Event Webhook by ID.
    /// - Parameters:
    ///   - id: The ID of the Event Webhook you want to retrieve.
    ///   - onbehalfOf: The on-behalf-of header allows you to make API calls from a parent account on behalf of the parent's Subusers or customer accounts.
    public func deleteEventWebhook(
        id: String,
        onbehalfOf: String? = nil
    ) async throws {
        var headers = HTTPHeaders()
        headers.add(name: "Authorization", value: "Bearer \(self.apiKey)")
        headers.add(name: "Content-Type", value: "application/json")
        headers.add(name: "User-Agent", value: "Swift SendGridKit/3.0.0")

        if let onbehalfOf = onbehalfOf {
            headers.add(name: "on-behalf-of", value: onbehalfOf)
        }

        let url = "\(self.apiURL)/user/webhooks/event/settings/\(id)"

        var request = HTTPClientRequest(url: url)
        request.method = .DELETE
        request.headers = headers

        let response = try await self.httpClient.execute(request, timeout: .seconds(30))

        // If the request was accepted, simply return
        if (200...299).contains(response.status.code) { return }

        // `JSONDecoder` will handle empty body by throwing decoding error
        throw try await self.decoder.decode(SendGridError.self, from: response.body.collect(upTo: 1024 * 1024))
    }

    /// This endpoint allows you to retrieve all of your current inbound parse settings.
    /// - Parameters:
    ///   - onbehalfOf: The on-behalf-of header allows you to make API calls from a parent account on behalf of the parent's Subusers or customer accounts.
    public func getParseWebhookSettings(
        onbehalfOf: String? = nil
    ) async throws -> [ParseWebhookSettingsResponse] {
        var headers = HTTPHeaders()
        headers.add(name: "Authorization", value: "Bearer \(self.apiKey)")
        headers.add(name: "Content-Type", value: "application/json")
        headers.add(name: "User-Agent", value: "Swift SendGridKit/3.0.0")

        if let onbehalfOf = onbehalfOf {
            headers.add(name: "on-behalf-of", value: onbehalfOf)
        }

        let url = "\(self.apiURL)/user/webhooks/parse/settings"

        var request = HTTPClientRequest(url: url)
        request.headers = headers

        let response = try await self.httpClient.execute(request, timeout: .seconds(30))

        // If the request was accepted, simply return
        if (200...299).contains(response.status.code) {
            return try await self.decoder.decode([ParseWebhookSettingsResponse].self, from: response.body.collect(upTo: 1024 * 1024))
        }

        // `JSONDecoder` will handle empty body by throwing decoding error
        throw try await self.decoder.decode(SendGridError.self, from: response.body.collect(upTo: 1024 * 1024))
    }

    /// This endpoint allows you to retrieve the statistics for your Parse Webhook usage.
    /// - Parameters:
    ///   - limit: The `HTTPClient` to use for sending requests
    ///   - offset: The number of statistics to skip.
    ///   - aggregatedBy: How you would like the statistics to by grouped.
    ///   - startDate: The starting date of the statistics you want to retrieve.
    ///   - endDate: The end date of the statistics you want to retrieve.
    ///   - onbehalfOf: The on-behalf-of header allows you to make API calls from a parent account on behalf of the parent's Subusers or customer accounts.
    public func getParseWebhookStatistics(
        limit: Int,
        offset: Int,
        aggregatedBy: SendGridInboundParseAggregateBy,
        startDate: Date,
        endDate: Date?,
        onbehalfOf: String? = nil
    ) async throws -> [ParseWebhookSettingsStatistics] {
        var headers = HTTPHeaders()
        headers.add(name: "Authorization", value: "Bearer \(self.apiKey)")
        headers.add(name: "Content-Type", value: "application/json")
        headers.add(name: "User-Agent", value: "Swift SendGridKit/3.0.0")

        if let onbehalfOf = onbehalfOf {
            headers.add(name: "on-behalf-of", value: onbehalfOf)
        }

        let url = "\(self.apiURL)/user/user/webhooks/parse/stats"

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset)),
            URLQueryItem(name: "aggregated_by", value: aggregatedBy.rawValue),
            URLQueryItem(name: "start_date", value: dailyDateFormatter.string(from: startDate)),
        ]

        if let endDate = endDate {
            queryItems.append(
                URLQueryItem(name: "end_date", value: dailyDateFormatter.string(from: endDate))
            )
        }

        let query = queryItems.map { "\($0.name)=\($0.value ?? "")" }

        var request = HTTPClientRequest(url: url + "?" + query.joined(separator: "&"))
        request.headers = headers

        let response = try await self.httpClient.execute(request, timeout: .seconds(30))

        // If the request was accepted, simply return
        if (200...299).contains(response.status.code) {
            return try await self.decoder.decode([ParseWebhookSettingsStatistics].self, from: response.body.collect(upTo: 1024 * 1024))
        }

        // `JSONDecoder` will handle empty body by throwing decoding error
        throw try await self.decoder.decode(SendGridError.self, from: response.body.collect(upTo: 1024 * 1024))
    }
}
