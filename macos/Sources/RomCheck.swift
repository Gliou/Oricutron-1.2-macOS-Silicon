//
//  RomCheck.swift — Vérification des ROMs et fenêtre d'information
//  Créé le 2026-11-04 by GliouCNR©70
//
//  Affichée au démarrage si une ROM manque, et à tout moment via
//  le menu Fichier > Vérifier les ROMs…
//

import AppKit

struct RomInfo {
    let file: String        // nom attendu dans roms/ (sans tenir compte de la casse)
    let usage: String       // à quoi elle sert
    let essential: Bool     // indispensable pour démarrer
}

enum RomCheck {
    static let roms: [RomInfo] = [
        RomInfo(file: "basic11b.rom", usage: "Oric Atmos (BASIC 1.1)", essential: true),
        RomInfo(file: "basic10.rom",  usage: "Oric-1 (BASIC 1.0)", essential: true),
        RomInfo(file: "microdis.rom", usage: "Lecteur Microdisc — la plupart des disquettes .dsk", essential: false),
        RomInfo(file: "jasmin.rom",   usage: "Lecteur Jasmin — disquettes Jasmin", essential: false),
        RomInfo(file: "bd500.rom",    usage: "Lecteur BD-500 (Byte Drive)", essential: false),
        RomInfo(file: "telmon24.rom", usage: "Telestrat — moniteur", essential: false),
        RomInfo(file: "teleass.rom",  usage: "Telestrat — assembleur", essential: false),
        RomInfo(file: "hyperbas.rom", usage: "Telestrat — Hyper-BASIC", essential: false),
        RomInfo(file: "pravetzt.rom", usage: "Pravetz 8D", essential: false),
        RomInfo(file: "8dos2.rom",    usage: "Pravetz 8D — lecteur de disquettes", essential: false),
    ]

    static var romsDir: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Oricutron/roms", isDirectory: true)
    }

    /// ROMs absentes (comparaison insensible à la casse : basic11b.ROM convient).
    static func missing() -> [RomInfo] {
        let present = Set(((try? FileManager.default.contentsOfDirectory(atPath: romsDir.path)) ?? [])
            .map { $0.lowercased() })
        return roms.filter { !present.contains($0.file.lowercased()) }
    }

    private static let suppressKey = "NePlusSignalerROMsOptionnelles"

    enum Outcome { case launch, quit }

    /// Fenêtre de vérification.
    /// - atStartup: au démarrage, rien n'est affiché si tout est présent (ou si l'utilisateur
    ///   a demandé à ne plus être prévenu pour les ROMs optionnelles).
    @MainActor
    @discardableResult
    static func showWindow(atStartup: Bool) -> Outcome {
        var lack = missing()
        let defaults = UserDefaults.standard

        if atStartup {
            if lack.isEmpty { return .launch }
            if !lack.contains(where: { $0.essential }) && defaults.bool(forKey: suppressKey) { return .launch }
        }

        NSApp.activate(ignoringOtherApps: true)

        while true {
            let essentialMissing = lack.contains { $0.essential }
            let alert = NSAlert()
            alert.alertStyle = essentialMissing ? .critical : (lack.isEmpty ? .informational : .warning)

            if lack.isEmpty {
                alert.messageText = "Toutes les ROMs sont présentes"
                alert.informativeText = "Oricutron peut émuler toutes les machines et tous les lecteurs de disquettes."
            } else if essentialMissing {
                alert.messageText = "ROM indispensable manquante"
                alert.informativeText = """
                Oricutron ne peut pas démarrer correctement sans la ROM BASIC. \
                Les ROMs ne sont pas fournies avec le code source (droits d'auteur) : \
                copie les fichiers .rom d'une distribution officielle d'Oricutron dans le dossier roms.
                """
            } else {
                alert.messageText = "Certaines ROMs sont manquantes"
                alert.informativeText = """
                L'émulateur démarre, mais les fonctions ci-dessous (marquées ✗) ne marcheront pas. \
                Copie les fichiers .rom manquants dans le dossier roms puis relance Oricutron.
                """
            }
            alert.accessoryView = makeList(missing: lack)

            // Boutons
            alert.addButton(withTitle: "Ouvrir le dossier ROMs")          // 1000
            alert.addButton(withTitle: "Vérifier à nouveau")              // 1001
            if atStartup {
                alert.addButton(withTitle: essentialMissing ? "Lancer quand même" : "Continuer") // 1002
                if essentialMissing { alert.addButton(withTitle: "Quitter") }                    // 1003
            } else {
                alert.addButton(withTitle: "Fermer")                       // 1002
            }
            if atStartup && !essentialMissing && !lack.isEmpty {
                alert.showsSuppressionButton = true
                alert.suppressionButton?.title = "Ne plus me prévenir pour les ROMs optionnelles"
            }

            let keyWindow = NSApp.keyWindow
            let response = alert.runModal()
            keyWindow?.makeKeyAndOrderFront(nil)
            if alert.suppressionButton?.state == .on { defaults.set(true, forKey: suppressKey) }

            switch response.rawValue {
            case 1000:
                try? FileManager.default.createDirectory(at: romsDir, withIntermediateDirectories: true)
                NSWorkspace.shared.open(romsDir)
                lack = missing()
            case 1001:
                lack = missing()
            case 1003:
                return .quit
            default:
                return .launch
            }
        }
    }

    /// Liste ✓ / ✗ de toutes les ROMs.
    private static func makeList(missing: [RomInfo]) -> NSView {
        let missingSet = Set(missing.map { $0.file })
        let text = NSMutableAttributedString()
        let font = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        let mono = NSFont.monospacedSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .medium)

        for (i, rom) in roms.enumerated() {
            let ok = !missingSet.contains(rom.file)
            let mark = ok ? "✓ " : "✗ "
            let color: NSColor = ok ? .systemGreen : (rom.essential ? .systemRed : .systemOrange)
            text.append(NSAttributedString(string: mark, attributes: [.font: mono, .foregroundColor: color]))
            text.append(NSAttributedString(string: rom.file.padding(toLength: 14, withPad: " ", startingAt: 0),
                                           attributes: [.font: mono, .foregroundColor: NSColor.labelColor]))
            text.append(NSAttributedString(string: rom.usage + (rom.essential ? " — indispensable" : ""),
                                           attributes: [.font: font, .foregroundColor: NSColor.secondaryLabelColor]))
            if i < roms.count - 1 { text.append(NSAttributedString(string: "\n")) }
        }
        text.append(NSAttributedString(string: "\n\nDossier : \(romsDir.path)",
                                       attributes: [.font: font, .foregroundColor: NSColor.tertiaryLabelColor]))

        let label = NSTextField(labelWithAttributedString: text)
        label.isSelectable = true
        label.lineBreakMode = .byWordWrapping
        label.maximumNumberOfLines = 0
        label.preferredMaxLayoutWidth = 440
        let size = label.sizeThatFits(NSSize(width: 440, height: CGFloat.greatestFiniteMagnitude))
        label.frame = NSRect(x: 0, y: 0, width: 440, height: ceil(size.height))
        return label
    }
}
