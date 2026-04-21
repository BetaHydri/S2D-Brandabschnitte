---
title: "Storage Spaces Direct — Setup-Leitfaden"
subtitle: "Vollständige Anleitung: Hardware, Software und Deployment eines S2D-Clusters unter Windows Server"
author: "Jan Tiedemann"
date: "20. April 2026"
lang: de
toc: true
toc-depth: 3
---

# Zusammenfassung

Dieses Dokument beschreibt den vollständigen Aufbau eines **Storage Spaces Direct (S2D)** Clusters unter Windows Server. Es behandelt alle Hardware- und Software-Voraussetzungen, die Netzwerk-Konfiguration, das schrittweise Deployment per PowerShell sowie die Post-Deployment-Validierung und Fehlerbehebung. Alle technischen Aussagen wurden gegen die offizielle Microsoft-Dokumentation validiert und mit Quellenangaben versehen.

**Zielgruppe**: Windows Server Administratoren und Infrastruktur-Architekten, die einen S2D-Cluster planen und implementieren.

# Hardware-Voraussetzungen

## Server

Storage Spaces Direct erfordert mindestens **2 Server** und unterstützt maximal **16 Server** pro Cluster [1][2]. Microsoft empfiehlt, dass alle Server vom selben Hersteller und Modell stammen (**symmetrische Hardware**) [2].

| Anforderung | Spezifikation |
|---|---|
| Minimale Knotenzahl | 2 Server |
| Maximale Knotenzahl | 16 Server |
| Hardware-Empfehlung | Identischer Hersteller und identisches Modell |
| Zertifizierung | Windows Server Catalog (SDDC Standard/Premium AQ empfohlen) [2] |

