module Discord.Markdown exposing
    ( Markdown(..)
    , Quotable
    , bold
    , boldMarkdown
    , code
    , codeBlock
    , customEmoji
    , italic
    , italicMarkdown
    , parser
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

import Array exposing (Array)
import Discord.Id exposing (CustomEmojiId, Id, UserId)
import Parser exposing ((|.), (|=), Parser, Step(..))
import UInt64


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
            "```" ++ Maybe.withDefault "" language ++ "\n" ++ text_ ++ "```"

        Quote content ->
            "\n> " ++ (List.map toStringHelper content |> String.concat) ++ "\n"

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


parser : String -> List (Markdown a)
parser input =
    case Parser.run discordMarkdownParser input of
        Ok result ->
            Array.toList result

        Err _ ->
            [ Text input ]


type alias LoopState a =
    { current : Array String, rest : Array (Markdown a) }


type Modifiers
    = IsBold
    | IsItalic
    | IsItalic2
    | IsUnderlined
    | IsStrikethrough
    | IsSpoilered


modifierToSymbol : Modifiers -> String
modifierToSymbol modifier =
    case modifier of
        IsBold ->
            "**"

        IsItalic ->
            "_"

        IsItalic2 ->
            "*"

        IsUnderlined ->
            "__"

        IsStrikethrough ->
            "~~"

        IsSpoilered ->
            "||"


discordMarkdownParser : Parser (Array (Markdown a))
discordMarkdownParser =
    Parser.loop
        { current = Array.empty, rest = Array.empty }
        (\state ->
            getRemainingText
                |> Parser.andThen
                    (\remainingText ->
                        Parser.oneOf
                            [ Parser.succeed
                                (\userId ->
                                    Loop
                                        { current = Array.empty
                                        , rest =
                                            Array.append
                                                state.rest
                                                (Array.push (Ping userId) (parserHelper state))
                                        }
                                )
                                |. Parser.symbol "<@!"
                                |= discordUserIdParser
                                |. Parser.symbol ">"
                                |> Parser.backtrackable
                            , Parser.succeed
                                (\( name, emojiId ) ->
                                    Loop
                                        { current = Array.empty
                                        , rest =
                                            Array.append
                                                state.rest
                                                (Array.push (CustomEmoji name emojiId) (parserHelper state))
                                        }
                                )
                                |. Parser.symbol "<:"
                                |= customEmojiParser
                                |. Parser.symbol ">"
                                |> Parser.backtrackable
                            , modifierHelper False IsBold Bold state []
                            , modifierHelper False IsUnderlined Underline state []
                            , modifierHelper False IsItalic Italic state []
                            , modifierHelper True IsItalic2 Italic state []
                            , modifierHelper False IsStrikethrough Strikethrough state []
                            , modifierHelper False IsSpoilered Spoiler state []
                            , Parser.succeed
                                (\( language, content ) ->
                                    Loop
                                        { current = Array.empty
                                        , rest =
                                            Array.append
                                                state.rest
                                                (Array.push
                                                    (CodeBlock language content)
                                                    (parserHelper state)
                                                )
                                        }
                                )
                                |= codeBlockParser
                                |> Parser.backtrackable
                            , Parser.succeed
                                (\codeContent ->
                                    Loop
                                        { current = Array.empty
                                        , rest =
                                            Array.append
                                                state.rest
                                                (Array.push
                                                    (Code codeContent)
                                                    (parserHelper state)
                                                )
                                        }
                                )
                                |. Parser.symbol "`"
                                |= (Parser.chompWhile (\char -> char /= '`') |> Parser.getChompedString)
                                |. Parser.symbol "`"
                                |> Parser.backtrackable
                            , Parser.chompIf (\_ -> True)
                                |> Parser.getChompedString
                                |> Parser.map
                                    (\a ->
                                        Loop
                                            { current = Array.push a state.current
                                            , rest = state.rest
                                            }
                                    )
                            , Parser.map (\() -> bailOut state []) Parser.end
                            ]
                    )
        )


discordUserIdParser : Parser (Id UserId)
discordUserIdParser =
    Parser.chompWhile Char.isDigit
        |> Parser.getChompedString
        |> Parser.andThen
            (\idStr ->
                case UInt64.fromString idStr of
                    Just id ->
                        Parser.succeed (Discord.Id.fromUInt64 id)

                    Nothing ->
                        Parser.problem "Invalid user ID"
            )


customEmojiParser : Parser ( String, Id CustomEmojiId )
customEmojiParser =
    Parser.succeed Tuple.pair
        |= (Parser.chompWhile (\c -> c /= ':') |> Parser.getChompedString)
        |. Parser.symbol ":"
        |= (Parser.chompWhile Char.isDigit
                |> Parser.getChompedString
                |> Parser.andThen
                    (\idStr ->
                        case UInt64.fromString idStr of
                            Just id ->
                                Parser.succeed (Discord.Id.fromUInt64 id)

                            Nothing ->
                                Parser.problem "Invalid emoji ID"
                    )
           )


codeBlockParser : Parser ( Maybe String, String )
codeBlockParser =
    Parser.succeed
        (\blockContent ->
            case String.split "\n" blockContent of
                [ single ] ->
                    ( Nothing, single )

                head :: rest ->
                    if String.contains " " head then
                        ( Nothing, blockContent )

                    else if String.isEmpty head then
                        ( Nothing, String.join "\n" rest )

                    else
                        ( Just head, String.join "\n" rest )

                [] ->
                    ( Nothing, "" )
        )
        |. Parser.symbol "```"
        |= Parser.loop
            []
            (\list ->
                Parser.oneOf
                    [ Parser.succeed (Done (List.reverse list |> String.concat))
                        |. Parser.symbol "```"
                    , Parser.succeed (\char -> Loop (char :: list))
                        |= (Parser.chompIf (\_ -> True) |> Parser.getChompedString)
                    ]
            )


bailOut : LoopState a -> List Modifiers -> Step state (Array (Markdown a))
bailOut state modifiers =
    Array.append
        (case modifiers of
            IsBold :: _ ->
                Array.fromList [ Text "**" ]

            IsItalic :: _ ->
                Array.fromList [ Text "_" ]

            IsItalic2 :: _ ->
                Array.fromList [ Text "*" ]

            IsUnderlined :: _ ->
                Array.fromList [ Text "__" ]

            IsStrikethrough :: _ ->
                Array.fromList [ Text "~~" ]

            IsSpoilered :: _ ->
                Array.fromList [ Text "||" ]

            [] ->
                Array.empty
        )
        (Array.append state.rest (parserHelper state))
        |> Done


getRemainingText : Parser String
getRemainingText =
    Parser.succeed String.dropLeft
        |= Parser.getOffset
        |= Parser.getSource


modifierHelper :
    Bool
    -> Modifiers
    -> (List (Markdown a) -> Markdown a)
    -> LoopState a
    -> List Modifiers
    -> Parser (Step (LoopState a) (Array (Markdown a)))
modifierHelper noTrailingWhitespace modifier container state modifiers =
    let
        symbol : String
        symbol =
            modifierToSymbol modifier
    in
    if List.head modifiers == Just modifier then
        Parser.map
            (\() ->
                case
                    Array.append state.rest (parserHelper state)
                        |> Array.toList
                of
                    [] ->
                        Text symbol
                            |> List.singleton
                            |> Array.fromList
                            |> Done

                    nonEmpty ->
                        Done (Array.fromList [ container nonEmpty ])
            )
            (Parser.symbol symbol)

    else if List.member modifier modifiers then
        getRemainingText
            |> Parser.andThen
                (\remainingText ->
                    if String.startsWith symbol remainingText then
                        bailOut state modifiers |> Parser.succeed

                    else
                        Parser.backtrackable (Parser.problem "")
                )

    else
        Parser.succeed identity
            |. Parser.symbol symbol
            |= Parser.oneOf
                [ if noTrailingWhitespace then
                    getRemainingText
                        |> Parser.andThen
                            (\remainingText ->
                                if
                                    String.startsWith symbol remainingText
                                        || String.startsWith " " remainingText
                                then
                                    Parser.backtrackable (Parser.problem "")

                                else
                                    Parser.map
                                        (\a ->
                                            Loop
                                                { current = Array.empty
                                                , rest = Array.append state.rest (Array.append (parserHelper state) a)
                                                }
                                        )
                                        (nestedParser (modifier :: modifiers))
                            )

                  else
                    Parser.map
                        (\a ->
                            Loop
                                { current = Array.empty
                                , rest = Array.append state.rest (Array.append (parserHelper state) a)
                                }
                        )
                        (nestedParser (modifier :: modifiers))
                , Loop { current = Array.push symbol state.current, rest = state.rest }
                    |> Parser.succeed
                ]


nestedParser : List Modifiers -> Parser (Array (Markdown a))
nestedParser modifiers =
    Parser.loop
        { current = Array.empty, rest = Array.empty }
        (\state ->
            getRemainingText
                |> Parser.andThen
                    (\remainingText ->
                        Parser.oneOf
                            [ Parser.succeed
                                (\userId ->
                                    Loop
                                        { current = Array.empty
                                        , rest =
                                            Array.append
                                                state.rest
                                                (Array.push (Ping userId) (parserHelper state))
                                        }
                                )
                                |. Parser.symbol "<@!"
                                |= discordUserIdParser
                                |. Parser.symbol ">"
                                |> Parser.backtrackable
                            , Parser.succeed
                                (\( name, emojiId ) ->
                                    Loop
                                        { current = Array.empty
                                        , rest =
                                            Array.append
                                                state.rest
                                                (Array.push (CustomEmoji name emojiId) (parserHelper state))
                                        }
                                )
                                |. Parser.symbol "<:"
                                |= customEmojiParser
                                |. Parser.symbol ">"
                                |> Parser.backtrackable
                            , modifierHelper True IsBold Bold state modifiers
                            , modifierHelper False IsUnderlined Underline state modifiers
                            , modifierHelper False IsItalic Italic state modifiers
                            , modifierHelper False IsStrikethrough Strikethrough state modifiers
                            , modifierHelper False IsSpoilered Spoiler state modifiers
                            , Parser.succeed
                                (\inlineCodeContent ->
                                    Loop
                                        { current = Array.empty
                                        , rest =
                                            Array.append
                                                state.rest
                                                (Array.push
                                                    (Code inlineCodeContent)
                                                    (parserHelper state)
                                                )
                                        }
                                )
                                |. Parser.symbol "`"
                                |= (Parser.chompWhile (\char -> char /= '`') |> Parser.getChompedString)
                                |. Parser.symbol "`"
                                |> Parser.backtrackable
                            , Parser.chompIf (\_ -> True)
                                |> Parser.getChompedString
                                |> Parser.map
                                    (\a ->
                                        Loop
                                            { current = Array.push a state.current
                                            , rest = state.rest
                                            }
                                    )
                            , Parser.map (\() -> bailOut state modifiers) Parser.end
                            ]
                    )
        )


parserHelper : LoopState a -> Array (Markdown a)
parserHelper state =
    case state.current |> Array.toList |> String.concat of
        "" ->
            Array.empty

        textContent ->
            Array.fromList [ Text textContent ]
