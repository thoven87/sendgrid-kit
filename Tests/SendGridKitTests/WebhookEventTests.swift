import Foundation
import SendGridKit
import Testing

@Suite("SendGrid Webhook Event Tests")
struct WebhookEventTests {

    // MARK: - Delivery Event Tests

    @Test("Decode Bounce Event")
    func decodeBounceEvent() throws {
        let json = """
            {
                "email": "alex@example.com",
                "timestamp": 1513299569,
                "smtp-id": "<14c5d75ce93.dfd.64b469@ismtpd-555>",
                "bounce_classification": "Invalid Address",
                "event": "bounce",
                "category": ["cat facts"],
                "sg_event_id": "6g4ZI7SA-xmRDv57GoPIPw==",
                "sg_message_id": "14c5d75ce93.dfd.64b469.filter0001.16648.5515E0B88.0",
                "reason": "500 unknown recipient",
                "status": "5.0.0",
                "type": "bounce"
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let event = try decoder.decode(SendGridDeliveryEvent.self, from: data)

        #expect(event.email == "alex@example.com")
        #expect(event.event == .bounce)
        #expect(event.bounceClassification == "Invalid Address")
        #expect(event.reason == "500 unknown recipient")
        #expect(event.status == "5.0.0")
        #expect(event.type == .bounce)
        #expect(event.category == ["cat facts"])
        #expect(event.sgEventId == "6g4ZI7SA-xmRDv57GoPIPw==")
        #expect(event.timestamp == Date(timeIntervalSince1970: 1_513_299_569))
    }

    @Test("Decode Delivered Event")
    func decodeDeliveredEvent() throws {
        let json = """
            {
                "email": "alex@example.com",
                "timestamp": 1513299569,
                "smtp-id": "<14c5d75ce93.dfd.64b469@ismtpd-555>",
                "event": "delivered",
                "category": ["cat facts"],
                "sg_event_id": "rWVYmVk90MjZJ9iohOBa3w==",
                "sg_message_id": "14c5d75ce93.dfd.64b469.filter0001.16648.5515E0B88.0",
                "response": "250 OK"
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let event = try decoder.decode(SendGridDeliveryEvent.self, from: data)

        #expect(event.email == "alex@example.com")
        #expect(event.event == .delivered)
        #expect(event.response == "250 OK")
        #expect(event.category == ["cat facts"])
        #expect(event.sgEventId == "rWVYmVk90MjZJ9iohOBa3w==")
    }

    @Test("Decode Deferred Event")
    func decodeDeferredEvent() throws {
        let json = """
            {
                "email": "alex@example.com",
                "domain": "example.com",
                "from": "test@example.com",
                "timestamp": 1513299569,
                "smtp-id": "<14c5d75ce93.dfd.64b469@ismtpd-555>",
                "event": "deferred",
                "category": ["cat facts"],
                "sg_event_id": "t7LEShmowp86DTdUW8M-GQ==",
                "sg_message_id": "14c5d75ce93.dfd.64b469.filter0001.16648.5515E0B88.0",
                "response": "400 try again later",
                "attempt": 5
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let event = try decoder.decode(SendGridDeliveryEvent.self, from: data)

        #expect(event.email == "alex@example.com")
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
                "email": "alex@example.com",
                "timestamp": 1513299569,
                "smtp-id": "<14c5d75ce93.dfd.64b469@ismtpd-555>",
                "event": "dropped",
                "category": ["cat facts"],
                "sg_event_id": "zmzJhfJgAfUSOW80yEbPyw==",
                "sg_message_id": "14c5d75ce93.dfd.64b469.filter0001.16648.5515E0B88.0",
                "reason": "Bounced Address",
                "status": "5.0.0"
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let event = try decoder.decode(SendGridDeliveryEvent.self, from: data)

        #expect(event.email == "alex@example.com")
        #expect(event.event == .dropped)
        #expect(event.reason == "Bounced Address")
        #expect(event.status == "5.0.0")
    }

    @Test("Decode Processed Event with Pool")
    func decodeProcessedEventWithPool() throws {
        let json = """
            {
                "email": "alex@example.com",
                "timestamp": 1513299569,
                "pool": {
                    "name": "new_MY_test",
                    "id": 210
                },
                "smtp-id": "<14c5d75ce93.dfd.64b469@ismtpd-555>",
                "event": "processed",
                "category": ["cat facts"],
                "sg_event_id": "rbtnWrG1DVDGGGFHFyun0A==",
                "sg_message_id": "14c5d75ce93.dfd.64b469.filter0001.16648.5515E0B88.0"
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let event = try decoder.decode(SendGridDeliveryEvent.self, from: data)

        #expect(event.email == "alex@example.com")
        #expect(event.event == .processed)
        #expect(event.pool?.name == "new_MY_test")
        #expect(event.pool?.id == 210)
    }

    // MARK: - Engagement Event Tests

    @Test("Decode Click Event")
    func decodeClickEvent() throws {
        let json = """
            {
                "sg_event_id": "sendgrid_internal_event_id",
                "sg_message_id": "sendgrid_internal_message_id",
                "ip": "255.255.255.255",
                "useragent": "Mozilla/5.0 (iPhone; CPU iPhone OS 7_1_2 like Mac OS X)",
                "event": "click",
                "email": "email@example.com",
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

        #expect(event.email == "email@example.com")
        #expect(event.event == .click)
        #expect(event.ip == "255.255.255.255")
        #expect(event.url == "http://example.com/blog/news.html")
        #expect(event.urlOffset?.index == 0)
        #expect(event.urlOffset?.type == "html")
        #expect(event.category == ["category1", "category2"])
        #expect(event.asmGroupId == 1)
        #expect(event.newsletter?.newsletterId == "1943530")
    }

    @Test("Decode Open Event")
    func decodeOpenEvent() throws {
        let json = """
            {
                "email": "alex@example.com",
                "timestamp": 1513299569,
                "event": "open",
                "sg_machine_open": false,
                "category": ["cat facts"],
                "sg_event_id": "FOTFFO0ecsBE-zxFXfs6WA==",
                "sg_message_id": "14c5d75ce93.dfd.64b469.filter0001.16648.5515E0B88.0",
                "useragent": "Mozilla/4.0 (compatible; MSIE 6.1; Windows XP)",
                "ip": "255.255.255.255"
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let event = try decoder.decode(SendGridEngagementEvent.self, from: data)

        #expect(event.email == "alex@example.com")
        #expect(event.event == .open)
        #expect(event.sgMachineOpen == false)
        #expect(event.ip == "255.255.255.255")
        #expect(event.useragent == "Mozilla/4.0 (compatible; MSIE 6.1; Windows XP)")
    }

    @Test("Decode Spam Report Event")
    func decodeSpamReportEvent() throws {
        let json = """
            {
                "email": "alex@example.com",
                "timestamp": 1513299569,
                "smtp-id": "<14c5d75ce93.dfd.64b469@ismtpd-555>",
                "event": "spamreport",
                "sg_event_id": "37nvH5QBz858KGVYCM4uOA==",
                "sg_message_id": "14c5d75ce93.dfd.64b469.filter0001.16648.5515E0B88.0"
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let event = try decoder.decode(SendGridEngagementEvent.self, from: data)

        #expect(event.email == "alex@example.com")
        #expect(event.event == .spamreport)
        #expect(event.sgEventId == "37nvH5QBz858KGVYCM4uOA==")
    }

    @Test("Decode Unsubscribe Event")
    func decodeUnsubscribeEvent() throws {
        let json = """
            {
                "email": "alex@example.com",
                "timestamp": 1513299569,
                "event": "unsubscribe",
                "category": ["cat facts"],
                "sg_event_id": "zz_BjPgU_5pS-J8vlfB1sg==",
                "sg_message_id": "14c5d75ce93.dfd.64b469.filter0001.16648.5515E0B88.0"
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let event = try decoder.decode(SendGridEngagementEvent.self, from: data)

        #expect(event.email == "alex@example.com")
        #expect(event.event == .unsubscribe)
        #expect(event.category == ["cat facts"])
    }

    @Test("Decode Group Resubscribe Event")
    func decodeGroupResubscribeEvent() throws {
        let json = """
            {
                "email": "alex@example.com",
                "timestamp": 1513299569,
                "smtp-id": "<14c5d75ce93.dfd.64b469@ismtpd-555>",
                "event": "group_resubscribe",
                "category": ["cat facts"],
                "sg_event_id": "w_u0vJhLT-OFfprar5N93g==",
                "sg_message_id": "14c5d75ce93.dfd.64b469.filter0001.16648.5515E0B88.0",
                "useragent": "Mozilla/4.0 (compatible; MSIE 6.1; Windows XP)",
                "ip": "255.255.255.255",
                "url": "http://www.example.com/",
                "asm_group_id": 10
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let event = try decoder.decode(SendGridEngagementEvent.self, from: data)

        #expect(event.email == "alex@example.com")
        #expect(event.event == .groupResubscribe)
        #expect(event.asmGroupId == 10)
        #expect(event.url == "http://www.example.com/")
    }

    @Test("Decode Group Unsubscribe Event")
    func decodeGroupUnsubscribeEvent() throws {
        let json = """
            {
                "email": "alex@example.com",
                "timestamp": 1513299569,
                "smtp-id": "<14c5d75ce93.dfd.64b469@ismtpd-555>",
                "event": "group_unsubscribe",
                "category": ["cat facts"],
                "sg_event_id": "ahSCB7xYcXFb-hEaawsPRw==",
                "sg_message_id": "14c5d75ce93.dfd.64b469.filter0001.16648.5515E0B88.0",
                "useragent": "Mozilla/4.0 (compatible; MSIE 6.1; Windows XP)",
                "ip": "255.255.255.255",
                "url": "http://www.example.com/",
                "asm_group_id": 10
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let event = try decoder.decode(SendGridEngagementEvent.self, from: data)

        #expect(event.email == "alex@example.com")
        #expect(event.event == .groupUnsubscribe)
        #expect(event.asmGroupId == 10)
    }

    // MARK: - Account Status Change Event Tests

    @Test("Decode Account Status Change Event")
    func decodeAccountStatusChangeEvent() throws {
        let json = """
            {
                "event": "account_status_change",
                "sg_event_id": "MjEzNTg5OTcyOC10ZXJtaW5hdGUtMTcwNzg1MTUzMQ",
                "timestamp": 1709142428,
                "type": "compliance_suspend"
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let event = try decoder.decode(SendGridAccountStatusChangeEvent.self, from: data)

        #expect(event.event == "account_status_change")
        #expect(event.type == .complianceSuspend)
        #expect(event.sgEventId == "MjEzNTg5OTcyOC10ZXJtaW5hdGUtMTcwNzg1MTUzMQ")
        #expect(event.timestamp == Date(timeIntervalSince1970: 1_709_142_428))
    }

    // MARK: - Marketing Campaign Event Tests

    @Test("Decode Marketing Campaign Event")
    func decodeMarketingCampaignEvent() throws {
        let json = """
            {
                "category": [],
                "email": "alex@example.com",
                "event": "processed",
                "marketing_campaign_id": 12345,
                "marketing_campaign_name": "campaign name",
                "sg_event_id": "sendgrid_internal_event_id",
                "sg_message_id": "sendgrid_internal_message_id",
                "smtp-id": "",
                "timestamp": 1442349428
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let event = try decoder.decode(SendGridDeliveryEvent.self, from: data)

        #expect(event.email == "alex@example.com")
        #expect(event.event == .processed)
        #expect(event.marketingCampaignId == 12345)
        #expect(event.marketingCampaignName == "campaign name")
    }

    @Test("Decode A/B Test Marketing Campaign Event")
    func decodeABTestMarketingCampaignEvent() throws {
        let json = """
            {
                "category": [],
                "email": "tadpole_0010@stbase-018.sjc1.sendgrid.net",
                "event": "processed",
                "marketing_campaign_id": 23314,
                "marketing_campaign_name": "unique args ab",
                "marketing_campaign_version": "B",
                "marketing_campaign_split_id": 13471,
                "sg_event_id": "qNOzbkTuTNCdxa1eXEpnXg",
                "sg_message_id": "5lFl7Fr1Rjme_EyzNNB_5A.stfilter-015.5185.55F883172.0",
                "smtp-id": "<5lFl7Fr1Rjme_EyzNNB_5A@stismtpd-006.sjc1.sendgrid.net>",
                "timestamp": 1442349848
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let event = try decoder.decode(SendGridDeliveryEvent.self, from: data)

        #expect(event.email == "tadpole_0010@stbase-018.sjc1.sendgrid.net")
        #expect(event.event == .processed)
        #expect(event.marketingCampaignVersion == "B")
        #expect(event.marketingCampaignSplitId == 13471)
    }

    // MARK: - Legacy Newsletter Event Tests

    @Test("Decode Legacy Newsletter Unsubscribe Event")
    func decodeLegacyNewsletterUnsubscribeEvent() throws {
        let json = """
            {
                "email": "nick@sendgrid.com",
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

        #expect(event.email == "nick@sendgrid.com")
        #expect(event.event == .unsubscribe)
        #expect(event.newsletter?.newsletterId == "1943530")
        #expect(event.newsletter?.newsletterUserListId == "10557865")
        #expect(event.newsletter?.newsletterSendId == "2308608")
        #expect(event.category == ["Tests", "Newsletter"])
    }

    // MARK: - Main Webhook Event Enum Tests

    @Test("Decode Webhook Event as Delivery Event")
    func decodeWebhookEventAsDeliveryEvent() throws {
        let json = """
            {
                "email": "alex@example.com",
                "timestamp": 1513299569,
                "event": "delivered",
                "sg_event_id": "rWVYmVk90MjZJ9iohOBa3w==",
                "sg_message_id": "14c5d75ce93.dfd.64b469.filter0001.16648.5515E0B88.0",
                "response": "250 OK"
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let webhookEvent = try decoder.decode(SendGridWebhookEvent.self, from: data)

        switch webhookEvent {
        case .delivery(let deliveryEvent):
            #expect(deliveryEvent.email == "alex@example.com")
            #expect(deliveryEvent.event == .delivered)
        case .engagement(_):
            Issue.record("Expected delivery event but got engagement event")
        case .accountStatusChange(_):
            Issue.record("Expected delivery event but got account status change event")
        }
    }

    @Test("Decode Webhook Event as Engagement Event")
    func decodeWebhookEventAsEngagementEvent() throws {
        let json = """
            {
                "email": "alex@example.com",
                "timestamp": 1513299569,
                "event": "open",
                "sg_event_id": "FOTFFO0ecsBE-zxFXfs6WA==",
                "sg_message_id": "14c5d75ce93.dfd.64b469.filter0001.16648.5515E0B88.0",
                "ip": "255.255.255.255"
            }
            """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let webhookEvent = try decoder.decode(SendGridWebhookEvent.self, from: data)

        switch webhookEvent {
        case .delivery(_):
            Issue.record("Expected engagement event but got delivery event")
        case .engagement(let engagementEvent):
            #expect(engagementEvent.email == "alex@example.com")
            #expect(engagementEvent.event == .open)
        case .accountStatusChange(_):
            Issue.record("Expected engagement event but got account status change event")
        }
    }

    @Test("Decode Webhook Event as Account Status Change Event")
    func decodeWebhookEventAsAccountStatusChangeEvent() throws {
        let json = """
            {
                "event": "account_status_change",
                "sg_event_id": "MjEzNTg5OTcyOC10ZXJtaW5hdGUtMTcwNzg1MTUzMQ",
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
        }
    }

    // MARK: - Custom Arguments Tests

    @Test("Decode Event with Custom Arguments")
    func decodeEventWithCustomArguments() throws {
        let json = """
            {
                "email": "alex@example.com",
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

        #expect(event.email == "alex@example.com")
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
                    "email": "alex@example.com",
                    "timestamp": 1513299569,
                    "event": "delivered",
                    "sg_event_id": "delivered_event_id",
                    "sg_message_id": "delivered_message_id",
                    "response": "250 OK"
                },
                {
                    "email": "alex@example.com",
                    "timestamp": 1513299570,
                    "event": "open",
                    "sg_event_id": "open_event_id",
                    "sg_message_id": "open_message_id",
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
