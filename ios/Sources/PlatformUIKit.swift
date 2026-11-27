//
//  PlatformUIKit.swift — Couche native iOS d'Oricutron, en Swift
//  Créé le 2026-11-06 by GliouCNR©70
//
//  Équivalent iOS de macos/Sources/PlatformCocoa.swift :
//   • sélecteur de fichiers (filereq.h) et boîtes de dialogue (msgbox.h)
//   • presse-papiers, ouverture de liens (gui.h)
//   • scène UIKit (cycle de vie par scènes, désormais exigé par iOS)
//   • barre de boutons tactiles sous l'écran de l'Oric
//
//  Les fonctions appelées par le cœur C sont exportées avec leur nom C (@_cdecl).
//  `struct machine *` est un pointeur opaque ; SDL_bool = Int32.
//

import UIKit
import UniformTypeIdentifiers

private let SDL_TRUE: Int32 = 1
private let SDL_FALSE: Int32 = 0

// MARK: - Outils

/// Fait tourner la boucle d'événements jusqu'à ce que `done()` soit vrai.
/// Le cœur C attend une réponse synchrone (comme NSAlert.runModal sur Mac) ;
/// SDL fait de même pour ses propres boîtes de dialogue sur iOS.
func spinRunLoop(until done: () -> Bool) {
    while !done() {
        RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
    }
}

/// Contrôleur le plus « haut » de la fenêtre SDL, pour présenter alertes et sélecteurs.
@MainActor
func topViewController() -> UIViewController? {
    var vc = OricUI.sdlWindow?.rootViewController
        ?? OricSceneDelegate.currentScene?.windows.first(where: { $0.isKeyWindow })?.rootViewController
    while let presented = vc?.presentedViewController { vc = presented }
    return vc
}

/// Copie `src` dans le dossier `dir` (remplace un fichier de même nom).
func importFile(_ src: URL, into dir: URL, lowercaseName: Bool = false) -> URL? {
    try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
    let name = lowercaseName ? src.lastPathComponent.lowercased() : src.lastPathComponent
    let dst = dir.appendingPathComponent(name)
    if dst.standardizedFileURL == src.standardizedFileURL { return dst }
    let scoped = src.startAccessingSecurityScopedResource()
    defer { if scoped { src.stopAccessingSecurityScopedResource() } }
    try? fm.removeItem(at: dst)
    do { try fm.copyItem(at: src, to: dst) } catch { return nil }
    return dst
}

/// Sous-dossier de données selon l'extension du fichier.
func dataSubdir(forExtension ext: String) -> String {
    switch ext.lowercased() {
    case "dsk": return "disks"
    case "sna": return "snapshots"
    case "rom": return "roms"
    default:    return "tapes"
    }
}

/// Sélecteur de documents synchrone. Les fichiers sont copiés par iOS (asCopy).
@MainActor
func pickDocuments(multiple: Bool) -> [URL] {
    guard let presenter = topViewController() else { return [] }
    let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: true)
    picker.allowsMultipleSelection = multiple
    let delegate = PickerDelegate()
    picker.delegate = delegate
    presenter.present(picker, animated: true)
    spinRunLoop { delegate.finished }
    return delegate.urls
}

@MainActor
private final class PickerDelegate: NSObject, UIDocumentPickerDelegate {
    var finished = false
    var urls: [URL] = []
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        self.urls = urls; finished = true
    }
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        finished = true
    }
}

/// Alerte synchrone ; renvoie l'index du bouton choisi (et le texte saisi s'il y a un champ).
@MainActor
@discardableResult
func runAlert(title: String, message: String, buttons: [String],
              textField: String? = nil) -> (index: Int, text: String) {
    guard let presenter = topViewController() else { return (0, textField ?? "") }
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    final class Result { var index: Int? = nil; var text = "" }
    let result = Result()
    if let textField {
        alert.addTextField { $0.text = textField; $0.clearButtonMode = .whileEditing }
    }
    for (i, title) in buttons.enumerated() {
        let style: UIAlertAction.Style = (i == buttons.count - 1 && buttons.count > 1
            && (title == "Annuler" || title == "Non")) ? .cancel : .default
        alert.addAction(UIAlertAction(title: title, style: style) { [weak alert] _ in
            result.text = alert?.textFields?.first?.text ?? ""
            result.index = i
        })
    }
    presenter.present(alert, animated: true)
    spinRunLoop { result.index != nil }
    return (result.index ?? 0, result.text)
}

