# ``SendGridKit/Contact``

## Overview

`Contact` represents a SendGrid Marketing Campaigns contact. The same type is used when **creating or updating** contacts (supply only the fields you want to set) and when **reading** contacts from the API (system-assigned fields like ``id``, ``listIDs``, and ``createdAt`` will be populated).

All fields are optional. The only field required by SendGrid is at least one unique identifier — ``email`` is the default.

### Creating a Contact for Upsert

```swift
// Minimal — email only
let contact = Contact(email: "ada@example.com")

// With reserved fields
let contact = Contact(
    email: "ada@example.com",
    firstName: "Ada",
    lastName: "Lovelace",
    phoneNumberID: "+14155551234",  // E.164 format, used as a unique identifier
    city: "London",
    country: "GB"
)
```

### Using Custom Fields

Custom fields are keyed by the field's SendGrid-assigned name (e.g. `e1_T` for a text field, `e2_N` for a number field). Values are typed with ``ContactCustomFieldValue``.

```swift
let contact = Contact(
    email: "ada@example.com",
    customFields: [
        "e1_T": .text("enterprise"),   // text custom field
        "e2_N": .number(42)            // number custom field
    ]
)
```

### Reading API Responses

When a contact comes back from the API, the read-only fields are populated:

```swift
let contact = try await contactClient.getContact(id: "uuid")

print(contact.id ?? "")                   // SendGrid-assigned UUID
print(contact.email ?? "")
print(contact.listIDs ?? [])              // lists this contact belongs to
print(contact.segmentIDs ?? [])           // segments this contact belongs to
print(contact.createdAt ?? "")            // ISO 8601 string
print(contact.updatedAt ?? "")
```

### Unique Identifiers

SendGrid requires each contact to have at least one unique identifier. The library exposes all four:

| Field | Used as identifier | Format |
|---|---|---|
| ``email`` | Yes (default) | Any valid email |
| ``phoneNumberID`` | Yes | E.164 (e.g. `+14155551234`) |
| ``externalID`` | Yes | Any string |
| ``anonymousID`` | Yes | Any string |

You can store a phone number in both ``phoneNumberID`` (identifier) and ``phoneNumber`` (reserved field), but only ``phoneNumberID`` is used for deduplication. Use ``ContactIdentifierType`` with ``SendGridContactClient/deleteContactIdentifier(contactID:type:)`` to remove an identifier without deleting the contact.

## Topics

### Identifiers and Custom Values

- ``ContactCustomFieldValue``
- ``ContactIdentifierType``

### Request and Response Types

- ``UpsertContactsRequest``
- ``UpsertContactsResponse``
- ``ContactsResponse``
- ``ContactSearchRequest``
- ``ContactSearchResponse``
- ``ContactCount``
- ``ContactJobResponse``
- ``ContactMetadata``
