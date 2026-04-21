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
  — Vollständige technische Bewertung
- [S2D Setup-Leitfaden](docs/s2d-setup-guide.md)
  — Hardware, Software und Deployment eines S2D-Clusters
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
