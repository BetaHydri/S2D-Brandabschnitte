---
title: "Glossar — Fachbegriffe und Abkürzungen"
subtitle: "Nachschlagewerk für Storage Spaces Direct, Netzwerk und Cluster-Technologien"
author: "Jan Tiedemann"
date: "21. April 2026"
lang: de
toc: true
toc-depth: 2
---

# Glossar — Fachbegriffe und Abkürzungen

Dieses Dokument dient als Nachschlagewerk für alle Fachbegriffe und Abkürzungen, die in den Dokumenten [S2D über Brandabschnitte](s2d-brandabschnitte.md) und [S2D Setup-Leitfaden](s2d-setup-guide.md) verwendet werden.

---

## Storage und Dateisysteme

### S2D (Storage Spaces Direct)

Software-defined Storage (SDS) Lösung in Windows Server Datacenter. Fasst die internen Speicherlaufwerke eines Clusters von 2 bis 16 Servern zu einem softwaredefinierten Speicherpool zusammen. Kein SAN erforderlich — alle Laufwerke sind direkt an die Server angeschlossen.

### SDS (Software-defined Storage)

Oberbegriff für Speicherlösungen, bei denen die Storage-Logik (Resilienz, Caching, Tiering) in Software statt in dedizierter Hardware (z. B. RAID-Controller oder SAN) implementiert ist. S2D ist Microsofts SDS-Implementierung.

### Storage Pool

Ein logischer Zusammenschluss aller physischen Laufwerke im Cluster. S2D erstellt automatisch einen einzelnen Pool über alle Knoten. Aus diesem Pool werden virtuelle Volumes mit unterschiedlichen Resilienz-Einstellungen erstellt.

### Cache Tier / Capacity Tier

S2D nutzt automatisch die schnellsten Laufwerke als **Cache** (Schreib- und/oder Lese-Cache) und die langsameren als **Kapazität** (persistenter Speicher). Beispiel: NVMe als Cache, SSD oder HDD als Kapazität.

### CSV (Cluster Shared Volume)

Ein Dateisystem-Feature, das es allen Cluster-Knoten ermöglicht, gleichzeitig auf dasselbe Volume zuzugreifen. Notwendig für Hyper-V-VMs, die zwischen Knoten verschoben werden.

### CSVFS (Cluster Shared Volume File System)

Das Dateisystem-Format für Cluster Shared Volumes. S2D-Volumes werden typischerweise als `CSVFS_ReFS` formatiert.

### ReFS (Resilient File System)

Microsofts modernes Dateisystem, optimiert für große Datenmengen und Fehlerresilienz. Für S2D empfohlen, da es Features wie **Block Cloning** (schnelle VM-Checkpoints) und **Integrity Streams** (automatische Fehlererkennung) bietet.

### IOPS (Input/Output Operations Per Second)

Maßeinheit für die Leistung von Speichergeräten. Gibt an, wie viele Lese-/Schreiboperationen pro Sekunde ein Laufwerk oder ein Storage-System verarbeiten kann. NVMe-Laufwerke erreichen typischerweise mehrere hunderttausend IOPS.

---

## Laufwerkstypen und Schnittstellen

### NVMe (Non-Volatile Memory Express)

Hochleistungs-Speicherprotokoll für Flash-basierte Laufwerke. Nutzt PCIe direkt (statt SATA/SAS) und bietet die höchsten IOPS und niedrigsten Latenzen. Verfügbar als M.2, U.2 oder Add-in-Card. In S2D typischerweise als Cache-Tier eingesetzt.

### SSD (Solid-State Drive)

Flash-basiertes Speicherlaufwerk ohne bewegliche Teile. Schneller als HDD, aber langsamer als NVMe. Über SATA oder SAS angeschlossen. Für S2D müssen SSDs über **Power-Loss Protection** verfügen (keine Consumer-SSDs).

### HDD (Hard Disk Drive)

Magnetische Festplatte mit rotierenden Scheiben. Höchste Kapazität pro Euro, aber niedrigste IOPS und höchste Latenz. In S2D nur als Kapazitäts-Tier in Kombination mit schnelleren Cache-Laufwerken (NVMe oder SSD) unterstützt.