private func copyCString(_ string: String, into buffer: UnsafeMutablePointer<CChar>, capacity: Int) {
    _ = string.withCString { strncpy(buffer, $0, capacity - 1) }
    buffer[capacity - 1] = 0
}

// MARK: - Scène UIKit

/// Délégué de scène déclaré dans Info.plist (UIApplicationSceneManifest).
/// SDL2 ne gère pas les scènes : ses fenêtres sont rattachées à cette scène
/// dès leur création (ios_attach_uiwindow, appelée par system_sdl.c).
@objc(OricSceneDelegate)
final class OricSceneDelegate: UIResponder, UIWindowSceneDelegate {
    nonisolated(unsafe) static var currentScene: UIWindowScene?
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        OricSceneDelegate.currentScene = windowScene
        if let pending = OricUI.sdlWindow, pending.windowScene == nil {
            pending.windowScene = windowScene
            pending.makeKeyAndVisible()
        }
    }
}

@_cdecl("ios_attach_uiwindow")
public func ios_attach_uiwindow(_ pointer: UnsafeMutableRawPointer?) {
    guard let pointer else { return }
    let window = Unmanaged<UIWindow>.fromOpaque(pointer).takeUnretainedValue()
    MainActor.assumeIsolated {
        OricUI.sdlWindow = window
        if let scene = OricSceneDelegate.currentScene {
            window.windowScene = scene
        }
        window.makeKeyAndVisible()
        OricUI.installToolbar(in: window)
    }
}

// MARK: - Sélecteur de fichiers (filereq.h)

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
    guard let path, let fname else { return SDL_FALSE }
    if macos_take_preset(path, fname) != 0 { return SDL_TRUE }   // fichier déjà choisi

    let kind = FR(rawValue: type) ?? .other
    let (save, ext, subdir): (Bool, String, String) = {
        switch kind {
        case .diskLoad:     return (false, "dsk", "disks")
        case .diskSave:     return (true,  "dsk", "disks")
        case .tapeLoad:     return (false, "tap", "tapes")
        case .tapeSaveTap:  return (true,  "tap", "tapes")
        case .tapeSaveOrt:  return (true,  "ort", "tapes")
        case .roms:         return (false, "rom", "roms")
        case .snapshotLoad: return (false, "sna", "snapshots")
        case .snapshotSave: return (true,  "sna", "snapshots")
        case .keymapLoad:   return (false, "kma", "keymap")
        case .keymapSave:   return (true,  "kma", "keymap")
        case .other:        return (false, "",    "")
        }
    }()

    // Dossier de destination : celui proposé par le cœur C s'il est dans nos données
    let proposed = URL(fileURLWithPath: String(cString: path), isDirectory: true).standardizedFileURL
    let root = dataDir.standardizedFileURL.path
    let dir = (proposed.path.hasPrefix(root) && proposed.path != root)
        ? proposed : dataDir.appendingPathComponent(subdir, isDirectory: true)
    let titleStr = title.map { String(cString: $0) } ?? "Oricutron"
    let current = String(cString: fname)

    let result: URL? = MainActor.assumeIsolated {
        if save {
            let answer = runAlert(title: titleStr,
                                  message: "Nom du fichier (enregistré dans « \(dir.lastPathComponent) »)",
                                  buttons: ["Enregistrer", "Annuler"],
                                  textField: current.isEmpty ? "oric.\(ext)" : current)
            guard answer.index == 0 else { return nil }
            var name = answer.text.trimmingCharacters(in: .whitespaces)
            if name.isEmpty { name = "oric" }
            if !ext.isEmpty && (name as NSString).pathExtension.lowercased() != ext { name += ".\(ext)" }
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
            return dir.appendingPathComponent(name)
        } else {
            guard let picked = pickDocuments(multiple: false).first else { return nil }
            let target = subdir.isEmpty ? dataDir.appendingPathComponent(dataSubdir(forExtension: picked.pathExtension)) : dir
            return importFile(picked, into: target, lowercaseName: kind == .roms)
        }
    }

    guard let url = result else { return SDL_FALSE }
    copyCString(url.deletingLastPathComponent().path, into: path, capacity: 4096)
    copyCString(url.lastPathComponent, into: fname, capacity: 512)
    return SDL_TRUE
}

