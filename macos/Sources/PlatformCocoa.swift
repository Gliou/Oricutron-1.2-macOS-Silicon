//
//  PlatformCocoa.swift — Couche native macOS d'Oricutron, en Swift
//
//  Remplace filereq_osx.m, msgbox_osx.m et gui_osx.m. Chaque fonction est exportée
//  avec son nom C exact (@_cdecl) pour être appelée directement par le cœur C.
//  `struct machine *` est manipulé comme un pointeur opaque ; SDL_bool = Int32.
//

import AppKit
import UniformTypeIdentifiers

private let SDL_TRUE: Int32 = 1
private let SDL_FALSE: Int32 = 0

/// Exécute `body` sur le main actor (le cœur C appelle toujours depuis le thread principal).
private func onMain<T>(_ body: @MainActor () -> T) -> T {
    if Thread.isMainThread {
        return MainActor.assumeIsolated(body)
    }
    return DispatchQueue.main.sync { MainActor.assumeIsolated(body) }
}

/// Copie une chaîne Swift dans un tampon C de taille `capacity` (toujours terminé par 0).
private func copyCString(_ string: String, into buffer: UnsafeMutablePointer<CChar>, capacity: Int) {
    _ = string.withCString { src in
        strncpy(buffer, src, capacity - 1)
    }
    buffer[capacity - 1] = 0
}

// MARK: - Sélecteur de fichiers (filereq.h)

// Doit correspondre à l'enum de filereq.h
private enum FR: Int32 {
    case diskLoad = 0, diskSave, tapeLoad, tapeSaveTap, tapeSaveOrt, roms,
         snapshotLoad, snapshotSave, keymapLoad, keymapSave, other
}

@_cdecl("init_filerequester")
public func init_filerequester(_ oric: UnsafeMutableRawPointer?) -> Int32 { SDL_TRUE }

@_cdecl("shut_filerequester")
public func shut_filerequester(_ oric: UnsafeMutableRawPointer?) {}

@_cdecl("filerequester")
public func filerequester(_ oric: UnsafeMutableRawPointer?,
                          _ title: UnsafeMutablePointer<CChar>?,
                          _ path: UnsafeMutablePointer<CChar>?,
                          _ fname: UnsafeMutablePointer<CChar>?,
                          _ type: Int32) -> Int32 {
    // Fichier déjà choisi (menu natif, glisser-déposer, « Ouvrir avec ») : pas de dialogue.
    if let path, let fname, macos_take_preset(path, fname) != 0 {
        return SDL_TRUE
    }

    let kind = FR(rawValue: type) ?? .other

    let (save, extensions): (Bool, [String]) = {
        switch kind {
        case .diskLoad:     return (false, ["dsk"])
        case .diskSave:     return (true,  ["dsk"])
        case .tapeLoad:     return (false, ["tap", "ort", "wav"])
        case .tapeSaveTap:  return (true,  ["tap"])
        case .tapeSaveOrt:  return (true,  ["ort"])
        case .roms:         return (false, ["rom"])
        case .snapshotLoad: return (false, ["sna"])
        case .snapshotSave: return (true,  ["sna"])
        case .keymapLoad:   return (false, ["kma"])
        case .keymapSave:   return (true,  ["kma"])
        case .other:        return (false, [])
        }
    }()

    let titleStr = title.map { String(cString: $0) } ?? "Oricutron"
    let dirStr = path.map { String(cString: $0) } ?? ""
    let nameStr = fname.map { String(cString: $0) } ?? ""

    let chosen: URL? = onMain {
        let panel: NSSavePanel
        if save {
            panel = NSSavePanel()
            panel.canCreateDirectories = true
            if !nameStr.isEmpty { panel.nameFieldStringValue = nameStr }
        } else {
            let open = NSOpenPanel()
            open.canChooseFiles = true
            open.canChooseDirectories = false
            open.allowsMultipleSelection = false
            panel = open
        }
        panel.title = titleStr
        panel.message = titleStr
        if !dirStr.isEmpty {
            panel.directoryURL = URL(fileURLWithPath: dirStr, isDirectory: true)
        }
        // Filtrage par extension via le délégué, PAS via allowedContentTypes :
        // .dsk/.tap sont souvent revendiqués par d'autres apps (images disque…) avec un
        // autre type UTI, et les fichiers apparaissaient alors grisés / impossibles à choisir.
        let filter = ExtensionFilter(extensions: save ? [] : extensions)
        panel.delegate = filter

        let keyWindow = NSApp.keyWindow
        let result = panel.runModal()
        panel.delegate = nil
        keyWindow?.makeKeyAndOrderFront(nil)   // rend le focus clavier à la fenêtre SDL
        guard result == .OK, var url = panel.url else { return nil }
        // Sauvegarde : ajoute l'extension attendue si l'utilisateur l'a omise
        if save, let ext = extensions.first, url.pathExtension.lowercased() != ext {
            url.appendPathExtension(ext)
        }
        return url
    }

    guard let url = chosen, url.isFileURL, let path, let fname else { return SDL_FALSE }
    copyCString(url.deletingLastPathComponent().path, into: path, capacity: 4096)
    copyCString(url.lastPathComponent, into: fname, capacity: 512)
    return SDL_TRUE
}

