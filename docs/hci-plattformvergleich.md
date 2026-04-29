---
title: "HCI-Plattformvergleich: Windows Server HCI, Azure Local Connected und Azure Local Isolated"
subtitle: "Drei-Wege-Vergleich: HCI On-Premises (Windows Server), Azure Local (Connected) und Azure Local mit Disconnected Operations"
author: "Jan Tiedemann"
date: "29. April 2026"
lang: de
toc: true
toc-depth: 3
---

# Zusammenfassung

Dieses Dokument vergleicht drei hyperkonvergente
Infrastrukturplattformen ([HCI](glossar.md#hci-hyper-converged-infrastructure)) von Microsoft:

1. **HCI On-Premises (Windows Server)** — die in
   Windows Server Datacenter enthaltene hyperkonvergente
   Lösung bestehend aus Hyper-V (Compute), [Storage Spaces
   Direct](glossar.md#s2d-storage-spaces-direct) (Storage) und Failover Clustering (Hochverfügbarkeit)
2. **[Azure Local](glossar.md#azure-local-ehemals-azure-stack-hci) (Connected)** — ehemals Azure Stack HCI; die
   über [Azure Arc](glossar.md#azure-arc) in die Azure-Verwaltungsebene integrierte
   HCI-Plattform mit permanenter oder periodischer
   Cloud-Anbindung
3. **Azure Local Isolated (Disconnected Operations)** — Azure
   Local im vollständig isolierten Betriebsmodus ohne jegliche
   Verbindung zur Azure Public Cloud

Es beleuchtet die architektonischen Unterschiede, den
Funktionsumfang, die Lizenzierung und die Einsatzszenarien
jeder Plattform.

**Ergebnis**: Alle drei Plattformen basieren auf derselben
S2D-Storage-Technologie und Hyper-V-Virtualisierung,
unterscheiden sich jedoch fundamental in Management,
Diensteumfang und Cloud-Integration. Azure Local (Connected)
bietet das vollständigste Azure-Erlebnis mit Cloud-basierten
Updates, Azure Monitor und Marketplace-Zugriff. Azure Local
Isolated liefert ein vergleichbares Funktionsspektrum ohne
Cloud-Anbindung — ideal für regulierte und [Air-Gap](glossar.md#air-gap)-Umgebungen.
HCI On-Premises unter Windows Server bleibt die
kostengünstigste Option für reine
Windows-Server-Umgebungen ohne Azure-Anforderungen.

# Hintergrund

## HCI On-Premises (Windows Server)

Windows Server Datacenter enthält seit Version 2016 alle
Komponenten für eine vollständige hyperkonvergente
Infrastruktur (HCI). Dabei bilden mehrere Technologien
gemeinsam den HCI-Stack:

| Schicht | Technologie | Rolle |
|---|---|---|
| **Compute** | Hyper-V | Virtualisierung von Workloads (VMs) |
| **Storage** | [Storage Spaces Direct (S2D)](glossar.md#s2d-storage-spaces-direct) | [Software-defined Storage](glossar.md#sds-software-defined-storage) — fasst die internen Laufwerke von 2 bis 16 Servern zu einem [Speicherpool](glossar.md#storage-pool) zusammen [^1] |
| **Hochverfügbarkeit** | Failover Clustering | Automatisches Failover von VMs und Diensten bei Knotenausfall |
| **Netzwerk** | [SET](glossar.md#set-switch-embedded-teaming), [SMB Direct](glossar.md#smb-direct), [RDMA](glossar.md#rdma-remote-direct-memory-access) | Konvergentes Netzwerk mit RDMA-Beschleunigung |
| **Netzwerk (optional)** | Network Controller / SDN | Software Defined Networking für Mandantenisolation |

S2D allein ist also nur die **Storage-Schicht** — erst in
Kombination mit Hyper-V und Failover Clustering entsteht
eine vollständige HCI-Lösung.

Die Verwaltung erfolgt über klassische
Windows-Server-Werkzeuge:

- [Windows Admin Center (WAC)](glossar.md#wac-windows-admin-center)
- Failover Cluster Manager
- PowerShell
- [System Center Virtual Machine Manager (SCVMM)](glossar.md#scvmm-system-center-virtual-machine-manager)

Details zur S2D-Architektur und zum Aufbau eines Clusters
finden sich im
[S2D Setup-Leitfaden](s2d-setup-guide.md) und in der
[technischen Bewertung für
Brandabschnitte](s2d-brandabschnitte.md).

## Azure Local — Connected (ehemals Azure Stack HCI)

Azure Local ist Microsofts hyperkonvergente
Infrastrukturplattform, die über [Azure Arc](glossar.md#azure-arc) in die
Azure-Verwaltungsebene integriert wird. Im Standardmodus
(**Connected**) erfordert Azure Local eine Verbindung zur
Azure Public Cloud für Lizenzierung, Updates und
Management [^2].

Die Cloud-Anbindung kann permanent oder periodisch erfolgen —
Azure Local toleriert eine Offline-Phase von bis zu **30
aufeinanderfolgenden Tagen**, bevor die Funktionalität
eingeschränkt wird [^2]. Die Verwaltung erfolgt über:

- Azure Portal (Cloud-basiert)
- Azure CLI und Azure PowerShell
- Windows Admin Center (mit Azure-Integration)
- [ARM](glossar.md#arm-azure-resource-manager)-Templates und [Bicep](glossar.md#bicep)

Azure Local Connected bietet Zugriff auf das vollständige
Azure-Hybrid-Ökosystem:

- **[Azure Kubernetes Service (AKS)](glossar.md#aks-azure-kubernetes-service)** enabled by Arc
- **Azure Arc VMs** — Azure-verwaltete virtuelle Maschinen
- **Azure Monitor** — Cloud-basiertes Monitoring und Alerting
- **Azure Update Manager** — Zentralisierte Update-Verwaltung
- **Azure Marketplace** — VM-Images und Erweiterungen
- **Azure Backup und Site Recovery** — Cloud-basierte
  Datensicherung und Disaster Recovery
- **Microsoft Defender for Cloud** — Sicherheitsüberwachung

## Azure Local — Isolated (Disconnected Operations, Preview)

**Disconnected Operations** ist ein Zusatzmodul für Azure Local,
das als virtuelle Appliance bereitgestellt wird. Es ermöglicht
den Betrieb von Azure Local **ohne jegliche Verbindung zur
Azure Public Cloud** — einschließlich Deployment, Lifecycle
Management und Nutzung ausgewählter Azure-Arc-Dienste über
eine lokale Steuerungsebene [^3][^4].

Im Isolated-Modus werden die Cloud-Dienste durch lokale
Pendants ersetzt:

- Lokales Azure-Portal statt Cloud-Portal
- Offline-Update-Pakete statt Azure Update Manager
- Lokale [RBAC](glossar.md#rbac-role-based-access-control)-Verwaltung statt [Azure Entra ID](glossar.md#entra-id-ehemals-azure-active-directory--azure-ad)
- Kein Azure Monitor, Azure Backup oder Azure Marketplace

# Funktionsvergleich

## Management und Verwaltung

| Funktion | HCI On-Premises (Windows Server) | Azure Local (Connected) | Azure Local (Isolated) |
|---|---|---|---|
| **Verwaltungsoberfläche** | WAC, Failover Cluster Manager, SCVMM | Azure Portal (Cloud), WAC | Lokales Azure-Portal (Appliance) |
| **CLI-Verwaltung** | PowerShell | Azure CLI, Azure PowerShell, PowerShell | Azure CLI + PowerShell (lokal) |
| **Infrastructure as Code** | PowerShell [DSC](glossar.md#dsc-desired-state-configuration), manuell | [ARM](glossar.md#arm-azure-resource-manager)-Templates, [Bicep](glossar.md#bicep), Terraform (AzureRM) | ARM-Templates, Azure CLI (lokal) |
| **Rollenbasierte Zugriffskontrolle** | Active Directory, lokale Gruppenrichtlinien | Azure [RBAC](glossar.md#rbac-role-based-access-control) via [Entra ID](glossar.md#entra-id-ehemals-azure-active-directory--azure-ad) | Azure RBAC (lokal, ohne Entra ID) |
| **Managed Identity** | Nicht verfügbar | System-assigned Managed Identity | System-assigned Managed Identity |
| **Identitätsprovider** | Active Directory | Azure Entra ID + Active Directory | Lokale Identitätsverwaltung + Active Directory |
| **Ressourcenmodell** | Windows-basiert (Cluster, Nodes, Volumes) | Azure Resource Manager (Subscriptions, Resource Groups) | Azure Resource Manager (lokal) |
| **Multi-Cluster-Management** | SCVMM, WAC (einzeln) | Azure Portal — zentrales Management aller Cluster | Lokales Portal pro Appliance |

## Workloads und Dienste

| Funktion | HCI On-Premises (Windows Server) | Azure Local (Connected) | Azure Local (Isolated) |
|---|---|---|---|
| **Virtuelle Maschinen** | Hyper-V VMs | Azure Arc VMs (Azure-verwaltete VMs) | Azure Local VMs (lokal verwaltet) |
| **Container / Kubernetes** | Nicht nativ integriert | [AKS](glossar.md#aks-azure-kubernetes-service) enabled by Arc | AKS enabled by Arc (Preview) |
| **Container Registry** | Nicht verfügbar | Azure Container Registry (Cloud) | Azure Container Registry (lokal) |
| **Secret Management** | Kein zentraler Dienst | Azure Key Vault (Cloud) | Azure Key Vault (lokal) |
| **Policy Enforcement** | Group Policy, manuell | Azure Policy | Azure Policy (lokal) |
| **Arc-enabled Servers** | Nicht verfügbar | VM-Gast-Management über Arc | VM-Gast-Management über Arc (lokal) |
| **AI / ML Workloads** | Nicht nativ unterstützt | AI-Workloads über AKS + GPU VMs | Disconnected AI Containers über AKS |
| **Azure Marketplace** | Nicht verfügbar | VM-Images, Extensions aus Marketplace | Nicht verfügbar (Offline-Import) |
| **Backup** | Windows Server Backup, [DPM](glossar.md#dpm-data-protection-manager), Drittanbieter | Azure Backup, Azure Site Recovery | Keine Azure-Backup-Integration |
| **Security** | Windows Defender, [SCOM](glossar.md#scom-system-center-operations-manager) | Microsoft Defender for Cloud, Sentinel | Kein Defender for Cloud |

## Storage und Resilienz

| Funktion | HCI On-Premises (Windows Server) | Azure Local (Connected) | Azure Local (Isolated) |
|---|---|---|---|
| **Storage-Technologie** | Storage Spaces Direct | Storage Spaces Direct (identisch) | Storage Spaces Direct (identisch) |
| **Compute-Technologie** | Hyper-V | Hyper-V (identisch) | Hyper-V (identisch) |
| **Resilienz-Optionen** | Mirror, Parity, Mixed | Mirror, Parity, Mixed (identisch) | Mirror, Parity, Mixed (identisch) |
| **Fault Domain Awareness** | [Node, Chassis, Rack, Site](glossar.md#fault-domain--fault-domain-awareness) | Node, Chassis, Rack, Site (identisch) | Node, Chassis, Rack, Site (identisch) |
| **Max. Knotenzahl** | 16 (Windows Server) | 16 | 16 |
| **Dateisystem** | [ReFS](glossar.md#refs-resilient-file-system) | ReFS | ReFS |

## Netzwerk und Konnektivität

| Funktion | HCI On-Premises (Windows Server) | Azure Local (Connected) | Azure Local (Isolated) |
|---|---|---|---|
| **Cloud-Verbindung** | Nicht erforderlich | **Erforderlich** (max. 30 Tage offline) | **Nicht erforderlich** ([Air-Gap](glossar.md#air-gap)-fähig) |
| **RDMA-Support** | [iWARP](glossar.md#iwarp-internet-wide-area-rdma-protocol), [RoCE](glossar.md#roce-rdma-over-converged-ethernet) | iWARP, RoCE (identisch) | iWARP, RoCE (identisch) |
| **Netzwerk-Anforderungen** | 10/25/100 [GbE](glossar.md#gbe-gigabit-ethernet) | 10/25/100 GbE (identisch) | 10/25/100 GbE (identisch) |
| **Azure-Endpunkte** | Keine | Firewall-Freigabe für Azure-Endpunkte erforderlich | Keine externen Endpunkte |
| **SDN (Software Defined Networking)** | Network Controller optional (ab WS2016) | Network Controller, SDN Load Balancer | Network Controller, SDN Load Balancer |

## Lifecycle und Updates

| Funktion | HCI On-Premises (Windows Server) | Azure Local (Connected) | Azure Local (Isolated) |
|---|---|---|---|
| **Update-Mechanismus** | [WSUS](glossar.md#wsus-windows-server-update-services), [SCCM](glossar.md#sccm--mecm-system-center-configuration-manager--microsoft-endpoint-configuration-manager), manuell | Azure Update Manager (Cloud-gesteuert) | Monatliche Offline-Update-Pakete |
| **Update-Umfang** | OS + Treiber separat | OS, Firmware, Treiber, Agents koordiniert | Appliance + Azure Local + AKS + Agents in einem Paket |
| **Lifecycle Management** | Manuell / SCCM | Azure Portal + Cloud-Orchestrierung | Über lokale Steuerungsebene |
| **Node-Management** | Failover Cluster Manager / PowerShell | Azure Portal (Nodes hinzufügen/entfernen) | Lokales Portal (Nodes hinzufügen/entfernen) |
| **Feature-Updates** | Windows Server Upgrades | Rolling Updates über Azure | Offline-Pakete (verzögerter Funktionsumfang) |

## Monitoring

| Funktion | HCI On-Premises (Windows Server) | Azure Local (Connected) | Azure Local (Isolated) |
|---|---|---|---|
| **Health Service** | Windows Health Service | Windows Health Service | Windows Health Service |
| **Cloud-Monitoring** | Nicht verfügbar | Azure Monitor, Log Analytics, Insights | Nicht verfügbar (kein Cloud-Zugang) |
| **On-Premises-Monitoring** | SCOM, Prometheus (manuell) | SCOM, Azure Monitor Agent | SCOM, Prometheus + Grafana für AKS |
| **Alerting** | SCOM-Regeln, manuell | Azure Monitor Alerts, Action Groups | SCOM-Regeln, manuell |
| **Telemetrie** | Optional ([CEIP](glossar.md#ceip-customer-experience-improvement-program)) | Azure-Telemetrie (erforderlich) | Keine Cloud-Telemetrie |

## Lizenzierung und Kosten

| Funktion | HCI On-Premises (Windows Server) | Azure Local (Connected) | Azure Local (Isolated) |
|---|---|---|---|
| **Lizenzmodell** | Windows Server Datacenter (pro Kern) | Azure-Abonnement (monatlich pro physischem Kern) | [MCA-E](glossar.md#mca-e-microsoft-customer-agreement-for-enterprises)-Vertrag + Azure-Abonnement |
| **Zugangsbeschränkung** | Keine | Keine | Qualifizierungsprozess + Business Need |
| **Software Assurance** | Optional (empfohlen) | Nicht erforderlich (Azure-Abo) | Nicht erforderlich (Azure-Abo) |
| **Azure Hybrid Benefit** | Nicht anwendbar | Ja — Windows Server SA anrechenbar | Ja — Windows Server SA anrechenbar |
| **Zusätzliche Dienste** | Separate Lizenzen (SCVMM, SCOM) | Inkludiert (Arc, AKS, Azure Portal) | Inkludiert (lokale Dienste) |

# Plattform-Stärken

## HCI On-Premises (Windows Server)

### Einfachheit und Kosteneffizienz

Der gesamte HCI-Stack — Hyper-V, S2D, Failover Clustering —
ist Bestandteil der Windows Server Datacenter-Lizenz und
erfordert keine zusätzlichen Azure-Abonnements oder
Cloud-Verträge. Organisationen mit bestehender
Windows-Server-Infrastruktur können HCI ohne zusätzliche
Lizenzkosten nutzen [^1].

### Keine Cloud-Abhängigkeit

Windows Server HCI arbeitet vollständig unabhängig von
Cloud-Diensten. Es gibt keine Registrierungspflicht, keine
Telemetrie-Anforderungen und keine Abhängigkeit von externen
Diensten für den laufenden Betrieb.

### Bekannte Verwaltungswerkzeuge

Administratoren mit Windows-Server-Erfahrung können
bestehende Kenntnisse in Failover Cluster Manager,
PowerShell und SCVMM direkt anwenden — ohne Einarbeitung
in Azure-spezifische Konzepte.

### Flexible Hardware

Windows Server HCI unterstützt jede im Windows Server
Catalog zertifizierte Hardware. Es ist keine Beschränkung
auf einen speziellen Hardware-Katalog erforderlich.

## Azure Local (Connected)

### Vollständiges Azure-Hybrid-Erlebnis

Azure Local Connected bietet die umfassendste Integration in
die Azure-Plattform. Cluster erscheinen als
Azure-Ressourcen im Azure Portal und können zusammen mit
Cloud-Ressourcen zentral verwaltet werden [^2].

### Cloud-basierte Dienste

Im Connected-Modus stehen alle Azure-Hybrid-Dienste zur
Verfügung [^2]:

- **Azure Monitor**: Vollständiges Cloud-Monitoring mit
  Log Analytics, Metriken und Alerts
- **Azure Update Manager**: Zentralisierte, orchestrierte
  Updates über alle Cluster hinweg
- **Azure Backup und Site Recovery**: Cloud-basierte
  Datensicherung und Disaster Recovery
- **Azure Marketplace**: Zugriff auf VM-Images,
  Erweiterungen und Lösungen
- **Microsoft Defender for Cloud**: Sicherheitsbewertung
  und Bedrohungserkennung

### Zentrales Multi-Site-Management

Organisationen mit mehreren Standorten können alle Azure
Local Cluster über ein einziges Azure Portal verwalten —
unabhängig vom physischen Standort. Dies ermöglicht
einheitliche Governance, [RBAC](glossar.md#rbac-role-based-access-control) und Policy-Durchsetzung
über die gesamte Infrastruktur [^2].

### Azure Kubernetes Service (AKS)

AKS enabled by Arc ermöglicht die Bereitstellung und
Verwaltung von Kubernetes-Clustern auf Azure Local mit
vollständiger Azure-Integration — einschließlich
Azure Container Registry, Helm Charts aus dem
Marketplace und GitOps-basiertem Deployment [^2].

## Azure Local Isolated (Disconnected Operations)

### Konsistentes Azure-Erlebnis ohne Cloud

Azure Local Isolated bietet dieselbe Verwaltungserfahrung
wie die Azure Public Cloud — mit lokalem Azure-Portal,
Azure CLI und ARM-Templates. Administratoren können
bestehende Azure-Kenntnisse nutzen, ohne neue Tools oder
Workflows erlernen zu müssen [^4].

### Erweiterte Dienste ohne Cloud-Anbindung

Im Gegensatz zu HCI On-Premises unter Windows Server
stehen bei Azure Local Isolated zusätzliche
Plattformdienste lokal zur Verfügung [^3]:

- **Azure Kubernetes Service (AKS)**: Container-Orchestrierung
  mit Azure-Integration
- **Azure Container Registry**: Lokale Speicherung und
  Verwaltung von Container-Images
- **Azure Key Vault**: Zentrales Secret Management
- **Azure Policy**: Durchsetzung von Governance-Standards
- **[RBAC](glossar.md#rbac-role-based-access-control)**: Granulare Zugriffskontrolle auf
  Subscription-/Resource-Group-Ebene

### Datensouveränität und Compliance

Disconnected Operations ermöglichen den Betrieb in
vollständig isolierten Netzwerken ([Air-Gap](glossar.md#air-gap)). Daten,
Steuerungsebene und Verwaltung verbleiben innerhalb der
physischen und rechtlichen Grenzen der Organisation [^3][^4].
Dies adressiert:

- **Datensouveränität**: Keine Daten verlassen die
  Organisationsgrenze
- **Regulatorische Anforderungen**: [DSGVO](glossar.md#dsgvo-datenschutz-grundverordnung), [KRITIS](glossar.md#kritis-kritische-infrastrukturen), [VS-NfD](glossar.md#vs-nfd-verschlusssache--nur-für-den-dienstgebrauch) und
  branchenspezifische Vorschriften
- **Angriffsfläche**: Reduktion durch fehlende externe
  Netzwerkverbindungen

### Vereinfachtes Lifecycle Management

Updates werden als monatliche Offline-Pakete bereitgestellt,
die alle Komponenten umfassen — Appliance, Azure Local
Software, AKS und Arc-Agents. Dies vereinfacht den
Update-Prozess im Vergleich zur manuellen
Patch-Verwaltung bei HCI On-Premises erheblich [^4].

### AI- und Container-Workloads

Azure Local Isolated mit AKS ermöglicht den Betrieb von
Kubernetes-basierten Workloads — einschließlich
AI-Inferencing und containerisierter Anwendungen — in
isolierten Umgebungen. HCI On-Premises unter Windows Server
bietet hierfür keine native Unterstützung [^4].

# Einschränkungen von Azure Local (Disconnected)

## Höhere Hardware-Anforderungen

Die Disconnected-Operations-Appliance erfordert einen
**dedizierten Management-Cluster** mit erhöhten
Mindestanforderungen [^3]:

| Anforderung | Spezifikation |
|---|---|
| Anzahl Knoten | 3 |
| RAM pro Knoten | 96 GB (Minimum 64 GB für Appliance) |
| CPU-Kerne pro Knoten | 24 physische Kerne |
| Storage pro Knoten | 2 TB SSD/NVMe |
| Boot-Disk | 960 GB SSD/NVMe |

## Lizenzierung und Zugang

- Erfordert ein **Microsoft Customer Agreement for
  Enterprises ([MCA-E](glossar.md#mca-e-microsoft-customer-agreement-for-enterprises))** oder gleichwertiges Abkommen
- Ein begründeter **Business Need** für den
  Disconnected-Betrieb muss nachgewiesen werden
- Zugang erfolgt über einen Qualifizierungsprozess mit dem
  Microsoft Account Team [^3]

## Eingeschränktes Monitoring

Azure Monitor steht im Disconnected-Modus nicht zur
Verfügung. Monitoring erfolgt über [SCOM](glossar.md#scom-system-center-operations-manager) (Management Packs)
oder Drittanbieter-Lösungen wie Prometheus und Grafana [^4].

## Zertifizierte Hardware

Disconnected Operations unterstützen ausschließlich
**Premier Azure Local Hardware** aus dem
[Azure Local Solutions Catalog](https://azurestackhcisolutions.azure.microsoft.com/#/catalog).
Bestehende Windows-Server-HCI-Hardware ist möglicherweise
nicht qualifiziert [^3].

# Einsatzszenarien

## Wann HCI On-Premises (Windows Server) wählen

- Bestehende Windows-Server-Infrastruktur ohne
  Migrationsdruck
- Keine Anforderung an Container oder Kubernetes
- Kostensensitive Umgebungen mit vorhandener Hardware
- Kleine Cluster (2–4 Knoten) ohne erweiterte
  Azure-Dienste
- Verwaltung ausschließlich über klassische
  Windows-Tools gewünscht
- Volle Kontrolle über Hardware-Auswahl ohne
  Katalogbeschränkung

## Wann Azure Local (Connected) wählen

- **Azure-Integration**: Einheitliches Management von
  On-Premises- und Cloud-Ressourcen über Azure Portal
- **Multi-Site-Management**: Zentrale Verwaltung aller
  Standorte über ein einziges Portal
- **Cloud-Dienste**: Azure Monitor, Azure Backup,
  Azure Site Recovery, Azure Marketplace
- **Kubernetes**: AKS-Workloads mit vollständiger
  Azure-Integration und GitOps
- **Sicherheit**: Microsoft Defender for Cloud,
  Azure Sentinel
- **Zukunftssicherheit**: Strategische Plattform mit
  kontinuierlicher Weiterentwicklung
- **Cloud-Anbindung möglich**: Mindestens periodische
  Verbindung zur Azure Public Cloud ist erlaubt

## Wann Azure Local Isolated (Disconnected) wählen

- **Regulierte Branchen**: Behörden, Verteidigung,
  Gesundheitswesen, Finanzdienstleistungen, Energie
- **Air-Gap-Anforderungen**: Keinerlei externe
  Netzwerkverbindung erlaubt
- **Container und Kubernetes**: AKS-Workloads in
  isolierten Umgebungen
- **AI-Inferencing**: Disconnected AI Containers
- **Azure-Konsistenz**: Einheitliches Management über
  verbundene und isolierte Standorte hinweg
- **Datensouveränität**: [DSGVO](glossar.md#dsgvo-datenschutz-grundverordnung), [KRITIS](glossar.md#kritis-kritische-infrastrukturen), [VS-NfD](glossar.md#vs-nfd-verschlusssache--nur-für-den-dienstgebrauch) und
  branchenspezifische Vorschriften erfordern vollständige
  Datenisolation

# Quellenverzeichnis

[^1]: **Microsoft Learn** — „Storage Spaces Direct overview"\
<https://learn.microsoft.com/en-us/windows-server/storage/storage-spaces/storage-spaces-direct-overview>\
Abgerufen: 29. April 2026

[^2]: **Microsoft Learn** — „Azure Local overview"\
<https://learn.microsoft.com/en-us/azure/azure-local/overview>\
Abgerufen: 29. April 2026

[^3]: **Microsoft Learn** — „Disconnected operations for Azure Local overview (preview)"\
<https://learn.microsoft.com/en-us/azure/azure-local/manage/disconnected-operations-overview>\
Abgerufen: 29. April 2026

[^4]: **Microsoft Tech Community** — „Cloud infrastructure for disconnected environments enabled by Azure Arc"\
<https://techcommunity.microsoft.com/blog/azurearcblog/cloud-infrastructure-for-disconnected-environments-enabled-by-azure-arc/4413561>\
Abgerufen: 29. April 2026