// MARK: - Boîtes de dialogue (msgbox.h)

private let MSGBOX_YES_NO: Int32 = 0
private let MSGBOX_OK_CANCEL: Int32 = 1

@_cdecl("init_msgbox")
public func init_msgbox(_ oric: UnsafeMutableRawPointer?) -> Int32 { SDL_TRUE }

@_cdecl("shut_msgbox")
public func shut_msgbox(_ oric: UnsafeMutableRawPointer?) {}

@_cdecl("msgbox")
public func msgbox(_ oric: UnsafeMutableRawPointer?, _ type: Int32, _ msg: UnsafeMutablePointer<CChar>?) -> Int32 {
    let text = msg.map { String(cString: $0) } ?? ""
    let buttons: [String]
    switch type {
    case MSGBOX_YES_NO:    buttons = ["Oui", "Non"]
    case MSGBOX_OK_CANCEL: buttons = ["OK", "Annuler"]
    default:               buttons = ["OK"]
    }
    let choice = MainActor.assumeIsolated { runAlert(title: "Oricutron", message: text, buttons: buttons).index }
    return (buttons.count == 1 || choice == 0) ? SDL_TRUE : SDL_FALSE
}

// MARK: - Intégration GUI native (gui.h)

private var romCheckDone = false

@_cdecl("init_gui_native")
public func init_gui_native(_ oric: UnsafeMutableRawPointer?) -> Int32 {
    // Appelée une fois la fenêtre créée et AVANT le chargement des ROMs :
    // l'utilisateur peut importer les ROMs manquantes puis continuer.
    if !romCheckDone {
        romCheckDone = true
        MainActor.assumeIsolated { RomCheckIOS.show(atStartup: true) }
    }
    return SDL_TRUE
}

@_cdecl("shut_gui_native")
public func shut_gui_native(_ oric: UnsafeMutableRawPointer?) {}

@_cdecl("gui_open_url")
public func gui_open_url(_ url: UnsafePointer<CChar>?) {
    guard let url, let u = URL(string: String(cString: url)) else { return }
    MainActor.assumeIsolated { UIApplication.shared.open(u) }
}

/// Appelée par clipboard_shim.c avec le texte de l'écran Oric.
@_cdecl("oricutron_pasteboard_set_text")
public func oricutron_pasteboard_set_text(_ text: UnsafePointer<CChar>?) {
    guard let text else { return }
    UIPasteboard.general.string = String(cString: text)
}

@_cdecl("clipboard_paste")
public func clipboard_paste(_ oric: UnsafeMutableRawPointer?) -> Int32 {
    MainActor.assumeIsolated { OricUI.pasteText() }
    return SDL_FALSE
}

// MARK: - Barre de boutons tactiles

@MainActor
enum OricUI {
    static weak var sdlWindow: UIWindow?
    private static let toolbarTag = 0x0071C

    /// Codes des commandes (doivent correspondre à macos_glue.c)
    enum Command: Int32 {
        case tape = 1, disk0 = 2, disk1 = 3, reset = 4, cload = 5, menu = 6
        static let machine: Int32 = 0x100
    }

