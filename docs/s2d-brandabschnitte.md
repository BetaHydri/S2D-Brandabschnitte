---
title: "Storage Spaces Direct über Brandabschnitte"
subtitle: "Technische Bewertung: 6-Node S2D-Cluster (3+3) über zwei Brandabschnitte im selben Subnet"
author: "Jan Tiedemann"
date: "20. April 2026"
lang: de
toc: true
toc-depth: 3
---

# Zusammenfassung

Dieses Dokument bewertet die Machbarkeit eines **Storage Spaces Direct (S2D)** Clusters, der über **zwei Brandabschnitte** innerhalb eines Rechenzentrums gespannt wird. Das Szenario umfasst einen **6-Node-Cluster** mit je **3 Knoten pro Brandabschnitt** im selben IP-Subnet. Alle Aussagen wurden gegen die offizielle Microsoft-Dokumentation validiert.

**Ergebnis**: Ein S2D-Cluster über zwei Brandabschnitte ist technisch machbar und wird durch die **Fault Domain Awareness** (Site-Typ) von Windows Server offiziell unterstützt. Voraussetzung ist die Einhaltung der Netzwerk-, Quorum- und Resilienz-Anforderungen.

# Ausgangslage

## Szenario

| Parameter | Wert |
|---|---|
| Cluster-Typ | Storage Spaces Direct (Hyperconverged) |
| Anzahl Knoten | 6 |
| Verteilung | 3 Knoten in Brandabschnitt A, 3 Knoten in Brandabschnitt B |
| Netzwerk | Gleiches IP-Subnet |
| Standort | Einzelnes Rechenzentrum |
| Betriebssystem | Windows Server 2022 / 2025 Datacenter |

## Fragestellung

Kann ein S2D-Cluster zuverlässig über zwei physische Brandabschnitte betrieben werden, wenn alle Server im selben Subnet liegen?

# Storage Spaces Direct — Grundlagen

## Was ist S2D?

