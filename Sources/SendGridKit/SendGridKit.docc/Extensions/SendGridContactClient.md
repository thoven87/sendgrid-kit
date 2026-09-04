# ``SendGridKit/SendGridContactClient``

## Overview

`SendGridContactClient` manages Marketing Campaigns contacts and contact lists. It covers the full lifecycle — upserting contacts, searching, deleting, managing lists, and exporting your full contact database.

### Basic Setup

```swift
import AsyncHTTPClient
import SendGridKit

let contactClient = SendGridContactClient(
    httpClient: .shared,
    apiKey: "YOUR_API_KEY"
)
```

### Adding and Updating Contacts

Use ``upsertContacts(_:)`` to create or update one or more contacts in a single request. The operation is asynchronous — SendGrid queues the work and returns a job ID immediately.

```swift
let contact = Contact(
    email: "jane@example.com",
    firstName: "Jane",
    lastName: "Doe",
    city: "San Francisco",
    country: "US",
    customFields: ["plan": .text("pro"), "score": .number(98)]
)

let response = try await contactClient.upsertContacts(
    UpsertContactsRequest(
        contacts: [contact],
        listIDs: ["your-list-id"] // optional: add to lists immediately
    )
)

print("Import queued — job ID:", response.jobID ?? "n/a")
```

> Note: A single request supports up to 30,000 contacts.

### Retrieving Contacts

#### Sample (up to 50)

``getSampleContacts()`` returns up to 50 of the most recently updated contacts and the total count for your account. SendGrid deprecated pagination on this endpoint.

```swift
let sample = try await contactClient.getSampleContacts()
print("Total contacts in account:", sample.contactCount ?? 0)
print("Sample size returned:", sample.result?.count ?? 0)
```

To retrieve your full contact list, use ``exportContacts(_:)`` instead.

#### By ID

```swift
let contact = try await contactClient.getContact(id: "contact-uuid")
print(contact.email ?? "no email")
print("In lists:", contact.listIDs ?? [])
```

#### Search with SGQL

``searchContacts(_:)`` accepts any [SGQL](https://sendgrid.com/docs/for-developers/sending-email/segmentation-query-language/) query and returns up to 50 matching contacts.

```swift
// Find all contacts on a specific domain
let results = try await contactClient.searchContacts(
    ContactSearchRequest(query: "email LIKE '%@example.com'")
)
print("Matched:", results.contactCount ?? 0, "total")

// Find contacts added to a specific list
let listResults = try await contactClient.searchContacts(
    ContactSearchRequest(query: "CONTAINS(list_ids, 'your-list-id')")
)
```

#### Contact Count

```swift
let count = try await contactClient.getContactCount()
print("Total:", count.contactCount ?? 0)
print("Billable:", count.billableCount ?? 0)
```

### Deleting Contacts

```swift
// Delete by IDs (async — returns a job ID)
let job = try await contactClient.deleteContacts(ids: ["id-1", "id-2"])
print("Deletion queued — job ID:", job.jobID ?? "n/a")
```

To find IDs by email before deleting, combine search with delete:

```swift
let results = try await contactClient.searchContacts(
    ContactSearchRequest(query: "email = 'bounced@example.com'")
)
let ids = results.result?.compactMap(\.id) ?? []
if !ids.isEmpty {
    try await contactClient.deleteContacts(ids: ids)
}
```

### Removing a Contact Identifier

Use ``deleteContactIdentifier(contactID:type:)`` to remove a specific unique identifier (phone number ID, external ID, or anonymous ID) without deleting the contact itself.

```swift
try await contactClient.deleteContactIdentifier(
    contactID: "contact-uuid",
    type: .phoneNumberID
)
```

### Exporting All Contacts

``getSampleContacts()`` only returns 50 contacts. To get your full list, use the export API:

```swift
// 1. Request the export
let export = try await contactClient.exportContacts(
    ContactExportRequest(
        fileType: .csv,
        notifications: .init(email: true)  // get an email when ready
    )
)

// 2. Poll until ready (exports are processed asynchronously)
var exportStatus: ContactExportResponse
repeat {
    try await Task.sleep(for: .seconds(5))
    exportStatus = try await contactClient.getContactExport(id: export.id!)
} while exportStatus.status == .pending

// 3. Download from the signed URL (valid for 12 hours after initiation)
if exportStatus.status == .ready, let downloadURL = exportStatus.urls?.first {
    print("Download at:", downloadURL)
}
```

You can also limit the export to specific lists or segments:

```swift
let export = try await contactClient.exportContacts(
    ContactExportRequest(
        listIDs: ["list-id-1", "list-id-2"],
        fileType: .csv
    )
)
```

### Managing Contact Lists

#### Create and Retrieve

```swift
// Create
let list = try await contactClient.createContactList(
    CreateContactListRequest(name: "VIP Customers")
)
print("Created list:", list.id ?? "n/a")

// Get all lists
let allLists = try await contactClient.getAllContactLists()
for list in allLists.result ?? [] {
    print("\(list.name ?? "?"): \(list.contactCount ?? 0) contacts")
}

// Get one list, with a contact sample
let detail = try await contactClient.getContactList(
    id: "list-id",
    contactSample: true
)
print("Sample contacts:", detail.contactSample?.count ?? 0)
```

#### Update and Delete

```swift
// Rename a list
let updated = try await contactClient.updateContactList(
    id: "list-id",
    request: UpdateContactListRequest(name: "Premium Customers")
)

// Delete the list only (contacts are retained in your account)
try await contactClient.deleteContactList(id: "list-id", deleteContacts: false)

// Delete the list AND all of its contacts (returns an async job ID)
let job = try await contactClient.deleteContactList(id: "list-id", deleteContacts: true)
print("Deletion queued — job ID:", job?.jobID ?? "n/a")
```

#### Remove Specific Contacts from a List

Removing contacts from a list does not delete them from your account.

```swift
let job = try await contactClient.removeContactsFromList(
    listID: "list-id",
    request: RemoveContactsFromListRequest(contactIDs: ["id-1", "id-2"])
)
print("Removal queued — job ID:", job.jobID ?? "n/a")
```

### Regional API Support

For EU regional subusers, pass `forEU: true` at initialisation:

```swift
let contactClient = SendGridContactClient(
    httpClient: .shared,
    apiKey: "YOUR_API_KEY",
    forEU: true  // uses api.eu.sendgrid.com
)
```

### Error Handling

All methods throw ``SendGridError`` when the API returns a non-2xx response.

```swift
do {
    let response = try await contactClient.upsertContacts(request)
} catch let error as SendGridError {
    for detail in error.errors ?? [] {
        print("API error:", detail.message ?? "unknown")
    }
} catch {
    print("Unexpected error:", error)
}
```

## Topics

### Managing Contacts

- ``upsertContacts(_:)``
- ``getSampleContacts()``
- ``getContact(id:)``
- ``searchContacts(_:)``
- ``getContactCount()``
- ``deleteContacts(ids:)``
- ``deleteContactIdentifier(contactID:type:)``

### Exporting Contacts

- ``exportContacts(_:)``
- ``getContactExport(id:)``

### Managing Lists

- ``createContactList(_:)``
- ``getAllContactLists()``
- ``getContactList(id:contactSample:)``
- ``updateContactList(id:request:)``
- ``deleteContactList(id:deleteContacts:)``
- ``removeContactsFromList(listID:request:)``
