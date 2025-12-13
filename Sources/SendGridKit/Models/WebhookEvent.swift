import Foundation

/// Main webhook event enum that encompasses all SendGrid webhook event types
public enum SendGridWebhookEvent: Codable, Sendable {
    case delivery(SendGridDeliveryEvent)
    case engagement(SendGridEngagementEvent)
    case accountStatusChange(SendGridAccountStatusChangeEvent)
    case received(SendGridReceivedEvent)

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
        case received
    }

    /// Shared structures used across different event types
    public struct Pool: Codable, Sendable {
        public let name: String
        public let id: Int
    }

    public struct Newsletter: Codable, Sendable {
        public let newsletterUserListID: String
        public let newsletterID: String
        public let newsletterSendID: String

        enum CodingKeys: String, CodingKey {
            case newsletterUserListID = "newsletter_user_list_id"
            case newsletterID = "newsletter_id"
            case newsletterSendID = "newsletter_send_id"
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
                    debugDescription: "Could not determine SendGrid webhook event type"
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
        case .received:
            self = .received(try container.decode(SendGridReceivedEvent.self))
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
        case .received(let event):
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
    /// SendGrid documentation states that `unique_args` should only contain string values.
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
    /// Content type of the email (html or text).
    public let sgContentType: String?
    /// Custom arguments passed with the message.
    /// Note: SendGrid can send categories as either a string or array. This field normalizes both to an array.
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
        case sgContentType = "sg_content_type"
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

/// Received events from inbound email processing
public struct SendGridReceivedEvent: Codable, Sendable {
    /// Type of event (always "received").
    public let event: String
    /// Received message ID.
    public let recvMsgid: String
    /// Unique ID attached to this event.
    public let sgEventId: String
    /// Unix timestamp when the event occurred.
    public let timestamp: Date
    /// API key ID used.
    public let apiKeyId: String?
    /// API version used.
    public let apiVersion: String?
    /// Client IP address.
    public let clientIp: String?
    /// Protocol used (SMTP, HTTP, etc.).
    public let `protocol`: String?
    /// Number of recipients.
    public let recipientCount: Int?
    /// Reseller ID.
    public let resellerId: String?
    /// Size of the message in bytes.
    public let size: Int?
    /// User agent string.
    public let useragent: String?
    /// V3 payload details containing message breakdown information.
    public let v3PayloadDetails: V3PayloadDetails?

    /// Detailed breakdown of V3 payload information.
    public struct V3PayloadDetails: Codable, Sendable {
        public let textPlain: Int?
        public let textHtml: Int?
        public let contentBytes: Int?
        public let recipientCount: Int?
        public let substitutionBytes: Int?
        public let substitutionCount: Int?
        public let senderCount: Int?
        public let customargCount: Int?
        public let attachmentsBytes: Int?
        public let customargLargestBytes: Int?
        public let personalizationCount: Int?

        enum CodingKeys: String, CodingKey {
            case textPlain = "text/plain"
            case textHtml = "text/html"
            case contentBytes = "content_bytes"
            case recipientCount = "recipient_count"
            case substitutionBytes = "substitution_bytes"
            case substitutionCount = "substitution_count"
            case senderCount = "sender_count"
            case customargCount = "customarg_count"
            case attachmentsBytes = "attachments_bytes"
            case customargLargestBytes = "customarg_largest_bytes"
            case personalizationCount = "personalization_count"
        }
    }

    enum CodingKeys: String, CodingKey {
        case event
        case recvMsgid = "recv_msgid"
        case sgEventId = "sg_event_id"
        case timestamp
        case apiKeyId = "api_key_id"
        case apiVersion = "api_version"
        case clientIp = "client_ip"
        case `protocol`
        case recipientCount = "recipient_count"
        case resellerId = "reseller_id"
        case size
        case useragent
        case v3PayloadDetails = "v3_payload_details"
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
        sgContentType = try container.decodeIfPresent(String.self, forKey: .sgContentType)
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
        try container.encodeIfPresent(sgContentType, forKey: .sgContentType)
        try container.encodeIfPresent(uniqueArgs, forKey: .uniqueArgs)

        // Encode timestamp as Unix timestamp
        try container.encode(timestamp.timeIntervalSince1970, forKey: .timestamp)
    }
}

extension SendGridReceivedEvent {
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        event = try container.decode(String.self, forKey: .event)
        recvMsgid = try container.decode(String.self, forKey: .recvMsgid)
        sgEventId = try container.decode(String.self, forKey: .sgEventId)
        apiKeyId = try container.decodeIfPresent(String.self, forKey: .apiKeyId)
        apiVersion = try container.decodeIfPresent(String.self, forKey: .apiVersion)
        clientIp = try container.decodeIfPresent(String.self, forKey: .clientIp)
        `protocol` = try container.decodeIfPresent(String.self, forKey: .protocol)
        recipientCount = try container.decodeIfPresent(Int.self, forKey: .recipientCount)
        resellerId = try container.decodeIfPresent(String.self, forKey: .resellerId)
        size = try container.decodeIfPresent(Int.self, forKey: .size)
        useragent = try container.decodeIfPresent(String.self, forKey: .useragent)
        v3PayloadDetails = try container.decodeIfPresent(V3PayloadDetails.self, forKey: .v3PayloadDetails)

        // Handle timestamp as Unix timestamp
        let timestampValue = try container.decode(Double.self, forKey: .timestamp)
        timestamp = Date(timeIntervalSince1970: timestampValue)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(event, forKey: .event)
        try container.encode(recvMsgid, forKey: .recvMsgid)
        try container.encode(sgEventId, forKey: .sgEventId)
        try container.encodeIfPresent(apiKeyId, forKey: .apiKeyId)
        try container.encodeIfPresent(apiVersion, forKey: .apiVersion)
        try container.encodeIfPresent(clientIp, forKey: .clientIp)
        try container.encodeIfPresent(`protocol`, forKey: .protocol)
        try container.encodeIfPresent(recipientCount, forKey: .recipientCount)
        try container.encodeIfPresent(resellerId, forKey: .resellerId)
        try container.encodeIfPresent(size, forKey: .size)
        try container.encodeIfPresent(useragent, forKey: .useragent)
        try container.encodeIfPresent(v3PayloadDetails, forKey: .v3PayloadDetails)

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

public struct EventWebhookInput: Codable, Sendable {
    /// Set this property to true to enable the Event Webhook or false to disable it.
    public let enabled: Bool
    /// Set this property to the URL where you want the Event Webhook to send event data.
    public let url: String
    /// Set this property to true to receive group resubscribe events.
    /// Group resubscribes occur when recipients resubscribe to a specific unsubscribe group by updating their subscription preferences.
    /// You must enable Subscription Tracking to receive this type of event.
    public let groupResubscribe: Bool
    /// Set this property to true to receive delivered events. Delivered events occur when a message has been successfully delivered to the receiving server.
    public let delivered: Bool
    /// Set this property to true to receive group unsubscribe events.
    /// Group unsubscribes occur when recipients unsubscribe from a specific unsubscribe group either by direct link or by updating their subscription preferences.
    /// You must enable Subscription Tracking to receive this type of event.
    public let groupUnsubscribe: Bool
    /// Set this property to true to receive spam report events. Spam reports occur when recipients mark a message as spam.
    public let spamReport: Bool
    /// Set this property to true to receive bounce events. A bounce occurs when a receiving server could not or would not accept a message.
    public let bounce: Bool
    /// Set this property to true to receive deferred events. Deferred events occur when a recipient's email server temporarily rejects a message.
    public let deferred: Bool
    /// Set this property to true to receive unsubscribe events.
    /// Unsubscribes occur when recipients click on a message's subscription management link.
    /// You must enable Subscription Tracking to receive this type of event.
    public let unsubscribe: Bool
    /// Set this property to true to receive processed events.
    /// Processed events occur when a message has been received by Twilio SendGrid and the message is ready to be delivered.
    public let processed: Bool
    /// Set this property to true to receive open events. Open events occur when a recipient has opened the HTML message.
    /// You must enable Open Tracking to receive this type of event.
    public let open: Bool
    /// Set this property to true to receive click events.
    /// Click events occur when a recipient clicks on a link within the message.
    /// You must enable Click Tracking to receive this type of event.
    public let click: Bool
    /// Set this property to true to receive dropped events. Dropped events occur when your message is not delivered by Twilio SendGrid.
    /// Dropped events are accomponied by a reason property, which indicates why the message was dropped.
    /// Reasons for a dropped message include: Invalid SMTPAPI header, Spam Content (if spam checker app enabled), Unsubscribed Address, Bounced Address, Spam Reporting Address, Invalid, Recipient List over Package Quota.
    public let dropped: Bool
    /// Optionally set this property to a friendly name for the Event Webhook.
    /// A friendly name may be assigned to each of your webhooks to help you differentiate them.
    /// The friendly name is for convenience only. You should use the webhook id property for any programmatic tasks.
    public let friendlyName: String?
    /// Set this property to the OAuth client ID that SendGrid will pass to your OAuth server or service provider to generate an OAuth access token.
    /// When passing data in this property, you must also include the oauth_token_url property.
    public let oauthClientId: String?
    /// Set this property to the OAuth client secret that SendGrid will pass to your OAuth server or service provider to generate an OAuth access token.
    /// This secret is needed only once to create an access token. SendGrid will store the secret, allowing you to update your client ID and Token URL without passing the secret to SendGrid again.
    /// When passing data in this field, you must also include the oauth_client_id and oauth_token_url properties.
    public let oauthClientSecret: String?
    /// Set this property to the URL where SendGrid will send the OAuth client ID and client secret to generate an OAuth access token.
    /// This should be your OAuth server or service provider. When passing data in this field, you must also include the oauth_client_id property.
    public let oauthTokenUrl: String?

    public init(
        enabled: Bool,
        url: String,
        groupResubscribe: Bool,
        delivered: Bool,
        groupUnsubscribe: Bool,
        spamReport: Bool,
        bounce: Bool,
        deferred: Bool,
        unsubscribe: Bool,
        processed: Bool,
        open: Bool,
        click: Bool,
        dropped: Bool,
        friendlyName: String?,
        oauthClientId: String?,
        oauthClientSecret: String?,
        oauthTokenUrl: String?
    ) {
        self.enabled = enabled
        self.url = url
        self.groupResubscribe = groupResubscribe
        self.delivered = delivered
        self.groupUnsubscribe = groupUnsubscribe
        self.spamReport = spamReport
        self.bounce = bounce
        self.deferred = deferred
        self.unsubscribe = unsubscribe
        self.processed = processed
        self.open = open
        self.click = click
        self.dropped = dropped
        self.friendlyName = friendlyName
        self.oauthClientId = oauthClientId
        self.oauthClientSecret = oauthClientSecret
        self.oauthTokenUrl = oauthTokenUrl
    }

    enum CodingKeys: String, CodingKey {
        case enabled
        case url
        case groupResubscribe = "group_resubscribe"
        case delivered
        case groupUnsubscribe = "group_unsubscribe"
        case spamReport = "spam_report"
        case bounce
        case deferred
        case unsubscribe
        case processed
        case open
        case click
        case dropped
        case friendlyName = "friendly_name"
        case oauthClientId = "oauth_client_id"
        case oauthClientSecret = "oauth_client_secret"
        case oauthTokenUrl = "oauth_token_url"
    }
}

public struct WebhookSettingsResponse: Codable, Sendable {
    /// A unique string used to identify the webhook. A webhook's ID is generated programmatically and cannot be changed after creation.
    /// You can assign a natural language identifier to your webhook using the friendly_name property.
    public let id: String
    /// An ISO 8601 timestamp in UTC timezone when the Event Webhook was created.
    /// If a Webhook's created_date is null, it is a legacy Event Webook , which means it is your oldest Webhook.
    public let createdAt: Date?
    /// Set this property to true to enable the Event Webhook or false to disable it.
    public let enabled: Bool
    /// Set this property to the URL where you want the Event Webhook to send event data.
    public let url: String
    /// Set this property to true to receive group resubscribe events.
    /// Group resubscribes occur when recipients resubscribe to a specific unsubscribe group by updating their subscription preferences.
    /// You must enable Subscription Tracking to receive this type of event.
    public let groupResubscribe: Bool
    /// Set this property to true to receive delivered events. Delivered events occur when a message has been successfully delivered to the receiving server.
    public let delivered: Bool
    /// Set this property to true to receive group unsubscribe events.
    /// Group unsubscribes occur when recipients unsubscribe from a specific unsubscribe group either by direct link or by updating their subscription preferences.
    /// You must enable Subscription Tracking to receive this type of event.
    public let groupUnsubscribe: Bool
    /// Set this property to true to receive spam report events. Spam reports occur when recipients mark a message as spam.
    public let spamReport: Bool
    /// Set this property to true to receive bounce events. A bounce occurs when a receiving server could not or would not accept a message.
    public let bounce: Bool
    /// Set this property to true to receive deferred events. Deferred events occur when a recipient's email server temporarily rejects a message.
    public let deferred: Bool
    /// Set this property to true to receive unsubscribe events.
    /// Unsubscribes occur when recipients click on a message's subscription management link.
    /// You must enable Subscription Tracking to receive this type of event.
    public let unsubscribe: Bool
    /// Set this property to true to receive processed events.
    /// Processed events occur when a message has been received by Twilio SendGrid and the message is ready to be delivered.
    public let processed: Bool
    /// Set this property to true to receive open events. Open events occur when a recipient has opened the HTML message.
    /// You must enable Open Tracking to receive this type of event.
    public let open: Bool
    /// Set this property to true to receive click events.
    /// Click events occur when a recipient clicks on a link within the message.
    /// You must enable Click Tracking to receive this type of event.
    public let click: Bool
    /// Set this property to true to receive dropped events. Dropped events occur when your message is not delivered by Twilio SendGrid.
    /// Dropped events are accomponied by a reason property, which indicates why the message was dropped.
    /// Reasons for a dropped message include: Invalid SMTPAPI header, Spam Content (if spam checker app enabled), Unsubscribed Address, Bounced Address, Spam Reporting Address, Invalid, Recipient List over Package Quota.
    public let dropped: Bool
    /// Optionally set this property to a friendly name for the Event Webhook.
    /// A friendly name may be assigned to each of your webhooks to help you differentiate them.
    /// The friendly name is for convenience only. You should use the webhook id property for any programmatic tasks.
    public let friendlyName: String?
    /// Set this property to the OAuth client ID that SendGrid will pass to your OAuth server or service provider to generate an OAuth access token.
    /// When passing data in this property, you must also include the oauth_token_url property.
    public let oauthClientId: String?
    /// Set this property to the OAuth client secret that SendGrid will pass to your OAuth server or service provider to generate an OAuth access token.
    /// This secret is needed only once to create an access token. SendGrid will store the secret, allowing you to update your client ID and Token URL without passing the secret to SendGrid again.
    /// When passing data in this field, you must also include the oauth_client_id and oauth_token_url properties.
    public let oauthClientSecret: String?
    /// Set this property to the URL where SendGrid will send the OAuth client ID and client secret to generate an OAuth access token.
    /// This should be your OAuth server or service provider. When passing data in this field, you must also include the oauth_client_id property.
    public let oauthTokenUrl: String?
    /// An ISO 8601 timestamp in UTC timezone when the Event Webhook was last modified.
    public let updatedAt: Date
    /// Indicates if the webhook is configured to send account status change events related to compliance action taken by SendGrid.
    public let accountStatusChange: Bool?
    /// The public key you can use to verify the SendGrid signature.
    public let publicKey: String?

    enum CodingKeys: String, CodingKey {
        case id
        case createdAt = "created_date"
        case enabled
        case url
        case groupResubscribe = "group_resubscribe"
        case delivered
        case groupUnsubscribe = "group_unsubscribe"
        case spamReport = "spam_report"
        case bounce
        case deferred
        case unsubscribe
        case processed
        case open
        case click
        case dropped
        case friendlyName = "friendly_name"
        case oauthClientId = "oauth_client_id"
        case oauthClientSecret = "oauth_client_secret"
        case oauthTokenUrl = "oauth_token_url"
        case updatedAt = "updated_date"
        case accountStatusChange = "account_status_change"
        case publicKey = "public_key"
    }
}

public struct SendGridTestWebhookInput: Codable, Sendable {
    /// The ID of the Event Webhook you want to retrieve.
    public let id: String
    /// The URL where you would like the test notification to be sent.
    public let url: String
    /// The client ID Twilio SendGrid sends to your OAuth server or service provider to generate an OAuth access token.
    /// When passing data in this property, you must also include the oauth_token_url property.
    public let oauthClientId: String?
    /// The oauth_client_secret is needed only once to create an access token.
    /// SendGrid will store this secret, allowing you to update your Client ID and Token URL without passing the secret to SendGrid again.
    /// When passing data in this field, you must also include the oauth_client_id and oauth_token_url properties.
    public let oauthClientSecret: String?
    /// The URL where Twilio SendGrid sends the Client ID and Client Secret to generate an access token.
    /// This should be your OAuth server or service provider. When passing data in this field, you must also include the oauth_client_id property.
    public let oauthTokenUrl: String?

    public init(
        id: String,
        url: String,
        oauthClientId: String?,
        oauthClientSecret: String?,
        oauthTokenUrl: String?
    ) {
        self.id = id
        self.url = url
        self.oauthClientId = oauthClientId
        self.oauthClientSecret = oauthClientSecret
        self.oauthTokenUrl = oauthTokenUrl
    }

    enum CodingKeys: String, CodingKey {
        case id
        case url
        case oauthClientId = "oauth_client_id"
        case oauthClientSecret = "oauth_client_secret"
        case oauthTokenUrl = "oauth_token_url"
    }
}

public struct AllEventWebhooks: Codable, Sendable {
    /// The maximum number of Event Webhooks you can have enabled under your current Twilio SendGrid plan.
    /// See the Twilio SendGrid pricing page for more information about the features available with each plan.
    public let maxAllowed: Int
    /// An array of Event Webhook objects. Each object represents one of your webhooks and contains its configuration settings,
    /// including which events it is set to send in the POST request, the URL where it will send those events, and the webhook's ID.
    public let webhooks: [WebhookSettingsResponse]

    public init(maxAllowed: Int, webhooks: [WebhookSettingsResponse]) {
        self.maxAllowed = maxAllowed
        self.webhooks = webhooks
    }

    enum CodingKeys: String, CodingKey {
        case maxAllowed = "max_allowed"
        case webhooks
    }
}

struct ToogleEventWebhookSignatureVerification: Codable, Sendable {
    public let enabled: Bool
    
    public init(enabled: Bool) {
        self.enabled = enabled
    }
}

public struct EventWebhookSignaturePublicKeyResponse: Codable, Sendable {
    /// A unique string used to identify the webhook. A webhook's ID is generated programmatically and cannot be changed after creation.
    /// You can assign a natural language identifier to your webhook using the friendly_name property.
    public let id: String
    /// The public key you can use to verify the Twilio SendGrid signature.
    public let publicKey: String

    public init(id: String, publicKey: String) {
        self.id = id
        self.publicKey = publicKey
    }

    enum CodingKeys: String, CodingKey {
        case id
        case publicKey = "public_key"
    }
}

public struct ParseWebhookSettingsResponse: Codable, Sendable {
    /// The public URL where you would like SendGrid to POST the data parsed from your email.
    /// Any emails sent with the given hostname provided (whose MX records have been updated to point to SendGrid) will be parsed and POSTed to this URL.
    public let url: String
    /// A specific and unique domain or subdomain that you have created to use exclusively to parse your incoming email. For example, parse.yourdomain.com.
    public let hostname: String
    /// Indicates if you would like SendGrid to check the content parsed from your emails for spam before POSTing them to your domain.
    public let spamCheck: Bool
    /// Indicates if you would like SendGrid to post the original MIME-type content of your parsed email.
    /// When this parameter is set to true, SendGrid will send a JSON payload of the content of your email.
    public let sendRaw: Bool

    public init(url: String, hostname: String, spamCheck: Bool, sendRaw: Bool) {
        self.url = url
        self.hostname = hostname
        self.spamCheck = spamCheck
        self.sendRaw = sendRaw
    }

    enum CodingKeys: String, CodingKey {
        case url
        case hostname
        case spamCheck = "spam_check"
        case sendRaw = "send_raw"
    }
}

/// How you would like the statistics to by grouped.
public enum SendGridInboundParseAggregateBy: String, Codable, Sendable {
    case day, week, month
}

public struct ParseWebhookSettingsStatistics: Codable, Sendable {
    /// The date that the stats were collected.
    public let date: Date
    /// The Parse Webhook usage statistics.
    public let stats: [Metric]

    public struct Metric: Codable, Sendable {
        /// The number of emails received and parsed by the Parse Webhook.
        public let received: Int
    }
}
