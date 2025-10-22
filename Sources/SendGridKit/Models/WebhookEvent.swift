import Foundation

/// Main webhook event enum that encompasses all SendGrid webhook event types
public enum SendGridWebhookEvent: Codable, Sendable {
    case delivery(SendGridDeliveryEvent)
    case engagement(SendGridEngagementEvent)
    case accountStatusChange(SendGridAccountStatusChangeEvent)

    /// Common event types used for initial parsing
    public enum EventType: String, Codable, Sendable {
        case bounce
        case click
        case deferred
        case delivered
        case dropped
        case groupResubscribe = "group_resubscribe"
        case groupUnsubscribe = "group_unsubscribe"
        case open
        case processed
        case spamreport
        case unsubscribe
        case blocked
        case accountStatusChange = "account_status_change"
    }

    /// Shared structures used across different event types
    public struct Pool: Codable, Sendable {
        public let name: String
        public let id: Int
    }

    public struct Newsletter: Codable, Sendable {
        public let newsletterUserListId: String
        public let newsletterId: String
        public let newsletterSendId: String

        enum CodingKeys: String, CodingKey {
            case newsletterUserListId = "newsletter_user_list_id"
            case newsletterId = "newsletter_id"
            case newsletterSendId = "newsletter_send_id"
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Try to decode as a generic event first to determine the event type
        let eventData = try container.decode([String: AnyCodable].self)

        guard let eventTypeString = eventData["event"]?.value as? String,
            let eventType = SendGridWebhookEvent.EventType(rawValue: eventTypeString)
        else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Could not determine event type"
                )
            )
        }

        switch eventType {
        case .bounce, .delivered, .deferred, .dropped, .processed, .blocked:
            self = .delivery(try container.decode(SendGridDeliveryEvent.self))
        case .click, .open, .spamreport, .unsubscribe, .groupResubscribe, .groupUnsubscribe:
            self = .engagement(try container.decode(SendGridEngagementEvent.self))
        case .accountStatusChange:
            self = .accountStatusChange(try container.decode(SendGridAccountStatusChangeEvent.self))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .delivery(let event):
            try container.encode(event)
        case .engagement(let event):
            try container.encode(event)
        case .accountStatusChange(let event):
            try container.encode(event)
        }
    }
}

/// Delivery events: bounce, delivered, deferred, dropped, processed, blocked
public struct SendGridDeliveryEvent: Codable, Sendable {
    /// ID of the unsubscribe group that includes the recipient's email address.
    public let asmGroupId: Int?
    /// Grouping of SMTP failure messages into classifications.
    public let bounceClassification: String?
    /// Number of times SendGrid attempted to deliver this message.
    public let attempt: Int?
    /// Categories assigned to the message.
    /// Note: SendGrid can send categories as either a string or array. This field normalizes both to an array.
    public let category: [String]?
    /// Email address to which SendGrid sent the message.
    public let email: String
    /// The domain portion of the email address.
    public let domain: String?
    /// The sender's email address.
    public let from: String?
    /// Type of delivery event.
    public let event: DeliveryEventType
    /// IP address used to send the email.
    public let ip: String?
    /// Marketing campaign ID.
    public let marketingCampaignId: Int?
    /// Marketing campaign name.
    public let marketingCampaignName: String?
    /// Marketing campaign version for A/B tests.
    public let marketingCampaignVersion: String?
    /// Marketing campaign split ID for A/B tests.
    public let marketingCampaignSplitId: Int?
    /// Newsletter information for legacy marketing campaigns.
    public let newsletter: SendGridWebhookEvent.Newsletter?
    /// IP Pool information.
    public let pool: SendGridWebhookEvent.Pool?
    /// Error response from the receiving server.
    public let reason: String?
    /// Full HTTP response error from receiving server.
    public let response: String?
    /// Unique ID attached to this event.
    public let sgEventId: String
    /// Unique message ID.
    public let sgMessageId: String
    /// Unique ID from the originating system.
    public let smtpId: String?
    /// HTTP status code as string.
    public let status: String?
    /// Unix timestamp when the event occurred.
    public let timestamp: Date
    /// TLS encryption flag.
    public let tls: Int?
    /// Type of bounce or status change.
    public let type: StatusType?
    /// Custom arguments passed with the message.
    /// SendGrid documentation states that unique_args should only contain string values.
    public let uniqueArgs: [String: String]?

