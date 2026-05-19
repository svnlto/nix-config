# IDP Capability Domains

The 13 capability domains from the CNCF Platforms White Paper.
Use to scope platform offerings and identify gaps.

## Capability Map

| Domain | Purpose | Example Tools |
|--------|---------|---------------|
| Web Portals | Documentation, service catalogs, templates, telemetry | Backstage, Skooner, Ortelius |
| APIs / CLIs | Automated provisioning and observation | Kubernetes, Crossplane, Helm, KubeVela |
| Golden Path Templates | Rapid project scaffolding with integrated capabilities | ArtifactHub, Cookiecutter |
| Build / Test Automation | Service and product validation | Tekton, Jenkins, Buildpacks, ko, Carvel |
| Delivery / Verification | Service deployment, progressive delivery, feature flags | Argo, Flux, Keptn, Flagger, OpenFeature |
| Development Environments | Local/remote dev, preview environments | Devfile, Nocalhost, Telepresence, DevSpace |
| Application Observability | Instrumentation, telemetry, analysis | OpenTelemetry, Jaeger, Prometheus, Grafana, OpenCost |
| Infrastructure Services | Compute, networking, storage, service mesh | Kubernetes, Knative, KEDA, Cilium, Istio, Envoy, Linkerd |
| Data Services | Structured data persistence | TiKV, Vitess, SchemaHero |
| Messaging / Events | Async communication, event-driven architecture | Strimzi, NATS, gRPC, Knative, Dapr |
| Identity / Secrets | Workload auth, certificate management | Keycloak, Dex, External Secrets, SPIFFE/SPIRE, cert-manager |
| Security Services | Runtime observation, artifact verification, policy | Falco, In-toto, KubeArmor, OPA, Kyverno |
| Artifact Storage | Built artifacts, dependency caching, source code | ArtifactHub, Harbor, Distribution, Porter |

## Scoping Guidance

Not every platform needs all 13 domains. Prioritize based on:

1. **Frequency** — what do teams request most often?
2. **Differentiation** — is this undifferentiated heavy lifting?
3. **Risk** — does inconsistency here create security/compliance exposure?
4. **Toil** — how much manual effort does this consume today?

Start with the highest-frequency, lowest-differentiation capabilities
(typically: build automation, delivery pipelines, observability, identity/secrets).

## Capability vs. Implementation

Platforms provide capabilities but don't always implement them.
A managed database service (RDS, Cloud SQL) is the implementation;
the platform provides the self-service interface, golden path config,
and governance wrapper.
