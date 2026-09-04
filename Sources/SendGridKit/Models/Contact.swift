import Foundation

/// A type-safe value for a SendGrid contact custom field.
///
/// Custom fields support text and numeric values.
public enum ContactCustomFieldValue: Codable, Sendable {
    case text(String)
    case number(Double)

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .text(value)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode ContactCustomFieldValue: expected String or Double"
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        }
    }
}

/// The type of unique identifier to delete from a contact.
public enum ContactIdentifierType: String, Sendable {
    case phoneNumberID = "phone_number_id"
    case externalID = "external_id"
    case anonymousID = "anonymous_id"
}

/// Pagination metadata included in contact and list responses.
public struct ContactMetadata: Codable, Sendable {
    /// The URL of the current page.
    public let selfURL: String?
    /// The URL of the next page, if any.
    public let next: String?
    /// The URL of the previous page, if any.
    public let prev: String?
    /// The total number of results.
    public let count: Int?

    enum CodingKeys: String, CodingKey {
        case selfURL = "self"
        case next
        case prev
        case count
    }
}

/// A SendGrid Marketing Campaigns contact.
///
/// Use this type both when creating/updating contacts (only supply the fields you want to set)
/// and when reading contacts from the API (all system-assigned fields like ``id`` will be populated).
public struct Contact: Codable, Sendable {
    /// The SendGrid-assigned unique identifier for the contact.
    public let id: String?

    /// The contact's primary email address.
    public let email: String?

    /// The contact's first name.
    public let firstName: String?

    /// The contact's last name.
    public let lastName: String?

    /// The contact's phone number in E.164 format, used as a unique identifier.
    /// This differs from ``phoneNumber``: this field serves as a contact identifier.
    public let phoneNumberID: String?

    /// An identifier that links the contact to data stored in an external system.
    public let externalID: String?

    /// An identifier that links an anonymous contact to data stored in an external system.
    public let anonymousID: String?

    /// The first line of the contact's address.
    public let addressLine1: String?

    /// The second line of the contact's address.
    public let addressLine2: String?

    /// The contact's city.
    public let city: String?

    /// The contact's state, province, or region.
    public let stateProvinceRegion: String?

    /// The contact's postal code.
    public let postalCode: String?

    /// The contact's country.
    public let country: String?

    /// A list of alternate email addresses for the contact.
    public let alternateEmails: [String]?

    /// The contact's phone number in E.164 format.
    public let phoneNumber: String?

    /// The contact's WhatsApp address.
    public let whatsapp: String?

    /// The contact's Line address.
    public let line: String?

    /// The contact's Facebook address.
    public let facebook: String?

    /// A unique name for the contact.
    public let uniqueName: String?

    /// A dictionary of custom field values for the contact, keyed by custom field name.
    public let customFields: [String: ContactCustomFieldValue]?

    /// The IDs of the lists this contact belongs to (read-only, set by SendGrid).
    public let listIDs: [String]?

    /// The IDs of the segments this contact belongs to (read-only, set by SendGrid).
    public let segmentIDs: [String]?

    /// The ISO 8601 date-time string when the contact was created (read-only, set by SendGrid).
    public let createdAt: String?

    /// The ISO 8601 date-time string when the contact was last updated (read-only, set by SendGrid).
    public let updatedAt: String?

    /// The ISO 8601 date-time string when the contact last clicked a link in an email (read-only).
    public let lastClicked: String?

    /// The ISO 8601 date-time string when the contact was last emailed (read-only).
    public let lastEmailed: String?

    /// The ISO 8601 date-time string when the contact last opened an email (read-only).
    public let lastOpened: String?

