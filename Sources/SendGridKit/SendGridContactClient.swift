import AsyncHTTPClient
import Foundation
import NIO
import NIOFoundationCompat
import NIOHTTP1

/// A client for managing Marketing Campaigns contacts using the SendGrid API.
///
/// Supports adding, updating, searching, and deleting contacts, as well as managing
/// contact lists and exporting contacts.
public struct SendGridContactClient: Sendable {

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

    /// Initialize a new ``SendGridContactClient``.
    ///
    /// - Parameters:
    ///   - httpClient: The `HTTPClient` to use for sending requests.
    ///   - apiKey: The SendGrid API key.
    ///   - forEU: Whether to use the API endpoint for EU regional subusers. Defaults to `false`.
    public init(httpClient: HTTPClient, apiKey: String, forEU: Bool = false) {
        self.httpClient = httpClient
        self.apiKey = apiKey
        self.apiURL = forEU ? "https://api.eu.sendgrid.com/v3" : "https://api.sendgrid.com/v3"
    }

    // MARK: - Contacts

    /// Add or update one or more contacts in Marketing Campaigns.
    ///
    /// This is an asynchronous operation. Use the returned ``UpsertContactsResponse/jobID``
    /// to track import progress via the SendGrid console or a future status endpoint.
    ///
    /// - Parameter request: A ``UpsertContactsRequest`` containing the contacts to add or update
    ///   and optional list IDs to associate them with.
    /// - Returns: A ``UpsertContactsResponse`` with the async job ID.
    public func upsertContacts(_ request: UpsertContactsRequest) async throws -> UpsertContactsResponse {
        var headers = HTTPHeaders()
        headers.add(name: "Authorization", value: "Bearer \(self.apiKey)")
        headers.add(name: "Content-Type", value: "application/json")
        headers.add(name: "User-Agent", value: "Swift SendGridKit/3.0.0")

        var httpRequest = HTTPClientRequest(url: "\(self.apiURL)/marketing/contacts")
        httpRequest.method = .PUT
        httpRequest.headers = headers
        httpRequest.body = try HTTPClientRequest.Body.bytes(self.encoder.encode(request))

        let response = try await self.httpClient.execute(httpRequest, timeout: .seconds(30))

        if (200...299).contains(response.status.code) {
            return try await self.decoder.decode(
                UpsertContactsResponse.self,
                from: response.body.collect(upTo: 1024 * 1024)
            )
        }

        throw try await self.decoder.decode(SendGridError.self, from: response.body.collect(upTo: 1024 * 1024))
    }

    /// Retrieve a sample of up to 50 of the most recently updated contacts in your account.
    ///
    /// > Important: Pagination of this endpoint has been deprecated by SendGrid. This method
    /// > will never return more than 50 contacts regardless of your total contact count.
    /// > Use ``exportContacts(_:)`` to retrieve your full contact list as a downloadable file.
    ///
    /// - Returns: A ``ContactsResponse`` with up to 50 contacts and the total ``ContactsResponse/contactCount``.
    public func getSampleContacts() async throws -> ContactsResponse {
        var headers = HTTPHeaders()
        headers.add(name: "Authorization", value: "Bearer \(self.apiKey)")
        headers.add(name: "User-Agent", value: "Swift SendGridKit/3.0.0")

        var httpRequest = HTTPClientRequest(url: "\(self.apiURL)/marketing/contacts")
        httpRequest.method = .GET
        httpRequest.headers = headers

        let response = try await self.httpClient.execute(httpRequest, timeout: .seconds(30))

        if (200...299).contains(response.status.code) {
            return try await self.decoder.decode(
                ContactsResponse.self,
                from: response.body.collect(upTo: 1024 * 1024)
            )
        }

        throw try await self.decoder.decode(SendGridError.self, from: response.body.collect(upTo: 1024 * 1024))
    }

