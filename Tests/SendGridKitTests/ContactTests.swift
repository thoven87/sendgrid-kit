import AsyncHTTPClient
import Foundation
import SendGridKit
import Testing

@Suite("Contact API Tests")
struct ContactTests {
    let client: SendGridContactClient
    // TODO: Replace with `false` when you have a valid API key
    let credentialsAreInvalid = true

    init() {
        // TODO: Replace with a valid Marketing Campaigns API key to test
        client = SendGridContactClient(httpClient: .shared, apiKey: "YOUR_API_KEY_HERE")
    }

    // MARK: - Contacts

    @Test("Upsert contacts")
    func upsertContacts() async throws {
        let request = UpsertContactsRequest(
            contacts: [
                Contact(
                    email: "test@example.com",
                    firstName: "Test",
                    lastName: "User",
                    city: "San Francisco",
                    country: "US"
                )
            ]
        )

        try await withKnownIssue {
            let response = try await client.upsertContacts(request)
            #expect(response.jobID != nil)
            #expect(!(response.jobID?.isEmpty ?? true))
        } when: {
            credentialsAreInvalid
        }
    }

    @Test("Upsert contacts with list IDs")
    func upsertContactsWithListIDs() async throws {
        let request = UpsertContactsRequest(
            contacts: [Contact(email: "listmember@example.com")],
            listIDs: ["your-list-id"]
        )

        try await withKnownIssue {
            let response = try await client.upsertContacts(request)
            #expect(response.jobID != nil)
        } when: {
            credentialsAreInvalid
        }
    }

    @Test("Get sample contacts (up to 50)")
    func getSampleContacts() async throws {
        try await withKnownIssue {
            let response = try await client.getSampleContacts()
            #expect(response.result != nil)
            // contactCount reflects the total account count, not just the sample size
            #expect(response.contactCount != nil)
        } when: {
            credentialsAreInvalid
        }
    }

    @Test("Get contact by ID")
    func getContactByID() async throws {
        try await withKnownIssue {
            let contact = try await client.getContact(id: "your-contact-id")
            #expect(contact.id != nil)
        } when: {
            credentialsAreInvalid
        }
    }

    @Test("Delete contacts")
    func deleteContacts() async throws {
        try await withKnownIssue {
            let response = try await client.deleteContacts(ids: ["contact-id-1", "contact-id-2"])
            #expect(response.jobID != nil)
        } when: {
            credentialsAreInvalid
        }
    }

    @Test("Search contacts")
    func searchContacts() async throws {
        let request = ContactSearchRequest(query: "email LIKE '%@example.com'")

        try await withKnownIssue {
            let response = try await client.searchContacts(request)
            #expect(response.result != nil)
            #expect(response.contactCount != nil)
        } when: {
            credentialsAreInvalid
        }
    }

    @Test("Get contact count")
    func getContactCount() async throws {
        try await withKnownIssue {
            let count = try await client.getContactCount()
            #expect(count.contactCount != nil)
        } when: {
            credentialsAreInvalid
        }
    }

    @Test("Delete contact identifier")
    func deleteContactIdentifier() async throws {
        try await withKnownIssue {
            try await client.deleteContactIdentifier(
                contactID: "your-contact-id",
                type: .phoneNumberID
            )
        } when: {
            credentialsAreInvalid
        }
    }

    // MARK: - Lists

    @Test("Create contact list")
    func createContactList() async throws {
        let request = CreateContactListRequest(name: "My Swift Test List")

        try await withKnownIssue {
            let list = try await client.createContactList(request)
            #expect(list.id != nil)
            #expect(list.name == "My Swift Test List")
        } when: {
            credentialsAreInvalid
        }
    }

    @Test("Get all contact lists")
    func getAllContactLists() async throws {
        try await withKnownIssue {
            let response = try await client.getAllContactLists()
            #expect(response.result != nil)
        } when: {
            credentialsAreInvalid
        }
    }

