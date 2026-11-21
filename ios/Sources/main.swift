//
//  main.swift — Point d'entrée d'Oricutron pour iOS / iPadOS
//
//  1. Recopie les données par défaut (images, symboles, oricutron.cfg…) dans le
//     dossier Documents de l'app, visible dans l'app Fichiers :
//     « Sur mon iPhone > Oricutron ».
//  2. Démarre SDL2 (SDL_UIKitRunApp), qui appelle ensuite le cœur C d'Oricutron.
//

import UIKit

let fm = FileManager.default

/// Dossier de données (Documents de l'app).
let dataDir: URL = fm.urls(for: .documentDirectory, in: .userDomainMask)[0]

/// Données par défaut embarquées dans l'app.
let bundledData: URL? = Bundle.main.resourceURL?.appendingPathComponent("OricData", isDirectory: true)

/// Copie récursive sans écraser les fichiers existants.
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
    for name in (try? fm.contentsOfDirectory(atPath: src.path)) ?? [] where name != ".DS_Store" {
        mergeCopy(from: src.appendingPathComponent(name), to: dst.appendingPathComponent(name))
    }
}

func prepareDataDirectory() {
    if let bundledData { mergeCopy(from: bundledData, to: dataDir) }
    for sub in ["roms", "images", "disks", "tapes", "teledisks", "pravdisks", "snapshots"] {
        try? fm.createDirectory(at: dataDir.appendingPathComponent(sub), withIntermediateDirectories: true)
    }
    let cfg = dataDir.appendingPathComponent("oricutron.cfg")
    if !fm.fileExists(atPath: cfg.path) { fm.createFile(atPath: cfg.path, contents: Data()) }
}

prepareDataDirectory()

// Arguments transmis au cœur C. argv[0] désigne un fichier réel du dossier de données :
// le cœur en déduit son préfixe de fichiers via realpath(argv[0]).
var oricArgs: [UnsafeMutablePointer<CChar>?] = [strdup(dataDir.appendingPathComponent("oricutron.cfg").path), nil]

/// Fonction « main » donnée à SDL : exécutée une fois UIKit lancé.
let oricEntry: @convention(c) (Int32, UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>?) -> Int32 = { _, _ in
    // UIKit exige désormais le cycle de vie par scènes : on attend que la scène soit connectée
    // avant de laisser SDL créer sa fenêtre (voir OricSceneDelegate dans PlatformUIKit.swift).
    let deadline = Date().addingTimeInterval(5)
    while OricSceneDelegate.currentScene == nil && Date() < deadline {
        RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
    }
    fm.changeCurrentDirectoryPath(dataDir.path)
    return oricArgs.withUnsafeMutableBufferPointer { buf in
        oricutron_main(1, buf.baseAddress)
    }
}

exit(SDL_UIKitRunApp(CommandLine.argc, CommandLine.unsafeArgv, oricEntry))
