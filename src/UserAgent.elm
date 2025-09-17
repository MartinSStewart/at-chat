module UserAgent exposing (Browser(..), Device(..), UserAgent, init, parseUserAgent)


type Browser
    = Chrome
    | Firefox
    | Safari
    | Edge
    | Opera
    | UnknownBrowser


type Device
    = Desktop
    | Mobile
    | Tablet


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


parseDevice : String -> Device
parseDevice userAgentString =
    let
        lowerUserAgent =
            String.toLower userAgentString
    in
    if String.contains "mobile" lowerUserAgent || String.contains "iphone" lowerUserAgent || String.contains "android" lowerUserAgent then
        Mobile

    else if String.contains "tablet" lowerUserAgent || String.contains "ipad" lowerUserAgent then
        Tablet

    else
        Desktop
