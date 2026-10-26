module CallRecording exposing
    ( fileNames
    , zipName
    )

{-| Names for a call's recorded files.
-}

import Date
import Effect.Time as Time
import Id exposing (Id, UserId)
import Message exposing (CallRecordingFile)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)


{-| What each file is called when it's downloaded. The name in it is the person's name now,
and two people with the same name get their user id added so it's clear whose is whose.
The date and time are kept from the name the file was recorded under, which is in the
time zone of the person who recorded it.
-}
fileNames : (Id UserId -> String) -> List (CallRecordingFile (Id UserId)) -> List ( CallRecordingFile (Id UserId), String )
fileNames userName files =
    let
        usersByName : SeqDict String (SeqSet (Id UserId))
        usersByName =
            List.foldl
                (\file dict ->
                    SeqDict.update
                        (safeName (userName file.recordedBy))
                        (\maybeSet ->
                            case maybeSet of
                                Just set ->
                                    Just (SeqSet.insert file.recordedBy set)

                                Nothing ->
                                    Just (SeqSet.singleton file.recordedBy)
                        )
                        dict
                )
                SeqDict.empty
                files
    in
    List.map
        (\file ->
            let
                name : String
                name =
                    safeName (userName file.recordedBy)

                name2 : String
                name2 =
                    case SeqDict.get name usersByName of
                        Just set ->
                            if SeqSet.size set > 1 then
                                name ++ "-" ++ Id.toString file.recordedBy

                            else
                                name

                        Nothing ->
                            name
            in
            ( file
            , case String.split "_" file.name of
                kind :: _ :: _ ->
                    -- "_2026-10-25_20-31-07.250.mp4"
                    kind ++ "_" ++ name2 ++ String.right 28 file.name

                _ ->
                    file.name
            )
        )
        files


{-| Matches recordingFileName in voice-chat.js, which keeps names safe on Windows and macOS.
-}
safeName : String -> String
safeName name =
    case
        String.map
            (\char ->
                if String.contains (String.fromChar char) "/\\:*?\"<>|" || Char.toCode char < 32 then
                    '_'

                else
                    char
            )
            name
            |> String.trim
    of
        "" ->
            "unknown"

        name2 ->
            name2


zipName : Time.Zone -> Time.Posix -> String
zipName timezone startedAt =
    "Call recording "
        ++ String.fromInt (Time.toYear timezone startedAt)
        ++ "-"
        ++ String.padLeft 2 '0' (String.fromInt (Date.monthToNumber (Time.toMonth timezone startedAt)))
        ++ "-"
        ++ String.padLeft 2 '0' (String.fromInt (Time.toDay timezone startedAt))
        ++ " "
        ++ String.padLeft 2 '0' (String.fromInt (Time.toHour timezone startedAt))
        ++ "-"
        ++ String.padLeft 2 '0' (String.fromInt (Time.toMinute timezone startedAt))
        ++ ".zip"
