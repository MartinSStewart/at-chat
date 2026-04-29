module Discord.Markdown exposing
    ( HeadingLevel(..)
    , Markdown(..)
    , Quotable
    , bold
    , boldMarkdown
    , code
    , codeBlock
    , customEmoji
    , italic
    , italicMarkdown
    , ping
    , quote
    , spoiler
    , strikethrough
    , strikethroughMarkdown
    , text
    , toString
    , underline
    , underlineMarkdown
    )

import Discord exposing (CustomEmojiId, Id, UserId)


type Quotable
    = Quotable Never


type Markdown a
    = CodeBlock (Maybe String) String
    | Quote (List (Markdown a))
    | Code String
    | Text String
    | Bold (List (Markdown a))
    | Italic (List (Markdown a))
    | Underline (List (Markdown a))
    | Strikethrough (List (Markdown a))
    | Ping (Id UserId)
    | CustomEmoji String (Id CustomEmojiId)
    | Spoiler (List (Markdown a))
    | Heading HeadingLevel (List (Markdown a))


type HeadingLevel
    = H1
    | H2
    | H3
    | Small


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
            Bold (List.map map a)

        Italic a ->
            Italic (List.map map a)

        Underline a ->
            Underline (List.map map a)

        Strikethrough a ->
            Strikethrough (List.map map a)

        Ping a ->
            Ping a

        CustomEmoji a b ->
            CustomEmoji a b

        Spoiler a ->
            List.map map a |> Spoiler

        Heading level a ->
            Heading level (List.map map a)


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
bold text2 =
    Bold [ Text text2 ]


boldMarkdown : List (Markdown a) -> Markdown a
boldMarkdown =
    Bold


italic : String -> Markdown a
italic text2 =
    Italic [ Text text2 ]


italicMarkdown : List (Markdown a) -> Markdown a
italicMarkdown =
    Italic


underline : String -> Markdown a
underline text2 =
    Underline [ Text text2 ]


underlineMarkdown : List (Markdown a) -> Markdown a
underlineMarkdown =
    Underline


strikethrough : String -> Markdown a
strikethrough text2 =
    Strikethrough [ Text text2 ]


strikethroughMarkdown : List (Markdown a) -> Markdown a
strikethroughMarkdown =
    Strikethrough


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
toString markdown2 =
    List.map toStringHelper markdown2 |> String.concat


toStringHelper : Markdown a -> String
toStringHelper markdown =
    case markdown of
        CodeBlock language text_ ->
            "```"
                ++ (case language of
                        Just language2 ->
                            language2 ++ "\n"

                        Nothing ->
                            ""
                   )
                ++ text_
                ++ "```"

        Quote content ->
            "\n> " ++ (List.map toStringHelper content |> String.concat |> String.replace "\n" "\n> ")

        Code text2 ->
            "`" ++ String.replace "`" "``" text2 ++ "`"

        Text text_ ->
            escapeText text_

        Bold markdown2 ->
            "**" ++ toString markdown2 ++ "**"

        Italic markdown2 ->
            "*" ++ toString markdown2 ++ "*"

        Underline markdown2 ->
            "__" ++ toString markdown2 ++ "__"

        Strikethrough markdown2 ->
            "~~" ++ toString markdown2 ++ "~~"

        Ping userId ->
            "<@!" ++ Discord.idToString userId ++ ">"

        CustomEmoji name id ->
            "<:" ++ name ++ ":" ++ Discord.idToString id ++ ">"

        Spoiler content ->
            "||" ++ (List.map toStringHelper content |> String.concat) ++ "||"

        Heading level markdown2 ->
            (case level of
                H1 ->
                    "# "

                H2 ->
                    "## "

                H3 ->
                    "### "

                Small ->
                    "-# "
            )
                ++ toString markdown2


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
