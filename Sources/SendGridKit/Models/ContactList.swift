/// A SendGrid Marketing Campaigns contact list.
public struct ContactList: Codable, Sendable {
    /// The SendGrid-assigned unique identifier for the list.
    public let id: String?
    /// The name of the contact list.
    public let name: String?
    /// The number of contacts associated with this list.
    public let contactCount: Int?
    /// Pagination metadata for the list (present on collection responses).
    public let metadata: ContactMetadata?
    /// A sample of contacts from the list (present when requested on a single-list GET).
    public let contactSample: [Contact]?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case contactCount = "contact_count"
        case metadata = "_metadata"
        case contactSample = "contact_sample"
    }
}

/// A paginated collection of contact lists returned by the SendGrid API.
public struct ContactListsResponse: Codable, Sendable {
    /// The contact lists.
    public let result: [ContactList]?
    /// The total number of contacts across all lists.
    public let contactCount: Int?
    /// Pagination metadata for the response.
    public let metadata: ContactMetadata?

    enum CodingKeys: String, CodingKey {
        case result
        case contactCount = "contact_count"
        case metadata = "_metadata"
    }
}

/// A request to create a new contact list.
public struct CreateContactListRequest: Codable, Sendable {
    /// The name for the new contact list.
    public let name: String

    public init(name: String) {
        self.name = name
    }
}

/// A request to rename an existing contact list.
public struct UpdateContactListRequest: Codable, Sendable {
    /// The new name for the contact list.
    public let name: String

    public init(name: String) {
        self.name = name
    }
}

/// A request to remove specific contacts from a contact list.
///
/// Removing contacts from a list does not delete them from your account.
public struct RemoveContactsFromListRequest: Codable, Sendable {
    /// The IDs of the contacts to remove from the list.
    public let contactIDs: [String]

    public init(contactIDs: [String]) {
        self.contactIDs = contactIDs
    }

    enum CodingKeys: String, CodingKey {
        case contactIDs = "contact_ids"
    }
}