Storage Spaces Direct ist eine [Software-defined Storage (SDS)](glossar.md#sds-software-defined-storage) Lösung, die in Windows Server 2016 Datacenter und höher enthalten ist. Sie ermöglicht es, die internen Speicherlaufwerke eines Clusters von **2 bis 16 physischen Servern** zu einem softwaredefinierten [Speicherpool](glossar.md#storage-pool) zusammenzufassen [1].

## Unterstützte Konfigurationen

| Eigenschaft | Spezifikation |
|---|---|
| Minimale Knotenzahl | 2 Server |
| Maximale Knotenzahl | 16 Server |
| Unterstützte Laufwerke | SATA, SAS, NVMe, Persistent Memory (direkt angeschlossen) |
| Netzwerk (Minimum) | 10 GbE |
| Netzwerk (Empfohlen, 4+ Knoten) | [25 GbE](glossar.md#gbe-gigabit-ethernet) mit [RDMA](glossar.md#rdma-remote-direct-memory-access) ([iWARP](glossar.md#iwarp-internet-wide-area-rdma-protocol) oder [RoCE](glossar.md#roce-rdma-over-converged-ethernet)) |
| **Netzwerk (Produktion)** | **2× 25 GbE oder 2× 100 GbE** mit RDMA für Storage; dedizierte NICs pro Traffic-Typ |
| NIC-Trennung (Produktion) | Dedizierte NICs für Management, Storage (East-West / CSV), Live Migration und VM-Traffic |
| Dateisystem | [ReFS](glossar.md#refs-resilient-file-system) (empfohlen) |
| Deployment-Optionen | Hyperconverged oder Converged (Scale-Out File Server) |

*Quelle: Microsoft Learn — Storage Spaces Direct Hardware Requirements [2]*

> **Hinweis zur Netzwerkbandbreite**: Die oben genannten 10 GbE bzw. 25 GbE sind Microsofts **Mindestanforderungen**. Für Produktionsumgebungen sind diese Werte in der Regel nicht ausreichend — Replikations-Overhead (Two-/Three-Way Mirror), Re-Sync nach Knotenausfällen und NVMe-Durchsatz erfordern deutlich mehr Bandbreite. Details und konkrete Empfehlungen siehe [Setup-Leitfaden — Netzwerk-Mindestanforderungen](s2d-setup-guide.md#mindestanforderungen).

# Fault Domain Awareness — Site-Unterstützung

## Konzept der Fault Domains

Windows Server Failover Clustering kennt vier hierarchische Ebenen von [Fault Domains](glossar.md#fault-domain--fault-domain-awareness) [3]:

| Ebene | Beschreibung | Automatisch erkannt? |
|---|---|---|
| **Node** | Einzelner Serverknoten | Ja |
| **Chassis** | Blade-Server-Gehäuse | Nein — manuelle Konfiguration |
| **Rack** | Server-Rack | Nein — manuelle Konfiguration |
| **Site** | Physischer Standort / Brandabschnitt | Nein — manuelle Konfiguration |

## Vorteile der Fault Domain Awareness

Laut Microsoft-Dokumentation bietet Fault Domain Awareness drei zentrale Vorteile [3]:

1. **Storage Spaces / S2D**: Nutzt Fault Domains zur Maximierung der Datensicherheit. Datenkopien werden auf separate Fault Domains verteilt, um optimale Resilienz zu gewährleisten.
2. **Health Service**: Stellt aussagekräftigere Alarme bereit, da jede Fault Domain mit Standort-Metadaten versehen werden kann.
3. **Stretch Clustering**: Nutzt Fault Domains für Storage Affinity, sodass VMs bevorzugt auf Servern laufen, die nahe an ihrem Speicher liegen.

## Konfiguration für zwei Brandabschnitte

### PowerShell-Konfiguration

Die Fault Domains werden **vor** der Aktivierung von S2D konfiguriert [3]:

```powershell
# Sites (Brandabschnitte) anlegen
New-ClusterFaultDomain -Type Site -Name "BrandabschnittA" `
    -Location "RZ Gebäude 1, Brandabschnitt A"
New-ClusterFaultDomain -Type Site -Name "BrandabschnittB" `
    -Location "RZ Gebäude 1, Brandabschnitt B"

# Knoten zuordnen
Set-ClusterFaultDomain -Name "Node01","Node02","Node03" `
    -Parent "BrandabschnittA"
Set-ClusterFaultDomain -Name "Node04","Node05","Node06" `
    -Parent "BrandabschnittB"

# Konfiguration prüfen
Get-ClusterFaultDomain
```

### XML-Konfiguration

Alternativ kann die Topologie per XML definiert werden [3]:

```xml
<Topology>
  <Site Name="BrandabschnittA"
        Location="RZ Gebäude 1, Brandabschnitt A">
    <Node Name="Node01" />
    <Node Name="Node02" />
    <Node Name="Node03" />
  </Site>
  <Site Name="BrandabschnittB"
        Location="RZ Gebäude 1, Brandabschnitt B">
    <Node Name="Node04" />
    <Node Name="Node05" />
    <Node Name="Node06" />
  </Site>
</Topology>
```

```powershell
$xml = Get-Content .\FaultDomains.xml | Out-String
Set-ClusterFaultDomainXML -XML $xml
```

> **Wichtig**: Microsoft weist explizit darauf hin, dass Fault Domains **vor** der Aktivierung von Storage Spaces Direct konfiguriert werden sollten. Nachträgliche Änderungen führen **nicht** zu einer automatischen Umverteilung der Daten [3].

# Netzwerk-Anforderungen

## Validierte Anforderungen (Microsoft)

Die Microsoft-Dokumentation definiert folgende Netzwerk-Anforderungen für S2D [2]:

| Anforderung | Spezifikation |
|---|---|
| Minimum (2–3 Knoten) | 10 GbE NIC oder schneller |
| Empfohlen (4+ Knoten) | 25 GbE oder schneller, RDMA-fähig (iWARP oder RoCE) |
| Redundanz | Mindestens 2 Netzwerkverbindungen pro Knoten empfohlen |
| Topologie | Switched oder Switchless (direkte Verbindungen) |

## Anforderungen bei Brandabschnitt-übergreifendem Betrieb

Zusätzlich zu den Standardanforderungen gelten für den Betrieb über zwei Brandabschnitte:

| Anforderung | Begründung |
|---|---|
| **Latenz < 1 ms (Round-Trip)** | S2D schreibt synchron über den Software Storage Bus. Erhöhte Latenz reduziert die I/O-Performance direkt proportional. |
| **Symmetrische Bandbreite** | Die Inter-Site-Verbindung wird zum Engpass für Schreibvorgänge. Gleiche Bandbreite in beide Richtungen ist erforderlich. |
| **Redundante Verbindung** | Einzelne Kabelwege durch Brandschotts sind ein Single Point of Failure. Mindestens 2 unabhängige Pfade empfohlen. |
| **RDMA-Konsistenz** | [RDMA](glossar.md#rdma-remote-direct-memory-access)-Konfiguration ([iWARP](glossar.md#iwarp-internet-wide-area-rdma-protocol)/[RoCE](glossar.md#roce-rdma-over-converged-ethernet)) muss auf beiden Seiten identisch sein. RoCE erfordert zusätzliche Switch-Konfiguration ([PFC](glossar.md#pfc-priority-flow-control), [ECN](glossar.md#ecn-explicit-congestion-notification)). |

## Physische Kabelführung durch Brandabschnitte

Die Kabelführung durch Brandschottdurchführungen muss den geltenden Brandschutzvorschriften entsprechen:

- Zertifizierte [Brandschottdurchführungen](glossar.md#brandschott--brandschottdurchführung) für [LWL](glossar.md#lwl-lichtwellenleiter)-/Kupferkabel
- Dokumentation der Durchführungen gemäß Bauordnung
- Regelmäßige Prüfung der Brandschottintegrität

# Resilienz und Fehlertoleranz

## Resilienz-Optionen

Die folgende Tabelle zeigt die verfügbaren Resilienz-Typen und ihre Eigenschaften [4]:

| Resilienz-Typ | Tolerierte Ausfälle | Speichereffizienz | Min. Fault Domains |
|---|---|---|---|
| Two-way Mirror | 1 | 50,0 % | 2 |
| **[Three-way Mirror](glossar.md#three-way-mirror)** | **2** | **33,3 %** | **3** |
| [Dual Parity](glossar.md#dual-parity) | 2 | 50,0–80,0 % | 4 |
| [Mixed (Mirror-Accelerated Parity)](glossar.md#mirror-accelerated-parity) | 2 | 33,3–80,0 % | 4 |

## Empfehlung für 6-Node-Cluster über Brandabschnitte

Für den Betrieb über zwei Brandabschnitte wird **Three-way Mirror** empfohlen:

| Ausfallszenario | Three-way Mirror | Ergebnis |
|---|---|---|
| 1 Laufwerk ausgefallen | Toleriert | Cluster und Volumes online |
| 1 Server ausgefallen | Toleriert | Cluster und Volumes online |
| 1 Server + 1 Laufwerk ausgefallen | Toleriert | Cluster und Volumes online |
| 2 Server ausgefallen (gleicher Brandabschnitt) | Toleriert | Cluster und Volumes online |
| 2 Server ausgefallen (verschiedene Brandabschnitte) | Toleriert | Cluster und Volumes online |
| 3 Server ausgefallen (ganzer Brandabschnitt) | **Kritisch** | Abhängig von Quorum und Pool Quorum |

> **Microsoft-Dokumentation**: „Three-way mirroring can safely tolerate at least two hardware problems (drive or server) at a time." [4] — „Storage Spaces Direct can't handle more than two nodes down." [5]

## Auswirkung bei Verlust eines Brandabschnitts

Wenn ein kompletter Brandabschnitt ausfällt (3 von 6 Knoten), gelten folgende Einschränkungen:

**[Cluster Quorum](glossar.md#quorum--cluster-quorum)**: Bei 6 Knoten (ungerade Stimmenzahl nach [Dynamic Quorum](glossar.md#dynamic-quorum)) überlebt der Cluster den Verlust von 3 Knoten grundsätzlich, da die verbleibenden 3 Knoten die Mehrheit bilden können [5].

**[Pool Quorum](glossar.md#pool-quorum)**: Die verbleibende Hälfte der Laufwerke muss zusammen mit dem Pool Resource Owner die Mehrheit der Stimmen haben. Bei symmetrischer Laufwerksverteilung (gleiche Anzahl pro Knoten) ist dies grenzwertig [5].

> **Risiko**: Der gleichzeitige Ausfall aller 3 Server eines Brandabschnitts überschreitet die von S2D unterstützte maximale Ausfalltoleranz von 2 Knoten. Volumes können offline gehen.

# Quorum-Konfiguration

## Cluster Quorum bei 6 Knoten

Laut Microsoft-Dokumentation gilt für 5 oder mehr Knoten [5]:

> „Five nodes and beyond — All nodes vote, or all but one vote, whatever makes the total odd. Storage Spaces Direct can't handle more than two nodes down anyway, so at this point, no witness is needed or useful."

**Für den Betrieb über zwei Brandabschnitte wird dennoch ein Witness dringend empfohlen**, um bei einem exakten 3:3-Split eine deterministische Entscheidung zu erzwingen.

## Witness-Optionen (On-Premises)

| Witness-Typ | Beschreibung | Eignung |
|---|---|---|
| **[File Share Witness](glossar.md#file-share-witness)** | [SMB](glossar.md#smb-server-message-block)-Freigabe auf einem separaten Dateiserver | **Empfohlen** — rein on-premises |
| [Cloud Witness](glossar.md#cloud-witness) | Azure Blob Storage | Erfordert Internetverbindung zu Azure |
| [Disk Witness](glossar.md#disk-witness) | Clustered Disk | **Nicht unterstützt** bei S2D [5] |

### On-Premises File Share Witness einrichten

Der File Share Witness sollte an einem **dritten physischen Standort** platziert werden — also weder in Brandabschnitt A noch in Brandabschnitt B:

```powershell
# File Share Witness konfigurieren
# Der Dateiserver muss AUSSERHALB beider Brandabschnitte stehen
Set-ClusterQuorum -Cluster "S2DCluster" `
    -FileShareWitness "\\FileServer03\ClusterWitness$"
```

> **Kritisch**: Befindet sich der File Share Witness in einem der beiden Brandabschnitte, geht bei dessen Ausfall sowohl die Hälfte der Knoten als auch der Witness verloren — ein Split-Brain-Szenario wird wahrscheinlich.

## Quorum-Empfehlung

| Komponente | Empfehlung |
|---|---|
| Witness-Typ | File Share Witness (on-premises) |
| Standort | Dritter Brandabschnitt oder separater Netzwerkbereich |
| Dateiserver | Dedizierter Dateiserver, kein S2D-Clustermitglied |
| Redundanz | Dateiserver sollte selbst hochverfügbar sein |

# Architekturübersicht

## Physische Topologie

```
+============================+         +============================+
|     Brandabschnitt A       |         |     Brandabschnitt B       |
|                            |  <1 ms  |                            |
|  +------+ +------+ +------+|  25Gbps |+------+ +------+ +------+  |
|  |Node01| |Node02| |Node03||=========||Node04| |Node05| |Node06|  |
|  |      | |      | |      ||  RDMA   ||      | |      | |      |  |
|  | SSD  | | SSD  | | SSD  ||  Link 1 || SSD  | | SSD  | | SSD  |  |
|  | HDD  | | HDD  | | HDD  ||  Link 2 || HDD  | | HDD  | | HDD  |  |
|  +------+ +------+ +------+|=========|+------+ +------+ +------+  |
+============================+         +============================+
              |                                       |
              |          Brandabschnitt C             |
              |    +---------------------------+      |
              +--->| File Share Witness         |<----+
                   | (\\FileServer03\Witness$)  |
                   +---------------------------+
```

## Logische Komponenten

| Komponente | Konfiguration |
|---|---|
| Fault Domain Level | Site |
| Fault Domain A | BrandabschnittA (Node01, Node02, Node03) |
| Fault Domain B | BrandabschnittB (Node04, Node05, Node06) |
| Storage Pool | 1 Pool über alle 6 Knoten |
| Resilienz | Three-way Mirror |
| Quorum Witness | File Share Witness (dritter Standort) |
| Netzwerk | 25 GbE RDMA, mindestens 2 Pfade zwischen Brandabschnitten |

# Validierung gegen Microsoft-Dokumentation

Die folgende Tabelle dokumentiert die Validierung der technischen Aussagen:

| Aussage | Validiert? | Microsoft-Quelle |
|---|---|---|
| S2D unterstützt 2–16 Knoten | Ja | Hardware Requirements [2] |
| Fault Domains vom Typ "Site" werden unterstützt | Ja | Fault Domain Awareness [3] |
| S2D nutzt Fault Domains zur Datenverteilung | Ja | Fault Domain Awareness: Benefits [3] |
| Stretch Clustering nutzt Fault Domains für Storage Affinity | Ja | Fault Domain Awareness: Benefits [3] |
| 10 GbE Minimum, 25 GbE empfohlen für 4+ Knoten | Ja | Hardware Requirements: Network [2] |
| RDMA empfohlen (iWARP oder RoCE) | Ja | Hardware Requirements: Network [2] |
| Three-way Mirror toleriert 2 gleichzeitige Ausfälle | Ja | Fault Tolerance [4] |
| S2D verträgt maximal 2 Knotenausfälle gleichzeitig | Ja | Cluster and Pool Quorum [5] |
| Disk Witness nicht unterstützt bei S2D | Ja | Cluster and Pool Quorum [5] |
| File Share Witness als on-premises Option | Ja | Deploy a Quorum Witness [6] |
| Fault Domains vor S2D-Aktivierung konfigurieren | Ja | Fault Domain Awareness: Usage [3] |
| Pool Quorum benötigt 50 % + 1 der Laufwerke | Ja | Cluster and Pool Quorum [5] |
| SMB-Verschlüsselung für East-West-Traffic (CSV/SBL) ab WS2022 | Ja | SMB Security Enhancements [7] |
| SMB Direct + Encryption kompatibel ab WS2022 | Ja | SMB Security Enhancements [7] |
| SMB 1.0 Deaktivierung empfohlen | Ja | SMB Security Enhancements [7] |
| Storage QoS für IOPS-Management pro VM | Ja | Storage Quality of Service [8] |

# Empfehlungen

## Checkliste vor Deployment

| Nr. | Aufgabe | Status |
|---|---|---|
| 1 | Netzwerk-Latenz zwischen Brandabschnitten messen (< 1 ms RTT) | Offen |
| 2 | Mindestens 25 GbE RDMA-NICs in allen Knoten | Offen |
| 3 | Mindestens 2 redundante Netzwerkpfade durch Brandschotts | Offen |
| 4 | Brandschottdurchführungen zertifiziert und dokumentiert | Offen |
| 5 | File Share Witness auf drittem Server (dritter Brandabschnitt) | Offen |
| 6 | Symmetrische Laufwerkskonfiguration auf allen Knoten | Offen |
| 7 | Fault Domains als "Site" konfiguriert VOR S2D-Aktivierung | Offen |
| 8 | Three-way Mirror als Resilienz-Typ gewählt | Offen |
| 9 | Cluster Validation Test bestanden | Offen |
| 10 | Failover-Test: Ausfall eines Brandabschnitts simuliert | Offen |
| 11 | SMB-Verschlüsselung für East-West-Traffic aktiviert (ab WS2022) | Offen |
| 12 | SMB 1.0 auf allen Knoten deaktiviert | Offen |
| 13 | SMB Signing oder SMB-Verschlüsselung erzwungen | Offen |
| 14 | BitLocker auf Boot- und CSV-Volumes aktiviert (Encryption at Rest) | Offen |
| 15 | Storage QoS Policies für IO-intensive VMs konfiguriert | Offen |
| 16 | CSV In-Memory Read Cache konfiguriert (bei read-intensiven Workloads) | Offen |
| 17 | Windows-Firewall auf allen Knoten aktiviert und gehärtet | Offen |

## Risikobewertung

| Risiko | Wahrscheinlichkeit | Auswirkung | Mitigation |
|---|---|---|---|
| Ausfall eines einzelnen Servers | Mittel | Gering — toleriert durch Three-way Mirror | Automatische Reparatur durch S2D |
| Ausfall beider Netzwerkpfade zwischen Abschnitten | Niedrig | Hoch — Cluster-Partition | Redundante, physisch getrennte Kabelwege |
| Ausfall eines kompletten Brandabschnitts (3 Knoten) | Niedrig | Kritisch — Volumes gehen möglicherweise offline | Witness an drittem Standort; schneller Wiederaufbau |
| File Share Witness nicht erreichbar | Niedrig | Mittel — bei zusätzlichem Knotenausfall kein Quorum | Hochverfügbaren Dateiserver verwenden |
| Latenz-Anstieg zwischen Brandabschnitten | Mittel | Mittel — Performance-Degradation | Monitoring; dedizierte Storage-NICs |
| Unverschlüsselter Storage-Traffic über Brandschotts | Mittel | Hoch — Daten im Klartext über physische Grenzen | SMB-Verschlüsselung aktivieren (ab WS2022 RDMA-kompatibel) [7] |
| Noisy-Neighbor bei IO-intensiven VMs | Hoch | Mittel — Performance-Degradation anderer VMs | Storage QoS Policies mit IOPS-Limits konfigurieren [8] |

# Quellenverzeichnis

1. **Microsoft Learn** — „Storage Spaces Direct overview"\
   <https://learn.microsoft.com/en-us/windows-server/storage/storage-spaces/storage-spaces-direct-overview>\
   Abgerufen: 20. April 2026

2. **Microsoft Learn** — „Storage Spaces Direct hardware requirements in Windows Server"\
   <https://learn.microsoft.com/en-us/windows-server/storage/storage-spaces/storage-spaces-direct-hardware-requirements>\
   Abgerufen: 20. April 2026

3. **Microsoft Learn** — „Fault domain awareness"\
   <https://learn.microsoft.com/en-us/windows-server/failover-clustering/fault-domains>\
   Abgerufen: 20. April 2026

4. **Microsoft Learn** — „Fault tolerance and storage efficiency on Azure Local and Windows Server clusters"\
   <https://learn.microsoft.com/en-us/windows-server/storage/storage-spaces/fault-tolerance>\
   Abgerufen: 20. April 2026

5. **Microsoft Learn** — „Understanding cluster and pool quorum"\
   <https://learn.microsoft.com/en-us/windows-server/storage/storage-spaces/quorum>\
   Abgerufen: 20. April 2026

6. **Microsoft Learn** — „Deploy a quorum witness"\
   <https://learn.microsoft.com/en-us/windows-server/failover-clustering/deploy-quorum-witness>\
   Abgerufen: 20. April 2026

7. **Microsoft Learn** — „SMB security enhancements"\
   <https://learn.microsoft.com/en-us/windows-server/storage/file-server/smb-security>\
   Abgerufen: 21. April 2026

8. **Microsoft Learn** — „Storage Quality of Service"\
   <https://learn.microsoft.com/en-us/windows-server/storage/storage-qos/storage-qos-overview>\
   Abgerufen: 21. April 2026
