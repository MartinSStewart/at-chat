module RichTextOld exposing (fromNonemptyString)

import Benchmark
import Benchmark.Runner exposing (BenchmarkProgram)
import Dict exposing (Dict)
import Id
import List.Nonempty exposing (Nonempty(..))
import PersonName exposing (PersonName)
import RichText exposing (EscapedChar(..), Language(..), RichText(..))
import SeqDict exposing (SeqDict)
import String.Nonempty exposing (NonemptyString(..))
import Url exposing (Protocol(..), Url)


allEscapedChars : List EscapedChar
allEscapedChars =
    [ EscapedSquareBracket
    , EscapedBackslash
    , EscapedBacktick
    , EscapedAtSymbol
    , EscapedBold
    , EscapedItalic
    , EscapedStrikethrough
    , EscapedSpoilered
    ]


escapedCharToString : EscapedChar -> String
escapedCharToString escaped =
    case escaped of
        EscapedSquareBracket ->
            "["

        EscapedBackslash ->
            "\\"

        EscapedBacktick ->
            "`"

        EscapedAtSymbol ->
            "@"

        EscapedBold ->
            "*"

        EscapedItalic ->
            "_"

        EscapedStrikethrough ->
            "~"

        EscapedSpoilered ->
            "|"


normalTextFromNonempty : NonemptyString -> RichText userId
normalTextFromNonempty text =
    NormalText (String.Nonempty.head text) (String.Nonempty.tail text)


fromNonemptyString : SeqDict userId { a | name : PersonName } -> NonemptyString -> Nonempty (RichText userId)
fromNonemptyString users string =
    let
        source =
            String.Nonempty.toString string

        len =
            String.length source

        result =
            parseLoop source 0 len users [] "" []
    in
    case List.Nonempty.fromList result.nodes of
        Just nonempty ->
            normalize nonempty

        Nothing ->
            Nonempty (normalTextFromNonempty string) []


normalize : Nonempty (RichText userId) -> Nonempty (RichText userId)
normalize nonempty =
    List.foldl
        (\richText nonempty2 ->
            case richText of
                NormalText char rest ->
                    case List.Nonempty.head nonempty2 of
                        NormalText previousChar previousRest ->
                            List.Nonempty.replaceHead
                                (NormalText previousChar (previousRest ++ String.cons char rest))
                                nonempty2

                        _ ->
                            List.Nonempty.cons richText nonempty2

                Italic a ->
                    List.Nonempty.cons (Italic (normalize a)) nonempty2

                Bold a ->
                    List.Nonempty.cons (Bold (normalize a)) nonempty2

                Underline a ->
                    List.Nonempty.cons (Underline (normalize a)) nonempty2

                UserMention _ ->
                    List.Nonempty.cons richText nonempty2

                Strikethrough a ->
                    List.Nonempty.cons (Strikethrough (normalize a)) nonempty2

                Spoiler a ->
                    List.Nonempty.cons (Spoiler (normalize a)) nonempty2

                Hyperlink data ->
                    List.Nonempty.cons (Hyperlink data) nonempty2

                InlineCode char string ->
                    List.Nonempty.cons (InlineCode char string) nonempty2

                CodeBlock language string ->
                    List.Nonempty.cons (CodeBlock language string) nonempty2

                AttachedFile fileId ->
                    List.Nonempty.cons (AttachedFile fileId) nonempty2

                EscapedChar char ->
                    List.Nonempty.cons (EscapedChar char) nonempty2
        )
        (Nonempty
            (case List.Nonempty.head nonempty of
                Italic a ->
                    Italic (normalize a)

                UserMention id ->
                    UserMention id

                NormalText char string ->
                    NormalText char string

                Bold a ->
                    Bold (normalize a)

                Underline a ->
                    Underline (normalize a)

                Strikethrough a ->
                    Strikethrough (normalize a)

                Spoiler a ->
                    Spoiler (normalize a)

                Hyperlink data ->
                    Hyperlink data

                InlineCode char string ->
                    InlineCode char string

                CodeBlock language string ->
                    CodeBlock language string

                AttachedFile fileId ->
                    AttachedFile fileId

                EscapedChar char ->
                    EscapedChar char
            )
            []
        )
        (List.Nonempty.tail nonempty)
        |> List.Nonempty.reverse


