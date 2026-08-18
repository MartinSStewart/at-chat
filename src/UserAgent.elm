module UserAgent exposing (Browser(..), Device(..), UserAgent, browserToString, deviceToString, init, isDesktop, parseUserAgent)


type Browser
    = Chrome
    | Firefox
    | Safari
    | Edge
    | Opera
    | UnknownBrowser


type Device
    = IPhone
    | IPad
    | AndroidPhone
    | AndroidTablet
    | Windows
    | MacOS
    | ChromeOS
    | Linux
    | Mobile
    | Tablet
    | Desktop


type alias UserAgent =
    { browser : Browser
    , device : Device
    }


init : UserAgent
init =
    { browser = UnknownBrowser, device = Desktop }


parseUserAgent : String -> UserAgent
parseUserAgent userAgentString =
    { browser = parseBrowser userAgentString
    , device = parseDevice userAgentString
    }


parseBrowser : String -> Browser
parseBrowser userAgentString =
    let
        lowerUserAgent =
            String.toLower userAgentString
    in
    if String.contains "chrome" lowerUserAgent && not (String.contains "edge" lowerUserAgent) then
        Chrome

    else if String.contains "firefox" lowerUserAgent then
        Firefox

    else if String.contains "safari" lowerUserAgent && not (String.contains "chrome" lowerUserAgent) then
        Safari

    else if String.contains "edge" lowerUserAgent then
        Edge

    else if String.contains "opera" lowerUserAgent || String.contains "opr" lowerUserAgent then
        Opera

    else
        UnknownBrowser


browserToString : Browser -> String
browserToString browser =
    case browser of
        Chrome ->
            "chrome"

        Firefox ->
            "firefox"

        Safari ->
            "safari"

        Edge ->
            "edge"

        Opera ->
            "opera"

        UnknownBrowser ->
            "unknown browser"


deviceToString : Device -> String
deviceToString device =
    case device of
        IPhone ->
            "iPhone"

        IPad ->
            "iPad"

        AndroidPhone ->
            "Android phone"

        AndroidTablet ->
            "Android tablet"

        Windows ->
            "Windows"

        MacOS ->
            "macOS"

        ChromeOS ->
            "ChromeOS"

        Linux ->
            "Linux"

        Mobile ->
            "Mobile"

        Tablet ->
            "Tablet"

        Desktop ->
            "Desktop"


{-| True for devices that are used with a mouse and keyboard rather than a touch screen.
-}
isDesktop : Device -> Bool
isDesktop device =
    case device of
        IPhone ->
            False

        IPad ->
            False

        AndroidPhone ->
            False

        AndroidTablet ->
            False

        Windows ->
            True

        MacOS ->
            True

        ChromeOS ->
            True

        Linux ->
            True

        Mobile ->
            False

        Tablet ->
            False

        Desktop ->
            True


parseDevice : String -> Device
parseDevice userAgentString =
    let
        lowerUserAgent =
            String.toLower userAgentString
    in
    if String.contains "ipad" lowerUserAgent then
        IPad

    else if String.contains "iphone" lowerUserAgent || String.contains "ipod" lowerUserAgent then
        IPhone

    else if String.contains "android" lowerUserAgent then
        if String.contains "mobile" lowerUserAgent then
            AndroidPhone

        else
            AndroidTablet

    else if String.contains "mobile" lowerUserAgent then
        Mobile

    else if String.contains "tablet" lowerUserAgent then
        Tablet

    else if String.contains "windows" lowerUserAgent then
        Windows

    else if String.contains "cros" lowerUserAgent then
        ChromeOS

    else if String.contains "macintosh" lowerUserAgent || String.contains "mac os" lowerUserAgent then
        -- iPads running iOS 13 and later claim to be a mac and can't be told apart from one here
        MacOS

    else if String.contains "linux" lowerUserAgent || String.contains "x11" lowerUserAgent then
        Linux

    else
        Desktop