    public enum DeliveryEventType: String, Codable, CaseIterable, Sendable {
        case bounce
        case delivered
        case deferred
        case dropped
        case processed
        case blocked
    }

    public enum StatusType: String, Codable, Sendable {
        case bounce
        case blocked
    }

    enum CodingKeys: String, CodingKey {
        case asmGroupId = "asm_group_id"
        case bounceClassification = "bounce_classification"
        case attempt
        case category
        case email
        case domain
        case from
        case event
        case ip
        case marketingCampaignId = "marketing_campaign_id"
        case marketingCampaignName = "marketing_campaign_name"
        case marketingCampaignVersion = "marketing_campaign_version"
        case marketingCampaignSplitId = "marketing_campaign_split_id"
        case newsletter
        case pool
        case reason
        case response
        case sgEventId = "sg_event_id"
        case sgMessageId = "sg_message_id"
        case smtpId = "smtp-id"
        case status
        case timestamp
        case tls
        case type
        case uniqueArgs = "unique_args"
    }
}

/// Engagement events: click, open, spamreport, unsubscribe, group_resubscribe, group_unsubscribe
public struct SendGridEngagementEvent: Codable, Sendable {
    /// ID of the unsubscribe group.
    public let asmGroupId: Int?
    /// Categories assigned to the message.
    /// Note: SendGrid can send categories as either a string or array. This field normalizes both to an array.
    public let category: [String]?
    /// Email address of the recipient.
    public let email: String
    /// Type of engagement event.
    public let event: EngagementEventType
    /// IP address of the recipient who engaged.
    public let ip: String?
    /// Marketing campaign ID.
    public let marketingCampaignId: Int?
    /// Marketing campaign name.
    public let marketingCampaignName: String?
    /// Newsletter information for legacy campaigns.
    public let newsletter: SendGridWebhookEvent.Newsletter?
    /// Unique ID attached to this event.
    public let sgEventId: String
    /// Unique message ID.
    public let sgMessageId: String
    /// Whether Apple Mail Privacy Protection generated the open.
    public let sgMachineOpen: Bool?
    /// Unique ID from the originating system.
    public let smtpId: String?
    /// Unix timestamp when the event occurred.
    public let timestamp: Date
    /// URL that was clicked (for click events).
    public let url: String?
    /// URL offset information for click events.
    public let urlOffset: UrlOffset?
    /// User agent of the recipient.
    public let useragent: String?
    /// Custom arguments passed with the message.
    /// SendGrid documentation states that unique_args should only contain string values.
    public let uniqueArgs: [String: String]?

    public enum EngagementEventType: String, Codable, CaseIterable, Sendable {
        case click
        case open
        case spamreport
        case unsubscribe
        case groupResubscribe = "group_resubscribe"
        case groupUnsubscribe = "group_unsubscribe"
    }

    public struct UrlOffset: Codable, Sendable {
        public let index: Int
        public let type: String
    }

    enum CodingKeys: String, CodingKey {
        case asmGroupId = "asm_group_id"
        case category
        case email
        case event
        case ip
        case marketingCampaignId = "marketing_campaign_id"
        case marketingCampaignName = "marketing_campaign_name"
        case newsletter
        case sgEventId = "sg_event_id"
        case sgMessageId = "sg_message_id"
        case sgMachineOpen = "sg_machine_open"
        case smtpId = "smtp-id"
        case timestamp
        case url
        case urlOffset = "url_offset"
        case useragent
        case uniqueArgs = "unique_args"
    }
}

/// Account status change events
public struct SendGridAccountStatusChangeEvent: Codable, Sendable {
    /// Type of event.
    public let event: String
    /// Unique ID attached to this event.
    public let sgEventId: String
    /// Unix timestamp when the event occurred.
    public let timestamp: Date
    /// Type of status change.
    public let type: AccountStatusType

    public enum AccountStatusType: String, Codable, Sendable {
        case complianceSuspend = "compliance_suspend"
        case complianceDeactivate = "compliance_deactivate"
        case complianceBan = "compliance_ban"
        case reactivate
    }

    enum CodingKeys: String, CodingKey {
        case event
        case sgEventId = "sg_event_id"
        case timestamp
        case type
    }
}

