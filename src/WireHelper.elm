module WireHelper exposing
    ( decodeStreamedBackendModel
    , encodeBackendModel
    , encodeDiscordDmChannel
    , encodeDiscordGuild
    , encodeDmChannel
    , encodeGuild
    )

{-| These functions are in a separate module because Intellij flags w3\_\* functions as missing and that's annoying to look at while doing other stuff.
-}

import Bytes
import Bytes.Decode exposing (Decoder)
import Bytes.Encode exposing (Encoder)
import Discord
import DmChannel
import Id exposing (GuildId, Id)
import Lamdera.Wire3
import LocalState
import SeqDict
import Types exposing (BackendModel)


encodeBackendModel : BackendModel -> Encoder
encodeBackendModel =
    Types.w3_encode_BackendModel


decodeBackendModel : Decoder BackendModel
decodeBackendModel =
    Types.w3_decode_BackendModel


encodeGuild : ( Id GuildId, LocalState.BackendGuild ) -> Encoder
encodeGuild ( key, value ) =
    Bytes.Encode.sequence
        [ Id.w3_encode_Id Lamdera.Wire3.failEncode key
        , LocalState.w3_encode_BackendGuild value
        ]


decodeGuild : Decoder ( Id GuildId, LocalState.BackendGuild )
decodeGuild =
    Bytes.Decode.map2 Tuple.pair
        (Id.w3_decode_Id Lamdera.Wire3.failDecode)
        LocalState.w3_decode_BackendGuild


encodeDmChannel : ( DmChannel.DmChannelId, DmChannel.DmChannel ) -> Encoder
encodeDmChannel ( key, value ) =
    Bytes.Encode.sequence
        [ DmChannel.w3_encode_DmChannelId key
        , DmChannel.w3_encode_DmChannel value
        ]


decodeDmChannel : Decoder ( DmChannel.DmChannelId, DmChannel.DmChannel )
decodeDmChannel =
    Bytes.Decode.map2 Tuple.pair
        DmChannel.w3_decode_DmChannelId
        DmChannel.w3_decode_DmChannel


encodeDiscordGuild : ( Discord.Id Discord.GuildId, LocalState.DiscordBackendGuild ) -> Encoder
encodeDiscordGuild ( key, value ) =
    Bytes.Encode.sequence
        [ Discord.w3_encode_Id Lamdera.Wire3.failEncode key
        , LocalState.w3_encode_DiscordBackendGuild value
        ]


decodeDiscordGuild : Decoder ( Discord.Id Discord.GuildId, LocalState.DiscordBackendGuild )
decodeDiscordGuild =
    Bytes.Decode.map2 Tuple.pair
        (Discord.w3_decode_Id Lamdera.Wire3.failDecode)
        LocalState.w3_decode_DiscordBackendGuild


encodeDiscordDmChannel : ( Discord.Id Discord.PrivateChannelId, DmChannel.DiscordDmChannel ) -> Encoder
encodeDiscordDmChannel ( key, value ) =
    Bytes.Encode.sequence
        [ Discord.w3_encode_Id Lamdera.Wire3.failEncode key
        , DmChannel.w3_encode_DiscordDmChannel value
        ]


decodeDiscordDmChannel : Decoder ( Discord.Id Discord.PrivateChannelId, DmChannel.DiscordDmChannel )
decodeDiscordDmChannel =
    Bytes.Decode.map2 Tuple.pair
        (Discord.w3_decode_Id Lamdera.Wire3.failDecode)
        DmChannel.w3_decode_DiscordDmChannel


decodeStreamedBackendModel : Decoder BackendModel
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
        (decodeLengthPrefixedList decodeGuild)
        (decodeLengthPrefixedList decodeDmChannel)
        (decodeLengthPrefixedList decodeDiscordGuild)
        (decodeLengthPrefixedList decodeDiscordDmChannel)


decodeLengthPrefixedList : Decoder a -> Decoder (List a)
decodeLengthPrefixedList itemDecoder =
    Bytes.Decode.unsignedInt32 Bytes.BE
        |> Bytes.Decode.andThen
            (\count ->
                Bytes.Decode.loop
                    ( count, [] )
                    (\( remaining, acc ) ->
                        if remaining > 0 then
                            Bytes.Decode.map (\item -> Bytes.Decode.Loop ( remaining - 1, item :: acc )) itemDecoder

                        else
                            Bytes.Decode.succeed (Bytes.Decode.Done (List.reverse acc))
                    )
            )
