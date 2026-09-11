module ExportComparison exposing (Difference(..), compareExports, differenceToString, oneWeek)

{-| Compares a channel export generated from the latest backup against the
reference export that was stored the first time we saw that channel.

Only messages that are older than the cutoff are checked. Recent messages are
still being edited, reacted to and replied to, so they're expected to differ
between two backups. Messages older than a week should be settled, so if one of
them changes it means the backup lost or corrupted data.

Thread messages are checked against the same cutoff as top level messages rather
than inheriting their parent's age, otherwise an old message with an active
thread would look like it changed every time someone replied to it.

Messages are matched up by their position in the `messages` array, since the
export doesn't give them an id. That position is stable: messages are only ever
appended, and deleting one leaves a placeholder behind instead of shortening the
array, so the message at a given position is the same message in both exports.

-}

import Array exposing (Array)
import Dict
import Json.Decode
import SafeJson exposing (SafeJson(..))
import Time


oneWeek : Int
oneWeek =
    7 * 24 * 60 * 60 * 1000


type Difference
    = MessageMissing String
    | MessageChanged String SafeJson SafeJson


{-| `Err` means one of the two documents couldn't be understood at all, which is
a different (and worse) kind of problem than the two disagreeing about a message.
-}
compareExports : Time.Posix -> String -> String -> Result String (List Difference)
compareExports cutoff referenceExport newExport =
    case ( parseGroups "reference export" referenceExport, parseGroups "new export" newExport ) of
        ( Ok reference, Ok new ) ->
            Ok (compareGroups cutoff reference new)

        ( Err error, _ ) ->
            Err error

        ( _, Err error ) ->
            Err error


differenceToString : Difference -> String
differenceToString difference =
    case difference of
        MessageMissing path ->
            path ++ " is in the reference export but missing from the backup"

        MessageChanged path reference new ->
            path
                ++ " changed\n    reference: "
                ++ SafeJson.toString 0 reference
                ++ "\n    backup:    "
                ++ SafeJson.toString 0 new


{-| The channel's own messages, and then the messages of each of its threads. Threads hang
off the channel rather than off the message they reply to, so they're listed separately and
matched up by the id of that message.
-}
parseGroups : String -> String -> Result String (List ( String, List SafeJson ))
parseGroups name export =
    case Json.Decode.decodeString SafeJson.decoder export of
        Ok json ->
            case channelOf json of
                Just channel ->
                    case messagesOf channel of
                        Just messages ->
                            Ok (( "message ", messages ) :: threadGroups channel)

                        Nothing ->
                            Err ("The " ++ name ++ " has no \"messages\" array")

                Nothing ->
                    Err ("The " ++ name ++ " isn't a channel export")

        Err error ->
            Err ("The " ++ name ++ " is not valid JSON: " ++ Json.Decode.errorToString error)


{-| An export is the channel wrapped in the tag that says which kind of channel it is.
-}
channelOf : SafeJson -> Maybe SafeJson
channelOf json =
    case ( field "tag" json, field "args" json ) of
        ( Just (JsonString _), Just (JsonArray [ channel ]) ) ->
            Just channel

        _ ->
            Nothing


messagesOf : SafeJson -> Maybe (List SafeJson)
messagesOf json =
    case field "messages" json of
        Just (JsonArray messages) ->
            Just messages

        _ ->
            Nothing


threadGroups : SafeJson -> List ( String, List SafeJson )
threadGroups channel =
    case field "threads" channel of
        Just (JsonArray entries) ->
            List.filterMap
                (\entry ->
                    case ( field "k" entry, Maybe.andThen messagesOf (field "v" entry) ) of
                        ( Just key, Just messages ) ->
                            Just ( "thread " ++ SafeJson.toString 0 key ++ " message ", messages )

                        _ ->
                            Nothing
                )
                entries

        _ ->
            []


compareGroups :
    Time.Posix
    -> List ( String, List SafeJson )
    -> List ( String, List SafeJson )
    -> List Difference
compareGroups cutoff reference new =
    List.concatMap
        (\( path, referenceMessages ) ->
            compareMessages
                cutoff
                path
                referenceMessages
                (List.filter (\( otherPath, _ ) -> otherPath == path) new
                    |> List.concatMap Tuple.second
                )
        )
        reference


compareMessages : Time.Posix -> String -> List SafeJson -> List SafeJson -> List Difference
compareMessages cutoff path reference new =
    let
        newMessages : Array SafeJson
        newMessages =
            Array.fromList new
    in
    List.indexedMap
        (\index referenceMessage ->
            let
                messagePath : String
                messagePath =
                    path ++ String.fromInt index
            in
            case Array.get index newMessages of
                Just newMessage ->
                    if isOldEnough cutoff referenceMessage && referenceMessage /= newMessage then
                        [ MessageChanged messagePath referenceMessage newMessage ]

                    else
                        []

                Nothing ->
                    -- A recent message going missing is fine to ignore. It might not have
                    -- existed yet when the backup was taken.
                    if isOldEnough cutoff referenceMessage then
                        [ MessageMissing messagePath ]

                    else
                        []
        )
        reference
        |> List.concat


{-| Every kind of message carries a time as the first thing in it, either on its own (a
message that was deleted, or someone joining) or as a field of the record that follows.
-}
messageTime : SafeJson -> Maybe Time.Posix
messageTime message =
    case field "args" message of
        Just (JsonArray (first :: _)) ->
            case first of
                JsonNumber millis ->
                    Just (Time.millisToPosix (round millis))

                _ ->
                    List.filterMap
                        (\key ->
                            case field key first of
                                Just (JsonNumber millis) ->
                                    Just (Time.millisToPosix (round millis))

                                _ ->
                                    Nothing
                        )
                        [ "createdAt", "startedAt" ]
                        |> List.head

        _ ->
            Nothing


isOldEnough : Time.Posix -> SafeJson -> Bool
isOldEnough cutoff message =
    case messageTime message of
        Just time ->
            Time.posixToMillis time < Time.posixToMillis cutoff

        Nothing ->
            -- A message we can't date is checked anyway. Skipping it would let a
            -- corrupted timestamp hide every other change to that message.
            True


field : String -> SafeJson -> Maybe SafeJson
field key message =
    case message of
        JsonObject fields ->
            Dict.get key fields

        _ ->
            Nothing
