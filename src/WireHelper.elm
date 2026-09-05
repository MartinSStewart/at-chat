module WireHelper exposing
    ( decodeStreamedBackendModel
    , encodeBackendModel
    , encodeDiscordDmChannel
    , encodeDiscordGuildChannel
    , encodeDiscordGuildHeader
    , encodeDmChannel
    , encodeGuildChannel
    , encodeGuildHeader
    , foldStreamedBackendModel
    )

{-| These functions are in a separate module because Intellij flags w3\_\* functions as missing and that's annoying to look at while doing other stuff.
-}

import Bytes
import Bytes.Decode exposing (Decoder)
import Bytes.Encode exposing (Encoder)
import Discord
import DmChannel
import DmChannelId exposing (DmChannelId)
import Id exposing (ChannelId, GuildId, Id)
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


{-| A guild is written as this header followed by one encoding per channel, so
that encoding a guild can be spread over as many steps as it has channels. The
header carries the guild with its channels emptied out, then the number of
channel encodings that follow it.
-}
encodeGuildHeader : ( Id GuildId, LocalState.BackendGuild ) -> Encoder
encodeGuildHeader ( key, value ) =
    Bytes.Encode.sequence
        [ Id.w3_encode_Id Lamdera.Wire3.failEncode key
        , LocalState.w3_encode_BackendGuild { value | channels = SeqDict.empty }
        , Bytes.Encode.unsignedInt32 Bytes.BE (SeqDict.size value.channels)
        ]


encodeGuildChannel : ( Id ChannelId, LocalState.BackendChannel ) -> Encoder
encodeGuildChannel ( key, value ) =
    Bytes.Encode.sequence
        [ Id.w3_encode_Id Lamdera.Wire3.failEncode key
        , LocalState.w3_encode_BackendChannel value
        ]


decodeGuild : Decoder ( Id GuildId, LocalState.BackendGuild )
decodeGuild =
    Bytes.Decode.map3
        (\key value channels -> ( key, { value | channels = SeqDict.fromList channels } ))
        (Id.w3_decode_Id Lamdera.Wire3.failDecode)
        LocalState.w3_decode_BackendGuild
        (decodeLengthPrefixedList decodeGuildChannel)


decodeGuildChannel : Decoder ( Id ChannelId, LocalState.BackendChannel )
decodeGuildChannel =
    Bytes.Decode.map2 Tuple.pair
        (Id.w3_decode_Id Lamdera.Wire3.failDecode)
        LocalState.w3_decode_BackendChannel


encodeDmChannel : ( DmChannelId, DmChannel.BackendDmChannel ) -> Encoder
encodeDmChannel ( key, value ) =
    Bytes.Encode.sequence
        [ DmChannelId.w3_encode_DmChannelId key
        , DmChannel.w3_encode_BackendDmChannel value
        ]


decodeDmChannel : Decoder ( DmChannelId, DmChannel.BackendDmChannel )
decodeDmChannel =
    Bytes.Decode.map2 Tuple.pair
        DmChannelId.w3_decode_DmChannelId
        DmChannel.w3_decode_BackendDmChannel


{-| Written the same way `encodeGuildHeader` writes a guild: the guild without
its channels, the number of channels, and then one encoding per channel.
-}
encodeDiscordGuildHeader : ( Discord.Id Discord.GuildId, LocalState.DiscordBackendGuild ) -> Encoder
encodeDiscordGuildHeader ( key, value ) =
    Bytes.Encode.sequence
        [ Discord.w3_encode_Id Lamdera.Wire3.failEncode key
        , LocalState.w3_encode_DiscordBackendGuild { value | channels = SeqDict.empty }
        , Bytes.Encode.unsignedInt32 Bytes.BE (SeqDict.size value.channels)
        ]


encodeDiscordGuildChannel : ( Discord.Id Discord.ChannelId, LocalState.DiscordBackendChannel ) -> Encoder
encodeDiscordGuildChannel ( key, value ) =
    Bytes.Encode.sequence
        [ Discord.w3_encode_Id Lamdera.Wire3.failEncode key
        , LocalState.w3_encode_DiscordBackendChannel value
        ]


decodeDiscordGuild : Decoder ( Discord.Id Discord.GuildId, LocalState.DiscordBackendGuild )
decodeDiscordGuild =
    Bytes.Decode.map3
        (\key value channels -> ( key, { value | channels = SeqDict.fromList channels } ))
        (Discord.w3_decode_Id Lamdera.Wire3.failDecode)
        LocalState.w3_decode_DiscordBackendGuild
        (decodeLengthPrefixedList decodeDiscordGuildChannel)


decodeDiscordGuildChannel : Decoder ( Discord.Id Discord.ChannelId, LocalState.DiscordBackendChannel )
decodeDiscordGuildChannel =
    Bytes.Decode.map2 Tuple.pair
        (Discord.w3_decode_Id Lamdera.Wire3.failDecode)
        LocalState.w3_decode_DiscordBackendChannel


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


{-| Reads the same format as `decodeStreamedBackendModel`, but hands each guild
and DM channel to a fold function as it is decoded instead of collecting them
all.

A backup expands to more than twenty times its file size once it has been decoded
into a `BackendModel`, so anything that only needs a part of one should fold it
away here rather than decode the whole thing and pick through it afterwards. Only
one guild is alive at a time, and `init` is the chance to keep whatever is needed
from the rest of the model before that is dropped too. A fold function that hangs
on to what it is handed gives up that guarantee, so it should keep a bounded
amount.

-}
foldStreamedBackendModel :
    { init : BackendModel -> state
    , guild : ( Id GuildId, LocalState.BackendGuild ) -> state -> state
    , dmChannel : ( DmChannelId, DmChannel.BackendDmChannel ) -> state -> state
    , discordGuild : ( Discord.Id Discord.GuildId, LocalState.DiscordBackendGuild ) -> state -> state
    , discordDmChannel : ( Discord.Id Discord.PrivateChannelId, DmChannel.DiscordDmChannel ) -> state -> state
    }
    -> Decoder state
foldStreamedBackendModel config =
    Bytes.Decode.map config.init decodeBackendModel
        |> Bytes.Decode.andThen (foldLengthPrefixedList decodeGuild config.guild)
        |> Bytes.Decode.andThen (foldLengthPrefixedList decodeDmChannel config.dmChannel)
        |> Bytes.Decode.andThen (foldLengthPrefixedList decodeDiscordGuild config.discordGuild)
        |> Bytes.Decode.andThen (foldLengthPrefixedList decodeDiscordDmChannel config.discordDmChannel)


decodeLengthPrefixedList : Decoder a -> Decoder (List a)
decodeLengthPrefixedList itemDecoder =
    foldLengthPrefixedList itemDecoder (::) [] |> Bytes.Decode.map List.reverse


foldLengthPrefixedList : Decoder a -> (a -> state -> state) -> state -> Decoder state
foldLengthPrefixedList itemDecoder func state =
    Bytes.Decode.unsignedInt32 Bytes.BE
        |> Bytes.Decode.andThen
            (\count ->
                Bytes.Decode.loop
                    ( count, state )
                    (\( remaining, state2 ) ->
                        if remaining > 0 then
                            Bytes.Decode.map
                                (\item -> Bytes.Decode.Loop ( remaining - 1, func item state2 ))
                                itemDecoder

                        else
                            Bytes.Decode.succeed (Bytes.Decode.Done state2)
                    )
            )
