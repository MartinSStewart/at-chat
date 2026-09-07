port module NotificationDecoder exposing (main)

{-| Turns the message inside an encrypted push notification into the line of text the
notification shows.

The server never sees an encrypted message, so it can't write the notification body: it
forwards the ciphertext the sender uploaded and `public/service-worker.js` decrypts it on a
device that has the conversation's key. What comes out is a `MessageContent` encoded by
`Message.contentAndEmbedsCodec`, and nothing in a service worker can read that -- there is
no Elm there, and reimplementing the codec in JavaScript would be a second copy of a format
with twenty odd recursive cases and no compiler checking the two against each other.

So this is compiled to `public/notification-decoder.js` and imported by the worker, which
hands over the decrypted bytes and gets the text back. The real codec and the real
`RichText` renderer do the work, so the notification says what the message says for as long
as those two agree with themselves.

Rebuild it with `npm run notification-decoder` after changing anything it reaches.

-}

import Base64
import Json.Decode
import Json.Encode
import Message
import Platform
import RichText
import SeqDict
import Serialize
import Time


{-| Base64 of one decrypted message, with an id to answer under.
-}
port decode_notification_to_elm : (Json.Decode.Value -> msg) -> Sub msg


{-| The same id, and the text to show, or null if those bytes weren't a message.
-}
port decode_notification_from_elm : Json.Encode.Value -> Cmd msg


main : Program () () Msg
main =
    Platform.worker
        { init = \_ -> ( (), Cmd.none )
        , update = update
        , subscriptions = \_ -> decode_notification_to_elm GotRequest
        }


type Msg
    = GotRequest Json.Decode.Value


update : Msg -> () -> ( (), Cmd Msg )
update (GotRequest value) model =
    ( model
    , case
        Json.Decode.decodeValue
            (Json.Decode.map2 Tuple.pair
                (Json.Decode.field "requestId" Json.Decode.int)
                (Json.Decode.field "message" Json.Decode.string)
            )
            value
      of
        Ok ( requestId, base64 ) ->
            Json.Encode.object
                [ ( "requestId", Json.Encode.int requestId )
                , ( "text"
                  , case previewText base64 of
                        Just text ->
                            Json.Encode.string text

                        Nothing ->
                            Json.Encode.null
                  )
                ]
                |> decode_notification_from_elm

        Err _ ->
            Cmd.none
    )


{-| The notification text for a message, given the base64 of its decrypted bytes. `Nothing`
when those bytes aren't a message, which is what a key from the wrong conversation looks
like once AES-GCM has been talked into accepting it.

Mentions come out as `@<missing>` because the names live on the server and the message only
carries user ids. Stickers and attachments become the emoji `RichText.toString` uses for
them, the same as they do in a notification email.

-}
previewText : String -> Maybe String
previewText base64 =
    case Base64.toBytes base64 of
        Just bytes ->
            case Serialize.decodeFromBytes Message.contentAndEmbedsCodec bytes of
                Ok content ->
                    RichText.toString Time.utc True SeqDict.empty content.content |> Just

                Err _ ->
                    Nothing

        Nothing ->
            Nothing