    /// Retrieve a single contact by their SendGrid contact ID.
    ///
    /// - Parameter id: The SendGrid-assigned unique identifier of the contact.
    /// - Returns: The matching ``Contact``.
    public func getContact(id: String) async throws -> Contact {
        var headers = HTTPHeaders()
        headers.add(name: "Authorization", value: "Bearer \(self.apiKey)")
        headers.add(name: "User-Agent", value: "Swift SendGridKit/3.0.0")

        var httpRequest = HTTPClientRequest(url: "\(self.apiURL)/marketing/contacts/\(id)")
        httpRequest.method = .GET
        httpRequest.headers = headers

        let response = try await self.httpClient.execute(httpRequest, timeout: .seconds(30))

        if (200...299).contains(response.status.code) {
            return try await self.decoder.decode(
                Contact.self,
                from: response.body.collect(upTo: 1024 * 1024)
            )
        }

        throw try await self.decoder.decode(SendGridError.self, from: response.body.collect(upTo: 1024 * 1024))
    }

    /// Delete one or more contacts by their SendGrid contact IDs.
    ///
    /// This is an asynchronous operation. Deletion may take some time to propagate.
    ///
    /// - Parameter ids: The SendGrid-assigned contact IDs to delete.
    /// - Returns: A ``ContactJobResponse`` with the async job ID.
    public func deleteContacts(ids: [String]) async throws -> ContactJobResponse {
        var headers = HTTPHeaders()
        headers.add(name: "Authorization", value: "Bearer \(self.apiKey)")
        headers.add(name: "User-Agent", value: "Swift SendGridKit/3.0.0")

        let idList = ids.joined(separator: ",")
        var httpRequest = HTTPClientRequest(url: "\(self.apiURL)/marketing/contacts?ids=\(idList)")
        httpRequest.method = .DELETE
        httpRequest.headers = headers

        let response = try await self.httpClient.execute(httpRequest, timeout: .seconds(30))

        if (200...299).contains(response.status.code) {
            return try await self.decoder.decode(
                ContactJobResponse.self,
                from: response.body.collect(upTo: 1024 * 1024)
            )
        }

        throw try await self.decoder.decode(SendGridError.self, from: response.body.collect(upTo: 1024 * 1024))
    }

    /// Search for contacts using an SGQL query string.
    ///
    /// - Parameter request: A ``ContactSearchRequest`` containing the SGQL query.
    /// - Returns: A ``ContactSearchResponse`` with matching contacts and pagination metadata.
    public func searchContacts(_ request: ContactSearchRequest) async throws -> ContactSearchResponse {
        var headers = HTTPHeaders()
        headers.add(name: "Authorization", value: "Bearer \(self.apiKey)")
        headers.add(name: "Content-Type", value: "application/json")
        headers.add(name: "User-Agent", value: "Swift SendGridKit/3.0.0")

        var httpRequest = HTTPClientRequest(url: "\(self.apiURL)/marketing/contacts/search")
        httpRequest.method = .POST
        httpRequest.headers = headers
        httpRequest.body = try HTTPClientRequest.Body.bytes(self.encoder.encode(request))

        let response = try await self.httpClient.execute(httpRequest, timeout: .seconds(30))

        if (200...299).contains(response.status.code) {
            return try await self.decoder.decode(
                ContactSearchResponse.self,
                from: response.body.collect(upTo: 1024 * 1024)
            )
        }

        throw try await self.decoder.decode(SendGridError.self, from: response.body.collect(upTo: 1024 * 1024))
    }

    /// Retrieve the total and billable contact counts for your account.
    ///
    /// - Returns: A ``ContactCount`` with the total and billable contact counts.
    public func getContactCount() async throws -> ContactCount {
        var headers = HTTPHeaders()
        headers.add(name: "Authorization", value: "Bearer \(self.apiKey)")
        headers.add(name: "User-Agent", value: "Swift SendGridKit/3.0.0")

        var httpRequest = HTTPClientRequest(url: "\(self.apiURL)/marketing/contacts/count")
        httpRequest.method = .GET
        httpRequest.headers = headers

        let response = try await self.httpClient.execute(httpRequest, timeout: .seconds(30))

        if (200...299).contains(response.status.code) {
            return try await self.decoder.decode(
                ContactCount.self,
                from: response.body.collect(upTo: 1024 * 1024)
            )
        }

        throw try await self.decoder.decode(SendGridError.self, from: response.body.collect(upTo: 1024 * 1024))
    }

