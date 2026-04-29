---
title: "S2D On-Premises vs. Azure Local (Isolated)"
subtitle: "Vergleich: Storage Spaces Direct On-Premises und Azure Local mit Disconnected Operations"
author: "Jan Tiedemann"
date: "29. April 2026"
lang: de
toc: true
toc-depth: 3
---

# Zusammenfassung

Dieses Dokument vergleicht **Storage Spaces Direct (S2D)
On-Premises** unter Windows Server mit **Azure Local** (ehemals
Azure Stack HCI) im Betriebsmodus **Disconnected Operations**.
Es beleuchtet die architektonischen Unterschiede, den
Funktionsumfang und die Vorteile von Azure Local — insbesondere
für regulierte Umgebungen, die keine permanente
Cloud-Anbindung erlauben.

**Ergebnis**: Azure Local mit Disconnected Operations bietet
gegenüber klassischem S2D On-Premises ein deutlich erweitertes
Funktionsspektrum — einschließlich eines lokalen Azure-Portals,
Azure Resource Manager, RBAC, AKS und Container-Diensten — bei
gleichzeitiger Wahrung der Datensouveränität und
Air-Gap-Fähigkeit.

# Hintergrund

## S2D On-Premises

Storage Spaces Direct ist die in Windows Server 2016 Datacenter
und höher enthaltene Software-defined Storage Lösung. Sie fasst
die internen Laufwerke von 2 bis 16 physischen Servern zu einem
softwaredefinierten Speicherpool zusammen und stellt
hochverfügbaren Storage für virtuelle Maschinen bereit [1].

Die Verwaltung erfolgt über klassische
Windows-Server-Werkzeuge:

- Windows Admin Center (WAC)
- Failover Cluster Manager
- PowerShell
- System Center Virtual Machine Manager (SCVMM)

Details zur S2D-Architektur und zum Aufbau eines Clusters
finden sich im
[S2D Setup-Leitfaden](s2d-setup-guide.md) und in der
[technischen Bewertung für
Brandabschnitte](s2d-brandabschnitte.md).

## Azure Local (ehemals Azure Stack HCI)

Azure Local ist Microsofts hyperkonvergente
Infrastrukturplattform, die über Azure Arc in die
Azure-Verwaltungsebene integriert wird. Im Standardmodus
erfordert Azure Local eine Verbindung zur Azure Public Cloud
für Lizenzierung, Updates und Management [2].

## Disconnected Operations (Preview)

**Disconnected Operations** ist ein Zusatzmodul für Azure Local,
das als virtuelle Appliance bereitgestellt wird. Es ermöglicht
den Betrieb von Azure Local **ohne jegliche Verbindung zur
Azure Public Cloud** — einschließlich Deployment, Lifecycle
Management und Nutzung ausgewählter Azure-Arc-Dienste über
eine lokale Steuerungsebene [2][3].

# Funktionsvergleich

## Management und Verwaltung

| Funktion | S2D On-Premises | Azure Local (Disconnected) |
|---|---|---|
| **Verwaltungsoberfläche** | WAC, Failover Cluster Manager, SCVMM | Lokales Azure-Portal (Azure-Portal-Erlebnis) |
| **CLI-Verwaltung** | PowerShell | Azure CLI + PowerShell |
| **Infrastructure as Code** | PowerShell DSC, manuell | ARM-Templates, Azure CLI |
| **Rollenbasierte Zugriffskontrolle** | Active Directory, lokale Gruppenrichtlinien | Azure RBAC für Subscriptions und Resource Groups |
| **Managed Identity** | Nicht verfügbar | System-assigned Managed Identity |
| **Ressourcenmodell** | Windows-basiert (Cluster, Nodes, Volumes) | Azure Resource Manager (Subscriptions, Resource Groups, Resources) |

## Workloads und Dienste

| Funktion | S2D On-Premises | Azure Local (Disconnected) |
|---|---|---|
| **Virtuelle Maschinen** | Hyper-V VMs | Azure Local VMs (Azure-verwaltete VMs mit Hyper-V) |
| **Container / Kubernetes** | Nicht nativ integriert | AKS enabled by Arc (Preview) |
| **Container Registry** | Nicht verfügbar | Azure Container Registry (lokal) |
| **Secret Management** | Kein zentraler Dienst | Azure Key Vault (lokal) |
| **Policy Enforcement** | Group Policy, manuell | Azure Policy (lokal) |
| **Arc-enabled Servers** | Nicht verfügbar | VM-Gast-Management über Arc |
| **AI / ML Workloads** | Nicht nativ unterstützt | Disconnected AI Containers über AKS |