    @Test("Get contact list by ID")
    func getContactListByID() async throws {
        try await withKnownIssue {
            let list = try await client.getContactList(id: "your-list-id", contactSample: true)
            #expect(list.id != nil)
        } when: {
            credentialsAreInvalid
        }
    }

    @Test("Update contact list")
    func updateContactList() async throws {
        let request = UpdateContactListRequest(name: "Updated List Name")

        try await withKnownIssue {
            let list = try await client.updateContactList(id: "your-list-id", request: request)
            #expect(list.name == "Updated List Name")
        } when: {
            credentialsAreInvalid
        }
    }

    @Test("Delete contact list (list only)")
    func deleteContactListOnly() async throws {
        try await withKnownIssue {
            let result = try await client.deleteContactList(id: "your-list-id", deleteContacts: false)
            // Returns nil when only the list is deleted (204 No Content)
            #expect(result == nil)
        } when: {
            credentialsAreInvalid
        }
    }

    @Test("Delete contact list and its contacts")
    func deleteContactListAndContacts() async throws {
        try await withKnownIssue {
            let result = try await client.deleteContactList(id: "your-list-id", deleteContacts: true)
            // Returns a job ID when contacts are also deleted (202 Accepted)
            #expect(result?.jobID != nil)
        } when: {
            credentialsAreInvalid
        }
    }

    @Test("Remove contacts from list")
    func removeContactsFromList() async throws {
        let request = RemoveContactsFromListRequest(contactIDs: ["contact-id-1"])

        try await withKnownIssue {
            let response = try await client.removeContactsFromList(listID: "your-list-id", request: request)
            #expect(response.jobID != nil)
        } when: {
            credentialsAreInvalid
        }
    }

    // MARK: - Exports

    @Test("Export contacts")
    func exportContacts() async throws {
        let request = ContactExportRequest(fileType: .csv, notifications: .init(email: true))

        try await withKnownIssue {
            let response = try await client.exportContacts(request)
            #expect(response.id != nil)
            #expect(response.status != nil)
        } when: {
            credentialsAreInvalid
        }
    }

    @Test("Get contact export status")
    func getContactExportStatus() async throws {
        try await withKnownIssue {
            let response = try await client.getContactExport(id: "your-export-job-id")
            #expect(response.id != nil)
        } when: {
            credentialsAreInvalid
        }
    }

    // MARK: - JSON Decoding

    @Test("Decode Contact response")
    func decodeContactResponse() throws {
        let json = """
            {
                "id": "abc-123",
                "email": "test@example.com",
                "first_name": "Test",
                "last_name": "User",
                "city": "San Francisco",
                "country": "US",
                "created_at": "2024-01-01T00:00:00Z",
                "updated_at": "2024-06-01T00:00:00Z"
            }
            """
        let contact = try JSONDecoder().decode(Contact.self, from: Data(json.utf8))
        #expect(contact.id == "abc-123")
        #expect(contact.email == "test@example.com")
        #expect(contact.firstName == "Test")
        #expect(contact.lastName == "User")
        #expect(contact.city == "San Francisco")
    }

    @Test("Decode ContactsResponse with metadata")
    func decodeContactsResponse() throws {
        let json = """
            {
                "result": [
                    {
                        "id": "abc-123",
                        "email": "test@example.com",
                        "first_name": "Test",
                        "list_ids": ["list-1", "list-2"],
                        "segment_ids": ["seg-1"]
                    }
                ],
                "contact_count": 1234,
                "_metadata": {
                    "self": "https://api.sendgrid.com/v3/marketing/contacts"
                }
            }
            """
        let response = try JSONDecoder().decode(ContactsResponse.self, from: Data(json.utf8))
        #expect(response.result?.count == 1)
        #expect(response.result?.first?.email == "test@example.com")
        #expect(response.result?.first?.listIDs == ["list-1", "list-2"])
        #expect(response.result?.first?.segmentIDs == ["seg-1"])
        // contactCount is the total account count, not the size of result
        #expect(response.contactCount == 1234)
    }