/// Helper type for handling dynamic JSON values used internally for event type detection
/// This is only used to determine the event type before parsing the specific event struct
private struct AnyCodable: Codable {
    let value: Any

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()

        if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Cannot decode value")
            )
        }
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()

        switch value {
        case let stringValue as String:
            try container.encode(stringValue)
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let arrayValue as [Any]:
            try container.encode(arrayValue.map(AnyCodable.init))
        case let dictValue as [String: Any]:
            try container.encode(dictValue.mapValues(AnyCodable.init))
        default:
            throw EncodingError.invalidValue(
                value,
                EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Cannot encode value")
            )
        }
    }

    private init(_ value: Any) {
        self.value = value
    }
}

// MARK: - Custom Date Decoding
extension SendGridDeliveryEvent {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        asmGroupId = try container.decodeIfPresent(Int.self, forKey: .asmGroupId)
        bounceClassification = try container.decodeIfPresent(String.self, forKey: .bounceClassification)
        attempt = try container.decodeIfPresent(Int.self, forKey: .attempt)

        // Handle category as either string or array, normalize to array
        if container.contains(.category) {
            if let categoryString = try? container.decode(String.self, forKey: .category) {
                category = [categoryString]
            } else {
                category = try container.decode([String].self, forKey: .category)
            }
        } else {
            category = nil
        }
        email = try container.decode(String.self, forKey: .email)
        domain = try container.decodeIfPresent(String.self, forKey: .domain)
        from = try container.decodeIfPresent(String.self, forKey: .from)
        event = try container.decode(DeliveryEventType.self, forKey: .event)
        ip = try container.decodeIfPresent(String.self, forKey: .ip)
        marketingCampaignId = try container.decodeIfPresent(Int.self, forKey: .marketingCampaignId)
        marketingCampaignName = try container.decodeIfPresent(String.self, forKey: .marketingCampaignName)
        marketingCampaignVersion = try container.decodeIfPresent(String.self, forKey: .marketingCampaignVersion)
        marketingCampaignSplitId = try container.decodeIfPresent(Int.self, forKey: .marketingCampaignSplitId)
        newsletter = try container.decodeIfPresent(SendGridWebhookEvent.Newsletter.self, forKey: .newsletter)
        pool = try container.decodeIfPresent(SendGridWebhookEvent.Pool.self, forKey: .pool)
        reason = try container.decodeIfPresent(String.self, forKey: .reason)
        response = try container.decodeIfPresent(String.self, forKey: .response)
        sgEventId = try container.decode(String.self, forKey: .sgEventId)
        sgMessageId = try container.decode(String.self, forKey: .sgMessageId)
        smtpId = try container.decodeIfPresent(String.self, forKey: .smtpId)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        tls = try container.decodeIfPresent(Int.self, forKey: .tls)
        type = try container.decodeIfPresent(StatusType.self, forKey: .type)
        uniqueArgs = try container.decodeIfPresent([String: String].self, forKey: .uniqueArgs)

        // Handle timestamp as Unix timestamp
        let timestampValue = try container.decode(Double.self, forKey: .timestamp)
        timestamp = Date(timeIntervalSince1970: timestampValue)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(asmGroupId, forKey: .asmGroupId)
        try container.encodeIfPresent(bounceClassification, forKey: .bounceClassification)
        try container.encodeIfPresent(attempt, forKey: .attempt)
        try container.encodeIfPresent(category, forKey: .category)
        try container.encode(email, forKey: .email)
        try container.encodeIfPresent(domain, forKey: .domain)
        try container.encodeIfPresent(from, forKey: .from)
        try container.encode(event, forKey: .event)
        try container.encodeIfPresent(ip, forKey: .ip)
        try container.encodeIfPresent(marketingCampaignId, forKey: .marketingCampaignId)
        try container.encodeIfPresent(marketingCampaignName, forKey: .marketingCampaignName)
        try container.encodeIfPresent(marketingCampaignVersion, forKey: .marketingCampaignVersion)
        try container.encodeIfPresent(marketingCampaignSplitId, forKey: .marketingCampaignSplitId)
        try container.encodeIfPresent(newsletter, forKey: .newsletter)
        try container.encodeIfPresent(pool, forKey: .pool)
        try container.encodeIfPresent(reason, forKey: .reason)
        try container.encodeIfPresent(response, forKey: .response)
        try container.encode(sgEventId, forKey: .sgEventId)
        try container.encode(sgMessageId, forKey: .sgMessageId)
        try container.encodeIfPresent(smtpId, forKey: .smtpId)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(tls, forKey: .tls)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encodeIfPresent(uniqueArgs, forKey: .uniqueArgs)

