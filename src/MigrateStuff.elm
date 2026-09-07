module MigrateStuff exposing (Msg(..), main)

import Backend
import Browser
import Bytes exposing (Bytes)
import Bytes.Decode exposing (Decoder)
import Bytes.Encode
import Evergreen.V368.Discord
import Evergreen.V368.DmChannel
import Evergreen.V368.DmChannelId
import Evergreen.V368.Id
import Evergreen.V368.LocalState
import Evergreen.V368.Types
import File.Download
import Html
import Html.Attributes
import Html.Events
import Http
import Lamdera.Wire3
import MyUi
import SeqDict
import Task
import Time
import Types exposing (ExportStep(..))


type Msg
    = LoadedData (Result String Bytes)
    | PressedDownload


main : Program () (Result String Bytes) Msg
main =
    Browser.element
        { init =
            \_ ->
                ( Err "Loading..."
                , Http.task
                    { method = "GET"
                    , url =
                        "/backend-export (13).bin"

                    --"/backend-export-2026-09-05-14:34:56.bin"
                    , headers = []
                    , body = Http.emptyBody
                    , resolver =
                        Http.bytesResolver
                            (\response ->
                                case response of
                                    Http.BadStatus_ _ _ ->
                                        Err ""

                                    Http.GoodStatus_ _ bytes ->
                                        let
                                            _ =
                                                Debug.log "asd2f" ""
                                        in
                                        case Bytes.Decode.decode decodeStreamedBackendModel bytes of
                                            Just _ ->
                                                let
                                                    _ =
                                                        Debug.log "asdf" ""

                                                    bytes2 : Bytes
                                                    bytes2 =
                                                        Bytes.Encode.sequence [] |> Bytes.Encode.encode

                                                    --Evergreen.Migrate.V368.migrate_Types_BackendModel backendModel
                                                    --    |> Evergreen.V368.Types.w3_encode_BackendModel
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
                                                        Err "Failed to decode 2"

                                            Nothing ->
                                                let
                                                    _ =
                                                        Debug.log "asdf3" ""
                                                in
                                                Err "Failed to decode"

                                    Http.BadUrl_ _ ->
                                        Err ""

                                    Http.Timeout_ ->
                                        Err ""

                                    Http.NetworkError_ ->
                                        Err ""
                            )
                    , timeout = Just 60000
                    }
                    |> Task.attempt LoadedData
                )
        , update =
            \msg model ->
                case msg of
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
                case result of
                    Ok _ ->
                        Html.button [ Html.Events.onClick PressedDownload ] [ Html.text "Download" ]

                    Err error ->
                        Html.div [ Html.Attributes.style "color" (MyUi.colorToStyle MyUi.font1) ] [ Html.text error ]
        , subscriptions = \_ -> Sub.none
        }


decodeBackendModel : Decoder Evergreen.V368.Types.BackendModel
decodeBackendModel =
    Evergreen.V368.Types.w3_decode_BackendModel


decodeGuild : Decoder ( Evergreen.V368.Id.Id a, Evergreen.V368.LocalState.BackendGuild )
decodeGuild =
    Bytes.Decode.map3
        (\key value channels -> ( key, { value | channels = SeqDict.fromList channels } ))
        (Evergreen.V368.Id.w3_decode_Id Lamdera.Wire3.failDecode)
        Evergreen.V368.LocalState.w3_decode_BackendGuild
        (decodeLengthPrefixedList "Guild channel" decodeGuildChannel)


decodeGuildChannel : Decoder ( Evergreen.V368.Id.Id a, Evergreen.V368.LocalState.BackendChannel )
decodeGuildChannel =
    Bytes.Decode.map2 Tuple.pair
        (Evergreen.V368.Id.w3_decode_Id Lamdera.Wire3.failDecode)
        Evergreen.V368.LocalState.w3_decode_BackendChannel


decodeDmChannel : Decoder ( Evergreen.V368.DmChannelId.DmChannelId, Evergreen.V368.DmChannel.BackendDmChannel )
decodeDmChannel =
    Bytes.Decode.map2 Tuple.pair
        Evergreen.V368.DmChannelId.w3_decode_DmChannelId
        Evergreen.V368.DmChannel.w3_decode_BackendDmChannel


decodeDiscordGuild : Decoder ( Evergreen.V368.Discord.Id a, Evergreen.V368.LocalState.DiscordBackendGuild )
decodeDiscordGuild =
    Bytes.Decode.map3
        (\key value channels -> ( key, { value | channels = SeqDict.fromList channels } ))
        (Evergreen.V368.Discord.w3_decode_Id Lamdera.Wire3.failDecode)
        Evergreen.V368.LocalState.w3_decode_DiscordBackendGuild
        (decodeLengthPrefixedList "DiscordGuild channel" decodeDiscordGuildChannel)


decodeDiscordGuildChannel : Decoder ( Evergreen.V368.Discord.Id a, Evergreen.V368.LocalState.DiscordBackendChannel )
decodeDiscordGuildChannel =
    Bytes.Decode.map2 Tuple.pair
        (Evergreen.V368.Discord.w3_decode_Id Lamdera.Wire3.failDecode)
        (Evergreen.V368.LocalState.w3_decode_DiscordBackendChannel |> Bytes.Decode.map (Debug.log "channel"))


decodeDiscordDmChannel : Decoder ( Evergreen.V368.Discord.Id Evergreen.V368.Discord.PrivateChannelId, Evergreen.V368.DmChannel.DiscordDmChannel )
decodeDiscordDmChannel =
    Bytes.Decode.map2 Tuple.pair
        (Evergreen.V368.Discord.w3_decode_Id Lamdera.Wire3.failDecode)
        Evergreen.V368.DmChannel.w3_decode_DiscordDmChannel


decodeStreamedBackendModel : Decoder Evergreen.V368.Types.BackendModel
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