type Modifiers
    = IsBold
    | IsItalic
    | IsUnderlined
    | IsStrikethrough
    | IsSpoilered


modifierToSymbol : Modifiers -> NonemptyString
modifierToSymbol modifier =
    case modifier of
        IsBold ->
            NonemptyString '*' ""

        IsItalic ->
            NonemptyString '_' ""

        IsUnderlined ->
            NonemptyString '_' "_"

        IsStrikethrough ->
            NonemptyString '~' "~"

        IsSpoilered ->
            NonemptyString '|' "|"


charToEscaped : Dict String EscapedChar
charToEscaped =
    List.map (\escaped -> ( escapedCharToString escaped, escaped )) allEscapedChars |> Dict.fromList


flushText : String -> List (RichText userId) -> List (RichText userId)
flushText text revNodes =
    case String.uncons text of
        Just ( char, rest ) ->
            NormalText char rest :: revNodes

        Nothing ->
            revNodes


finalizeResult : String -> List (RichText userId) -> List Modifiers -> Int -> { nodes : List (RichText userId), nextIndex : Int }
finalizeResult accText revNodes modifiers index =
    let
        flushed =
            flushText accText revNodes

        finalNodes =
            List.reverse flushed
    in
    { nodes =
        case modifiers of
            head :: _ ->
                let
                    (NonemptyString char rest) =
                        modifierToSymbol head
                in
                NormalText char rest :: finalNodes

            [] ->
                finalNodes
    , nextIndex = index
    }


closeModifier : Int -> String -> List (RichText userId) -> (Nonempty (RichText userId) -> RichText userId) -> NonemptyString -> { nodes : List (RichText userId), nextIndex : Int }
closeModifier afterSymbol accText revNodes container symbol =
    let
        flushed =
            flushText accText revNodes

        finalNodes =
            List.reverse flushed
    in
    case List.Nonempty.fromList finalNodes of
        Just nonempty ->
            { nodes = [ container nonempty ], nextIndex = afterSymbol }

        Nothing ->
            { nodes = [ NormalText (String.Nonempty.head symbol) (String.Nonempty.tail symbol) ]
            , nextIndex = afterSymbol
            }


parseInner : String -> Int -> Int -> SeqDict userId { a | name : PersonName } -> List Modifiers -> { nodes : List (RichText userId), nextIndex : Int }
parseInner source index len users modifiers =
    parseLoop source index len users modifiers "" []


parseLoop :
    String
    -> Int
    -> Int
    -> SeqDict userId { a | name : PersonName }
    -> List Modifiers
    -> String
    -> List (RichText userId)
    -> { nodes : List (RichText userId), nextIndex : Int }
