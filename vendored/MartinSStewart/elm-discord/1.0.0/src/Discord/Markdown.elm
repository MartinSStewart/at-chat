module Discord.Markdown exposing
    ( Markdown
    , Quotable
    , bold
    , boldItalic
    , boldItalicStrikethrough
    , boldStrikethrough
    , code
    , codeBlock
    , customEmoji
    , italic
    , italicStrikethrough
    , ping
    , quote
    , spoiler
    , strikethrough
    , text
    , toString
    )

import Discord.Id exposing (CustomEmojiId, Id, UserId)


type Quotable
    = Quotable Never


type Markdown a
    = CodeBlock (Maybe String) String
    | Quote (List (Markdown a))
    | Code String
    | Text String
    | Bold String
    | Italic String
    | Strikethrough String
    | BoldItalic String
    | BoldStrikethrough String
    | ItalicStrikethrough String
    | BoldItalicStrikethrough String
    | Ping (Id UserId)
    | CustomEmoji String (Id CustomEmojiId)
    | Spoiler (List (Markdown a))


map : Markdown a -> Markdown b
map markdown =
    case markdown of
        CodeBlock a b ->
            CodeBlock a b

        Quote a ->
            List.map map a |> Quote

        Code a ->
            Code a

        Text a ->
            Text a

        Bold a ->
            Bold a

        Italic a ->
            Italic a

        Strikethrough a ->
            Strikethrough a

        BoldItalic a ->
            BoldItalic a

        BoldStrikethrough a ->
            BoldStrikethrough a

        ItalicStrikethrough a ->
            ItalicStrikethrough a

        BoldItalicStrikethrough a ->
            BoldItalicStrikethrough a

        Ping a ->
            Ping a

        CustomEmoji a b ->
            CustomEmoji a b

        Spoiler a ->
            List.map map a |> Spoiler


codeBlock : Maybe String -> String -> Markdown a
codeBlock language content =
    CodeBlock language content


quote : List (Markdown Quotable) -> Markdown ()
quote content =
    List.map map content |> Quote


code : String -> Markdown a
code =
    Code


text : String -> Markdown a
text =
    Text


bold : String -> Markdown a
bold =
    Bold


italic : String -> Markdown a
italic =
    Italic


strikethrough : String -> Markdown a
strikethrough =
    Strikethrough


boldItalic : String -> Markdown a
boldItalic =
    BoldItalic


boldStrikethrough : String -> Markdown a
boldStrikethrough =
    BoldStrikethrough


italicStrikethrough : String -> Markdown a
italicStrikethrough =
    ItalicStrikethrough


boldItalicStrikethrough : String -> Markdown a
boldItalicStrikethrough =
    BoldItalicStrikethrough


ping : Id UserId -> Markdown a
ping =
    Ping


{-| Only write the inner text. Don't include the : characters (i.e. green\_square, not :green\_square:)
-}
customEmoji : String -> Id CustomEmojiId -> Markdown a
customEmoji =
    CustomEmoji


spoiler : List (Markdown a) -> Markdown a
spoiler =
    Spoiler


toString : List (Markdown a) -> String
toString =
    List.map toStringHelper >> String.concat


toStringHelper : Markdown a -> String
toStringHelper markdown =
    case markdown of
        CodeBlock language text_ ->
            "```" ++ Maybe.withDefault "" language ++ "\n" ++ text_ ++ "```"

        Quote content ->
            "\n> " ++ (List.map toStringHelper content |> String.concat) ++ "\n"

        Code text_ ->
            "`" ++ String.replace "`" "``" text_ ++ "`"

        Text text_ ->
            escapeText text_

        Bold text_ ->
            "**" ++ escapeText text_ ++ "**"

        Italic text_ ->
            "_" ++ escapeText text_ ++ "_"

        Strikethrough text_ ->
            "~~" ++ escapeText text_ ++ "~~"

        BoldItalic text_ ->
            "**_" ++ escapeText text_ ++ "_**"

        BoldStrikethrough text_ ->
            "**_" ++ escapeText text_ ++ "_**"

        ItalicStrikethrough text_ ->
            "**_" ++ escapeText text_ ++ "_**"

        BoldItalicStrikethrough text_ ->
            "~~**_" ++ escapeText text_ ++ "_**~~"

        Ping userId ->
            "<@!" ++ Discord.Id.toString userId ++ ">"

        CustomEmoji name id ->
            "<:" ++ name ++ ":" ++ Discord.Id.toString id ++ ">"

        Spoiler content ->
            "||" ++ (List.map toStringHelper content |> String.concat) ++ "||"


escapeText : String -> String
escapeText =
    String.replace "\\" "\\\\"
        -- This needs to be disabled until url parsing works
        -->> String.replace "_" "\\_"
        >> String.replace "*" "\\*"
        >> String.replace "`" "\\`"
        >> String.replace ">" "\\>"
        >> String.replace "@" "\\@"
        >> String.replace "~" "\\~"



-->> String.replace ":" "\\:"