## Storage und Resilienz

| Funktion | S2D On-Premises | Azure Local (Disconnected) |
|---|---|---|
| **Storage-Technologie** | Storage Spaces Direct | Storage Spaces Direct (identisch) |
| **Resilienz-Optionen** | Mirror, Parity, Mixed | Mirror, Parity, Mixed (identisch) |
| **Fault Domain Awareness** | Node, Chassis, Rack, Site | Node, Chassis, Rack, Site (identisch) |
| **Max. Knotenzahl** | 16 (Windows Server) | 16 |
| **Dateisystem** | ReFS | ReFS |

## Netzwerk und Konnektivität

| Funktion | S2D On-Premises | Azure Local (Disconnected) |
|---|---|---|
| **Cloud-Verbindung** | Nicht erforderlich | **Nicht erforderlich** (Air-Gap-fähig) |
| **RDMA-Support** | iWARP, RoCE | iWARP, RoCE (identisch) |
| **Netzwerk-Anforderungen** | 10/25/100 GbE | 10/25/100 GbE (identisch) |
| **Update-Mechanismus** | WSUS, manuell | Offline-Update-Pakete (monatlich) |

## Lifecycle und Updates

| Funktion | S2D On-Premises | Azure Local (Disconnected) |
|---|---|---|
| **Betriebssystem-Updates** | WSUS, SCCM, manuell | Monatliche Offline-Update-Pakete |
| **Update-Umfang** | OS + Treiber separat | Appliance + Azure Local Software + AKS + Agents in einem Paket |
| **Lifecycle Management** | Manuell / SCCM | Über lokale Steuerungsebene |
| **Node-Management** | Failover Cluster Manager / PowerShell | Azure Local Device Management (Nodes hinzufügen/entfernen) |

## Monitoring

| Funktion | S2D On-Premises | Azure Local (Disconnected) |
|---|---|---|
| **Health Service** | Windows Health Service | Windows Health Service |
| **Externes Monitoring** | SCOM, Prometheus (manuell) | SCOM (Management Packs), Prometheus + Grafana für AKS |
| **Azure Monitor** | Nicht verfügbar (ohne Cloud) | Nicht verfügbar (disconnected) |

# Vorteile von Azure Local mit Disconnected Operations

## Konsistentes Azure-Erlebnis

Azure Local bietet dieselbe Verwaltungserfahrung wie die
Azure Public Cloud — mit lokalem Azure-Portal, Azure CLI und
ARM-Templates. Administratoren können bestehende
Azure-Kenntnisse nutzen, ohne neue Tools oder Workflows
erlernen zu müssen [3].

## Erweiterte Dienste ohne Cloud-Anbindung

Im Gegensatz zu S2D On-Premises stehen bei Azure Local
zusätzliche Plattformdienste lokal zur Verfügung [2]:

- **Azure Kubernetes Service (AKS)**: Container-Orchestrierung
  mit Azure-Integration
- **Azure Container Registry**: Lokale Speicherung und
  Verwaltung von Container-Images
- **Azure Key Vault**: Zentrales Secret Management
- **Azure Policy**: Durchsetzung von Governance-Standards
- **RBAC**: Granulare Zugriffskontrolle auf
  Subscription-/Resource-Group-Ebene

## Datensouveränität und Compliance

Disconnected Operations ermöglichen den Betrieb in
vollständig isolierten Netzwerken (Air-Gap). Daten,
Steuerungsebene und Verwaltung verbleiben innerhalb der
physischen und rechtlichen Grenzen der Organisation [2][3].
Dies adressiert:

- **Datensouveränität**: Keine Daten verlassen die
  Organisationsgrenze
- **Regulatorische Anforderungen**: DSGVO, KRITIS, VS-NfD und
  branchenspezifische Vorschriften
- **Angriffsfläche**: Reduktion durch fehlende externe
  Netzwerkverbindungen

## Vereinfachtes Lifecycle Management