    /// Delete a unique identifier from a contact.
    ///
    /// Use this endpoint to remove a ``ContactIdentifierType/phoneNumberID``,
    /// ``ContactIdentifierType/externalID``, or ``ContactIdentifierType/anonymousID`` from a contact.
    /// To change an identifier, delete it first, then update the contact via ``upsertContacts(_:)``.
    ///
    /// - Parameters:
    ///   - contactID: The SendGrid-assigned unique identifier of the contact.
    ///   - type: The ``ContactIdentifierType`` to delete.
    public func deleteContactIdentifier(contactID: String, type: ContactIdentifierType) async throws {
        var headers = HTTPHeaders()
        headers.add(name: "Authorization", value: "Bearer \(self.apiKey)")
        headers.add(name: "User-Agent", value: "Swift SendGridKit/3.0.0")

        var httpRequest = HTTPClientRequest(
            url: "\(self.apiURL)/marketing/contacts/\(contactID)/identifiers/\(type.rawValue)"
        )
        httpRequest.method = .DELETE
        httpRequest.headers = headers

        let response = try await self.httpClient.execute(httpRequest, timeout: .seconds(30))

        if (200...299).contains(response.status.code) { return }

        throw try await self.decoder.decode(SendGridError.self, from: response.body.collect(upTo: 1024 * 1024))
    }

    // MARK: - Exports

    /// Start an asynchronous export of contacts from your account.
    ///
    /// Use the returned ``ContactExportResponse/id`` to poll ``getContactExport(id:)``
    /// until the status is ``ContactExportResponse/Status/ready``. Download URLs are valid
    /// for 12 hours after the export was initiated.
    ///
    /// - Parameter request: A ``ContactExportRequest`` specifying which contacts to export.
    /// - Returns: A ``ContactExportResponse`` with the job ID and initial status.
    public func exportContacts(_ request: ContactExportRequest) async throws -> ContactExportResponse {
        var headers = HTTPHeaders()
        headers.add(name: "Authorization", value: "Bearer \(self.apiKey)")
        headers.add(name: "Content-Type", value: "application/json")
        headers.add(name: "User-Agent", value: "Swift SendGridKit/3.0.0")

        var httpRequest = HTTPClientRequest(url: "\(self.apiURL)/marketing/contacts/exports")
        httpRequest.method = .POST
        httpRequest.headers = headers
        httpRequest.body = try HTTPClientRequest.Body.bytes(self.encoder.encode(request))

        let response = try await self.httpClient.execute(httpRequest, timeout: .seconds(30))

        if (200...299).contains(response.status.code) {
            return try await self.decoder.decode(
                ContactExportResponse.self,
                from: response.body.collect(upTo: 1024 * 1024)
            )
        }

        throw try await self.decoder.decode(SendGridError.self, from: response.body.collect(upTo: 1024 * 1024))
    }

    /// Retrieve the status of a contact export job.
    ///
    /// - Parameter id: The export job ID returned by ``exportContacts(_:)``.
    /// - Returns: A ``ContactExportResponse`` with the current status and, when ready, download URLs.
    public func getContactExport(id: String) async throws -> ContactExportResponse {
        var headers = HTTPHeaders()
        headers.add(name: "Authorization", value: "Bearer \(self.apiKey)")
        headers.add(name: "User-Agent", value: "Swift SendGridKit/3.0.0")

        var httpRequest = HTTPClientRequest(url: "\(self.apiURL)/marketing/contacts/exports/\(id)")
        httpRequest.method = .GET
        httpRequest.headers = headers

        let response = try await self.httpClient.execute(httpRequest, timeout: .seconds(30))

        if (200...299).contains(response.status.code) {
            return try await self.decoder.decode(
                ContactExportResponse.self,
                from: response.body.collect(upTo: 1024 * 1024)
            )
        }

        throw try await self.decoder.decode(SendGridError.self, from: response.body.collect(upTo: 1024 * 1024))
    }

