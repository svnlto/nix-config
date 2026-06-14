# Security

## mTLS Configuration

All clients and workers must present certificates signed by a trusted
CA. Temporal Cloud requires CA certificate upload.

**Rotation cadence:**

- Client certificates: quarterly
- CA certificates: annually
- Temporal supports simultaneous old+new CA certs for seamless rotation
- Always test rotated certificates in staging first

```go
cert, err := tls.LoadX509KeyPair("client.pem", "client.key")
c, err := client.Dial(client.Options{
    HostPort:  "my-ns.tmprl.cloud:7233",
    Namespace: "my-ns",
    ConnectionOptions: client.ConnectionOptions{
        TLS: &tls.Config{
            Certificates: []tls.Certificate{cert},
        },
    },
})
```

## API Key Security

- Store in secrets managers, never in code
- Rotate at least every 90 days (create new → swap → delete old)
- One key per service/person
- Monitor usage via audit logs
- Admins can disable all user API keys to enforce mTLS-only

## Data Encryption (Payload Codec)

Payload Codec encrypts BEFORE data reaches Temporal Service. The
Temporal Service never sees plaintext.

**Encryptable:**

- Workflow/activity/child workflow inputs and outputs
- Signal/query inputs and results
- Memos, headers
- Local activity and side effect results

**NOT encrypted by default:**

- Failure messages and stack traces — requires explicit Failure
  Converter configuration (critical for PII/financial data)

```go
c, err := client.Dial(client.Options{
    DataConverter: converter.NewCodecDataConverter(
        converter.GetDefaultDataConverter(),
        &myEncryptionCodec{},
    ),
})
```

## Codec Server

HTTP server with `/decode` and `/encode` endpoints allowing the
Temporal Web UI to display decrypted payloads.

- Requires CORS configuration for Web UI access
- Must be HTTPS for Web UI authorization
- Temporal Cloud JWT tokens available for authorization
- **Restrict access** — single API call decodes potentially sensitive data

**Nexus cross-namespace encryption strategies:**

1. Shared key (simplest)
2. KMS key ID metadata (separate keys per namespace)
3. Wrapper types (endpoint-specific encryption keys)

## RBAC

**Account roles (Temporal Cloud):**

| Role | Access |
|------|--------|
| Account Owner | Full account control |
| Global Admin | All namespaces, user management |
| Developer | Namespace-specific, workflow operations |
| Read-Only | View only |
| Finance Admin | Billing and usage |

**Best practices:**

- Namespace-level permissions to restrict developer access
- Service accounts for CI/CD with unique API keys
- Least-privilege per namespace
- SAML 2.0 SSO with corporate MFA enforcement
- SCIM for automated user lifecycle management

## Search Attribute Security

Search attribute values are stored **unencrypted** and readable in
plaintext regardless of payload encryption.

**NEVER include PII in search attributes.** Use workflow state +
queries for sensitive data filtering instead.

## Private Connectivity

- AWS PrivateLink or Google Cloud Private Service Connect
- Workers reach Temporal Cloud over private network paths
- No public internet exposure for worker-to-service communication