    static func installToolbar(in window: UIWindow) {
        guard let host = window.rootViewController?.view else { return }
        host.viewWithTag(toolbarTag)?.removeFromSuperview()

        let bar = UIStackView()
        bar.tag = toolbarTag
        bar.axis = .horizontal
        bar.distribution = .fillEqually
        bar.spacing = 6
        bar.translatesAutoresizingMaskIntoConstraints = false
        // jamais grisée, même quand une alerte vient d'être affichée
        bar.tintAdjustmentMode = .normal

        bar.addArrangedSubview(button("Cassette", "recordingtape") { macos_push_command(Command.tape.rawValue) })
        bar.addArrangedSubview(button("Disquette", "externaldrive") { macos_push_command(Command.disk0.rawValue) })
        bar.addArrangedSubview(button("CLOAD", "play.fill") { macos_push_command(Command.cload.rawValue) })
        bar.addArrangedSubview(button("Reset", "arrow.counterclockwise") { macos_push_command(Command.reset.rawValue) })
        bar.addArrangedSubview(moreButton())

        host.addSubview(bar)
        let guide = host.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 8),
            bar.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -8),
            bar.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -6),
            bar.heightAnchor.constraint(equalToConstant: 54),
        ])
    }

    private static func baseConfig(_ title: String, _ symbol: String) -> UIButton.Configuration {
        // Couleurs explicites : bien lisible sur le fond noir de l'émulateur
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = UIColor(white: 0.38, alpha: 1)
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 2, bottom: 6, trailing: 2)
        config.titleLineBreakMode = .byTruncatingTail
        config.title = title
        config.image = UIImage(systemName: symbol)
        config.imagePlacement = .top
        config.imagePadding = 3
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer {
            var a = $0; a.font = UIFont.systemFont(ofSize: 11, weight: .medium); return a
        }
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 15)
        return config
    }

    private static func button(_ title: String, _ symbol: String, _ action: @escaping () -> Void) -> UIButton {
        UIButton(configuration: baseConfig(title, symbol), primaryAction: UIAction { _ in action() })
    }

    private static func moreButton() -> UIButton {
        let machines: [(String, Int32)] = [("Oric Atmos", 2), ("Oric-1", 0), ("Oric-1 16K", 1),
                                           ("Telestrat", 3), ("Pravetz 8D", 4)]
        let machineMenu = UIMenu(title: "Machine", image: UIImage(systemName: "desktopcomputer"),
            children: machines.map { name, id in
                UIAction(title: name) { _ in macos_push_command(Command.machine + id) }
            })
        let menu = UIMenu(children: [
            UIAction(title: "Menu Oricutron (F1)", image: UIImage(systemName: "slider.horizontal.3")) { _ in
                macos_push_command(Command.menu.rawValue) },
            UIAction(title: "Ouvrir un fichier…", image: UIImage(systemName: "folder")) { _ in openAnyFile() },
            UIAction(title: "Disquette lecteur 1…", image: UIImage(systemName: "externaldrive")) { _ in
                macos_push_command(Command.disk1.rawValue) },
            machineMenu,
            UIAction(title: "Coller du texte", image: UIImage(systemName: "doc.on.clipboard")) { _ in pasteText() },
            UIAction(title: "Importer des ROMs…", image: UIImage(systemName: "square.and.arrow.down")) { _ in
                RomCheckIOS.importRoms(); RomCheckIOS.show(atStartup: false) },
            UIAction(title: "Vérifier les ROMs", image: UIImage(systemName: "checklist")) { _ in
                RomCheckIOS.show(atStartup: false) },
            UIAction(title: "À propos d'Oricutron", image: UIImage(systemName: "info.circle")) { _ in showAbout() },
        ])
        let b = UIButton(configuration: baseConfig("Plus", "ellipsis.circle"))
        b.menu = menu
        b.showsMenuAsPrimaryAction = true
        return b
    }

    /// Ouvre .tap/.ort/.wav/.dsk/.sna : le fichier est copié dans nos données puis inséré.
    static func openAnyFile() {
        guard let picked = pickDocuments(multiple: false).first else { return }
        let dir = dataDir.appendingPathComponent(dataSubdir(forExtension: picked.pathExtension))
        guard let local = importFile(picked, into: dir) else { return }
        local.path.withCString { macos_push_open_file($0) }
    }

    static func pasteText() {
        guard var t = UIPasteboard.general.string, !t.isEmpty else { return }
        t = t.replacingOccurrences(of: "\r\n", with: "\r")
             .replacingOccurrences(of: "\n", with: "\r")
             .replacingOccurrences(of: "\t", with: " ")
        let ascii = String(t.unicodeScalars.filter { $0.isASCII }.map(Character.init))
        ascii.withCString { queuekeys(UnsafeMutablePointer(mutating: $0)) }
    }

    static func showAbout() {
        let message = """
        Émulateur Oric par Peter Gordon (GPL v2)
        github.com/pete-gordon/oricutron

        Apple Silicon version CNR@70
        github.com/Gliou/Oricutron-1.2-macOS-Silicon
        """
        let choice = runAlert(title: "Oricutron 1.2 iOS", message: message,
                              buttons: ["Ouvrir la page du projet", "OK"]).index
        if choice == 0, let url = URL(string: "https://github.com/Gliou/Oricutron-1.2-macOS-Silicon") {
            UIApplication.shared.open(url)
        }
    }
}