### PMem (Persistent Memory)

Speichertechnologie, die wie RAM direkt vom Prozessor adressiert wird, aber Daten auch ohne Strom behält. Kann in S2D im Block-Storage-Modus als extrem schneller Cache oder als Kapazität eingesetzt werden.

### SATA (Serial Advanced Technology Attachment)

Standard-Schnittstelle für die Verbindung von Massenspeichergeräten (SSDs, HDDs) mit dem Mainboard. Maximale Bandbreite: 6 Gbit/s (SATA III). Für S2D unterstützt, aber langsamer als SAS oder NVMe.

### SAS (Serial Attached SCSI)

Enterprise-Schnittstelle für Speicherlaufwerke. Bietet höhere Zuverlässigkeit und Bandbreite als SATA (bis 24 Gbit/s bei SAS-4). Unterstützt Dual-Port für Pfadredundanz. Standard in Rechenzentren.

### HBA (Host Bus Adapter)

Controller-Karte, die Speicherlaufwerke mit dem Server verbindet. Für S2D muss der HBA im **Pass-Through-Modus** (auch JBOD-Modus) betrieben werden — **kein Hardware-RAID**. S2D verwaltet die Datenresilienz selbst.

### Pass-Through (HBA-Modus)

Betriebsmodus eines HBA oder RAID-Controllers, bei dem Laufwerke direkt an das Betriebssystem durchgereicht werden, ohne dass der Controller RAID-Funktionalität anwendet. Auch als **JBOD-Modus** (Just a Bunch Of Disks) bezeichnet. Für S2D zwingend erforderlich.

### Power-Loss Protection

Schutzmechanismus in Enterprise-SSDs, der sicherstellt, dass bei plötzlichem Stromausfall alle Daten im flüchtigen Schreibcache der SSD noch auf den Flash geschrieben werden. Consumer-SSDs ohne diesen Schutz können bei Stromausfall Daten verlieren und sind für S2D nicht unterstützt.

### SAN (Storage Area Network)

Dediziertes Netzwerk für den Zugriff auf Block-Level-Storage (typischerweise über Fibre Channel oder iSCSI). S2D verwendet **kein** SAN — die Laufwerke müssen direkt an die Server angeschlossen sein.

### SATADOM

Kleine Boot-SSD im DOM-Formfaktor (Disk-on-Module), die direkt auf dem Mainboard in einen SATA-Anschluss gesteckt wird. Wird als Boot-Gerät für Server verwendet, um die regulären Laufwerksschächte für S2D-Datenlaufwerke freizuhalten.

---

## Netzwerk — Grundlagen

### NIC (Network Interface Card)

Netzwerkadapter — die physische oder virtuelle Netzwerkkarte im Server. Für S2D werden NICs mit mindestens 10 GbE, empfohlen 25 GbE oder schneller, benötigt.

### vNIC (Virtual NIC)

Virtuelle Netzwerkkarte, die vom Hyper-V Virtual Switch bereitgestellt wird. Bei S2D werden vNICs für Storage-Traffic, Live Migration und Management-Traffic erstellt. RDMA kann über SET auf vNICs aktiviert werden.

### GbE (Gigabit Ethernet)

Maßeinheit für die Netzwerkbandbreite. 1 GbE = 1 Gbit/s. S2D erfordert mindestens **10 GbE**, empfohlen **25 GbE** für 4+ Knoten.

### MTU (Maximum Transmission Unit)

Die maximale Paketgröße in Bytes, die über ein Netzwerk übertragen werden kann, ohne fragmentiert zu werden. Standard: 1500 Bytes. Für S2D-Storage-Netzwerke werden **Jumbo Frames** mit 9014 Bytes empfohlen. Alle Geräte im Pfad (NICs, Switches, vNICs) müssen die gleiche MTU verwenden.

### Jumbo Frames

Ethernet-Frames mit einer MTU größer als 1500 Bytes, typischerweise **9014 Bytes**. Reduzieren den Protokoll-Overhead bei großen Datenübertragungen (mehr Nutzdaten pro Paket) und verbessern die Storage-Performance. Nur im Storage-Netzwerk einsetzen, nicht im Management-Netzwerk.

