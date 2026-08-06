port module DiscordMarkdownHarness exposing (Flags, Row, main, rowsFor)

{-| Answers "what actually happens to this text on its way to Discord and back?" for a
list of inputs, so that the escaping rules can be checked against something instead of
guessed at.

Discord's POST endpoint stores a message's content verbatim, so the only thing that
transforms the text is the markdown renderer in the Discord client, which has no published
grammar. What at-chat does have is `RichText.fromDiscord`, the parser it renders incoming
Discord messages with. That parser is at-chat's model of Discord's grammar, so a message
at-chat sends should survive being read back by it:

    fromDiscord (toDiscord (fromNonemptyString typed)) == fromNonemptyString typed

Each row below shows both halves of that: what at-chat makes of the text someone typed,
what it sends to Discord, and what it would make of the message coming back. `run.js`
renders the sent text with a JavaScript port of Discord's renderer as well, when one is
installed, which is as close to the real client as this can get without a person looking
at one.

Run it with `npm run discord-markdown` from the repo root.

-}

import Discord
import Json.Encode
import List.Nonempty exposing (Nonempty)
import OneToOne
import Platform
import RichText exposing (RichText)
import SeqDict
import String.Nonempty


type alias Flags =
    { inputs : List String
    , -- Read the inputs as Discord message content rather than as text typed into at-chat,
      -- which answers "what does at-chat think Discord means by this?"
      asDiscordContent : Bool
    }


type alias Row =
    { typed : String
    , atChatReads : String
    , sentToDiscord : String
    , comesBackAs : String
    , survivesTheRoundTrip : Bool
    }


port output : Json.Encode.Value -> Cmd msg


main : Program Flags () ()
main =
    Platform.worker
        { init =
            \flags ->
                ( ()
                , (if flags.asDiscordContent then
                    List.map discordRow flags.inputs

                   else
                    rowsFor flags.inputs
                  )
                    |> Json.Encode.list encodeRow
                    |> output
                )
        , update = \_ model -> ( model, Cmd.none )
        , subscriptions = \_ -> Sub.none
        }


rowsFor : List String -> List Row
rowsFor inputs =
    List.map row inputs


row : String -> Row
row typed =
    case String.Nonempty.fromString typed of
        Just nonempty ->
            let
                atChat : Nonempty (RichText (Discord.Id Discord.UserId))
                atChat =
                    RichText.fromNonemptyString SeqDict.empty nonempty

                sent : String
                sent =
                    case RichText.toDiscord OneToOne.empty atChat of
                        Ok text ->
                            text

                        Err charsLeft ->
                            "<too long by " ++ String.fromInt (negate charsLeft) ++ " characters>"

                comesBack : Nonempty (RichText (Discord.Id Discord.UserId))
                comesBack =
                    RichText.fromDiscord
                        sent
                        SeqDict.empty
                        Discord.Missing
                        OneToOne.empty
                        []
                        Discord.Missing
            in
            { typed = typed
            , atChatReads = Debug.toString (List.Nonempty.toList atChat)
            , sentToDiscord = sent
            , comesBackAs = Debug.toString (List.Nonempty.toList comesBack)
            , survivesTheRoundTrip = comesBack == atChat
            }

        Nothing ->
            { typed = typed
            , atChatReads = "<empty>"
            , sentToDiscord = ""
            , comesBackAs = "<empty>"
            , survivesTheRoundTrip = True
            }


{-| What at-chat makes of a message that arrives from Discord holding this text.
-}
discordRow : String -> Row
discordRow content =
    let
        parsed : Nonempty (RichText (Discord.Id Discord.UserId))
        parsed =
            RichText.fromDiscord content SeqDict.empty Discord.Missing OneToOne.empty [] Discord.Missing
    in
    { typed = content
    , atChatReads = Debug.toString (List.Nonempty.toList parsed)
    , sentToDiscord =
        case RichText.toDiscord OneToOne.empty parsed of
            Ok text ->
                text

            Err _ ->
                "<too long>"
    , comesBackAs = RichText.toString False (SeqDict.empty |> SeqDict.map (\_ user -> user)) parsed
    , survivesTheRoundTrip = True
    }


encodeRow : Row -> Json.Encode.Value
encodeRow data =
    Json.Encode.object
        [ ( "typed", Json.Encode.string data.typed )
        , ( "atChatReads", Json.Encode.string data.atChatReads )
        , ( "sentToDiscord", Json.Encode.string data.sentToDiscord )
        , ( "comesBackAs", Json.Encode.string data.comesBackAs )
        , ( "survivesTheRoundTrip", Json.Encode.bool data.survivesTheRoundTrip )
        ]