parseLoop source index len users modifiers accText revNodes =
    if index >= len then
        finalizeResult accText revNodes modifiers index

    else
        let
            c1 =
                String.slice index (index + 1) source
        in
        if c1 == "\\" then
            let
                afterBackslash =
                    index + 1
            in
            if afterBackslash < len then
                let
                    nextChar =
                        String.slice afterBackslash (afterBackslash + 1) source
                in
                case Dict.get nextChar charToEscaped of
                    Just escaped ->
                        parseLoop source (afterBackslash + 1) len users modifiers "" (EscapedChar escaped :: flushText accText revNodes)

                    Nothing ->
                        parseLoop source (afterBackslash + 1) len users modifiers (accText ++ "\\" ++ nextChar) revNodes

            else
                parseLoop source afterBackslash len users modifiers (accText ++ "\\") revNodes

        else if c1 == "@" then
            let
                afterAt =
                    index + 1

                remaining =
                    String.slice afterAt len source
            in
            case tryMatchUser users remaining of
                Just ( userId, matchLen ) ->
                    parseLoop source (afterAt + matchLen) len users modifiers "" (UserMention userId :: flushText accText revNodes)

                Nothing ->
                    parseLoop source afterAt len users modifiers (accText ++ "@") revNodes

        else if c1 == "*" then
            let
                afterSymbol =
                    index + 1
            in
            if List.head modifiers == Just IsBold then
                closeModifier afterSymbol accText revNodes Bold (modifierToSymbol IsBold)

            else if List.member IsBold modifiers then
                finalizeResult accText revNodes modifiers index

            else
                let
                    nextChar =
                        String.slice afterSymbol (afterSymbol + 1) source
                in
                if nextChar == "*" || nextChar == " " then
                    parseLoop source afterSymbol len users modifiers (accText ++ "*") revNodes

                else
                    let
                        flushed =
                            flushText accText revNodes

                        inner =
                            parseInner source afterSymbol len users (IsBold :: modifiers)

                        newRevNodes =
                            List.foldl (\node acc -> node :: acc) flushed inner.nodes
                    in
                    parseLoop source inner.nextIndex len users modifiers "" newRevNodes

        else if c1 == "_" then
            if String.slice index (index + 2) source == "__" then
                let
                    afterSymbol =
                        index + 2
                in
                if List.head modifiers == Just IsUnderlined then
                    closeModifier afterSymbol accText revNodes Underline (modifierToSymbol IsUnderlined)

                else if List.member IsUnderlined modifiers then
                    finalizeResult accText revNodes modifiers index

                else
                    let
                        flushed =
                            flushText accText revNodes

                        inner =
                            parseInner source afterSymbol len users (IsUnderlined :: modifiers)

                        newRevNodes =
                            List.foldl (\node acc -> node :: acc) flushed inner.nodes
                    in
                    parseLoop source inner.nextIndex len users modifiers "" newRevNodes

            else
                let
                    afterSymbol =
                        index + 1
                in
                if List.head modifiers == Just IsItalic then
                    closeModifier afterSymbol accText revNodes Italic (modifierToSymbol IsItalic)

                else if List.member IsItalic modifiers then
                    finalizeResult accText revNodes modifiers index

                else
                    let
                        flushed =
                            flushText accText revNodes

                        inner =
                            parseInner source afterSymbol len users (IsItalic :: modifiers)

                        newRevNodes =
                            List.foldl (\node acc -> node :: acc) flushed inner.nodes
                    in
                    parseLoop source inner.nextIndex len users modifiers "" newRevNodes

        else if c1 == "~" then
            if String.slice index (index + 2) source == "~~" then
                let
                    afterSymbol =
                        index + 2
                in
                if List.head modifiers == Just IsStrikethrough then
                    closeModifier afterSymbol accText revNodes Strikethrough (modifierToSymbol IsStrikethrough)

                else if List.member IsStrikethrough modifiers then
                    finalizeResult accText revNodes modifiers index

                else
                    let
                        flushed =
                            flushText accText revNodes

                        inner =
                            parseInner source afterSymbol len users (IsStrikethrough :: modifiers)

                        newRevNodes =
                            List.foldl (\node acc -> node :: acc) flushed inner.nodes
                    in
                    parseLoop source inner.nextIndex len users modifiers "" newRevNodes

            else
                parseLoop source (index + 1) len users modifiers (accText ++ "~") revNodes

        else if c1 == "|" then
            if String.slice index (index + 2) source == "||" then
                let
                    afterSymbol =
                        index + 2
                in
                if List.head modifiers == Just IsSpoilered then
                    closeModifier afterSymbol accText revNodes Spoiler (modifierToSymbol IsSpoilered)

                else if List.member IsSpoilered modifiers then
                    finalizeResult accText revNodes modifiers index

                else
                    let
                        flushed =
                            flushText accText revNodes

                        inner =
                            parseInner source afterSymbol len users (IsSpoilered :: modifiers)

                        newRevNodes =
                            List.foldl (\node acc -> node :: acc) flushed inner.nodes
                    in
                    parseLoop source inner.nextIndex len users modifiers "" newRevNodes

            else
                parseLoop source (index + 1) len users modifiers (accText ++ "|") revNodes

        else if c1 == "`" then
            if String.slice index (index + 3) source == "```" then
                case findSubstring source (index + 3) len "```" of
                    Just closeIndex ->
                        let
                            content =
                                String.slice (index + 3) closeIndex source

                            ( language, codeContent ) =
                                parseCodeBlockContent content
                        in
                        case String.Nonempty.fromString codeContent of
                            Just _ ->
                                parseLoop source (closeIndex + 3) len users modifiers "" (CodeBlock language codeContent :: flushText accText revNodes)

                            Nothing ->
                                parseLoop source (closeIndex + 3) len users modifiers (accText ++ "``````") revNodes

                    Nothing ->
                        -- No closing ```, try inline code
                        case findSingleBacktick source (index + 1) len of
                            Just closeIndex ->
                                let
                                    content =
                                        String.slice (index + 1) closeIndex source
                                in
                                case String.Nonempty.fromString content of
                                    Just a ->
                                        parseLoop source (closeIndex + 1) len users modifiers "" (InlineCode (String.Nonempty.head a) (String.Nonempty.tail a) :: flushText accText revNodes)

                                    Nothing ->
                                        parseLoop source (closeIndex + 1) len users modifiers (accText ++ "``") revNodes

                            Nothing ->
                                parseLoop source (index + 1) len users modifiers (accText ++ "`") revNodes

            else
                case findSingleBacktick source (index + 1) len of
                    Just closeIndex ->
                        let
                            content =
                                String.slice (index + 1) closeIndex source
                        in
                        case String.Nonempty.fromString content of
                            Just a ->
                                parseLoop source (closeIndex + 1) len users modifiers "" (InlineCode (String.Nonempty.head a) (String.Nonempty.tail a) :: flushText accText revNodes)

                            Nothing ->
                                parseLoop source (closeIndex + 1) len users modifiers (accText ++ "``") revNodes

                    Nothing ->
                        parseLoop source (index + 1) len users modifiers (accText ++ "`") revNodes

        else if c1 == "h" then
            if String.slice index (index + 8) source == "https://" then
                let
                    protocolEnd =
                        index + 8

                    urlEnd =
                        skipUrlChars source protocolEnd len

                    urlBody =
                        String.slice protocolEnd urlEnd source

                    result =
                        parseUrlBody Https urlBody
                in
                case result.hyperlink of
                    Ok url ->
                        parseLoop source urlEnd len users modifiers result.trailing (Hyperlink url :: flushText accText revNodes)

                    Err errText ->
                        parseLoop source urlEnd len users modifiers (accText ++ errText ++ result.trailing) revNodes

            else if String.slice index (index + 7) source == "http://" then
                let
                    protocolEnd =
                        index + 7

                    urlEnd =
                        skipUrlChars source protocolEnd len

                    urlBody =
                        String.slice protocolEnd urlEnd source

                    result =
                        parseUrlBody Http urlBody
                in
                case result.hyperlink of
                    Ok url ->
                        parseLoop source urlEnd len users modifiers result.trailing (Hyperlink url :: flushText accText revNodes)

                    Err errText ->
                        parseLoop source urlEnd len users modifiers (accText ++ errText ++ result.trailing) revNodes

            else
                let
                    nextIndex =
                        skipNormalChars source (index + 1) len
                in
                parseLoop source nextIndex len users modifiers (accText ++ String.slice index nextIndex source) revNodes

        else if c1 == "[" then
            if String.slice index (index + 2) source == "[!" then
                case parseFileId source (index + 2) len of
                    Just ( fileId, nextIndex ) ->
                        parseLoop source nextIndex len users modifiers "" (AttachedFile (Id.fromInt fileId) :: flushText accText revNodes)

                    Nothing ->
                        parseLoop source (index + 1) len users modifiers (accText ++ "[") revNodes

            else
                parseLoop source (index + 1) len users modifiers (accText ++ "[") revNodes

        else
            let
                nextIndex =
                    skipNormalChars source (index + 1) len
            in
            parseLoop source nextIndex len users modifiers (accText ++ String.slice index nextIndex source) revNodes