### VLAN (Virtual Local Area Network)

Logische Netzwerktrennung auf Layer 2 (IEEE 802.1Q). Erlaubt die Isolierung verschiedener Netzwerktypen (Management, Storage, VM-Traffic) auf derselben physischen Infrastruktur. Jedes VLAN bekommt eine eigene VLAN-ID (1–4094).

### RTT (Round-Trip Time)

Die Zeit, die ein Netzwerkpaket benötigt, um von A nach B und zurück zu gelangen. Für S2D über Brandabschnitte muss die RTT **unter 1 ms** liegen, da S2D synchron schreibt und erhöhte Latenz die I/O-Performance direkt reduziert.

### ToR (Top of Rack)

Netzwerk-Switch, der oben im Server-Rack montiert ist und die Server im Rack mit dem übergeordneten Netzwerk verbindet. Bei RoCE muss der ToR-Switch korrekt für PFC und ECN konfiguriert werden.

---

## Netzwerk — RDMA und Protokolle

### RDMA (Remote Direct Memory Access)

Technologie, die den direkten Speicherzugriff zwischen zwei Servern ermöglicht, **ohne die CPU zu belasten**. Die Daten werden direkt aus dem Arbeitsspeicher des Senders in den Arbeitsspeicher des Empfängers kopiert — unter Umgehung des Betriebssystem-Kernels. Ergebnis: extrem niedrige Latenz, hoher Durchsatz und minimale CPU-Last. S2D nutzt RDMA über SMB Direct für den Storage-Traffic.

### RoCE (RDMA over Converged Ethernet)

RDMA-Implementierung für Standard-Ethernet-Netzwerke. Verfügbar in zwei Versionen:

- **RoCE v1**: Layer-2-Protokoll (nur innerhalb eines VLANs)
- **RoCE v2**: Layer-3-fähig (routbar über IP-Netzwerke, bevorzugt)

