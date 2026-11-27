//
//  RomCheckIOS.swift — Vérification et import des ROMs (iOS)
//  Créé le 2026-11-06 by GliouCNR©70
//
//  Au démarrage (si une ROM manque) et via « Plus > Vérifier les ROMs ».
//  Les ROMs peuvent être importées depuis l'app Fichiers (iCloud Drive, AirDrop…),
//  ou copiées à la main dans « Sur mon iPhone > Oricutron > roms ».
//

import UIKit

@MainActor
enum RomCheckIOS {
    struct Rom { let file: String; let usage: String; let essential: Bool }

    static let roms: [Rom] = [
        Rom(file: "basic11b.rom", usage: "Oric Atmos", essential: true),
        Rom(file: "basic10.rom",  usage: "Oric-1", essential: true),
        Rom(file: "microdis.rom", usage: "disquettes Microdisc (.dsk)", essential: false),
        Rom(file: "jasmin.rom",   usage: "disquettes Jasmin", essential: false),
        Rom(file: "bd500.rom",    usage: "lecteur BD-500", essential: false),
        Rom(file: "telmon24.rom", usage: "Telestrat", essential: false),
        Rom(file: "teleass.rom",  usage: "Telestrat", essential: false),
        Rom(file: "hyperbas.rom", usage: "Telestrat", essential: false),
        Rom(file: "pravetzt.rom", usage: "Pravetz 8D", essential: false),
        Rom(file: "8dos2.rom",    usage: "Pravetz 8D (disquettes)", essential: false),
    ]

    static var romsDir: URL { dataDir.appendingPathComponent("roms", isDirectory: true) }

    /// Le système de fichiers d'iOS distingue majuscules et minuscules : l'émulateur
    /// cherche « basic11b.rom », un fichier « basic11b.ROM » ne serait pas trouvé.
    /// On renomme donc en minuscules les .rom présents.
    static func normalizeNames() {
        for name in (try? fm.contentsOfDirectory(atPath: romsDir.path)) ?? [] {
            let lower = name.lowercased()
            guard lower != name, lower.hasSuffix(".rom") else { continue }
            let src = romsDir.appendingPathComponent(name)
            let dst = romsDir.appendingPathComponent(lower)
            if !fm.fileExists(atPath: dst.path) { try? fm.moveItem(at: src, to: dst) }
        }
    }

    static func missing() -> [Rom] {
        normalizeNames()
        let present = Set((try? fm.contentsOfDirectory(atPath: romsDir.path)) ?? [])
        return roms.filter { !present.contains($0.file) }
    }

    /// Importe des fichiers .rom choisis dans l'app Fichiers.
    @discardableResult
    static func importRoms() -> Int {
        let picked = pickDocuments(multiple: true)
        var count = 0
        for url in picked where url.pathExtension.lowercased() == "rom" {
            if importFile(url, into: romsDir, lowercaseName: true) != nil { count += 1 }
        }
        return count
    }

    static func show(atStartup: Bool) {
        while true {
            let lack = missing()
            if atStartup && lack.isEmpty { return }

            let missingSet = Set(lack.map { $0.file })
            let list = roms.map { rom in
                (missingSet.contains(rom.file) ? "✗ " : "✓ ") + rom.file + " — " + rom.usage
            }.joined(separator: "\n")

            let essentialMissing = lack.contains { $0.essential }
            let title = lack.isEmpty ? "Toutes les ROMs sont présentes"
                : (essentialMissing ? "ROM indispensable manquante" : "Certaines ROMs sont manquantes")
            let intro = lack.isEmpty ? "" : """
            Les ROMs ne sont pas fournies (droits d'auteur). Importe les fichiers .rom \
            depuis l'app Fichiers, ou copie-les dans « Sur mon iPhone > Oricutron > roms ».


            """

            var buttons = ["Importer des ROMs…"]
            buttons.append(lack.isEmpty ? "OK" : (essentialMissing ? "Continuer quand même" : "Continuer"))
            let choice = runAlert(title: title, message: intro + list, buttons: buttons).index
            if choice == 0 {
                importRoms()
                continue          // on revérifie après l'import
            }
            return
        }
    }
}
