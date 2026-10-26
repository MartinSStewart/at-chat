module CallRecording exposing
    ( Model
    , Msg(..)
    , callId
    , fileNames
    , init
    , view
    )

{-| The list of a call's recorded files, opened from the call's card.
-}

import Call
import Date
import Effect.Browser.Dom as Dom
import Effect.Time as Time
import FileStatus
import Icons
import Id exposing (ChannelMessageId, GuildOrDmId(..), Id, UserId)
import Message exposing (CallRecording, CallRecordingFile)
import MyUi
import NonemptySet
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import Ui exposing (Element)
import Ui.Events
import Ui.Font
import Ui.Prose
import Url
import User exposing (FrontendUser)


type alias Model =
    { guildOrDmId : GuildOrDmId
    , messageId : Id ChannelMessageId
    , confirmDelete : Maybe Time.Posix
    }


type Msg
    = PressedClose
    | PressedDelete Time.Posix
    | PressedCancelDelete
    | PressedConfirmDelete Time.Posix


init : GuildOrDmId -> Id ChannelMessageId -> Model
init guildOrDmId messageId =
    { guildOrDmId = guildOrDmId, messageId = messageId, confirmDelete = Nothing }


callId : Model -> Call.CallId
callId model =
    case model.guildOrDmId of
        GuildOrDmId_Guild id ->
            Call.GuildRoomId id

        GuildOrDmId_Dm id ->
            Call.DmRoomId id


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


view :
    Bool
    -> Time.Zone
    -> Id UserId
    -> SeqDict (Id UserId) FrontendUser
    -> Model
    -> List (CallRecording (Id UserId))
    -> Element Msg
view isMobile timezone currentUserId allUsers model recordings =
    Ui.el
        [ Ui.behindContent
            (Ui.el
                [ Ui.background MyUi.scrim
                , Ui.height Ui.fill
                , Ui.Events.onClick PressedClose
                ]
                Ui.none
            )
        , Ui.height Ui.fill
        ]
        (Ui.column
            [ Ui.centerX
            , if isMobile then
                Ui.alignBottom

              else
                Ui.centerY
            , Ui.attrIf (not isMobile) (Ui.rounded 16)
            , if isMobile then
                Ui.paddingXY 16 16

              else
                Ui.paddingXY 24 24
            , Ui.background MyUi.background3
            , if isMobile then
                Ui.width Ui.fill

              else
                Ui.widthMax 700
            , Ui.heightMax 600

            -- Ui.scrollable would also make it fill the height it's given.
            , MyUi.htmlStyle "overflow-y" "auto"
            , Ui.spacing 24
            , Ui.borderColor MyUi.border1
            , Ui.border 1
            ]
            (Ui.row
                [ Ui.spacing 16, Ui.contentCenterY ]
                [ Ui.el [ Ui.Font.bold, Ui.Font.size 20 ] (Ui.text "Call recording")
                , MyUi.elButton
                    (Dom.id "callRecording_close")
                    PressedClose
                    [ Ui.alignRight, Ui.width Ui.shrink, Ui.Font.color MyUi.font3 ]
                    (Ui.html Icons.x)
                ]
                :: List.map
                    (recordingView timezone currentUserId allUsers model (Call.toSharedCallId currentUserId (callId model)))
                    recordings
            )
        )


recordingView :
    Time.Zone
    -> Id UserId
    -> SeqDict (Id UserId) FrontendUser
    -> Model
    -> Call.SharedCallId
    -> CallRecording (Id UserId)
    -> Element Msg