**Wichtig**: RoCE erfordert zwingend eine korrekte Switch-Konfiguration mit [PFC](#pfc-priority-flow-control) und [ECN](#ecn-explicit-congestion-notification), da RDMA **keine Paketverluste toleriert**.

### iWARP (Internet Wide Area RDMA Protocol)

Alternative RDMA-Implementierung, die auf TCP/IP aufsetzt. Von Microsoft **empfohlen**, da iWARP **keine spezielle Switch-Konfiguration** benötigt (kein PFC, kein ECN erforderlich). TCP übernimmt die Flusskontrolle. Einfacher zu implementieren als RoCE, aber bei identischer Hardware leicht geringerer Durchsatz.

### SMB (Server Message Block)

Netzwerkprotokoll für den Zugriff auf Dateien, Drucker und andere Netzwerkressourcen. S2D nutzt **SMB 3.x** als Transportprotokoll für den gesamten Storage-Traffic zwischen den Cluster-Knoten.

### SMB Direct

SMB über RDMA. Ermöglicht CPU-entlastende Datenübertragung mit niedriger Latenz und hohem Durchsatz für den S2D-Storage-Traffic. Erfordert RDMA-fähige NICs.

### SMB Multichannel

Feature von SMB 3.x, das automatisch mehrere Netzwerkverbindungen zwischen zwei Knoten nutzt. Bietet **Bandbreitenaggregation** (mehr Durchsatz) und **automatisches Failover** (Ausfall eines Pfads wird kompensiert). Aktiviert sich automatisch, wenn mehrere Netzwerkpfade vorhanden sind.

---

## Netzwerk — Flusskontrolle und Staumanagement

### PFC (Priority Flow Control)

**IEEE 802.1Qbb** — Erweiterung des klassischen Ethernet-Pause-Mechanismus. Stoppt Traffic **pro Priorität/Queue**, nicht die gesamte Leitung.

**Funktionsweise:**

1. Switch erkennt: Buffer läuft voll
2. Switch sendet **Pause-Frame** an den Sender
3. Sender **stoppt sofort** Traffic für diese Priorität

**Ziel:** Keine Paketverluste (**Lossless Ethernet**) — extrem wichtig für RDMA/RoCE, da sonst die Session abbricht.

**Mentales Modell:**

> PFC = „Stopp! Sende erstmal nichts mehr." — Die **Notbremse**.

**Risiken:**

- **Head-of-Line Blocking**: Andere Flows in derselben Queue werden ebenfalls blockiert
- **Congestion Spreading / Pause Storm**: Pausen pflanzen sich über mehrere Switches fort
- **Deadlocks**: Bei falscher ToR-Konfiguration können sich Flows gegenseitig blockieren

**Praxis**: PFC wird **nur für RoCE-Traffic** aktiviert (typischerweise Priority 3 oder 5), nicht für den gesamten Netzwerkverkehr.

*Quellen: [Microsoft Learn — Priority-based Flow Control](https://learn.microsoft.com/de-de/windows-hardware/drivers/network/priority-based-flow-control--pfc), [NVIDIA ONYX Documentation](https://docs.nvidia.com/networking/display/onyxv3103004/priority+flow+control+%28pfc%29)*

### ECN (Explicit Congestion Notification)

**RFC 3168** — Layer-3-Mechanismus zur frühzeitigen Stauanzeige. Markiert Pakete bei drohender Überlast, **statt sie zu verwerfen** (im Gegensatz zu klassischem Tail Drop).

**Funktionsweise:**

1. Switch erkennt steigende Queue (Congestion)
2. Switch **markiert** Pakete mit dem ECN-Flag im IP-Header
3. Empfänger meldet die Markierung an den Sender zurück
4. Sender **reduziert seine Senderate** freiwillig

**Ziel:** Frühzeitige Staukontrolle — verhindert Packet Loss **und** vermeidet harte PFC-Pausen.

**Mentales Modell:**

> ECN = „Langsamer senden — hier wird es eng." — Die **intelligente Verkehrsregelung**.

**Vorteile gegenüber reinem PFC:**

- Vermeidet harte Pausen
- Bessere Fairness zwischen Flows
- Stabilere Performance bei Clustern mit hohem Traffic

*Quellen: [Juniper — DCQCN Traffic Management](https://www.juniper.net/documentation/us/en/software/junos/traffic-mgmt-qfx/topics/topic-map/cos-qfx-series-DCQCN.html), [FS.com — ECN vs. DCQCN](https://www.fs.com/blog/ecn-vs-dcqcn-which-congestion-control-mechanism-is-more-efficient-17725.html)*

### PFC und ECN im Zusammenspiel (bei RoCE)

RoCE hat zwei harte Anforderungen:

| Anforderung | Mechanismus | Wirkung |
|---|---|---|
| Kein Packet Loss | **PFC** | Switch verhindert Drops durch „Pause" |
| Kein dauerhafter Stau / Deadlock | **ECN** | Reduziert Traffic, bevor PFC eskaliert |

Moderne RoCE-Designs kombinieren beide Mechanismen bewusst:

- **PFC** = Notbremse (reaktiv, link-basiert)
- **ECN** = Intelligente Verkehrsregelung (proaktiv, End-to-End)

**Praxis-Konfiguration** (ToR-Switch):

1. QoS / PCP korrekt mappen
2. PFC **nur für RoCE-Traffic** aktivieren (z. B. Priority 3 oder 5)
3. ECN auf Switch-Queues aktivieren (WRED / Marking Thresholds)
4. Endpoints müssen ECN verstehen (Windows Server unterstützt ECN)

### DCQCN (Data Center Quantized Congestion Notification)

Kongestions-Kontrollprotokoll speziell für RoCE v2 in Rechenzentren. Kombiniert ECN-Signale vom Switch mit einer Rate-Limiting-Logik auf dem Sender (NIC-Firmware). Bietet schnelle Reaktion auf Stau bei gleichzeitig hoher Auslastung der verfügbaren Bandbreite.

### DCB (Data Center Bridging)

Sammelbegriff für eine Gruppe von IEEE-Standards (802.1Qbb, 802.1Qaz, 802.1AB), die Ethernet für den Einsatz im Rechenzentrum optimieren. Umfasst PFC, ETS (Enhanced Transmission Selection) und DCBX (Data Center Bridging Exchange). In Windows Server als Feature **Data-Center-Bridging** installierbar — **nur bei RoCE erforderlich**, nicht bei iWARP.

### QoS (Quality of Service)

Sammelbegriff für Mechanismen zur Priorisierung und Steuerung von Netzwerk-Traffic. Im S2D-Kontext wird QoS verwendet, um RDMA-/Storage-Traffic gegenüber anderem Traffic zu bevorzugen und Bandbreiten-Minimum-Werte zu garantieren.

### PCP (Priority Code Point)

3-Bit-Feld im VLAN-Tag (IEEE 802.1Q), das die Priorität eines Ethernet-Frames angibt (Werte 0–7). Wird bei PFC und ETS verwendet, um Traffic in verschiedene Prioritätsklassen einzuordnen. RoCE-Traffic wird typischerweise auf Priority 3 oder 5 gemappt.

### WRED (Weighted Random Early Detection)

Staumanagement-Algorithmus auf Switches. Verwirft oder markiert (bei ECN) Pakete **zufällig und gewichtet**, bevor die Queue komplett voll ist. Verhindert globale Synchronisation (alle Sender reduzieren gleichzeitig) und ermöglicht eine fairere Verteilung der verfügbaren Bandbreite.

### Lossless Ethernet

Ethernet-Netzwerk, in dem **keine Pakete durch Überlast verworfen** werden. Wird durch PFC realisiert. Voraussetzung für RDMA/RoCE, da RDMA-Protokolle keinen eingebauten Retransmit-Mechanismus haben und bei Paketverlust die Verbindung abbrechen.

### Head-of-Line Blocking

Problem bei PFC: Wenn ein Flow pausiert wird, werden alle anderen Flows, die dieselbe Queue oder denselben Ausgangsport teilen, ebenfalls blockiert — auch wenn sie nicht am Stau beteiligt sind.

### Pause Storm (Congestion Spreading)

Kettenreaktion bei PFC: Ein überlasteter Switch sendet Pause-Frames an seine Upstream-Switches, die wiederum Pause-Frames an ihre Upstream-Switches senden. Der Stau breitet sich rückwärts über mehrere Switches aus und kann große Teile des Netzwerks lahmlegen.

---

## Netzwerk — Teaming und Verkabelung

### SET (Switch Embedded Teaming)

NIC-Teaming-Lösung, die direkt in den Hyper-V Virtual Switch integriert ist. Ab Windows Server 2016 die **empfohlene** Methode für S2D, da SET im Gegensatz zu LBFO **RDMA auf virtuellen NICs (vNICs) unterstützt**. Ermöglicht Bandbreitenaggregation und Failover.

### LBFO (Load Balancing and Failover)

Traditionelles NIC-Teaming in Windows Server. Fasst mehrere physische NICs zu einem logischen Team zusammen. **Nicht kompatibel mit RDMA** und daher für S2D **nicht empfohlen**. Wird durch SET ersetzt.

### DAC (Direct Attach Copper)

Kupferkabel mit fest montierten Transceivern (SFP+/SFP28/QSFP28) an beiden Enden. Kostengünstige Verbindungsoption für kurze Distanzen (bis ca. 5 m). Typisch für Verbindungen innerhalb eines Racks oder zwischen benachbarten Racks.

### LWL (Lichtwellenleiter)

Glasfaserkabel für die optische Datenübertragung. Bietet größere Reichweiten als Kupferkabel (bis mehrere Kilometer) und ist unempfindlich gegen elektromagnetische Störungen. Für brandabschnittübergreifende Verbindungen besonders geeignet, da LWL durch zertifizierte Brandschottdurchführungen verlegt werden können.

### Switchless / Switched Topologie

Zwei Netzwerk-Topologie-Optionen für S2D:

- **Switchless**: Direkte Kabelverbindungen zwischen allen Knoten (jeder mit jedem). Geeignet für 2–3 Knoten.
- **Switched**: Verbindung über Netzwerk-Switches. Empfohlen ab 4 Knoten und erforderlich für größere Cluster.

---

## Cluster und Resilienz

### Fault Domain / Fault Domain Awareness

Logische Gruppierung von Hardware-Komponenten, die von einem gemeinsamen Fehler betroffen sein können. Windows Server kennt vier hierarchische Ebenen: **Node** → **Chassis** → **Rack** → **Site**. S2D nutzt Fault Domains, um Datenkopien auf verschiedene Ausfallzonen zu verteilen und so die Resilienz zu maximieren.

### Three-way Mirror

Resilienz-Typ, bei dem **drei Kopien** jedes Datenblocks auf verschiedene Fault Domains verteilt werden. Toleriert den gleichzeitigen Ausfall von **2 Komponenten** (Laufwerke oder Server). Speichereffizienz: 33,3 %. Empfohlen für S2D-Cluster über Brandabschnitte.

### Dual Parity

Resilienz-Typ, ähnlich wie RAID 6. Verteilt Daten und **zwei Paritätsblöcke** über mindestens 4 Fault Domains. Toleriert 2 gleichzeitige Ausfälle bei höherer Speichereffizienz (50–80 %) als Three-way Mirror. Geeignet für kapazitätsoptimierte Workloads (Archiv, Backup).

### Mirror-Accelerated Parity

Hybrid-Resilienz-Typ, der Mirror für häufig geschriebene („heiße") Daten und Parity für selten geänderte („kalte") Daten kombiniert. Bietet einen Kompromiss zwischen Performance (Mirror) und Speichereffizienz (Parity).

### Quorum / Cluster Quorum

Abstimmungsmechanismus im Failover Cluster, der sicherstellt, dass der Cluster nur dann weiterarbeitet, wenn eine **Mehrheit der Stimmen** (Knoten + Witness) verfügbar ist. Verhindert Split-Brain-Szenarien, bei denen zwei Teile des Clusters unabhängig voneinander arbeiten und Daten beschädigen könnten.

### Pool Quorum

Separate Quorum-Berechnung für den Storage Pool. Die verbleibenden Laufwerke müssen zusammen mit dem Pool Resource Owner **mehr als 50 % der Stimmen** haben, damit der Pool und seine Volumes online bleiben.

### Dynamic Quorum

Automatische Anpassung der Quorum-Stimmen im laufenden Betrieb. Windows Server kann die Stimmenzahl einzelner Knoten dynamisch ändern, um nach Ausfällen die Überlebensfähigkeit des Clusters zu maximieren, ohne dass eine manuelle Neukonfiguration erforderlich ist.

### File Share Witness

SMB-Dateifreigabe auf einem separaten Server, die als Quorum-Witness dient. Bei S2D über Brandabschnitte sollte der File Share Witness an einem **dritten Standort** platziert werden — weder in Brandabschnitt A noch in B.

### Cloud Witness

Quorum-Witness in Azure Blob Storage. Alternative zum File Share Witness, wenn eine Internetverbindung zu Azure vorhanden ist. Einfach einzurichten und hochverfügbar durch Azure.

### Disk Witness

Quorum-Witness auf einer Cluster-Disk. Bei S2D **nicht unterstützt**, da kein gemeinsam genutzter (Shared) Speicher vorhanden ist.

### Split-Brain

Fehlerzustand, bei dem ein Cluster in zwei oder mehr Teile zerfällt, die jeweils glauben, der aktive Cluster zu sein. Beide Teile schreiben unabhängig Daten, was zu Datenkorruption führt. Wird durch Quorum-Mechanismen verhindert.

### Storage Affinity

Feature bei Stretch-Clustern, das VMs bevorzugt auf Servern platziert, die physisch nahe an ihrem Speicher liegen. Minimiert den Netzwerk-Traffic zwischen Standorten und reduziert die Latenz für I/O-Operationen.

### Stretch Clustering

Cluster-Konfiguration, bei der die Knoten über mehrere physische Standorte verteilt sind. S2D nutzt Fault Domains vom Typ **Site**, um die Standorte abzubilden und Daten standortübergreifend zu replizieren.

### Live Migration

Verschiebung einer laufenden VM von einem Cluster-Knoten auf einen anderen, ohne Ausfallzeit. Erfordert ausreichend Netzwerkbandbreite und identische CPU-Familien auf allen Knoten.

### Hyperconverged

Deployment-Modell, bei dem Compute (VMs) und Storage auf denselben physischen Servern laufen. Im Gegensatz dazu trennt das **Converged**-Modell Compute und Storage auf separate Server (Scale-Out File Server).

### Storage Bus

Interner Kommunikationskanal von S2D, über den die Cluster-Knoten auf die Laufwerke anderer Knoten zugreifen. Nutzt SMB 3.x über das Storage-Netzwerk. Schreibvorgänge erfolgen **synchron**, weshalb die Netzwerklatenz die I/O-Performance direkt beeinflusst.

---

## Infrastruktur und Brandschutz

### Brandabschnitt

Baulich abgeschlossener Bereich innerhalb eines Gebäudes, der durch Brandwände und Brandschottungen vom Rest des Gebäudes getrennt ist. Soll die Ausbreitung von Feuer und Rauch verhindern. In Rechenzentren werden Server und Infrastruktur oft auf mehrere Brandabschnitte verteilt, um bei einem Brand nicht die gesamte IT zu verlieren.

### Brandschott / Brandschottdurchführung

Abgedichtete Durchführung in einer Brandwand für Kabel (LWL, Kupfer, Strom). Muss den gleichen Feuerwiderstand wie die umgebende Wand bieten und nach geltenden Vorschriften zertifiziert sein. Kabel, die durch Brandschotts geführt werden, müssen dokumentiert werden.

### SDDC (Software-Defined Data Center)

Rechenzentrumsarchitektur, bei der Compute, Storage und Netzwerk vollständig softwaregesteuert sind. Microsoft bietet im Windows Server Catalog die Qualifikationen **SDDC Standard** und **SDDC Premium** für Hardware an, die für S2D und Hyper-V validiert ist.

---

## Weitere Abkürzungen

### ECC (Error-Correcting Code)

Speichertechnologie (RAM), die einzelne Bit-Fehler automatisch erkennen und korrigieren kann. Standard in Server-Hardware und für S2D erforderlich.

### FCoE (Fibre Channel over Ethernet)

Protokoll, das Fibre-Channel-Frames über Ethernet transportiert. Wird von S2D **nicht unterstützt** — S2D verwendet ausschließlich direkt angeschlossene Laufwerke.

### iSCSI (Internet Small Computer Systems Interface)

Block-Level-Storage-Protokoll über TCP/IP-Netzwerke. Wird von S2D ebenfalls **nicht unterstützt** für die Datenlaufwerke.

### RAID (Redundant Array of Independent Disks)

Hardware-basierte Datenredundanz auf Controller-Ebene. Bei S2D **nicht unterstützt** und kontraproduktiv, da S2D die Datenresilienz selbst in Software verwaltet. HBAs müssen im Pass-Through-Modus betrieben werden.

---

## Quellenverzeichnis

1. **Microsoft Learn** — „Priority-based Flow Control (PFC)"\
   <https://learn.microsoft.com/de-de/windows-hardware/drivers/network/priority-based-flow-control--pfc>\
   Abgerufen: 21. April 2026

2. **NVIDIA** — „Priority Flow Control (PFC) — ONYX Documentation"\
   <https://docs.nvidia.com/networking/display/onyxv3103004/priority+flow+control+%28pfc%29>\
   Abgerufen: 21. April 2026

3. **Juniper Networks** — „DCQCN Traffic Management"\
   <https://www.juniper.net/documentation/us/en/software/junos/traffic-mgmt-qfx/topics/topic-map/cos-qfx-series-DCQCN.html>\
   Abgerufen: 21. April 2026

4. **FS.com** — „ECN vs. DCQCN: Which Congestion Control Mechanism Is More Efficient?"\
   <https://www.fs.com/blog/ecn-vs-dcqcn-which-congestion-control-mechanism-is-more-efficient-17725.html>\
   Abgerufen: 21. April 2026
