//
//  main.swift — Point d'entrée Swift d'Oricutron pour macOS
//  Créé le 2026-11-04 by GliouCNR©70
//
//  1. Prépare le dossier de données utilisateur
//     ~/Library/Application Support/Oricutron (roms, images, disks, tapes, oricutron.cfg…)
//     en y recopiant les fichiers par défaut embarqués dans l'app (sans jamais écraser).
//  2. Vérifie la présence des ROMs indispensables.
//  3. Lance le cœur C de l'émulateur (oricutron_main) avec ce dossier comme base.
//

import AppKit
import Foundation

let fm = FileManager.default

/// Dossier de données modifiable par l'utilisateur.
let dataDir: URL = {
    let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    return base.appendingPathComponent("Oricutron", isDirectory: true)
}()

/// Données par défaut embarquées dans Oricutron.app/Contents/Resources/OricData
let bundledData: URL? = Bundle.main.resourceURL?.appendingPathComponent("OricData", isDirectory: true)

/// Copie récursive de `src` vers `dst` sans écraser les fichiers existants.
func mergeCopy(from src: URL, to dst: URL) {
    var isDir: ObjCBool = false
    guard fm.fileExists(atPath: src.path, isDirectory: &isDir) else { return }
    if !isDir.boolValue {
        if !fm.fileExists(atPath: dst.path) {
            try? fm.createDirectory(at: dst.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? fm.copyItem(at: src, to: dst)
        }
        return
    }
    try? fm.createDirectory(at: dst, withIntermediateDirectories: true)
    let children = (try? fm.contentsOfDirectory(atPath: src.path)) ?? []
    for name in children where name != ".DS_Store" {
        mergeCopy(from: src.appendingPathComponent(name), to: dst.appendingPathComponent(name))
    }
}

func prepareDataDirectory() {
    try? fm.createDirectory(at: dataDir, withIntermediateDirectories: true)
    if let bundledData { mergeCopy(from: bundledData, to: dataDir) }
    for sub in ["roms", "images", "disks", "tapes", "teledisks", "pravdisks", "snapshots"] {
        try? fm.createDirectory(at: dataDir.appendingPathComponent(sub), withIntermediateDirectories: true)
    }
}

// MARK: - Démarrage

prepareDataDirectory()
// NB : la vérification des ROMs se fait dans init_gui_native (PlatformCocoa.swift),
// une fois SDL initialisé. Créer NSApplication ici, avant SDL, empêcherait SDL de
// créer sa propre application Cocoa et la barre de menus.
fm.changeCurrentDirectoryPath(dataDir.path)

// argv[0] pointe dans le dossier de données : le cœur C en déduit son préfixe de fichiers
// (roms/, images/, oricutron.cfg…) via realpath(argv[0]). realpath() renvoie NULL si le
// fichier n'existe pas : on désigne donc un fichier réel du dossier, oricutron.cfg.
let cfg = dataDir.appendingPathComponent("oricutron.cfg")
if !fm.fileExists(atPath: cfg.path) {
    fm.createFile(atPath: cfg.path, contents: Data())
}
// Comme l'Oricutron d'origine : un oricutron.cfg placé dans le même dossier
// qu'Oricutron.app (ex. /Applications/oricutron.cfg) est prioritaire.
let cfgBesideApp = Bundle.main.bundleURL.deletingLastPathComponent()
    .appendingPathComponent("oricutron.cfg")
if fm.isReadableFile(atPath: cfgBesideApp.path) {
    macos_set_config_path(cfgBesideApp.path)
}

var args = CommandLine.arguments
args[0] = cfg.path
// macOS ajoute parfois -psn_XXX au lancement depuis le Finder : on l'ignore.
args = [args[0]] + args.dropFirst().filter { !$0.hasPrefix("-psn_") }

var cArgs: [UnsafeMutablePointer<CChar>?] = args.map { strdup($0) }
cArgs.append(nil)
let status = cArgs.withUnsafeMutableBufferPointer { buf in
    oricutron_main(Int32(args.count), buf.baseAddress)
}
exit(status)
