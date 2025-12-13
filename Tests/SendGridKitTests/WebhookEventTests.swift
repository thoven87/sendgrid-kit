import Foundation
import SendGridKit
import Testing

@Suite("SendGrid Webhook Event Tests")
struct WebhookEventTests {

    let client: SendGridWebhookClient
    // TODO: Replace with `false` when you have a valid API key
    let credentialsAreInvalid = true

    init() {
        // TODO: Replace with a valid API key to test
        client = SendGridWebhookClient(httpClient: .shared, apiKey: "YOUR-WEBHOOK-API-KEY")
    }

    @Test("Test Notification")
    func validateEmail() async throws {
        let testRequest = SendGridTestWebhookInput(
            id: "test",
            url: "https://example.com",
            oauthClientId: nil,
            oauthClientSecret: nil,
            oauthTokenUrl: nil
        )

        await withKnownIssue {
            await #expect(throws: Never.self) {
                try await client.testEventWebhook(testRequest)
            }
        } when: {
            credentialsAreInvalid
        }
    }

    // MARK: - Delivery Event Tests

    @Test("Decode Bounce Event")
    func decodeBounceEvent() throws {
        let json = """
            {
                "email": "test@example.com",
                "timestamp": 1513299569,
                "smtp-id": "<test_bounce_smtp_id@test.example.com>",
                "bounce_classification": "Invalid Address",
                "event": "bounce",
                "category": ["cat facts"],
                "sg_event_id": "test_bounce_event_id",
                "sg_message_id": "test_bounce_message_id",
                "reason": "500 unknown recipient",
                "status": "5.0.0",
                "type": "bounce"
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let event = try decoder.decode(SendGridDeliveryEvent.self, from: data)

        #expect(event.email == "test@example.com")
        #expect(event.event == .bounce)
        #expect(event.bounceClassification == "Invalid Address")
        #expect(event.reason == "500 unknown recipient")
        #expect(event.status == "5.0.0")
        #expect(event.type == .bounce)
        #expect(event.category == ["cat facts"])
        #expect(event.sgEventId == "test_bounce_event_id")
        #expect(event.timestamp == Date(timeIntervalSince1970: 1_513_299_569))
    }

    @Test("Decode Delivered Event")
    func decodeDeliveredEvent() throws {
        let json = """
            {
                "email": "test@example.com",
                "timestamp": 1513299569,
                "smtp-id": "<test_delivered_smtp_id@test.example.com>",
                "event": "delivered",
                "category": ["cat facts"],
                "sg_event_id": "test_delivered_event_id",
                "sg_message_id": "test_delivered_message_id",
                "response": "250 OK"
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let event = try decoder.decode(SendGridDeliveryEvent.self, from: data)

        #expect(event.email == "test@example.com")
        #expect(event.event == .delivered)
        #expect(event.response == "250 OK")
        #expect(event.category == ["cat facts"])
        #expect(event.sgEventId == "test_delivered_event_id")
    }

    @Test("Decode Deferred Event")
    func decodeDeferredEvent() throws {
        let json = """
            {
                "email": "test@example.com",
                "domain": "example.com",
                "from": "test@example.com",
                "timestamp": 1513299569,
                "smtp-id": "<test_deferred_smtp_id@test.example.com>",
                "event": "deferred",
                "category": ["cat facts"],
                "sg_event_id": "test_deferred_event_id",
                "sg_message_id": "test_deferred_message_id",
                "response": "400 try again later",
                "attempt": 5
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let event = try decoder.decode(SendGridDeliveryEvent.self, from: data)

        #expect(event.email == "test@example.com")
        #expect(event.domain == "example.com")
        #expect(event.from == "test@example.com")
        #expect(event.event == .deferred)
        #expect(event.attempt == 5)
        #expect(event.response == "400 try again later")
    }

    @Test("Decode Dropped Event")
    func decodeDroppedEvent() throws {
        let json = """
            {
                "email": "test@example.com",
                "timestamp": 1513299569,
                "smtp-id": "<test_dropped_smtp_id@test.example.com>",
                "event": "dropped",
                "category": ["cat facts"],
                "sg_event_id": "test_dropped_event_id",
                "sg_message_id": "test_dropped_message_id",
                "reason": "Bounced Address",
                "status": "5.0.0"
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let event = try decoder.decode(SendGridDeliveryEvent.self, from: data)

        #expect(event.email == "test@example.com")
        #expect(event.event == .dropped)
        #expect(event.reason == "Bounced Address")
        #expect(event.status == "5.0.0")
    }

    @Test("Decode Processed Event with Pool")
    func decodeProcessedEventWithPool() throws {
        let json = """
            {
                "email": "test@example.com",
                "timestamp": 1513299569,
                "pool": {
                    "name": "new_MY_test",
                    "id": 210
                },
                "smtp-id": "<test_processed_smtp_id@test.example.com>",
                "event": "processed",
                "category": ["cat facts"],
                "sg_event_id": "test_processed_pool_event_id",
                "sg_message_id": "test_processed_pool_message_id"
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let event = try decoder.decode(SendGridDeliveryEvent.self, from: data)

        #expect(event.email == "test@example.com")
        #expect(event.event == .processed)
        #expect(event.pool?.name == "new_MY_test")
        #expect(event.pool?.id == 210)
    }

    // MARK: - Engagement Event Tests

    @Test("Decode Click Event")
    func decodeClickEvent() throws {
        let json = """
            {
                "sg_event_id": "test_click_event_id",
                "sg_message_id": "test_click_message_id",
                "ip": "192.168.1.100",
                "useragent": "Mozilla/5.0 (iPhone; CPU iPhone OS 7_1_2 like Mac OS X)",
                "event": "click",
                "email": "test@example.com",
                "timestamp": 1249948800,
                "url": "http://example.com/blog/news.html",
                "url_offset": {
                    "index": 0,
                    "type": "html"
                },
                "category": ["category1", "category2"],
                "newsletter": {
                    "newsletter_user_list_id": "10557865",
                    "newsletter_id": "1943530",
                    "newsletter_send_id": "2308608"
                },
                "asm_group_id": 1
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let event = try decoder.decode(SendGridEngagementEvent.self, from: data)

        #expect(event.email == "test@example.com")
        #expect(event.event == .click)
        #expect(event.ip == "192.168.1.100")
        #expect(event.url == "http://example.com/blog/news.html")
        #expect(event.urlOffset?.index == 0)
        #expect(event.urlOffset?.type == "html")
        #expect(event.category == ["category1", "category2"])
        #expect(event.asmGroupId == 1)
        #expect(event.newsletter?.newsletterID == "1943530")
    }

    @Test("Decode Open Event")
    func decodeOpenEvent() throws {
        let json = """
            {
                "email": "test@example.com",
                "timestamp": 1513299569,
                "event": "open",
                "sg_machine_open": false,
                "category": ["cat facts"],
                "sg_event_id": "test_open_event_id",
                "sg_message_id": "test_open_message_id",
                "useragent": "Mozilla/4.0 (compatible; MSIE 6.1; Windows XP)",
                "ip": "192.168.1.100"
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let event = try decoder.decode(SendGridEngagementEvent.self, from: data)

        #expect(event.email == "test@example.com")
        #expect(event.event == .open)
        #expect(event.sgMachineOpen == false)
        #expect(event.ip == "192.168.1.100")
        #expect(event.useragent == "Mozilla/4.0 (compatible; MSIE 6.1; Windows XP)")
    }

    @Test("Decode Spam Report Event")
    func decodeSpamReportEvent() throws {
        let json = """
            {
                "email": "test@example.com",
                "timestamp": 1513299569,
                "smtp-id": "<test_spam_smtp_id@test.example.com>",
                "event": "spamreport",
                "sg_event_id": "test_spam_event_id",
                "sg_message_id": "test_spam_message_id"
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let event = try decoder.decode(SendGridEngagementEvent.self, from: data)

        #expect(event.email == "test@example.com")
        #expect(event.event == .spamreport)
        #expect(event.sgEventId == "test_spam_event_id")
    }

    @Test("Decode Unsubscribe Event")
    func decodeUnsubscribeEvent() throws {
        let json = """
            {
                "email": "test@example.com",
                "timestamp": 1513299569,
                "event": "unsubscribe",
                "category": ["cat facts"],
                "sg_event_id": "test_unsubscribe_event_id",
                "sg_message_id": "test_unsubscribe_message_id"
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let event = try decoder.decode(SendGridEngagementEvent.self, from: data)

        #expect(event.email == "test@example.com")
        #expect(event.event == .unsubscribe)
        #expect(event.category == ["cat facts"])
    }

    @Test("Decode Group Resubscribe Event")
    func decodeGroupResubscribeEvent() throws {
        let json = """
            {
                "email": "test@example.com",
                "timestamp": 1513299569,
                "smtp-id": "<test_group_resubscribe_smtp_id@test.example.com>",
                "event": "group_resubscribe",
                "category": ["cat facts"],
                "sg_event_id": "test_group_resubscribe_event_id",
                "sg_message_id": "test_group_resubscribe_message_id",
                "useragent": "Mozilla/4.0 (compatible; MSIE 6.1; Windows XP)",
                "ip": "192.168.1.100",
                "url": "http://www.example.com/",
                "asm_group_id": 10
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let event = try decoder.decode(SendGridEngagementEvent.self, from: data)

        #expect(event.email == "test@example.com")
        #expect(event.event == .groupResubscribe)
        #expect(event.asmGroupId == 10)
        #expect(event.url == "http://www.example.com/")
    }

    @Test("Decode Group Unsubscribe Event")
    func decodeGroupUnsubscribeEvent() throws {
        let json = """
            {
                "email": "test@example.com",
                "timestamp": 1513299569,
                "smtp-id": "<test_group_unsubscribe_smtp_id@test.example.com>",
                "event": "group_unsubscribe",
                "category": ["cat facts"],
                "sg_event_id": "test_group_unsubscribe_event_id",
                "sg_message_id": "test_group_unsubscribe_message_id",
                "useragent": "Mozilla/4.0 (compatible; MSIE 6.1; Windows XP)",
                "ip": "192.168.1.100",
                "url": "http://www.example.com/",
                "asm_group_id": 10
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let event = try decoder.decode(SendGridEngagementEvent.self, from: data)

        #expect(event.email == "test@example.com")
        #expect(event.event == .groupUnsubscribe)
        #expect(event.asmGroupId == 10)
    }

    // MARK: - Account Status Change Event Tests

    @Test("Decode Account Status Change Event")
    func decodeAccountStatusChangeEvent() throws {
        let json = """
            {
                "event": "account_status_change",
                "sg_event_id": "test_account_status_event_id",
                "timestamp": 1709142428,
                "type": "compliance_suspend"
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let event = try decoder.decode(SendGridAccountStatusChangeEvent.self, from: data)

        #expect(event.event == "account_status_change")
        #expect(event.type == .complianceSuspend)
        #expect(event.sgEventId == "test_account_status_event_id")
        #expect(event.timestamp == Date(timeIntervalSince1970: 1_709_142_428))
    }

    // MARK: - Marketing Campaign Event Tests

    @Test("Decode Marketing Campaign Event")
    func decodeMarketingCampaignEvent() throws {
        let json = """
            {
                "category": [],
                "email": "test@example.com",
                "event": "processed",
                "marketing_campaign_id": 12345,
                "marketing_campaign_name": "campaign name",
                "sg_event_id": "test_marketing_event_id",
                "sg_message_id": "test_marketing_message_id",
                "smtp-id": "<test_marketing_smtp_id@test.example.com>",
                "timestamp": 1442349428
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let event = try decoder.decode(SendGridDeliveryEvent.self, from: data)

        #expect(event.email == "test@example.com")
        #expect(event.event == .processed)
        #expect(event.marketingCampaignId == 12345)
        #expect(event.marketingCampaignName == "campaign name")
    }

    @Test("Decode A/B Test Marketing Campaign Event")
    func decodeABTestMarketingCampaignEvent() throws {
        let json = """
            {
                "category": [],
                "email": "test@example.com",
                "event": "processed",
                "marketing_campaign_id": 23314,
                "marketing_campaign_name": "unique args ab",
                "marketing_campaign_version": "B",
                "marketing_campaign_split_id": 13471,
                "sg_event_id": "test_ab_test_event_id",
                "sg_message_id": "test_ab_test_message_id",
                "smtp-id": "<test_ab_test_smtp_id@test.example.com>",
                "timestamp": 1442349848
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let event = try decoder.decode(SendGridDeliveryEvent.self, from: data)

        #expect(event.email == "test@example.com")
        #expect(event.event == .processed)
        #expect(event.marketingCampaignVersion == "B")
        #expect(event.marketingCampaignSplitId == 13471)
    }

    // MARK: - Legacy Newsletter Event Tests

    @Test("Decode Legacy Newsletter Unsubscribe Event")
    func decodeLegacyNewsletterUnsubscribeEvent() throws {
        let json = """
            {
                "email": "test@example.com",
                "timestamp": 1380822437,
                "newsletter": {
                    "newsletter_user_list_id": "10557865",
                    "newsletter_id": "1943530",
                    "newsletter_send_id": "2308608"
                },
                "category": ["Tests", "Newsletter"],
                "event": "unsubscribe",
                "sg_event_id": "test_event_id",
                "sg_message_id": "test_message_id"
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let event = try decoder.decode(SendGridEngagementEvent.self, from: data)

        #expect(event.email == "test@example.com")
        #expect(event.event == .unsubscribe)
        #expect(event.newsletter?.newsletterID == "1943530")
        #expect(event.newsletter?.newsletterUserListID == "10557865")
        #expect(event.newsletter?.newsletterSendID == "2308608")
        #expect(event.category == ["Tests", "Newsletter"])
    }

    // MARK: - Main Webhook Event Enum Tests

    @Test("Decode Webhook Event as Delivery Event")
    func decodeWebhookEventAsDeliveryEvent() throws {
        let json = """
            {
                "email": "test@example.com",
                "timestamp": 1513299569,
                "event": "delivered",
                "sg_event_id": "test_webhook_delivery_event_id",
                "sg_message_id": "test_webhook_delivery_message_id",
                "response": "250 OK"
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let webhookEvent = try decoder.decode(SendGridWebhookEvent.self, from: data)

        switch webhookEvent {
        case .delivery(let deliveryEvent):
            #expect(deliveryEvent.email == "test@example.com")
            #expect(deliveryEvent.event == .delivered)
        case .engagement(_):
            Issue.record("Expected delivery event but got engagement event")
        case .accountStatusChange(_):
            Issue.record("Expected delivery event but got account status change event")
        case .received(_):
            Issue.record("Expected delivery event but got received event")
        }
    }

    @Test("Decode Webhook Event as Engagement Event")
    func decodeWebhookEventAsEngagementEvent() throws {
        let json = """
            {
                "email": "test@example.com",
                "timestamp": 1513299569,
                "event": "open",
                "sg_event_id": "test_webhook_engagement_event_id",
                "sg_message_id": "test_webhook_engagement_message_id",
                "ip": "192.168.1.100"
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let webhookEvent = try decoder.decode(SendGridWebhookEvent.self, from: data)

        switch webhookEvent {
        case .delivery(_):
            Issue.record("Expected engagement event but got delivery event")
        case .engagement(let engagementEvent):
            #expect(engagementEvent.email == "test@example.com")
            #expect(engagementEvent.event == .open)
        case .accountStatusChange(_):
            Issue.record("Expected engagement event but got account status change event")
        case .received(_):
            Issue.record("Expected engagement event but got received event")
        }
    }

    @Test("Decode Webhook Event as Account Status Change Event")
    func decodeWebhookEventAsAccountStatusChangeEvent() throws {
        let json = """
            {
                "event": "account_status_change",
                "sg_event_id": "test_webhook_account_status_event_id",
                "timestamp": 1709142428,
                "type": "compliance_suspend"
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let webhookEvent = try decoder.decode(SendGridWebhookEvent.self, from: data)

        switch webhookEvent {
        case .delivery(_):
            Issue.record("Expected account status change event but got delivery event")
        case .engagement(_):
            Issue.record("Expected account status change event but got engagement event")
        case .accountStatusChange(let statusEvent):
            #expect(statusEvent.event == "account_status_change")
            #expect(statusEvent.type == .complianceSuspend)
        case .received(_):
            Issue.record("Expected account status change event but got received event")
        }
    }

    // MARK: - Custom Arguments Tests

    @Test("Decode Event with Custom Arguments")
    func decodeEventWithCustomArguments() throws {
        let json = """
            {
                "email": "test@example.com",
                "timestamp": 1513299569,
                "event": "processed",
                "sg_event_id": "test_event_id",
                "sg_message_id": "test_message_id",
                "unique_args": {
                    "user_id": "12345",
                    "campaign_name": "test_campaign",
                    "tracking_enabled": "true",
                    "priority": "1"
                }
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let event = try decoder.decode(SendGridDeliveryEvent.self, from: data)

        #expect(event.email == "test@example.com")
        #expect(event.event == .processed)

        // Test unique args - all values are strings as per SendGrid documentation
        #expect(event.uniqueArgs?["user_id"] == "12345")
        #expect(event.uniqueArgs?["campaign_name"] == "test_campaign")
        #expect(event.uniqueArgs?["tracking_enabled"] == "true")
        #expect(event.uniqueArgs?["priority"] == "1")
    }

    // MARK: - Array of Events Test

    @Test("Decode Array of Webhook Events")
    func decodeArrayOfWebhookEvents() throws {
        let json = """
            [
                {
                    "email": "test@example.com",
                    "timestamp": 1513299569,
                    "event": "delivered",
                    "sg_event_id": "delivered_event_id",
                    "sg_message_id": "test_array_delivered_message_id",
                    "response": "250 OK"
                },
                {
                    "email": "test@example.com",
                    "timestamp": 1513299570,
                    "event": "open",
                    "sg_event_id": "open_event_id",
                    "sg_message_id": "test_array_open_message_id",
                    "ip": "255.255.255.255"
                },
                {
                    "event": "account_status_change",
                    "sg_event_id": "status_change_event_id",
                    "timestamp": 1709142428,
                    "type": "compliance_suspend"
                }
            ]
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let events = try decoder.decode([SendGridWebhookEvent].self, from: data)

        #expect(events.count == 3)

        // First event should be delivery
        switch events[0] {
        case .delivery(let deliveryEvent):
            #expect(deliveryEvent.event == .delivered)
        default:
            Issue.record("Expected first event to be delivery")
        }

        // Second event should be engagement
        switch events[1] {
        case .engagement(let engagementEvent):
            #expect(engagementEvent.event == .open)
        default:
            Issue.record("Expected second event to be engagement")
        }

        // Third event should be account status change
        switch events[2] {
        case .accountStatusChange(let statusEvent):
            #expect(statusEvent.type == .complianceSuspend)
        default:
            Issue.record("Expected third event to be account status change")
        }
    }

    // MARK: - Error Handling Tests

    @Test("Decode Invalid Event Type")
    func decodeInvalidEventType() throws {
        let json = """
            {
                "email": "alex@example.com",
                "timestamp": 1513299569,
                "event": "invalid_event_type",
                "sg_event_id": "test_event_id",
                "sg_message_id": "test_message_id"
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(SendGridWebhookEvent.self, from: data)
        }
    }

    // MARK: - Webhook Payload with multiple events Tests

    @Test("Webhook Payload with multiple events")
    func webhookPayloadWithMultipleEvents() throws {
        // Webhook payload with multiple events
        let webhookPayload = """
            [
                {
                    "email": "user@example.com",
                    "timestamp": 1513299569,
                    "smtp-id": "<message@domain.com>",
                    "event": "processed",
                    "category": ["newsletter", "marketing"],
                    "sg_event_id": "processed-event-123",
                    "sg_message_id": "message-id-123",
                    "marketing_campaign_id": 12345,
                    "marketing_campaign_name": "Weekly Newsletter"
                },
                {
                    "email": "user@example.com",
                    "timestamp": 1513299570,
                    "event": "delivered",
                    "sg_event_id": "delivered-event-123",
                    "sg_message_id": "message-id-123",
                    "response": "250 2.0.0 OK"
                },
                {
                    "email": "user@example.com",
                    "timestamp": 1513299580,
                    "event": "open",
                    "sg_event_id": "open-event-123",
                    "sg_message_id": "message-id-123",
                    "ip": "192.168.1.100",
                    "useragent": "Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X)",
                    "sg_machine_open": false
                }
            ]
            """

        let data = webhookPayload.data(using: .utf8)!
        let decoder = JSONDecoder()

        let events = try decoder.decode([SendGridWebhookEvent].self, from: data)

        #expect(events.count == 3)

        // Verify each event type
        switch events[0] {
        case .delivery(let event):
            #expect(event.event == .processed)
            #expect(event.marketingCampaignId == 12345)
        default:
            Issue.record("Expected first event to be delivery")
        }

        switch events[1] {
        case .delivery(let event):
            #expect(event.event == .delivered)
            #expect(event.response == "250 2.0.0 OK")
        default:
            Issue.record("Expected second event to be delivery")
        }

        switch events[2] {
        case .engagement(let event):
            #expect(event.event == .open)
            #expect(event.sgMachineOpen == false)
        default:
            Issue.record("Expected third event to be engagement")
        }
    }

    @Test("Webhook event filtering by type")
    func webhookEventFiltering() throws {
        let mixedEvents = """
            [
                {
                    "email": "user1@example.com",
                    "timestamp": 1513299569,
                    "event": "bounce",
                    "sg_event_id": "bounce-1",
                    "sg_message_id": "msg-1",
                    "reason": "Invalid recipient"
                },
                {
                    "email": "user2@example.com",
                    "timestamp": 1513299570,
                    "event": "click",
                    "sg_event_id": "click-1",
                    "sg_message_id": "msg-2",
                    "url": "https://example.com/link"
                },
                {
                    "email": "user3@example.com",
                    "timestamp": 1513299571,
                    "event": "delivered",
                    "sg_event_id": "delivered-1",
                    "sg_message_id": "msg-3"
                }
            ]
            """

        let data = mixedEvents.data(using: .utf8)!
        let events = try JSONDecoder().decode([SendGridWebhookEvent].self, from: data)

        // Filter delivery events
        let deliveryEvents = events.compactMap { event in
            if case .delivery(let deliveryEvent) = event {
                return deliveryEvent
            }
            return nil
        }

        #expect(deliveryEvents.count == 2)  // bounce and delivered

        // Filter engagement events
        let engagementEvents = events.compactMap { event in
            if case .engagement(let engagementEvent) = event {
                return engagementEvent
            }
            return nil
        }

        #expect(engagementEvents.count == 1)  // click
    }

    @Test("Working with custom arguments")
    func workingWithCustomArguments() throws {
        let eventWithCustomArgs = """
            {
                "email": "customer@example.com",
                "timestamp": 1513299569,
                "event": "click",
                "sg_event_id": "click-event-123",
                "sg_message_id": "message-123",
                "url": "https://shop.example.com/product/123",
                "unique_args": {
                    "user_id": "12345",
                    "product_id": "PROD-123",
                    "campaign_type": "abandoned_cart",
                    "is_premium": "true",
                    "discount_percent": "15.5"
                }
            }
            """

        let data = eventWithCustomArgs.data(using: .utf8)!
        let webhookEvent = try JSONDecoder().decode(SendGridWebhookEvent.self, from: data)

        if case .engagement(let event) = webhookEvent {
            #expect(event.event == .click)
            #expect(event.url == "https://shop.example.com/product/123")

            // Extract custom arguments - all values are strings as per SendGrid documentation
            if let uniqueArgs = event.uniqueArgs {
                #expect(uniqueArgs["user_id"] == "12345")
                #expect(uniqueArgs["product_id"] == "PROD-123")
                #expect(uniqueArgs["campaign_type"] == "abandoned_cart")
                #expect(uniqueArgs["is_premium"] == "true")
                #expect(uniqueArgs["discount_percent"] == "15.5")
            }
        } else {
            Issue.record("Expected engagement event")
        }
    }

    @Test("Decode category as string - normalizes to array")
    func decodeCategoryAsString() throws {
        let json = """
            {
                "email": "test@example.com",
                "timestamp": 1513299569,
                "event": "delivered",
                "category": "newsletter",
                "sg_event_id": "test-event-id",
                "sg_message_id": "test-message-id"
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let event = try decoder.decode(SendGridDeliveryEvent.self, from: data)

        #expect(event.category == ["newsletter"])
    }

    @Test("Decode category as array - stays as array")
    func decodeCategoryAsArray() throws {
        let json = """
            {
                "email": "test@example.com",
                "timestamp": 1513299569,
                "event": "delivered",
                "category": ["newsletter", "marketing", "weekly"],
                "sg_event_id": "test-event-id",
                "sg_message_id": "test-message-id"
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let event = try decoder.decode(SendGridDeliveryEvent.self, from: data)

        #expect(event.category == ["newsletter", "marketing", "weekly"])
    }

    @Test("Decode engagement event category as string - normalizes to array")
    func decodeEngagementCategoryAsString() throws {
        let json = """
            {
                "email": "test@example.com",
                "timestamp": 1513299569,
                "event": "click",
                "category": "promotional",
                "sg_event_id": "test-event-id",
                "sg_message_id": "test-message-id",
                "url": "https://example.com"
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let event = try decoder.decode(SendGridEngagementEvent.self, from: data)

        #expect(event.category == ["promotional"])
    }

    @Test("Decode real-world open event with ISO 8601 timestamp")
    func decodeRealWorldOpenEvent() throws {
        let json = """
            {
              "event": "open",
              "email": "test@example.com",
              "sg_message_id": "test_real_world_open_message_id",
              "sg_event_id": "test_real_world_open_event_id",
              "timestamp": 1729555215,
              "ip": "192.168.1.100",
              "useragent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Safari/537.36",
              "sg_content_type": "html"
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let event = try decoder.decode(SendGridEngagementEvent.self, from: data)

        #expect(event.email == "test@example.com")
        #expect(event.event == .open)
        #expect(event.sgEventId == "test_real_world_open_event_id")
        #expect(event.ip == "192.168.1.100")
        #expect(event.sgContentType == "html")

        // Verify ISO 8601 timestamp parsing
        let expectedDate = Date(timeIntervalSince1970: 1_729_555_215)
        #expect(event.timestamp == expectedDate)
    }

    @Test("Decode Unix timestamp format still works")
    func decodeUnixTimestampFormat() throws {
        let json = """
            {
                "email": "test@example.com",
                "timestamp": 1513299569,
                "event": "delivered",
                "sg_event_id": "test-event-id",
                "sg_message_id": "test-message-id"
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let event = try decoder.decode(SendGridDeliveryEvent.self, from: data)

        #expect(event.timestamp == Date(timeIntervalSince1970: 1_513_299_569))
    }

    @Test("Decode received event")
    func decodeReceivedEvent() throws {
        let json = """
            {
              "event": "received",
              "recv_msgid": "test_received_msg_id",
              "sg_event_id": "test_received_event_id",
              "timestamp": 1729555201,
              "api_key_id": "test_api_key_id",
              "client_ip": "192.168.1.101",
              "protocol": "SMTP",
              "recipient_count": 1,
              "reseller_id": "48997024",
              "size": 2173
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let event = try decoder.decode(SendGridReceivedEvent.self, from: data)

        #expect(event.event == "received")
        #expect(event.recvMsgid == "test_received_msg_id")
        #expect(event.sgEventId == "test_received_event_id")
        #expect(event.apiKeyId == "test_api_key_id")
        #expect(event.clientIp == "192.168.1.101")
        #expect(event.protocol == "SMTP")
        #expect(event.recipientCount == 1)
        #expect(event.resellerId == "48997024")
        #expect(event.size == 2173)

        let expectedDate = Date(timeIntervalSince1970: 1_729_555_201)
        #expect(event.timestamp == expectedDate)
    }

    @Test("Decode received event with Unix timestamp and additional fields")
    func decodeReceivedEventWithUnixTimestampAndAdditionalFields() throws {
        let json = """
            {
                "event": "received",
                "recv_msgid": "test_unix_received_msg_id",
                "sg_event_id": "test_unix_received_event_id",
                "timestamp": 1761143529,
                "api_key_id": "test_unix_api_key_id",
                "api_version": "3",
                "client_ip": "192.168.1.102",
                "protocol": "HTTP",
                "recipient_count": 1,
                "reseller_id": "48997024",
                "size": 7513,
                "useragent": "Swift SendGridKit/3.0.0",
                "v3_payload_details": {
                    "text/plain": 1,
                    "content_bytes": 5997,
                    "recipient_count": 1,
                    "substitution_bytes": 0,
                    "substitution_count": 0,
                    "sender_count": 1,
                    "customarg_count": 0,
                    "attachments_bytes": 0,
                    "customarg_largest_bytes": 2,
                    "text/html": 1,
                    "personalization_count": 1
                }
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let event = try decoder.decode(SendGridReceivedEvent.self, from: data)

        #expect(event.event == "received")
        #expect(event.recvMsgid == "test_unix_received_msg_id")
        #expect(event.sgEventId == "test_unix_received_event_id")
        #expect(event.apiKeyId == "test_unix_api_key_id")
        #expect(event.apiVersion == "3")
        #expect(event.clientIp == "192.168.1.102")
        #expect(event.protocol == "HTTP")
        #expect(event.recipientCount == 1)
        #expect(event.resellerId == "48997024")
        #expect(event.size == 7513)
        #expect(event.useragent == "Swift SendGridKit/3.0.0")

        // Verify Unix timestamp decoding
        let expectedDate = Date(timeIntervalSince1970: 1_761_143_529)
        #expect(event.timestamp == expectedDate)

        // Verify v3_payload_details
        let payloadDetails = try #require(event.v3PayloadDetails)
        #expect(payloadDetails.textPlain == 1)
        #expect(payloadDetails.textHtml == 1)
        #expect(payloadDetails.contentBytes == 5997)
        #expect(payloadDetails.recipientCount == 1)
        #expect(payloadDetails.substitutionBytes == 0)
        #expect(payloadDetails.substitutionCount == 0)
        #expect(payloadDetails.senderCount == 1)
        #expect(payloadDetails.customargCount == 0)
        #expect(payloadDetails.attachmentsBytes == 0)
        #expect(payloadDetails.customargLargestBytes == 2)
        #expect(payloadDetails.personalizationCount == 1)
    }

    @Test("Decode webhook event as received event")
    func decodeWebhookEventAsReceivedEvent() throws {
        let json = """
            {
              "event": "received",
              "recv_msgid": "test_webhook_received_msg_id",
              "sg_event_id": "test_webhook_received_event_id",
              "timestamp": 1729555201
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let webhookEvent = try decoder.decode(SendGridWebhookEvent.self, from: data)

        switch webhookEvent {
        case .received(let receivedEvent):
            #expect(receivedEvent.event == "received")
            #expect(receivedEvent.recvMsgid == "test_webhook_received_msg_id")
        case .delivery(_):
            Issue.record("Expected received event but got delivery event")
        case .engagement(_):
            Issue.record("Expected received event but got engagement event")
        case .accountStatusChange(_):
            Issue.record("Expected received event but got account status change event")
        }
    }

    @Test("Decode Missing Required Fields")
    func decodeMissingRequiredFields() throws {
        let json = """
            {
                "timestamp": 1513299569,
                "event": "delivered"
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        #expect(throws: DecodingError.self) {
            _ = try decoder.decode(SendGridWebhookEvent.self, from: data)
        }
    }

    // MARK: - Encoding Tests

    @Test("Encode and Decode Delivery Event")
    func encodeAndDecodeDeliveryEvent() throws {
        let json = """
            {
                "email": "test@example.com",
                "timestamp": 1513299569,
                "event": "delivered",
                "category": ["test"],
                "sg_event_id": "test_event_id",
                "sg_message_id": "test_message_id",
                "response": "250 OK"
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let encoder = JSONEncoder()

        let originalEvent = try decoder.decode(SendGridDeliveryEvent.self, from: data)
        let encodedData = try encoder.encode(originalEvent)
        let decodedEvent = try decoder.decode(SendGridDeliveryEvent.self, from: encodedData)

        #expect(decodedEvent.email == originalEvent.email)
        #expect(decodedEvent.event == originalEvent.event)
        #expect(decodedEvent.response == originalEvent.response)
        #expect(decodedEvent.sgEventId == originalEvent.sgEventId)
        #expect(decodedEvent.timestamp == originalEvent.timestamp)
    }
}
