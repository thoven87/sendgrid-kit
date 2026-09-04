/// A request to export contacts from your SendGrid Marketing Campaigns account.
///
/// Exports are processed asynchronously. Use the returned ``ContactExportResponse/id``
/// to poll ``SendGridContactClient/getContactExport(id:)`` until the status is ``ContactExportResponse/Status/ready``.
public struct ContactExportRequest: Codable, Sendable {
    /// The IDs of specific lists to export. Omit to export all contacts.
    public let listIDs: [String]?
    /// The IDs of specific segments to export.
    public let segmentIDs: [String]?
    /// The file format for the export. Defaults to CSV when omitted.
    public let fileType: FileType?
    /// The maximum file size in MB for each export file. Files exceeding this size are split.
    public let maxFileSize: Int?
    /// Notification settings for the export job.
    public let notifications: Notifications?

    /// The file format of the exported contacts.
    public enum FileType: String, Codable, Sendable {
        case csv
        case json
    }

    /// Notification settings for a contact export job.
    public struct Notifications: Codable, Sendable {
        /// Whether to send an email notification when the export is ready.
        public let email: Bool?

        public init(email: Bool? = nil) {
            self.email = email
        }
    }

    public init(
        listIDs: [String]? = nil,
        segmentIDs: [String]? = nil,
        fileType: FileType? = nil,
        maxFileSize: Int? = nil,
        notifications: Notifications? = nil
    ) {
        self.listIDs = listIDs
        self.segmentIDs = segmentIDs
        self.fileType = fileType
        self.maxFileSize = maxFileSize
        self.notifications = notifications
    }

    enum CodingKeys: String, CodingKey {
        case listIDs = "list_ids"
        case segmentIDs = "segment_ids"
        case fileType = "file_type"
        case maxFileSize = "max_file_size"
        case notifications
    }
}

/// The status and details of a contact export job.
public struct ContactExportResponse: Codable, Sendable {
    /// The SendGrid-assigned unique identifier for the export job.
    public let id: String?
    /// The current status of the export job.
    public let status: Status?
    /// The ISO 8601 date-time string when the export was created.
    public let createdAt: String?
    /// The ISO 8601 date-time string when the export was last updated.
    public let updatedAt: String?
    /// The ISO 8601 date-time string when the download URLs expire (12 hours after initiation).
    public let expiresAt: String?
    /// The download URLs for the exported files. Populated when status is ``Status/ready``.
    public let urls: [String]?
    /// A human-readable message about the export status.
    public let message: String?
    /// The total number of contacts included in the export.
    public let contactCount: Int?

    /// The processing status of a contact export job.
    public enum Status: String, Codable, Sendable {
        case pending
        case ready
        case failed
    }

    enum CodingKeys: String, CodingKey {
        case id
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case expiresAt = "expires_at"
        case urls
        case message
        case contactCount = "contact_count"
    }
}