    @Test("Decode UpsertContactsResponse")
    func decodeUpsertContactsResponse() throws {
        let json = """
            { "job_id": "job-abc-123" }
            """
        let response = try JSONDecoder().decode(UpsertContactsResponse.self, from: Data(json.utf8))
        #expect(response.jobID == "job-abc-123")
    }

    @Test("Decode ContactSearchResponse")
    func decodeContactSearchResponse() throws {
        let json = """
            {
                "result": [
                    { "id": "abc-123", "email": "found@example.com" }
                ],
                "contact_count": 1,
                "_metadata": { "count": 1 }
            }
            """
        let response = try JSONDecoder().decode(ContactSearchResponse.self, from: Data(json.utf8))
        #expect(response.contactCount == 1)
        #expect(response.result?.first?.email == "found@example.com")
    }

    @Test("Decode ContactCount")
    func decodeContactCount() throws {
        let json = """
            { "contact_count": 500, "billable_count": 450 }
            """
        let count = try JSONDecoder().decode(ContactCount.self, from: Data(json.utf8))
        #expect(count.contactCount == 500)
        #expect(count.billableCount == 450)
    }

    @Test("Decode ContactList")
    func decodeContactList() throws {
        let json = """
            {
                "id": "list-abc",
                "name": "My List",
                "contact_count": 42,
                "_metadata": { "self": "https://api.sendgrid.com/v3/marketing/lists/list-abc" }
            }
            """
        let list = try JSONDecoder().decode(ContactList.self, from: Data(json.utf8))
        #expect(list.id == "list-abc")
        #expect(list.name == "My List")
        #expect(list.contactCount == 42)
    }

    @Test("Decode ContactExportResponse")
    func decodeContactExportResponse() throws {
        let json = """
            {
                "id": "export-abc",
                "status": "ready",
                "created_at": "2024-01-01T00:00:00Z",
                "expires_at": "2024-01-01T12:00:00Z",
                "urls": ["https://storage.example.com/export.csv"],
                "contact_count": 200
            }
            """
        let exportResponse = try JSONDecoder().decode(ContactExportResponse.self, from: Data(json.utf8))
        #expect(exportResponse.id == "export-abc")
        #expect(exportResponse.status == .ready)
        #expect(exportResponse.urls?.count == 1)
        #expect(exportResponse.contactCount == 200)
    }

    @Test("Decode Contact with custom fields")
    func decodeContactWithCustomFields() throws {
        let json = """
            {
                "id": "abc-123",
                "email": "test@example.com",
                "custom_fields": {
                    "e1_T": "VIP",
                    "e2_N": 42.5
                }
            }
            """
        let contact = try JSONDecoder().decode(Contact.self, from: Data(json.utf8))
        #expect(contact.customFields?["e1_T"] != nil)
        #expect(contact.customFields?["e2_N"] != nil)

        if case .text(let value) = contact.customFields?["e1_T"] {
            #expect(value == "VIP")
        }
        if case .number(let value) = contact.customFields?["e2_N"] {
            #expect(value == 42.5)
        }
    }

    @Test("Encode UpsertContactsRequest")
    func encodeUpsertContactsRequest() throws {
        let contact = Contact(
            email: "test@example.com",
            firstName: "Test",
            lastName: "User",
            phoneNumberID: "+14155551234"
        )
        let request = UpsertContactsRequest(contacts: [contact], listIDs: ["list-abc"])

        let data = try JSONEncoder().encode(request)
        let dict = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        let contacts = dict?["contacts"] as? [[String: Any]]
        #expect(contacts?.count == 1)
        #expect(contacts?.first?["email"] as? String == "test@example.com")
        #expect(contacts?.first?["first_name"] as? String == "Test")
        #expect(contacts?.first?["phone_number_id"] as? String == "+14155551234")

        let listIDs = dict?["list_ids"] as? [String]
        #expect(listIDs?.first == "list-abc")
    }
}