tryMatchUser : SeqDict userId { a | name : PersonName } -> String -> Maybe ( userId, Int )
tryMatchUser users remaining =
    SeqDict.toList users
        |> List.sortBy (\( _, user ) -> PersonName.toString user.name |> String.length |> negate)
        |> List.filterMap
            (\( userId, user ) ->
                let
                    name =
                        PersonName.toString user.name
                in
                if String.startsWith name remaining then
                    Just ( userId, String.length name )

                else
                    Nothing
            )
        |> List.head


parseUrlBody : Protocol -> String -> { hyperlink : Result String Url, trailing : String }
parseUrlBody protocol urlBody =
    let
        urlBodyLen =
            String.length urlBody

        ( trimIdx, _ ) =
            String.foldr
                (\char ( idx, stop ) ->
                    if stop then
                        ( idx, True )

                    else if char == '.' || char == ')' || char == ',' || char == '"' then
                        ( idx - 1, False )

                    else
                        ( idx, True )
                )
                ( urlBodyLen, False )
                urlBody

        protocolStr =
            case protocol of
                Http ->
                    "http://"

                Https ->
                    "https://"

        urlText =
            protocolStr ++ String.slice 0 trimIdx urlBody

        trailing =
            String.slice trimIdx urlBodyLen urlBody
    in
    case Url.fromString urlText of
        Just url ->
            let
                url2 =
                    { url | protocol = protocol }

                urlNoPath =
                    { url2 | path = "" }
            in
            -- This is a hack to get the url decode to exactly match the user's input
            -- Otherwise what the user is typing will get out of sync in the case they type http://google.com?query and it gets decoded to http://google.com/?query
            if Url.toString urlNoPath == urlText then
                { hyperlink = Ok urlNoPath, trailing = trailing }

            else
                { hyperlink = Ok url2, trailing = trailing }

        Nothing ->
            { hyperlink = Err urlText, trailing = trailing }


