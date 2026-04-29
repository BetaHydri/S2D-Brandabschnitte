# Storage Spaces Direct über Brandabschnitte

Technische Bewertung eines **6-Node S2D-Clusters (3+3)** über zwei
Brandabschnitte im selben Subnet innerhalb eines Rechenzentrums.

## Inhalt

Das Dokument behandelt:

- Fault Domain Awareness (Site-Konfiguration) für S2D
- Netzwerk-Anforderungen bei brandabschnittübergreifendem Betrieb
- Resilienz-Optionen (Three-way Mirror) und Fehlertoleranz
- Quorum-Konfiguration mit File Share Witness
- Architekturübersicht und physische Topologie
- Deployment-Checkliste und Risikobewertung

Alle Aussagen sind gegen die offizielle Microsoft-Dokumentation validiert.

## Dokumente

- [S2D über Brandabschnitte](docs/s2d-brandabschnitte.md)
  — Vollständige technische Bewertung eines 6-Node S2D-Clusters
  über zwei Brandabschnitte: Fault Domains, Netzwerk, Resilienz,
  Quorum und Risikobewertung
- [S2D Setup-Leitfaden](docs/s2d-setup-guide.md)
  — Schritt-für-Schritt-Anleitung für den Aufbau eines
  S2D-Clusters: Hardware-Voraussetzungen, Netzwerk-Konfiguration,
  Deployment per PowerShell und Post-Deployment-Validierung
- [HCI-Plattformvergleich: Windows Server HCI, Azure Local Connected und Azure Local Isolated](docs/hci-plattformvergleich.md)
  — Drei-Wege-Vergleich zwischen HCI On-Premises (Windows Server),
  Azure Local (Connected) und Azure Local mit Disconnected Operations:
  Funktionsunterschiede, Plattform-Stärken, Lizenzierung,
  Einsatzszenarien und Einschränkungen
- [Glossar — Fachbegriffe und Abkürzungen](docs/glossar.md)
  — Nachschlagewerk für alle technischen Begriffe und Abkürzungen

## Zielgruppe

Windows Server Administratoren und Infrastruktur-Architekten, die einen
Storage Spaces Direct Cluster über physische Brandabschnitte planen.

## Autor

Jan Tiedemann

## Lizenz

Dieses Dokument wird ohne ausdrückliche Lizenz bereitgestellt.
Alle Rechte vorbehalten.
