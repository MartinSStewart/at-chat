module MigrateStuff exposing (Msg(..), main)

import Backend
import Browser
import Bytes exposing (Bytes)
import Bytes.Decode exposing (Decoder)
import Bytes.Encode
import Discord
import DmChannel
import DmChannelId
import File exposing (File)
import File.Download
import File.Select
import Html
import Html.Attributes
import Html.Events
import Http
import Id
import Lamdera.Wire3
import LocalState
import MyUi
import SeqDict
import Task
import Time
import Types exposing (ExportStep(..))


type Msg
    = GotFile File
    | PressedSelectBackup
    | LoadedData (Result String Bytes)
    | PressedDownload


main : Program () (Result String Bytes) Msg
main =
    Browser.element
        { init = \_ -> ( Err "", Cmd.none )
        , update =
            \msg model ->
                case msg of
                    PressedSelectBackup ->
                        ( model, File.Select.file [ "application/octet-stream" ] GotFile )

                    GotFile file ->
                        ( Err "Loading..."
                        , File.toBytes file
                            |> Task.map
                                (\bytes ->
                                    case Bytes.Decode.decode decodeStreamedBackendModel bytes of
                                        Just asdf ->
                                            let
                                                _ =
                                                    Debug.log "asdf" asdf

                                                bytes2 : Bytes
                                                bytes2 =
                                                    Bytes.Encode.sequence [] |> Bytes.Encode.encode

                                                --Evergreen.Migrate.V392.migrate_Types_BackendModel backendModel
                                                --    |> Types.w3_encode_BackendModel
                                                --    |> Bytes.Encode.encode
                                            in
                                            case Bytes.Decode.decode Types.w3_decode_BackendModel bytes2 of
                                                Just backendModel3 ->
                                                    let
                                                        backendModel4 =
                                                            Backend.startExport (Time.millisToPosix 0) backendModel3

                                                        exportHelper export =
                                                            case Backend.handleExportBackendStep export of
                                                                ExportFinished bytes3 ->
                                                                    Ok bytes3

                                                                ExportInProgress _ export2 ->
                                                                    exportHelper export2
                                                    in
                                                    case backendModel4.scheduledExportState of
                                                        Just exportState ->
                                                            exportHelper exportState

                                                        Nothing ->
                                                            Err "Failed to export"

                                                Nothing ->
                                                    Err "Decoded streamed backend model but failed on next step"

                                        Nothing ->
                                            let
                                                _ =
                                                    Debug.log "asdf3" ""
                                            in
                                            Err "Failed to decode"
                                )
                            |> Task.perform LoadedData
                        )

                    LoadedData result ->
                        ( result, Cmd.none )

                    PressedDownload ->
                        case model of
                            Ok bytes ->
                                ( model, File.Download.bytes "migrated.bin" "application/octet-stream" bytes )

                            Err _ ->
                                ( model, Cmd.none )
        , view =
            \result ->
                Html.div
                    []
                    [ Html.button [ Html.Events.onClick PressedSelectBackup ] [ Html.text "Select backup" ]
                    , case result of
                        Ok _ ->
                            Html.button [ Html.Events.onClick PressedDownload ] [ Html.text "Download" ]

                        Err error ->
                            Html.div [ Html.Attributes.style "color" (MyUi.colorToStyle MyUi.font1) ] [ Html.text error ]
                    ]
        , subscriptions = \_ -> Sub.none
        }


decodeBackendModel : Decoder Types.BackendModel
decodeBackendModel =
    Types.w3_decode_BackendModel


decodeGuild : Decoder ( Id.Id a, LocalState.BackendGuild )
decodeGuild =
    Bytes.Decode.map3
        (\key value channels -> ( key, { value | channels = SeqDict.fromList channels } ))
        (Id.w3_decode_Id Lamdera.Wire3.failDecode)
        LocalState.w3_decode_BackendGuild
        (decodeLengthPrefixedList "Guild channel" decodeGuildChannel)


decodeGuildChannel : Decoder ( Id.Id a, LocalState.BackendChannel )
decodeGuildChannel =
    Bytes.Decode.map2 Tuple.pair
        (Id.w3_decode_Id Lamdera.Wire3.failDecode)
        LocalState.w3_decode_BackendChannel


decodeDmChannel : Decoder ( DmChannelId.DmChannelId, DmChannel.BackendDmChannel )
decodeDmChannel =
    Bytes.Decode.map2 Tuple.pair
        DmChannelId.w3_decode_DmChannelId
        DmChannel.w3_decode_BackendDmChannel


decodeDiscordGuild : Decoder ( Discord.Id a, LocalState.DiscordBackendGuild )
decodeDiscordGuild =
    Bytes.Decode.map3
        (\key value channels -> ( key, { value | channels = SeqDict.fromList channels } ))
        (Discord.w3_decode_Id Lamdera.Wire3.failDecode)
        LocalState.w3_decode_DiscordBackendGuild
        (decodeLengthPrefixedList "DiscordGuild channel" decodeDiscordGuildChannel)


decodeDiscordGuildChannel : Decoder ( Discord.Id a, LocalState.DiscordBackendChannel )
decodeDiscordGuildChannel =
    Bytes.Decode.map2 Tuple.pair
        (Discord.w3_decode_Id Lamdera.Wire3.failDecode)
        (LocalState.w3_decode_DiscordBackendChannel |> Bytes.Decode.map (Debug.log "channel"))


decodeDiscordDmChannel : Decoder ( Discord.Id Discord.PrivateChannelId, DmChannel.DiscordDmChannel )
decodeDiscordDmChannel =
    Bytes.Decode.map2 Tuple.pair
        (Discord.w3_decode_Id Lamdera.Wire3.failDecode)
        DmChannel.w3_decode_DiscordDmChannel


decodeStreamedBackendModel : Decoder Types.BackendModel
decodeStreamedBackendModel =
    Bytes.Decode.map5
        (\baseModel guilds dmChannels discordGuilds discordDmChannels ->
            { baseModel
                | guilds = SeqDict.fromList guilds
                , dmChannels = SeqDict.fromList dmChannels
                , discordGuilds = SeqDict.fromList discordGuilds
                , discordDmChannels = SeqDict.fromList discordDmChannels
            }
        )
        decodeBackendModel
        (decodeLengthPrefixedList "Guild" decodeGuild)
        (decodeLengthPrefixedList "DmChannel" decodeDmChannel)
        (decodeLengthPrefixedList "DiscordGuild" decodeDiscordGuild)
        (decodeLengthPrefixedList "DiscordDmChannel" decodeDiscordDmChannel)


decodeLengthPrefixedList : String -> Decoder a -> Decoder (List a)
decodeLengthPrefixedList name itemDecoder =
    Bytes.Decode.unsignedInt32 Bytes.BE
        |> Bytes.Decode.andThen
            (\count ->
                let
                    _ =
                        Debug.log (name ++ " count") count
                in
                Bytes.Decode.loop
                    ( count, [] )
                    (\( remaining, acc ) ->
                        if remaining > 0 then
                            Bytes.Decode.map (\item -> Bytes.Decode.Loop ( remaining - 1, item :: acc )) itemDecoder

                        else
                            Bytes.Decode.succeed (Bytes.Decode.Done (List.reverse acc))
                    )
            )