skipUrlChars : String -> Int -> Int -> Int
skipUrlChars source index len =
    if index >= len then
        index

    else
        let
            c =
                String.slice index (index + 1) source
        in
        if c == " " || c == "\n" || c == "\t" || c == "<" || c == "|" then
            index

        else
            skipUrlChars source (index + 1) len


parseCodeBlockContent : String -> ( Language, String )
parseCodeBlockContent text =
    case String.split "\n" text of
        [ single ] ->
            ( NoLanguage, single )

        head :: rest ->
            if String.contains " " head then
                ( NoLanguage, text )

            else
                case String.Nonempty.fromString head of
                    Just nonempty ->
                        ( Language nonempty, String.join "\n" rest )

                    Nothing ->
                        ( NoLanguage, text )

        [] ->
            ( NoLanguage, "" )


findSubstring : String -> Int -> Int -> String -> Maybe Int
findSubstring source index len target =
    let
        targetLen =
            String.length target
    in
    if index + targetLen > len then
        Nothing

    else if String.slice index (index + targetLen) source == target then
        Just index

    else
        findSubstring source (index + 1) len target


findSingleBacktick : String -> Int -> Int -> Maybe Int
findSingleBacktick source index len =
    if index >= len then
        Nothing

    else if String.slice index (index + 1) source == "`" then
        Just index

    else
        findSingleBacktick source (index + 1) len


parseFileId : String -> Int -> Int -> Maybe ( Int, Int )
parseFileId source index len =
    let
        digitEnd =
            skipDigits source index len
    in
    if digitEnd > index && digitEnd < len && String.slice digitEnd (digitEnd + 1) source == "]" then
        case String.toInt (String.slice index digitEnd source) of
            Just n ->
                Just ( n, digitEnd + 1 )

            Nothing ->
                Nothing

    else
        Nothing


skipDigits : String -> Int -> Int -> Int
skipDigits source index len =
    if index >= len then
        index

    else
        let
            c =
                String.slice index (index + 1) source
        in
        if c >= "0" && c <= "9" then
            skipDigits source (index + 1) len

        else
            index


skipNormalChars : String -> Int -> Int -> Int
skipNormalChars source index len =
    if index >= len then
        index

    else
        let
            c =
                String.slice index (index + 1) source
        in
        if c == "[" || c == "@" || c == "h" || c == "`" || c == "\\" || c == "*" || c == "_" || c == "~" || c == "|" then
            index

        else
            skipNormalChars source (index + 1) len


main : BenchmarkProgram
main =
    Benchmark.Runner.program
        (Benchmark.compare
            "Rich text parsing"
            "Old"
            (\() -> fromNonemptyString SeqDict.empty (NonemptyString '1' "234567890abcdefghijklmnopqrstuvwxyz"))
            "New"
            (\() -> RichText.fromNonemptyString SeqDict.empty (NonemptyString '1' "234567890abcdefghijklmnopqrstuvwxyz"))
        )