    public init(
        id: String? = nil,
        email: String? = nil,
        firstName: String? = nil,
        lastName: String? = nil,
        phoneNumberID: String? = nil,
        externalID: String? = nil,
        anonymousID: String? = nil,
        addressLine1: String? = nil,
        addressLine2: String? = nil,
        city: String? = nil,
        stateProvinceRegion: String? = nil,
        postalCode: String? = nil,
        country: String? = nil,
        alternateEmails: [String]? = nil,
        phoneNumber: String? = nil,
        whatsapp: String? = nil,
        line: String? = nil,
        facebook: String? = nil,
        uniqueName: String? = nil,
        customFields: [String: ContactCustomFieldValue]? = nil,
        listIDs: [String]? = nil,
        segmentIDs: [String]? = nil,
        createdAt: String? = nil,
        updatedAt: String? = nil,
        lastClicked: String? = nil,
        lastEmailed: String? = nil,
        lastOpened: String? = nil
    ) {
        self.id = id
        self.email = email
        self.firstName = firstName
        self.lastName = lastName
        self.phoneNumberID = phoneNumberID
        self.externalID = externalID
        self.anonymousID = anonymousID
        self.addressLine1 = addressLine1
        self.addressLine2 = addressLine2
        self.city = city
        self.stateProvinceRegion = stateProvinceRegion
        self.postalCode = postalCode
        self.country = country
        self.alternateEmails = alternateEmails
        self.phoneNumber = phoneNumber
        self.whatsapp = whatsapp
        self.line = line
        self.facebook = facebook
        self.uniqueName = uniqueName
        self.customFields = customFields
        self.listIDs = listIDs
        self.segmentIDs = segmentIDs
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastClicked = lastClicked
        self.lastEmailed = lastEmailed
        self.lastOpened = lastOpened
    }

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case firstName = "first_name"
        case lastName = "last_name"
        case phoneNumberID = "phone_number_id"
        case externalID = "external_id"
        case anonymousID = "anonymous_id"
        case addressLine1 = "address_line_1"
        case addressLine2 = "address_line_2"
        case city
        case stateProvinceRegion = "state_province_region"
        case postalCode = "postal_code"
        case country
        case alternateEmails = "alternate_emails"
        case phoneNumber = "phone_number"
        case whatsapp
        case line
        case facebook
        case uniqueName = "unique_name"
        case customFields = "custom_fields"
        case listIDs = "list_ids"
        case segmentIDs = "segment_ids"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case lastClicked = "last_clicked"
        case lastEmailed = "last_emailed"
        case lastOpened = "last_opened"
    }
}

// MARK: - Request / Response types

/// A request to add or update contacts in Marketing Campaigns.
///
/// Adding contacts is an asynchronous operation. The API returns a ``UpsertContactsResponse``
/// with a ``UpsertContactsResponse/jobID`` you can use to track the import status.
public struct UpsertContactsRequest: Codable, Sendable {
    /// The IDs of the lists to which the contacts will be added.
    public let listIDs: [String]?
    /// The contacts to add or update (maximum 30,000 per request).
    public let contacts: [Contact]

    public init(contacts: [Contact], listIDs: [String]? = nil) {
        self.contacts = contacts
        self.listIDs = listIDs
    }

    enum CodingKeys: String, CodingKey {
        case listIDs = "list_ids"
        case contacts
    }
}

/// The response to a contact upsert request, containing an asynchronous job ID.
public struct UpsertContactsResponse: Codable, Sendable {
    /// The ID of the asynchronous job processing the contacts.
    public let jobID: String?

    enum CodingKeys: String, CodingKey {
        case jobID = "job_id"
    }
}

/// The response from ``SendGridContactClient/getSampleContacts()``.
///
/// Contains up to 50 of the most recently updated contacts and the total contact count
/// for the account. Pagination of this endpoint has been deprecated by SendGrid.
/// Use ``SendGridContactClient/exportContacts(_:)`` to retrieve all contacts.
public struct ContactsResponse: Codable, Sendable {
    /// Up to 50 of the most recently updated contacts.
    public let result: [Contact]?
    /// The total number of contacts stored in your account.
    public let contactCount: Int?
    /// Metadata containing a link to this response.
    public let metadata: ContactMetadata?

    enum CodingKeys: String, CodingKey {
        case result
        case contactCount = "contact_count"
        case metadata = "_metadata"
    }
}

/// A request to search for contacts using an SGQL query string.
public struct ContactSearchRequest: Codable, Sendable {
    /// An SGQL (SendGrid Query Language) query string to filter contacts.
    /// Example: `"email LIKE '%@example.com'"`
    public let query: String

    public init(query: String) {
        self.query = query
    }
}

/// The response to a contact search request.
public struct ContactSearchResponse: Codable, Sendable {
    /// The contacts matching the search query.
    public let result: [Contact]?
    /// The total number of contacts matching the query.
    public let contactCount: Int?
    /// Pagination metadata for the response.
    public let metadata: ContactMetadata?

    enum CodingKeys: String, CodingKey {
        case result
        case contactCount = "contact_count"
        case metadata = "_metadata"
    }
}

/// The total and billable contact counts for your SendGrid account.
public struct ContactCount: Codable, Sendable {
    /// The total number of contacts stored in your account.
    public let contactCount: Int?
    /// The number of contacts that count toward your billing.
    public let billableCount: Int?

    enum CodingKeys: String, CodingKey {
        case contactCount = "contact_count"
        case billableCount = "billable_count"
    }
}

/// The response to an asynchronous contact operation, containing the job ID.
public struct ContactJobResponse: Codable, Sendable {
    /// The ID of the asynchronous job.
    public let jobID: String?

    enum CodingKeys: String, CodingKey {
        case jobID = "job_id"
    }
}