        // Encode timestamp as Unix timestamp
        try container.encode(timestamp.timeIntervalSince1970, forKey: .timestamp)
    }
}

extension SendGridEngagementEvent {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        asmGroupId = try container.decodeIfPresent(Int.self, forKey: .asmGroupId)

        // Handle category as either string or array, normalize to array
        if container.contains(.category) {
            if let categoryString = try? container.decode(String.self, forKey: .category) {
                category = [categoryString]
            } else {
                category = try container.decode([String].self, forKey: .category)
            }
        } else {
            category = nil
        }
        email = try container.decode(String.self, forKey: .email)
        event = try container.decode(EngagementEventType.self, forKey: .event)
        ip = try container.decodeIfPresent(String.self, forKey: .ip)
        marketingCampaignId = try container.decodeIfPresent(Int.self, forKey: .marketingCampaignId)
        marketingCampaignName = try container.decodeIfPresent(String.self, forKey: .marketingCampaignName)
        newsletter = try container.decodeIfPresent(SendGridWebhookEvent.Newsletter.self, forKey: .newsletter)
        sgEventId = try container.decode(String.self, forKey: .sgEventId)
        sgMessageId = try container.decode(String.self, forKey: .sgMessageId)
        sgMachineOpen = try container.decodeIfPresent(Bool.self, forKey: .sgMachineOpen)
        smtpId = try container.decodeIfPresent(String.self, forKey: .smtpId)
        url = try container.decodeIfPresent(String.self, forKey: .url)
        urlOffset = try container.decodeIfPresent(UrlOffset.self, forKey: .urlOffset)
        useragent = try container.decodeIfPresent(String.self, forKey: .useragent)
        uniqueArgs = try container.decodeIfPresent([String: String].self, forKey: .uniqueArgs)

        // Handle timestamp as Unix timestamp
        let timestampValue = try container.decode(Double.self, forKey: .timestamp)
        timestamp = Date(timeIntervalSince1970: timestampValue)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encodeIfPresent(asmGroupId, forKey: .asmGroupId)
        try container.encodeIfPresent(category, forKey: .category)
        try container.encode(email, forKey: .email)
        try container.encode(event, forKey: .event)
        try container.encodeIfPresent(ip, forKey: .ip)
        try container.encodeIfPresent(marketingCampaignId, forKey: .marketingCampaignId)
        try container.encodeIfPresent(marketingCampaignName, forKey: .marketingCampaignName)
        try container.encodeIfPresent(newsletter, forKey: .newsletter)
        try container.encode(sgEventId, forKey: .sgEventId)
        try container.encode(sgMessageId, forKey: .sgMessageId)
        try container.encodeIfPresent(sgMachineOpen, forKey: .sgMachineOpen)
        try container.encodeIfPresent(smtpId, forKey: .smtpId)
        try container.encodeIfPresent(url, forKey: .url)
        try container.encodeIfPresent(urlOffset, forKey: .urlOffset)
        try container.encodeIfPresent(useragent, forKey: .useragent)
        try container.encodeIfPresent(uniqueArgs, forKey: .uniqueArgs)

        // Encode timestamp as Unix timestamp
        try container.encode(timestamp.timeIntervalSince1970, forKey: .timestamp)
    }
}

extension SendGridAccountStatusChangeEvent {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        event = try container.decode(String.self, forKey: .event)
        sgEventId = try container.decode(String.self, forKey: .sgEventId)
        type = try container.decode(AccountStatusType.self, forKey: .type)

        // Handle timestamp as Unix timestamp
        let timestampValue = try container.decode(Double.self, forKey: .timestamp)
        timestamp = Date(timeIntervalSince1970: timestampValue)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(event, forKey: .event)
        try container.encode(sgEventId, forKey: .sgEventId)
        try container.encode(type, forKey: .type)

        // Encode timestamp as Unix timestamp
        try container.encode(timestamp.timeIntervalSince1970, forKey: .timestamp)
    }
}