    // MARK: - Lists

    /// Create a new contact list.
    ///
    /// - Parameter request: A ``CreateContactListRequest`` with the name for the new list.
    /// - Returns: The newly created ``ContactList``.
    public func createContactList(_ request: CreateContactListRequest) async throws -> ContactList {
        var headers = HTTPHeaders()
        headers.add(name: "Authorization", value: "Bearer \(self.apiKey)")
        headers.add(name: "Content-Type", value: "application/json")
        headers.add(name: "User-Agent", value: "Swift SendGridKit/3.0.0")

        var httpRequest = HTTPClientRequest(url: "\(self.apiURL)/marketing/lists")
        httpRequest.method = .POST
        httpRequest.headers = headers
        httpRequest.body = try HTTPClientRequest.Body.bytes(self.encoder.encode(request))

        let response = try await self.httpClient.execute(httpRequest, timeout: .seconds(30))

        if (200...299).contains(response.status.code) {
            return try await self.decoder.decode(
                ContactList.self,
                from: response.body.collect(upTo: 1024 * 1024)
            )
        }

        throw try await self.decoder.decode(SendGridError.self, from: response.body.collect(upTo: 1024 * 1024))
    }

    /// Retrieve all contact lists in your account.
    ///
    /// - Returns: A ``ContactListsResponse`` containing all contact lists.
    public func getAllContactLists() async throws -> ContactListsResponse {
        var headers = HTTPHeaders()
        headers.add(name: "Authorization", value: "Bearer \(self.apiKey)")
        headers.add(name: "User-Agent", value: "Swift SendGridKit/3.0.0")

        var httpRequest = HTTPClientRequest(url: "\(self.apiURL)/marketing/lists")
        httpRequest.method = .GET
        httpRequest.headers = headers

        let response = try await self.httpClient.execute(httpRequest, timeout: .seconds(30))

        if (200...299).contains(response.status.code) {
            return try await self.decoder.decode(
                ContactListsResponse.self,
                from: response.body.collect(upTo: 1024 * 1024)
            )
        }

        throw try await self.decoder.decode(SendGridError.self, from: response.body.collect(upTo: 1024 * 1024))
    }

    /// Retrieve a single contact list by its ID.
    ///
    /// - Parameters:
    ///   - id: The SendGrid-assigned unique identifier of the list.
    ///   - contactSample: When `true`, includes a sample of up to 50 contacts from the list.
    /// - Returns: The matching ``ContactList``.
    public func getContactList(id: String, contactSample: Bool = false) async throws -> ContactList {
        var headers = HTTPHeaders()
        headers.add(name: "Authorization", value: "Bearer \(self.apiKey)")
        headers.add(name: "User-Agent", value: "Swift SendGridKit/3.0.0")

        let url = "\(self.apiURL)/marketing/lists/\(id)?contact_sample=\(contactSample)"
        var httpRequest = HTTPClientRequest(url: url)
        httpRequest.method = .GET
        httpRequest.headers = headers

        let response = try await self.httpClient.execute(httpRequest, timeout: .seconds(30))

        if (200...299).contains(response.status.code) {
            return try await self.decoder.decode(
                ContactList.self,
                from: response.body.collect(upTo: 1024 * 1024)
            )
        }

        throw try await self.decoder.decode(SendGridError.self, from: response.body.collect(upTo: 1024 * 1024))
    }