Updates werden als monatliche Offline-Pakete bereitgestellt,
die alle Komponenten umfassen — Appliance, Azure Local
Software, AKS und Arc-Agents. Dies vereinfacht den
Update-Prozess im Vergleich zur manuellen
Patch-Verwaltung bei S2D On-Premises erheblich [3].

## AI- und Container-Workloads

Azure Local mit AKS ermöglicht den Betrieb von
Kubernetes-basierten Workloads — einschließlich
AI-Inferencing und containerisierter Anwendungen — in
isolierten Umgebungen. S2D On-Premises bietet hierfür keine
native Unterstützung [3].

## Zukunftssicherheit

Azure Local ist Microsofts strategische Plattform für
hyperkonvergente Infrastruktur. Windows Server S2D wird zwar
weiter unterstützt, aber die aktive Weiterentwicklung
und neue Funktionen konzentrieren sich auf Azure Local.

# Einschränkungen von Azure Local (Disconnected)

## Höhere Hardware-Anforderungen

Die Disconnected-Operations-Appliance erfordert einen
**dedizierten Management-Cluster** mit erhöhten
Mindestanforderungen [2]:

| Anforderung | Spezifikation |
|---|---|
| Anzahl Knoten | 3 |
| RAM pro Knoten | 96 GB (Minimum 64 GB für Appliance) |
| CPU-Kerne pro Knoten | 24 physische Kerne |
| Storage pro Knoten | 2 TB SSD/NVMe |
| Boot-Disk | 960 GB SSD/NVMe |

## Lizenzierung und Zugang

- Erfordert ein **Microsoft Customer Agreement for
  Enterprises (MCA-E)** oder gleichwertiges Abkommen
- Ein begründeter **Business Need** für den
  Disconnected-Betrieb muss nachgewiesen werden
- Zugang erfolgt über einen Qualifizierungsprozess mit dem
  Microsoft Account Team [2]

## Eingeschränktes Monitoring

Azure Monitor steht im Disconnected-Modus nicht zur
Verfügung. Monitoring erfolgt über SCOM (Management Packs)
oder Drittanbieter-Lösungen wie Prometheus und Grafana [3].

## Zertifizierte Hardware

Disconnected Operations unterstützen ausschließlich
**Premier Azure Local Hardware** aus dem
[Azure Local Solutions Catalog](https://azurestackhcisolutions.azure.microsoft.com/#/catalog).
Bestehende S2D-Hardware ist möglicherweise nicht
qualifiziert [2].

# Einsatzszenarien

## Wann S2D On-Premises wählen

- Bestehende Windows-Server-Infrastruktur ohne
  Migrationsdruck
- Keine Anforderung an Container oder Kubernetes
- Kostensensitive Umgebungen mit vorhandener Hardware
- Kleine Cluster (2–4 Knoten) ohne erweiterte
  Azure-Dienste
- Verwaltung ausschließlich über klassische
  Windows-Tools gewünscht

## Wann Azure Local (Disconnected) wählen

- **Regulierte Branchen**: Behörden, Verteidigung,
  Gesundheitswesen, Finanzdienstleistungen, Energie
- **Air-Gap-Anforderungen**: Keinerlei externe
  Netzwerkverbindung erlaubt
- **Container und Kubernetes**: AKS-Workloads in
  isolierten Umgebungen
- **AI-Inferencing**: Disconnected AI Containers
- **Azure-Konsistenz**: Einheitliches Management über
  verbundene und isolierte Standorte hinweg
- **Zukunftssicherheit**: Strategische Ausrichtung an
  Microsofts Plattform-Roadmap

# Quellenverzeichnis

1. **Microsoft Learn** — „Storage Spaces Direct overview"\
   <https://learn.microsoft.com/en-us/windows-server/storage/storage-spaces/storage-spaces-direct-overview>\
   Abgerufen: 29. April 2026

2. **Microsoft Learn** — „Disconnected operations for
   Azure Local overview (preview)"\
   <https://learn.microsoft.com/en-us/azure/azure-local/manage/disconnected-operations-overview>\
   Abgerufen: 29. April 2026

3. **Microsoft Tech Community** — „Cloud infrastructure
   for disconnected environments enabled by Azure Arc"\
   <https://techcommunity.microsoft.com/blog/azurearcblog/cloud-infrastructure-for-disconnected-environments-enabled-by-azure-arc/4413561>\
   Abgerufen: 29. April 2026