recordingView timezone currentUserId allUsers model sharedCallId recording =
    let
        recordingId : String
        recordingId =
            Call.recordingIdToString sharedCallId recording.startedAt

        userName : Id UserId -> String
        userName userId =
            User.toString userId allUsers

        isParticipant : Bool
        isParticipant =
            NonemptySet.member currentUserId recording.participants

        nothingYet : List (Id UserId)
        nothingYet =
            List.filter
                (\userId -> not (List.any (\file -> file.recordedBy == userId) recording.files))
                (NonemptySet.toList recording.participants)

        uploaded : List (CallRecordingFile (Id UserId))
        uploaded =
            List.filter (\file -> file.uploaded >= file.size) recording.files
    in
    Ui.column
        [ Ui.spacing 12 ]
        [ Ui.el
            [ Ui.Font.bold ]
            (Ui.text
                ("Recorded "
                    ++ MyUi.datestamp timezone recording.startedAt
                    ++ " "
                    ++ MyUi.timestamp recording.startedAt timezone
                    ++ (case recording.endedAt of
                            Just endedAt ->
                                ", lasted " ++ MyUi.timeElapsed recording.startedAt endedAt

                            Nothing ->
                                ", still recording"
                       )
                )
            )
        , Ui.Prose.paragraph
            [ Ui.Font.color MyUi.font3 ]
            [ Ui.text
                ("Agreed to be recorded: "
                    ++ String.join ", " (List.map userName (NonemptySet.toList recording.participants))
                )
            ]
        , case recording.deletedBy of
            Just deletedBy ->
                Ui.el [ Ui.Font.color MyUi.font3 ] (Ui.text ("Deleted by " ++ userName deletedBy))

            Nothing ->
                if isParticipant then
                    Ui.column
                        [ Ui.spacing 8 ]
                        (List.map
                            (\( file, downloadName ) -> fileView recordingId userName file downloadName)
                            (fileNames userName recording.files)
                            ++ List.map
                                (\userId ->
                                    Ui.el
                                        [ Ui.Font.color MyUi.font3 ]
                                        (Ui.text ("Nothing from " ++ userName userId ++ " yet. It uploads once they've left the call."))
                                )
                                nothingYet
                        )

                else
                    Ui.el
                        [ Ui.Font.color MyUi.font3 ]
                        (Ui.text "Only people who were in the recording can download it.")
        , case ( recording.deletedBy, isParticipant ) of
            ( Nothing, True ) ->
                Ui.row
                    [ Ui.spacing 16 ]
                    [ if List.isEmpty uploaded then
                        Ui.none

                      else
                        Ui.el
                            [ Ui.download (zipUrl recordingId (zipName timezone recording.startedAt))
                            , Ui.id ("callRecording_downloadAll_" ++ String.fromInt (Time.posixToMillis recording.startedAt))
                            , Ui.borderColor MyUi.buttonBorder
                            , Ui.border 1
                            , Ui.background MyUi.buttonBackground
                            , Ui.rounded 4
                            , Ui.width Ui.shrink
                            , Ui.paddingXY 16 8
                            , Ui.Font.weight 500
                            , Ui.Font.color MyUi.white
                            ]
                            (Ui.text "Download all")
                    , if model.confirmDelete == Just recording.startedAt then
                        Ui.row
                            [ Ui.spacing 8, Ui.alignRight, Ui.width Ui.shrink ]
                            [ MyUi.secondaryButtonTall (Dom.id "callRecording_cancelDelete") PressedCancelDelete "Keep it"
                            , MyUi.elButton
                                (Dom.id "callRecording_confirmDelete")
                                (PressedConfirmDelete recording.startedAt)
                                [ Ui.background MyUi.deleteButtonBackground
                                , Ui.border 1
                                , Ui.borderColor MyUi.deleteButtonBorder
                                , Ui.Font.color MyUi.deleteButtonFont
                                , Ui.rounded 4
                                , Ui.width Ui.shrink
                                , Ui.paddingXY 16 8
                                , Ui.Font.weight 500
                                ]
                                (Ui.text "Delete it for everyone")
                            ]

                      else
                        MyUi.secondaryButtonTall
                            (Dom.id "callRecording_delete")
                            (PressedDelete recording.startedAt)
                            "Delete recording"
                    ]

            _ ->
                Ui.none
        ]


fileView : String -> (Id UserId -> String) -> CallRecordingFile (Id UserId) -> String -> Element msg
fileView recordingId userName file downloadName =
    let
        details : String
        details =
            userName file.recordedBy
                ++ " · "
                ++ MyUi.timeElapsed file.startedAt file.endedAt
                ++ " · "
                ++ (if file.uploaded >= file.size then
                        FileStatus.sizeToString file.size

                    else
                        "uploading, "
                            ++ String.fromInt ((file.uploaded * 100) // file.size)
                            ++ "% of "
                            ++ FileStatus.sizeToString file.size
                   )
    in
    Ui.column
        [ Ui.spacing 2 ]
        [ if file.uploaded >= file.size then
            Ui.el
                [ Ui.download (fileUrl recordingId file)
                , Ui.Font.color MyUi.font1
                , Ui.Font.underline
                , MyUi.htmlStyle "word-break" "break-all"
                ]
                (Ui.text downloadName)

          else
            Ui.el [ MyUi.htmlStyle "word-break" "break-all" ] (Ui.text downloadName)
        , Ui.el [ Ui.Font.size 14, Ui.Font.color MyUi.font3 ] (Ui.text details)
        ]


fileUrl : String -> CallRecordingFile (Id UserId) -> String
fileUrl recordingId file =
    FileStatus.domain
        ++ "/file/recording/"
        ++ recordingId
        ++ "/"
        ++ Id.toString file.recordedBy
        ++ "/"
        ++ Url.percentEncode file.name


zipUrl : String -> String -> String
zipUrl recordingId name =
    FileStatus.domain ++ "/file/recording-zip/" ++ recordingId ++ "?name=" ++ Url.percentEncode name


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