/// Autorise uniquement les dossiers et les fichiers dont l'extension est attendue (insensible à la casse).
@MainActor
private final class ExtensionFilter: NSObject, NSOpenSavePanelDelegate {
    let extensions: Set<String>
    init(extensions: [String]) { self.extensions = Set(extensions.map { $0.lowercased() }) }

    func panel(_ sender: Any, shouldEnable url: URL) -> Bool {
        if extensions.isEmpty { return true }
        if (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true { return true }
        return extensions.contains(url.pathExtension.lowercased())
    }
}

// MARK: - Boîtes de dialogue (msgbox.h)

private let MSGBOX_YES_NO: Int32 = 0
private let MSGBOX_OK_CANCEL: Int32 = 1
private let MSGBOX_OK: Int32 = 2

@_cdecl("init_msgbox")
public func init_msgbox(_ oric: UnsafeMutableRawPointer?) -> Int32 { SDL_TRUE }

@_cdecl("shut_msgbox")
public func shut_msgbox(_ oric: UnsafeMutableRawPointer?) {}

@_cdecl("msgbox")
public func msgbox(_ oric: UnsafeMutableRawPointer?, _ type: Int32, _ msg: UnsafeMutablePointer<CChar>?) -> Int32 {
    let text = msg.map { String(cString: $0) } ?? ""
    return onMain {
        let alert = NSAlert()
        alert.messageText = "Oricutron"
        alert.informativeText = text
        switch type {
        case MSGBOX_YES_NO:
            alert.addButton(withTitle: "Oui")
            alert.addButton(withTitle: "Non")
        case MSGBOX_OK_CANCEL:
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Annuler")
        default:
            alert.addButton(withTitle: "OK")
        }
        let keyWindow = NSApp.keyWindow
        let response = alert.runModal()
        keyWindow?.makeKeyAndOrderFront(nil)
        if type == MSGBOX_OK { return SDL_TRUE }
        return response == .alertFirstButtonReturn ? SDL_TRUE : SDL_FALSE
    }
}

// MARK: - Intégration GUI native (gui.h)

/// Codes des commandes (doivent correspondre à macos_glue.c)
private enum MenuCommand: Int32 { case tape = 1, disk0 = 2, disk1 = 3 }

/// Cible des actions du menu natif : poste la commande dans la boucle SDL,
/// pour qu'elle soit exécutée au bon moment par le cœur C.
@MainActor
private final class MenuTarget: NSObject {
    static let shared = MenuTarget()
    @objc func openAny(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.title = "Ouvrir une cassette, une disquette ou un instantané"
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        let filter = ExtensionFilter(extensions: ["tap", "ort", "wav", "dsk", "sna"])
        panel.delegate = filter
        let keyWindow = NSApp.keyWindow
        let result = panel.runModal()
        panel.delegate = nil
        keyWindow?.makeKeyAndOrderFront(nil)
        guard result == .OK, let url = panel.url else { return }
        url.path.withCString { macos_push_open_file($0) }
    }
    @objc func insertTape(_ sender: Any?)  { macos_push_command(MenuCommand.tape.rawValue) }
    @objc func insertDisk0(_ sender: Any?) { macos_push_command(MenuCommand.disk0.rawValue) }
    @objc func insertDisk1(_ sender: Any?) { macos_push_command(MenuCommand.disk1.rawValue) }
    @objc func checkRoms(_ sender: Any?) { RomCheck.showWindow(atStartup: false) }
    @objc func showAbout(_ sender: Any?) {
        let small = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        let bold = NSFont.boldSystemFont(ofSize: NSFont.smallSystemFontSize)
        let center = NSMutableParagraphStyle()
        center.alignment = .center
        let base: [NSAttributedString.Key: Any] = [.font: small, .paragraphStyle: center,
                                                   .foregroundColor: NSColor.labelColor]
        let credits = NSMutableAttributedString(string: "Émulateur Oric par Peter Gordon (GPL v2)\n", attributes: base)
        credits.append(NSAttributedString(string: "https://github.com/pete-gordon/oricutron\n\n",
            attributes: base.merging([.link: URL(string: "https://github.com/pete-gordon/oricutron")!]) { $1 }))
        credits.append(NSAttributedString(string: "Apple Silicon version CNR@70\n",
            attributes: base.merging([.font: bold]) { $1 }))
        let repo = "https://github.com/Gliou/Oricutron-1.2-macOS-Silicon"
        credits.append(NSAttributedString(string: repo,
            attributes: base.merging([.link: URL(string: repo)!]) { $1 }))
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(options: [.credits: credits])
    }
    @objc func keyboardByPosition(_ sender: Any?)  { setKeyboardPositional(true) }
    @objc func keyboardByCharacter(_ sender: Any?) { setKeyboardPositional(false) }
    @objc func openDataFolder(_ sender: Any?) {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Oricutron", isDirectory: true)
        NSWorkspace.shared.open(dir)
    }
}

private var menuInstalled = false
private var romCheckDone = false
private let keyboardPrefKey = "ClavierParPosition"
private var keyboardItems: (position: NSMenuItem, character: NSMenuItem)?

@MainActor
private func setKeyboardPositional(_ on: Bool) {
    UserDefaults.standard.set(on, forKey: keyboardPrefKey)
    macos_set_keyboard_positional(on ? 1 : 0)
    keyboardItems?.position.state = on ? .on : .off
    keyboardItems?.character.state = on ? .off : .on
}

@MainActor
private func installFileMenu() {
    guard !menuInstalled, let mainMenu = NSApp.mainMenu else { return }
    menuInstalled = true

    // « À propos d'Oricutron » du menu de l'application : panneau avec nos crédits
    if let appMenu = mainMenu.items.first?.submenu,
       let about = appMenu.items.first(where: { $0.action == #selector(NSApplication.orderFrontStandardAboutPanel(_:)) }) {
        about.target = MenuTarget.shared
        about.action = #selector(MenuTarget.showAbout(_:))
    }

    let menu = NSMenu(title: "Fichier")
    func add(_ title: String, _ action: Selector, _ key: String, _ mods: NSEvent.ModifierFlags = .command) {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.keyEquivalentModifierMask = mods
        item.target = MenuTarget.shared
        menu.addItem(item)
    }
    add("Ouvrir…", #selector(MenuTarget.openAny(_:)), "o")
    menu.addItem(.separator())
    add("Insérer une cassette…", #selector(MenuTarget.insertTape(_:)), "t")
    add("Insérer une disquette (lecteur 0)…", #selector(MenuTarget.insertDisk0(_:)), "d")
    add("Insérer une disquette (lecteur 1)…", #selector(MenuTarget.insertDisk1(_:)), "d", [.command, .shift])
    menu.addItem(.separator())
    add("Vérifier les ROMs…", #selector(MenuTarget.checkRoms(_:)), "")
    add("Ouvrir le dossier de données", #selector(MenuTarget.openDataFolder(_:)), "")

    let fileItem = NSMenuItem(title: "Fichier", action: nil, keyEquivalent: "")
    fileItem.submenu = menu
    // Juste après le menu de l'application
    mainMenu.insertItem(fileItem, at: min(1, mainMenu.items.count))

    // Menu Clavier
    let kbd = NSMenu(title: "Clavier")
    let byPos = NSMenuItem(title: "Par position (comme le clavier de l'Oric)",
                           action: #selector(MenuTarget.keyboardByPosition(_:)), keyEquivalent: "")
    byPos.target = MenuTarget.shared
    byPos.toolTip = "Chaque touche du Mac actionne la touche située au même endroit sur le clavier QWERTY de l'Oric."
    let byChar = NSMenuItem(title: "Par caractère (comportement d'origine)",
                            action: #selector(MenuTarget.keyboardByCharacter(_:)), keyEquivalent: "")
    byChar.target = MenuTarget.shared
    kbd.addItem(byPos)
    kbd.addItem(byChar)
    keyboardItems = (byPos, byChar)
    let kbdItem = NSMenuItem(title: "Clavier", action: nil, keyEquivalent: "")
    kbdItem.submenu = kbd
    mainMenu.insertItem(kbdItem, at: min(2, mainMenu.items.count))

    let defaults = UserDefaults.standard
    let positional = defaults.object(forKey: keyboardPrefKey) as? Bool ?? true
    setKeyboardPositional(positional)
}

@_cdecl("init_gui_native")
public func init_gui_native(_ oric: UnsafeMutableRawPointer?) -> Int32 {
    // Appelée une fois SDL prêt et AVANT le chargement des ROMs (init_machine) :
    // l'utilisateur peut donc copier les ROMs manquantes puis continuer.
    // (init_gui est rappelée à chaque changement de mode de rendu : vérification une seule fois)
    let firstTime = !romCheckDone
    romCheckDone = true
    let outcome = onMain { () -> RomCheck.Outcome in
        installFileMenu()
        return firstTime ? RomCheck.showWindow(atStartup: true) : .launch
    }
    if outcome == .quit { exit(EXIT_SUCCESS) }
    return SDL_TRUE
}

@_cdecl("shut_gui_native")
public func shut_gui_native(_ oric: UnsafeMutableRawPointer?) {}

@_cdecl("gui_open_url")
public func gui_open_url(_ url: UnsafePointer<CChar>?) {
    guard let url, let u = URL(string: String(cString: url)) else { return }
    onMain { _ = NSWorkspace.shared.open(u) }
}

/// Appelée par clipboard_shim.c avec le contenu texte de l'écran Oric.
@_cdecl("oricutron_pasteboard_set_text")
public func oricutron_pasteboard_set_text(_ text: UnsafePointer<CChar>?) {
    guard let text else { return }
    let s = String(cString: text)
    onMain {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(s, forType: .string)
    }
}

@_cdecl("clipboard_paste")
public func clipboard_paste(_ oric: UnsafeMutableRawPointer?) -> Int32 {
    let text: String? = onMain { NSPasteboard.general.string(forType: .string) }
    guard var t = text, !t.isEmpty else { return SDL_FALSE }
    t = t.replacingOccurrences(of: "\r\n", with: "\r")
         .replacingOccurrences(of: "\n", with: "\r")
         .replacingOccurrences(of: "\t", with: " ")
    // L'Oric ne connaît que l'ASCII : on retire les accents et le reste.
    let ascii = String(t.unicodeScalars.filter { $0.isASCII }.map(Character.init))
    // queuekeys recopie la chaîne dans sa propre file d'attente.
    ascii.withCString { queuekeys(UnsafeMutablePointer(mutating: $0)) }
    return SDL_FALSE
}