> **Wichtig**: Systeme, Komponenten, Geräte und Treiber müssen für das verwendete Betriebssystem im [Windows Server Catalog](https://www.windowsservercatalog.com/) zertifiziert sein. Microsoft empfiehlt zusätzlich die Qualifikationen **Software-Defined Data Center (SDDC) Standard** oder **Premium** [2].

## Prozessoren

Die Mindestanforderungen an die CPU sind [2]:

| Anforderung | Spezifikation |
|---|---|
| Intel | Intel Nehalem oder neuer (empfohlen: Intel Xeon Scalable) |
| AMD | AMD EPYC oder neuer |
| Symmetrie | Identische CPU-Familien über alle Knoten empfohlen |

> **Hinweis**: Identische CPU-Familien auf allen Knoten vereinfachen die Live Migration von VMs und gewährleisten konsistente Performance im Cluster.

## Arbeitsspeicher

Die RAM-Anforderungen für S2D setzen sich aus mehreren Komponenten zusammen [2]:

| Komponente | Anforderung |
|---|---|
| Betriebssystem | Minimum gemäß Windows Server Systemanforderungen |
| VMs und Workloads | Abhängig von der geplanten Auslastung |
| S2D-Metadaten | **4 GB RAM pro TB Cache-Laufwerkskapazität** pro Server |
| RAM-Typ | ECC-RAM erforderlich (Server-Hardware-Standard) |

**Beispiel**: Ein Server mit 2× 800 GB NVMe-Cache-Laufwerken (1,6 TB Cache) benötigt mindestens 6,4 GB RAM allein für S2D-Metadaten — zusätzlich zum Bedarf des Betriebssystems und der Workloads.

## Speicherlaufwerke

### Unterstützte Laufwerkstypen

S2D arbeitet mit direkt angeschlossenen Laufwerken der folgenden Typen [2][3]:

| Laufwerkstyp | Beschreibung |
|---|---|
| **[NVMe](glossar.md#nvme-non-volatile-memory-express)** | Non-Volatile Memory Express — höchste [IOPS](glossar.md#iops-inputoutput-operations-per-second) und niedrigste Latenz (M.2, U.2, Add-in Card) |
| **[SSD](glossar.md#ssd-solid-state-drive)** | Solid-State Drives über [SATA](glossar.md#sata-serial-advanced-technology-attachment) oder [SAS](glossar.md#sas-serial-attached-scsi) |
| **[HDD](glossar.md#hdd-hard-disk-drive)** | Rotierende Festplatten über SATA oder SAS |
| **[Persistent Memory (PMem)](glossar.md#pmem-persistent-memory)** | Persistenter Speicher im Block-Storage-Modus |

> **Nicht unterstützt**: Reine HDD-Deployments ohne schnellere Laufwerke als Cache-Tier. [SAN](glossar.md#san-storage-area-network)-Storage (Fibre Channel, [iSCSI](glossar.md#iscsi-internet-small-computer-systems-interface), [FCoE](glossar.md#fcoe-fibre-channel-over-ethernet)) wird ebenfalls nicht unterstützt [2].

### Laufwerkssymmetrie

Alle Server im Cluster müssen über die **gleiche Anzahl und die gleichen Typen** von Laufwerken verfügen [2]. Weitere Empfehlungen:

- SSDs müssen über **[Power-Loss Protection](glossar.md#power-loss-protection)** verfügen (keine Consumer-SSDs) [2]
- Cache-Laufwerke müssen mindestens **32 GB** groß sein [2]
- Der NVMe-Treiber muss der von Microsoft bereitgestellte Treiber sein (`stornvme.sys`) [2]
- Die Anzahl der Kapazitätslaufwerke sollte ein ganzzahliges Vielfaches der Cache-Laufwerke sein [2]

### Minimale Laufwerksanzahl (ohne Boot-Laufwerk)

| Konfiguration | Mindestanzahl pro Server |
|---|---|
| Nur NVMe (gleicher Typ) | 2 NVMe |
| Nur SSD (gleicher Typ) | 2 SSD |
| NVMe + SSD (Cache + Kapazität) | 2 NVMe (Cache) + 4 SSD (Kapazität) |
| NVMe + HDD (Cache + Kapazität) | 2 NVMe (Cache) + 4 HDD (Kapazität) |
| SSD + HDD (Cache + Kapazität) | 2 SSD (Cache) + 4 HDD (Kapazität) |

*Quelle: Microsoft Learn — Storage Spaces Direct Hardware Requirements [2]*

### Cache-Tier und Kapazitäts-Tier

Wenn **zwei unterschiedliche Laufwerkstypen** vorhanden sind, verwendet S2D automatisch die schnelleren Laufwerke als **Cache** und die langsameren als **Kapazität** [3]:

| Deployment | Cache | Kapazität | Cache-Verhalten |
|---|---|---|---|
| Nur NVMe | Keiner (optional manuell) | NVMe | Write-only (falls konfiguriert) |
| Nur SSD | Keiner (optional manuell) | SSD | Write-only (falls konfiguriert) |
| NVMe + SSD | NVMe | SSD | Write-only |
| NVMe + HDD | NVMe | HDD | Read + Write |
| SSD + HDD | SSD | HDD | Read + Write |
| NVMe + SSD + HDD | NVMe | SSD + HDD | Read + Write (HDD), Write-only (SSD) |

*Quelle: Microsoft Learn — Understanding the Storage Pool Cache [3]*

### Boot-Laufwerk

| Anforderung | Spezifikation |
|---|---|
| Boot-Gerät | Jedes von Windows Server unterstützte Boot-Gerät (inkl. SATADOM) |
| [RAID](glossar.md#raid-redundant-array-of-independent-disks) 1 | Nicht erforderlich, aber für Boot unterstützt |
| Mindestgröße | 200 GB empfohlen |
| Trennung | Boot-Laufwerk muss **separat** von den S2D-Datenlaufwerken sein |

*Quelle: Microsoft Learn — Storage Spaces Direct Hardware Requirements [2]*

## Netzwerk

### Mindestanforderungen

| Szenario | Anforderung |
|---|---|
| 2–3 Knoten (Minimum) | **10 GbE** NIC oder schneller |
| 4+ Knoten (empfohlen) | **[25 GbE](glossar.md#gbe-gigabit-ethernet)** oder schneller, [RDMA](glossar.md#rdma-remote-direct-memory-access)-fähig |
| Redundanz | Mindestens **2 Netzwerkverbindungen** pro Knoten empfohlen |
| RDMA-Protokoll | **[iWARP](glossar.md#iwarp-internet-wide-area-rdma-protocol)** (empfohlen, einfacher einzurichten) oder **[RoCE](glossar.md#roce-rdma-over-converged-ethernet)** (v1/v2) |
| Topologie | Switched oder Switchless (Direct-Attach) |

*Quelle: Microsoft Learn — Storage Spaces Direct Hardware Requirements [2]*

> **Produktionswarnung — Bandbreite realistisch dimensionieren**: Die oben genannten 10 GbE bzw. 25 GbE sind Microsofts **absolute Mindestanforderungen**. In Produktionsumgebungen reichen diese Bandbreiten in der Regel **nicht** aus. S2D erzeugt erheblichen Storage-Traffic: Jeder Schreibvorgang wird je nach Resilienz-Level (Two-Way Mirror, Three-Way Mirror, Mirror-Accelerated Parity) **zwei- bis dreifach repliziert**. Hinzu kommen Re-Sync-Operationen nach Knotenausfällen oder Wartungsfenstern, die das gesamte verfügbare Storage-Netzwerk auslasten können.
>
> **Empfehlung für Produktionsumgebungen**:
>
> | Cluster-Größe | Empfohlene Bandbreite (Storage) |
> |---|---|
> | 2–3 Knoten | **25 GbE** mit RDMA (mindestens 2× pro Knoten) |
> | 4–8 Knoten | **2× 25 GbE** oder **2× 100 GbE** mit RDMA |
> | 8–16 Knoten / IO-intensive Workloads | **2× 100 GbE** mit RDMA |
>
> Gründe für höhere Bandbreite in Produktion:
>
> - **Replikations-Overhead**: Ein VM-Schreibvorgang mit 1 GB/s erzeugt bei Three-Way Mirror 3 GB/s Storage-Netzwerkverkehr
> - **Re-Sync nach Ausfall**: Wenn ein Knoten ausfällt oder nach einem Update neu gestartet wird, müssen potenziell Terabytes an Daten re-synchronisiert werden — das saturiert 10-GbE-Links vollständig und beeinträchtigt die VM-Performance
> - **Shared Bandwidth**: Storage-, Live-Migration- und CSV-Redirect-Traffic konkurrieren um die verfügbare Bandbreite. Ohne ausreichend Headroom leidet die Storage-Latenz
> - **NVMe-Laufwerke**: Moderne NVMe-SSDs liefern sequenziell > 3 GB/s pro Laufwerk. Bereits wenige NVMe-Laufwerke saturieren eine 25-GbE-Verbindung (ca. 3,1 GB/s) — das Netzwerk wird zum Flaschenhals

### Switchless vs. Switched

| Topologie | Beschreibung | Eignung |
|---|---|---|
| **Switchless** | Direkte Verbindungen zwischen allen Knoten (jeder mit jedem) | 2–3 Knoten |
| **Switched** | Über Netzwerk-Switches verbunden | Alle Cluster-Größen, empfohlen ab 4 Knoten |

> **Wichtig bei RoCE**: Bei Verwendung von RoCE muss der [Top-of-Rack-Switch](glossar.md#tor-top-of-rack) korrekt konfiguriert werden ([PFC](glossar.md#pfc-priority-flow-control), [ECN](glossar.md#ecn-explicit-congestion-notification)). iWARP erfordert keine spezielle Switch-Konfiguration und ist daher einfacher zu implementieren [1][4].

### NIC-Anforderungen

| Anforderung | Spezifikation |
|---|---|
| NIC-Typ | RDMA-fähig (iWARP oder RoCE) empfohlen |
| Firmenmatch | NIC-Adapter, Treiber und Firmware müssen auf allen Knoten **exakt identisch** sein [2] |
| [SET](glossar.md#set-switch-embedded-teaming)-Teaming | Switch Embedded Teaming (SET) unterstützt — siehe Netzwerk-Konfiguration |

## [Host Bus Adapter (HBA)](glossar.md#hba-host-bus-adapter)

| Anforderung | Spezifikation |
|---|---|
| Modus | **[Simple Pass-Through](glossar.md#pass-through-hba-modus)** (direkte Durchreichung) |
| RAID-Controller | **Nicht unterstützt** für S2D-Datenlaufwerke |
| SAS-HBA mit SAS-/SATA-Laufwerken | Unterstützt |
| RAID-Controller mit Pass-Through | Nur unterstützt, wenn ausschließlich SAS physische Laufwerke direkt durchgereicht werden |

> **Nicht unterstützt**: RAID-Controller, die keine direkte Durchreichung von SAS physischen Speichergeräten unterstützen. S2D verwaltet die Datenresilienz selbst — RAID auf Controller-Ebene ist kontraproduktiv [2].

## Verkabelung

| Topologie | Beschreibung |
|---|---|
| Switchless (2–3 Knoten) | Direkte Verbindungen (Direct-Attach) zwischen allen Knoten |
| Switched (4+ Knoten) | Über redundante Switches verbunden |
| Redundanz | Mindestens **2 unabhängige Switches** für Storage-Traffic empfohlen |
| Kabeltyp | Abhängig von NIC-Typ: [DAC](glossar.md#dac-direct-attach-copper)-Kabel (Direct Attach Copper), [LWL](glossar.md#lwl-lichtwellenleiter) (Glasfaser), Kupfer |

# Software-Voraussetzungen

## Betriebssystem

| Anforderung | Spezifikation |
|---|---|
| Edition | Windows Server **Datacenter** Edition (Standard reicht **nicht** aus) |
| Versionen | Windows Server 2016, 2019, 2022, 2025 |
| Installation | Server Core oder Server with Desktop Experience |

> **Wichtig**: Storage Spaces Direct ist ausschließlich in der **Datacenter-Edition** von Windows Server verfügbar. Die Standard-Edition unterstützt S2D nicht [1][4].

## Rollen und Features

Die folgenden Rollen und Features müssen auf **allen Knoten** installiert werden [4]:

| Rolle / Feature | Zweck |
|---|---|
| **Failover-Clustering** | Cluster-Infrastruktur |
| **Hyper-V** | Für Hyperconverged-Deployments (VMs auf dem Cluster) |
| **File Server** | Für Converged-Deployments (Scale-Out File Server) |
| **[Data-Center-Bridging](glossar.md#dcb-data-center-bridging)** | Für RoCEv2-Netzwerkadapter ([PFC](glossar.md#pfc-priority-flow-control)/[ECN](glossar.md#ecn-explicit-congestion-notification)-Konfiguration) |
| **RSAT-Clustering-PowerShell** | Remote-Verwaltung des Clusters |
| **Hyper-V-PowerShell** | PowerShell-Verwaltung von Hyper-V |
| Data Deduplication | Optional — Speicherplatzoptimierung |

## Active Directory

| Anforderung | Spezifikation |
|---|---|
| Domänenmitgliedschaft | Alle Knoten müssen der **gleichen Active Directory-Domäne** beigetreten sein |
| Berechtigungen | Das Administratorkonto muss auf allen Knoten lokaler Administrator sein |
| Cluster-Computerobjekt | Wird automatisch beim Erstellen des Clusters in AD erstellt |

## Updates und Treiber

| Anforderung | Spezifikation |
|---|---|
| Kumulative Updates | **Alle Knoten** müssen auf dem gleichen Patch-Stand sein |
| Firmware | Identische Firmware-Versionen auf allen Knoten |
| Treiber | Identische Treiberversionen, insbesondere für NICs und Storage-Controller |
| NVMe-Treiber | Microsoft-eigener Treiber (`stornvme.sys`) verwenden [2] |

> **Best Practice**: Vor dem Deployment alle Knoten auf den aktuellsten kumulativen Patch-Stand bringen und identische Firmware- sowie Treiberversionen sicherstellen. Heterogene Treiberstände sind eine häufige Ursache für Clustervalidierungsfehler.

# Netzwerk-Konfiguration

## Netzwerk-Übersicht

Für einen S2D-Cluster werden typischerweise mehrere logische Netzwerke konfiguriert:

| Netzwerk | Zweck | Empfohlene Bandbreite |
|---|---|---|
| **Management** | OS-Verwaltung, RDP, Cluster-Heartbeat | 1–10 GbE |
| **Storage** | S2D-Traffic (SMB Direct, Storage Bus) | 25 GbE+ mit RDMA |
| **Live Migration** | VM-Live-Migration zwischen Knoten | 10–25 GbE |
| **VM-Netzwerk** | VM-Traffic (Tenant-Netzwerk) | 10–25 GbE |

### Dedizierte NICs — Physische Trennung der Traffic-Typen

In Produktionsumgebungen sollten die verschiedenen Netzwerk-Traffic-Typen über **dedizierte physische Netzwerkkarten** getrennt werden. Die gemeinsame Nutzung von NICs für mehrere Traffic-Typen führt zu Bandbreitenkonflikten, unvorhersehbaren Latenzen und erschwert die Fehlerdiagnose.

| Traffic-Typ | Dedizierte NICs | Begründung |
|---|---|---|
| **Management** | 1–2× 1/10 GbE | Isoliert Verwaltungs- und Heartbeat-Traffic von performancekritischen Pfaden. Bei einem Storage-Re-Sync bleibt der Cluster-Heartbeat stabil und löst kein unbeabsichtigtes Node-Eviction aus |
| **Storage (East-West)** | 2× 25/100 GbE (RDMA) | S2D-Replikation, Re-Sync und [CSV](glossar.md#csv-cluster-shared-volumes)-I/O erfordern garantierte, latenzarme Bandbreite. RDMA funktioniert optimal, wenn der Adapter nicht durch anderen Traffic belastet wird |
| **CSV-Redirect** | Über Storage-NICs oder separate NICs | [CSV-Redirect-I/O](glossar.md#csv-redirected-io) tritt auf, wenn ein Knoten auf ein Volume zugreift, dessen Owner ein anderer Knoten ist. Dieser Traffic konkurriert direkt mit Storage-Replikation — bei hoher Last sollten separate NICs erwogen werden |
| **Live Migration** | 1–2× 10/25 GbE | Live Migration kann mehrere GB/s pro VM generieren. Ohne eigene NICs verdrängt eine Migration den Storage-Traffic und verursacht VM-Stalls |
| **VM-Netzwerk (Tenant)** | 2× 10/25 GbE (via SET vSwitch) | Nord-Süd-Traffic der VMs sollte vom East-West-Storage-Traffic vollständig getrennt sein |

> **Best Practice — Minimale NIC-Bestückung pro Knoten (Produktion)**:
>
> | NIC-Paar | Verwendung |
> |---|---|
> | 2× 1/10 GbE | Management + Cluster-Heartbeat |
> | 2× 25/100 GbE (RDMA) | Storage (S2D, CSV) |
> | 2× 10/25 GbE | VM-Netzwerk + Live Migration (SET vSwitch) |
>
> Damit verfügt jeder Knoten über mindestens **6 physische Netzwerkports**. Die Paare bieten Redundanz bei Adapter- oder Switch-Ausfall. Management-NICs sollten **nicht** Teil des SET vSwitch sein, damit die Verwaltung auch bei einem vSwitch-Problem erreichbar bleibt.

### [VLAN](glossar.md#vlan-virtual-local-area-network)-Trennung

| Netzwerk | VLAN | Begründung |
|---|---|---|
| Management | Eigenes VLAN | Trennung von Storage- und VM-Traffic |
| Storage (RDMA) | Eigenes VLAN (oder ungetaggt bei Switchless) | Isolation des Storage-Traffic für konsistente Latenz |
| Live Migration | Eigenes VLAN oder gemeinsam mit Storage | Vermeidung von Interferenz mit VM-Traffic |
| VM-Netzwerk | Ein oder mehrere VLANs | Mandantentrennung und Segmentierung |

## [SMB Direct](glossar.md#smb-direct) und [SMB Multichannel](glossar.md#smb-multichannel)

S2D nutzt **SMB 3.x** als Transportprotokoll für den Storage-Traffic [1]:

| Feature | Beschreibung |
|---|---|
| **SMB Direct** | SMB über RDMA — ermöglicht CPU-entlastende Datenübertragung mit niedriger Latenz und hohem Durchsatz |
| **SMB Multichannel** | Automatische Nutzung mehrerer Netzwerkverbindungen für Bandbreitenaggregation und Failover |

> **Hinweis**: SMB Direct erfordert RDMA-fähige NICs. SMB Multichannel ist automatisch aktiv, wenn mehrere Netzwerkpfade zwischen den Knoten vorhanden sind.

## SET (Switch Embedded Teaming) vs. NIC Teaming

Ab Windows Server 2016 wird **Switch Embedded Teaming (SET)** empfohlen [4]:

| Eigenschaft | SET (empfohlen) | Traditionelles NIC Teaming |
|---|---|---|
| Integration | Im Hyper-V Virtual Switch eingebettet | Separater Teaming-Layer |
| RDMA-Unterstützung | **Ja** — RDMA über virtuelle NICs (vNICs) | Nein — RDMA nicht mit NIC Teaming kompatibel |
| Verwaltung | Über Hyper-V Virtual Switch | Über separate NIC-Teaming-Konfiguration |
| Empfehlung für S2D | **Empfohlen** | Nicht empfohlen für S2D |

> **Wichtig**: Traditionelles NIC Teaming ([LBFO](glossar.md#lbfo-load-balancing-and-failover)) ist **nicht kompatibel** mit RDMA. Für S2D-Deployments muss SET verwendet werden, um RDMA-Funktionalität auf den virtuellen Host-NICs ([vNICs](glossar.md#vnic-virtual-nic)) zu nutzen.

### SET-Konfiguration (Beispiel)

```powershell
# Hyper-V Virtual Switch mit SET erstellen
New-VMSwitch -Name "SET-Switch" `
    -NetAdapterName "NIC1","NIC2" `
    -EnableEmbeddedTeaming $true `
    -AllowManagementOS $true

# Virtuelle NICs für Storage (RDMA) erstellen
Add-VMNetworkAdapter -ManagementOS -SwitchName "SET-Switch" -Name "Storage1"
Add-VMNetworkAdapter -ManagementOS -SwitchName "SET-Switch" -Name "Storage2"

# RDMA auf den virtuellen NICs aktivieren
Enable-NetAdapterRDMA -Name "vEthernet (Storage1)","vEthernet (Storage2)"

# VLAN-IDs zuweisen
Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName "Storage1" -Access -VlanId 711
Set-VMNetworkAdapterVlan -ManagementOS -VMNetworkAdapterName "Storage2" -Access -VlanId 712
```

## [Jumbo Frames](glossar.md#jumbo-frames)

| Aspekt | Empfehlung |
|---|---|
| [MTU](glossar.md#mtu-maximum-transmission-unit)-Größe | **9014 Bytes** (Jumbo Frames) für Storage-Netzwerk empfohlen |
| Konsistenz | Alle Geräte im Pfad (NICs, Switches, vNICs) müssen die gleiche MTU verwenden |
| Management-Netzwerk | Standard-MTU (1500 Bytes) beibehalten |
| Validierung | Jumbo Frames vor dem Cluster-Setup Ende-zu-Ende testen |

```powershell
# Jumbo Frames auf physischen NICs setzen
Set-NetAdapterAdvancedProperty -Name "NIC1" -RegistryKeyword "*JumboPacket" -RegistryValue 9014
Set-NetAdapterAdvancedProperty -Name "NIC2" -RegistryKeyword "*JumboPacket" -RegistryValue 9014

# MTU auf virtuellen NICs setzen
Set-NetIPInterface -InterfaceAlias "vEthernet (Storage1)" -NlMtuBytes 9014
Set-NetIPInterface -InterfaceAlias "vEthernet (Storage2)" -NlMtuBytes 9014
```

# Deployment-Schritte

## Übersicht

Das Deployment eines S2D-Clusters umfasst die folgenden Schritte [4]:

| Schritt | Beschreibung |
|---|---|
| 1 | Server vorbereiten (OS, Domain Join, Updates) |
| 2 | Rollen und Features installieren |
| 3 | Netzwerk konfigurieren (SET, RDMA, VLANs) |
| 4 | Cluster validieren |
| 5 | Cluster erstellen |
| 6 | [Fault Domains](glossar.md#fault-domain--fault-domain-awareness) konfigurieren (optional) |
| 7 | Storage Spaces Direct aktivieren |
| 8 | Volumes erstellen |
| 9 | Quorum Witness konfigurieren |
| 10 | Cluster validieren und testen |

## Schritt 1: Server vorbereiten

### OS-Installation

Windows Server **Datacenter Edition** auf allen Servern installieren. Server Core wird empfohlen, Server with Desktop Experience wird ebenfalls unterstützt [4].

### Domain Join

```powershell
# Alle Server der Domäne beitreten lassen
$ServerList = "Node01","Node02","Node03","Node04","Node05","Node06"

foreach ($Server in $ServerList) {
    Invoke-Command -ComputerName $Server -ScriptBlock {
        Add-Computer -NewName $using:Server `
            -DomainName "contoso.com" `
            -Credential "CONTOSO\Admin" `
            -Restart -Force
    }
}
```

### Updates installieren

Alle Server auf den gleichen kumulativen Patch-Stand bringen. Firmware und Treiber (insbesondere NIC- und Storage-Treiber) auf identische Versionen aktualisieren.

## Schritt 2: Rollen und Features installieren

```powershell
# Auf allen Knoten: Rollen und Features installieren
$ServerList = "Node01","Node02","Node03","Node04","Node05","Node06"
$FeatureList = "Hyper-V",
               "Failover-Clustering",
               "Data-Center-Bridging",
               "RSAT-Clustering-PowerShell",
               "Hyper-V-PowerShell",
               "FS-FileServer"

Invoke-Command -ComputerName $ServerList -ScriptBlock {
    Install-WindowsFeature -Name $using:FeatureList -IncludeManagementTools -Restart
}
```

> **Hinweis**: Das Feature **Data-Center-Bridging** ist nur erforderlich, wenn RoCEv2-Netzwerkadapter verwendet werden. Bei iWARP kann es weggelassen werden [4].

## Schritt 3: Netzwerk konfigurieren

### RDMA-Konfiguration prüfen

```powershell
# RDMA-Fähigkeit der NICs prüfen
Get-NetAdapterRDMA

# RDMA-Protokoll ermitteln (iWARP oder RoCE)
Get-NetAdapterRDMA | Select-Object Name, InterfaceDescription, Enabled
```

### SET und virtuelle NICs einrichten

Siehe die SET-Konfigurationsbeispiele im Abschnitt [Netzwerk-Konfiguration](#set-switch-embedded-teaming-vs-nic-teaming).

### IP-Adressen zuweisen

```powershell
# Statische IPs für Storage-Netzwerk zuweisen
New-NetIPAddress -InterfaceAlias "vEthernet (Storage1)" `
    -IPAddress "10.10.1.1" -PrefixLength 24
New-NetIPAddress -InterfaceAlias "vEthernet (Storage2)" `
    -IPAddress "10.10.2.1" -PrefixLength 24
```

## Schritt 4: Cluster validieren

Die Clustervalidierung ist ein **zwingend erforderlicher** Schritt vor der Clustererstellung [4]:

```powershell
# Cluster-Validierung ausführen
Test-Cluster -Node Node01,Node02,Node03,Node04,Node05,Node06 `
    -Include "Storage Spaces Direct",
             "Inventory",
             "Network",
             "System Configuration"
```

> **Wichtig**: Alle Validierungstests müssen bestanden werden, bevor der Cluster erstellt wird. Warnungen sollten untersucht und nach Möglichkeit behoben werden. Fehler in der Kategorie „Storage Spaces Direct" blockieren die spätere Aktivierung.

## Schritt 5: Cluster erstellen

```powershell
# Cluster erstellen (ohne Storage — S2D wird separat aktiviert)
New-Cluster -Name "S2DCluster" `
    -Node Node01,Node02,Node03,Node04,Node05,Node06 `
    -NoStorage `
    -StaticAddress 10.0.0.100
```

> **Hinweis**: Der Parameter `-NoStorage` ist entscheidend — er verhindert, dass traditionelle Cluster-Disks hinzugefügt werden. S2D verwaltet den Storage eigenständig. Der Clustername muss ein eindeutiger NetBIOS-Name mit maximal 15 Zeichen sein [4].

## Schritt 6: Fault Domains konfigurieren (optional)

Fault Domains ermöglichen es, die physische Topologie des Clusters abzubilden (Chassis, Rack, Site). Dies ist besonders relevant für Multi-Site- oder Multi-Rack-Deployments [5].

```powershell
# Beispiel: Rack-basierte Fault Domains
New-ClusterFaultDomain -Type Rack -Name "Rack01" -Location "RZ1, Reihe A"
New-ClusterFaultDomain -Type Rack -Name "Rack02" -Location "RZ1, Reihe B"

Set-ClusterFaultDomain -Name "Node01","Node02","Node03" -Parent "Rack01"
Set-ClusterFaultDomain -Name "Node04","Node05","Node06" -Parent "Rack02"

# Konfiguration prüfen
Get-ClusterFaultDomain
```

> **Wichtig**: Fault Domains müssen **vor** der Aktivierung von Storage Spaces Direct konfiguriert werden. Nachträgliche Änderungen führen nicht zu einer automatischen Umverteilung der Daten [5].

## Schritt 7: Storage Spaces Direct aktivieren

Vor der Aktivierung müssen die Datenlaufwerke bereinigt werden [4]:

### Laufwerke bereinigen

```powershell
# Alle Nicht-Boot-Laufwerke auf allen Servern bereinigen
$ServerList = "Node01","Node02","Node03","Node04","Node05","Node06"

Invoke-Command -ComputerName $ServerList -ScriptBlock {
    Get-Disk | Where-Object {
        $_.Number -ne $null -and !$_.IsBoot -and !$_.IsSystem -and $_.PartitionStyle -ne "RAW"
    } | ForEach-Object {
        $_ | Set-Disk -IsOffline:$false
        $_ | Set-Disk -IsReadOnly:$false
        $_ | Clear-Disk -RemoveData -RemoveOEM -Confirm:$false
    }
}
```

### S2D aktivieren

```powershell
# Storage Spaces Direct aktivieren
Enable-ClusterStorageSpacesDirect -CimSession "S2DCluster"
```

Dieser Befehl führt automatisch folgende Aktionen durch [4]:

| Aktion | Beschreibung |
|---|---|
| Pool erstellen | Ein einzelner großer Pool (z. B. „S2D on S2DCluster") |
| Cache konfigurieren | Automatische Zuweisung der schnellsten Laufwerke als Cache |
| Tiers erstellen | Standard-Tiers „Capacity" und „Performance" |

## Schritt 8: Volumes erstellen

```powershell
# Volume mit Three-way Mirror erstellen (empfohlen für 3+ Knoten)
New-Volume -FriendlyName "Volume01" `
    -FileSystem CSVFS_ReFS `
    -StoragePoolFriendlyName "S2D*" `
    -Size 1TB `
    -ResiliencySettingName Mirror

# Volume mit Dual Parity erstellen (4+ Knoten, kapazitätsoptimiert)
New-Volume -FriendlyName "Volume02" `
    -FileSystem CSVFS_ReFS `
    -StoragePoolFriendlyName "S2D*" `
    -Size 2TB `
    -ResiliencySettingName Parity
```

### Resilienz-Optionen

| Resilienz-Typ | Min. Knoten | Tolerierte Ausfälle | Speichereffizienz |
|---|---|---|---|
| Two-way Mirror | 2 | 1 | 50 % |
| [Three-way Mirror](glossar.md#three-way-mirror) | 3 | 2 | 33,3 % |
| Nested Resiliency | 2 | 2 (inkl. Intra-Node) | 25–40 % |
| [Dual Parity](glossar.md#dual-parity) | 4 | 2 | 50–80 % |
| [Mirror-Accelerated Parity](glossar.md#mirror-accelerated-parity) | 4 | 2 | 33,3–80 % |

*Quelle: Microsoft Learn — Plan Volumes [6], Fault Tolerance [7]*

> **Empfehlung**: Für Performance-kritische Workloads (VMs, SQL Server) wird **Three-way Mirror** empfohlen. Für kapazitätsoptimierte Workloads (Archiv, Backup) eignet sich **Dual Parity** [6].

### Kapazitätsplanung

Reservekapazität im Storage Pool freihalten [6]:

| Cluster-Größe | Empfohlene Reserve |
|---|---|
| 2 Server | Kapazität von 1 Laufwerk pro Server (2 Laufwerke gesamt) |
| 3 Server | Kapazität von 1 Laufwerk pro Server (3 Laufwerke gesamt) |
| 4+ Server | Kapazität von 1 Laufwerk pro Server (max. 4 Laufwerke gesamt) |

## Schritt 9: Quorum Witness konfigurieren

Ein Cluster Witness wird für alle Cluster mit **3 oder mehr Knoten** empfohlen und ist bei **2-Knoten-Clustern zwingend erforderlich** [4][8]:

```powershell
# Option 1: File Share Witness (on-premises)
Set-ClusterQuorum -Cluster "S2DCluster" `
    -FileShareWitness "\\FileServer\ClusterWitness$"

# Option 2: Cloud Witness (Azure Blob Storage)
Set-ClusterQuorum -Cluster "S2DCluster" `
    -CloudWitness `
    -AccountName "storageaccountname" `
    -AccessKey "accesskey"
```

| Witness-Typ | Beschreibung | Eignung |
|---|---|---|
| **[File Share Witness](glossar.md#file-share-witness)** | SMB-Freigabe auf separatem Server | On-premises-Deployments |
| **[Cloud Witness](glossar.md#cloud-witness)** | Azure Blob Storage | Deployments mit Internetzugang |
| [Disk Witness](glossar.md#disk-witness) | Clustered Disk | **Nicht unterstützt** bei S2D [8] |

> **Wichtig**: Ein **Disk Witness** wird bei S2D nicht unterstützt, da kein gemeinsam genutzter Speicher vorhanden ist [8].

## Schritt 10: Cluster validieren und testen

Nach dem vollständigen Deployment die Cluster-Gesundheit prüfen:

```powershell
# Cluster-Status prüfen
Get-Cluster -Name "S2DCluster" | Get-ClusterNode

# Storage Spaces Direct Status prüfen
Get-StorageSubSystem -FriendlyName "Cluster*" | Get-StorageHealthReport

# Pool-Status prüfen
Get-StoragePool -FriendlyName "S2D*"

# Volume-Status prüfen
Get-VirtualDisk | Select-Object FriendlyName, OperationalStatus, HealthStatus, ResiliencySettingName

# Laufwerks-Status prüfen
Get-PhysicalDisk | Select-Object FriendlyName, MediaType, OperationalStatus, HealthStatus, Usage
```

# Post-Deployment Validierung

## Health Service

Der in Windows Server integrierte **Health Service** überwacht den S2D-Cluster kontinuierlich [1]:

```powershell
# Cluster-Gesundheitszustand abfragen
Get-HealthFault -CimSession "S2DCluster"

# Detaillierten Storage-Subsystem-Status prüfen
Get-StorageSubSystem -FriendlyName "Cluster*" |
    Debug-StorageSubSystem

# Alle Faults anzeigen
Get-StorageSubSystem -FriendlyName "Cluster*" |
    Get-StorageHealthReport
```

## Performance-Monitoring

```powershell
# Storage-Performance-Daten abrufen
Get-Volume -FriendlyName "Volume01" |
    Get-ClusterPerformanceHistory -TimeFrame LastHour

# IOPS pro Volume
Get-VirtualDisk |
    Get-ClusterPerformanceHistory -TimeFrame LastHour |
    Select-Object Time, IOPSRead, IOPSWrite

# Netzwerk-Durchsatz der Storage-NICs prüfen
Get-NetAdapter -Name "vEthernet (Storage*)" |
    Get-NetAdapterStatistics
```

## Validierungsbefehle

| Prüfung | Befehl |
|---|---|
| Cluster-Knoten-Status | `Get-ClusterNode` |
| S2D-Status | `Get-ClusterS2D` |
| Pool-Gesundheit | `Get-StoragePool -FriendlyName "S2D*"` |
| Volume-Gesundheit | `Get-VirtualDisk` |
| Physische Laufwerke | `Get-PhysicalDisk` |
| Netzwerk-Status | `Get-ClusterNetwork` |
| Quorum-Status | `Get-ClusterQuorum` |
| Fault Domains | `Get-ClusterFaultDomain` |
| Health Faults | `Get-HealthFault` |

# Häufige Fehler und Troubleshooting

## Häufige Fehler beim Setup

| Fehler | Ursache | Lösung |
|---|---|---|
| Clustervalidierung schlägt bei „Storage Spaces Direct" fehl | Inkompatible oder nicht unterstützte Laufwerke | Laufwerke auf Windows Server Catalog prüfen; RAID-Controller deaktivieren oder im Pass-Through-Modus betreiben |
| `Enable-ClusterStorageSpacesDirect` scheitert | Heterogene Laufwerkskonfiguration oder noch vorhandene Partitionen | Laufwerkssymmetrie sicherstellen; alle Nicht-Boot-Laufwerke mit `Clear-Disk` bereinigen |
| RDMA funktioniert nicht | Falsche Treiber, SET nicht konfiguriert, VLAN-Mismatch | NIC-Treiber aktualisieren; SET statt LBFO verwenden; VLAN-Konfiguration auf allen Knoten und Switches prüfen |
| Cluster-Erstellung schlägt fehl | DNS-Probleme, Name bereits vergeben, Firewall blockiert | DNS-Auflösung prüfen; eindeutigen Clusternamen wählen; Firewall-Regeln für Failover Clustering prüfen |
| Volumes werden nicht erstellt | Unzureichende Kapazität im Pool oder zu wenige Fault Domains | Pool-Kapazität mit `Get-StoragePool` prüfen; Fault-Domain-Anzahl gegen Resilienz-Anforderungen prüfen |
| Performance-Probleme | Fehlende RDMA-Konfiguration, Jumbo Frames Mismatch, asymmetrische Bandbreite | RDMA-Status mit `Get-NetAdapterRDMA` prüfen; MTU Ende-zu-Ende validieren |

## Clustervalidierung fehlgeschlagen

```powershell
# Validierungsbericht anzeigen (Pfad wird nach Test-Cluster ausgegeben)
# Standardpfad: C:\Users\<User>\AppData\Local\Temp\
Get-ChildItem "$env:TEMP\Validation Report*.htm" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1 |
    Invoke-Item
```

## Laufwerke werden nicht erkannt

```powershell
# Physische Laufwerke und deren Status prüfen
Get-PhysicalDisk | Format-Table FriendlyName, SerialNumber, MediaType,
    CanPool, OperationalStatus, HealthStatus, Usage -AutoSize

# Laufwerke, die dem Pool beitreten können
Get-PhysicalDisk -CanPool $true
```

| Status | Bedeutung | Aktion |
|---|---|---|
| `CanPool = False` | Laufwerk kann nicht dem Pool beitreten | Prüfen, ob Partitionen/Daten vorhanden sind; `Clear-Disk` ausführen |
| `OperationalStatus = Lost Communication` | Verbindung zum Laufwerk verloren | Kabelverbindung und HBA prüfen |
| `HealthStatus = Unhealthy` | Laufwerk defekt | Laufwerk austauschen |

## Netzwerk-Troubleshooting

```powershell
# RDMA-Konnektivität testen
Test-NetConnection -ComputerName Node02 -Port 445

# SMB Direct Status prüfen
Get-SmbConnection | Select-Object ServerName, ShareName, Dialect, RdmaTransport

# SMB Multichannel prüfen
Get-SmbMultichannelConnection
```

# Quellenverzeichnis

1. **Microsoft Learn** — „Storage Spaces Direct overview"\
   <https://learn.microsoft.com/en-us/windows-server/storage/storage-spaces/storage-spaces-direct-overview>\
   Abgerufen: 20. April 2026

2. **Microsoft Learn** — „Storage Spaces Direct hardware requirements in Windows Server"\
   <https://learn.microsoft.com/en-us/windows-server/storage/storage-spaces/storage-spaces-direct-hardware-requirements>\
   Abgerufen: 20. April 2026

3. **Microsoft Learn** — „Understanding the storage pool cache"\
   <https://learn.microsoft.com/en-us/azure/azure-local/concepts/cache>\
   Abgerufen: 20. April 2026

4. **Microsoft Learn** — „Deploy Storage Spaces Direct on Windows Server"\
   <https://learn.microsoft.com/en-us/windows-server/storage/storage-spaces/deploy-storage-spaces-direct>\
   Abgerufen: 20. April 2026

5. **Microsoft Learn** — „Fault domain awareness"\
   <https://learn.microsoft.com/en-us/windows-server/failover-clustering/fault-domains>\
   Abgerufen: 20. April 2026

6. **Microsoft Learn** — „Plan volumes on Azure Local and Windows Server clusters"\
   <https://learn.microsoft.com/en-us/azure/azure-local/concepts/plan-volumes>\
   Abgerufen: 20. April 2026

7. **Microsoft Learn** — „Fault tolerance and storage efficiency on Azure Local and Windows Server clusters"\
   <https://learn.microsoft.com/en-us/windows-server/storage/storage-spaces/fault-tolerance>\
   Abgerufen: 20. April 2026

8. **Microsoft Learn** — „Understanding cluster and pool quorum"\
   <https://learn.microsoft.com/en-us/windows-server/storage/storage-spaces/quorum>\
   Abgerufen: 20. April 2026

9. **Microsoft Learn** — „Deploy a quorum witness"\
   <https://learn.microsoft.com/en-us/windows-server/failover-clustering/deploy-quorum-witness>\
   Abgerufen: 20. April 2026
