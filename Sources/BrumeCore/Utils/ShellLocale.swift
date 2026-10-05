/// La langue du shell (`LANG`) suit le Mac, pas le réglage Langue de Brume : sans `LANG`, le moteur
/// la déduit de la langue de l'app, que ce réglage force par `AppleLanguages`.
public enum ShellLocale {
    /// `appleLocale` : la région du Mac, comme `fr_FR` ou `en_FR@rg=frzzzz`. Nil si le système n'a
    /// pas cette locale : le moteur choisit alors seul, comme avant.
    public static func lang(appleLocale: String?, isAvailable: (String) -> Bool) -> String? {
        guard let identifier = appleLocale?.split(separator: "@").first, !identifier.isEmpty else { return nil }
        let lang = "\(identifier).UTF-8"
        return isAvailable(lang) ? lang : nil
    }
}