    /// Update the name of an existing contact list.
    ///
    /// - Parameters:
    ///   - id: The SendGrid-assigned unique identifier of the list to update.
    ///   - request: An ``UpdateContactListRequest`` with the new list name.
    /// - Returns: The updated ``ContactList``.
    public func updateContactList(id: String, request: UpdateContactListRequest) async throws -> ContactList {
        var headers = HTTPHeaders()
        headers.add(name: "Authorization", value: "Bearer \(self.apiKey)")
        headers.add(name: "Content-Type", value: "application/json")
        headers.add(name: "User-Agent", value: "Swift SendGridKit/3.0.0")

        var httpRequest = HTTPClientRequest(url: "\(self.apiURL)/marketing/lists/\(id)")
        httpRequest.method = .PATCH
        httpRequest.headers = headers
        httpRequest.body = try HTTPClientRequest.Body.bytes(self.encoder.encode(request))

        let response = try await self.httpClient.execute(httpRequest, timeout: .seconds(30))

        if (200...299).contains(response.status.code) {
            return try await self.decoder.decode(
                ContactList.self,
                from: response.body.collect(upTo: 1024 * 1024)
            )
        }

        throw try await self.decoder.decode(SendGridError.self, from: response.body.collect(upTo: 1024 * 1024))
    }

    /// Delete a contact list.
    ///
    /// - Parameters:
    ///   - id: The SendGrid-assigned unique identifier of the list to delete.
    ///   - deleteContacts: When `true`, all contacts associated with this list are also deleted
    ///     from your account. Defaults to `false` (only removes the list; contacts are retained).
    /// - Returns: A ``ContactJobResponse`` with the async job ID when `deleteContacts` is `true`,
    ///   or `nil` when only the list is deleted synchronously.
    @discardableResult
    public func deleteContactList(id: String, deleteContacts: Bool = false) async throws -> ContactJobResponse? {
        var headers = HTTPHeaders()
        headers.add(name: "Authorization", value: "Bearer \(self.apiKey)")
        headers.add(name: "User-Agent", value: "Swift SendGridKit/3.0.0")

        let url = "\(self.apiURL)/marketing/lists/\(id)?delete_contacts=\(deleteContacts)"
        var httpRequest = HTTPClientRequest(url: url)
        httpRequest.method = .DELETE
        httpRequest.headers = headers

        let response = try await self.httpClient.execute(httpRequest, timeout: .seconds(30))

        // 202 Accepted: async deletion of list + contacts — decode job ID
        if response.status.code == 202 {
            return try await self.decoder.decode(
                ContactJobResponse.self,
                from: response.body.collect(upTo: 1024 * 1024)
            )
        }

        // 204 No Content: list-only deletion completed synchronously
        if response.status.code == 204 { return nil }

        throw try await self.decoder.decode(SendGridError.self, from: response.body.collect(upTo: 1024 * 1024))
    }

    /// Remove specific contacts from a contact list without deleting them from your account.
    ///
    /// - Parameters:
    ///   - listID: The SendGrid-assigned unique identifier of the list.
    ///   - request: A ``RemoveContactsFromListRequest`` specifying the contact IDs to remove.
    /// - Returns: A ``ContactJobResponse`` with the async job ID.
    public func removeContactsFromList(
        listID: String,
        request: RemoveContactsFromListRequest
    ) async throws -> ContactJobResponse {
        var headers = HTTPHeaders()
        headers.add(name: "Authorization", value: "Bearer \(self.apiKey)")
        headers.add(name: "Content-Type", value: "application/json")
        headers.add(name: "User-Agent", value: "Swift SendGridKit/3.0.0")

        var httpRequest = HTTPClientRequest(url: "\(self.apiURL)/marketing/lists/\(listID)/contacts")
        httpRequest.method = .DELETE
        httpRequest.headers = headers
        httpRequest.body = try HTTPClientRequest.Body.bytes(self.encoder.encode(request))

        let response = try await self.httpClient.execute(httpRequest, timeout: .seconds(30))

        if (200...299).contains(response.status.code) {
            return try await self.decoder.decode(
                ContactJobResponse.self,
                from: response.body.collect(upTo: 1024 * 1024)
            )
        }

        throw try await self.decoder.decode(SendGridError.self, from: response.body.collect(upTo: 1024 * 1024))
    }
}
