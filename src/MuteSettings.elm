module MuteSettings exposing
    ( IsMuted(..)
    , Model
    , MutedChannel
    , MutedDiscordGuild
    , MutedGuild
    , init
    , isChannelMuted
    , isChannelSpecificallyMuted
    , isDiscordChannelMuted
    , isDiscordChannelSpecificallyMuted
    , isDiscordDmMuted
    , isDiscordGuildSpecificallyMute
    , isDiscordThreadSpecificallyMuted
    , isDmMuted
    , isGuildSpecificallyMute
    , isThreadSpecificallyMuted
    , setMuteChannel
    , setMuteDiscordChannel
    , setMuteDiscordGuild
    , setMuteDiscordThread
    , setMuteGuild
    , setMuteThread
    , view
    )

import Discord
import Effect.Browser.Dom as Dom
import Icons
import Id exposing (ChannelId, ChannelMessageId, GuildId, Id, ThreadRoute(..), UserId)
import MyUi
import SeqDict exposing (SeqDict)
import Ui exposing (Element)


type alias Model =
    { mutedGuilds : SeqDict (Id GuildId) MutedGuild
    , mutedDms : SeqDict (Id UserId) MutedChannel
    , mutedDiscordGuilds : SeqDict (Discord.Id Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqDict (Discord.Id Discord.PrivateChannelId) IsMuted
    }


type IsMuted
    = IsNotMuted
    | IsPartiallyMuted
    | IsFullyMuted


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict (Id ChannelId) MutedChannel
    }


type alias MutedChannel =
    { mutedChannel : IsMuted, mutedThreads : SeqDict (Id ChannelMessageId) IsMuted }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict (Discord.Id Discord.ChannelId) MutedChannel
    }


init : Model
init =
    { mutedGuilds = SeqDict.empty
    , mutedDms = SeqDict.empty
    , mutedDiscordGuilds = SeqDict.empty
    , mutedDiscordDms = SeqDict.empty
    }


view : (IsMuted -> msg) -> IsMuted -> Element msg
view onPress isMuted =
    MyUi.radioColumn
        (Dom.id "guild_muteChannel")
        onPress
        (Just isMuted)
        (Ui.row [ Ui.spacing 8 ]
            [ Ui.text "Mute notifications"
            , case isMuted of
                IsNotMuted ->
                    Ui.html Icons.bell

                IsPartiallyMuted ->
                    Ui.html Icons.bellSlash

                IsFullyMuted ->
                    Ui.html Icons.bellDoubleSlash
            ]
        )
        [ ( IsNotMuted, "Not muted" )
        , ( IsPartiallyMuted, "Partial mute (hide white dot)" )
        , ( IsFullyMuted, "Fully muted (hide red/white dot)" )
        ]


setMuteGuild : Id GuildId -> IsMuted -> Model -> Model
setMuteGuild guildId isMuted model =
    { model
        | mutedGuilds =
            SeqDict.update
                guildId
                (\maybeGuild ->
                    { mutedGuild = isMuted
                    , channels =
                        case maybeGuild of
                            Just guild ->
                                guild.channels

                            Nothing ->
                                SeqDict.empty
                    }
                        |> Just
                )
                model.mutedGuilds
    }


setMuteDiscordGuild : Discord.Id Discord.GuildId -> IsMuted -> Model -> Model
setMuteDiscordGuild guildId isMuted model =
    { model
        | mutedDiscordGuilds =
            SeqDict.update
                guildId
                (\maybeGuild ->
                    { mutedGuild = isMuted
                    , channels =
                        case maybeGuild of
                            Just guild ->
                                guild.channels

                            Nothing ->
                                SeqDict.empty
                    }
                        |> Just
                )
                model.mutedDiscordGuilds
    }


setMuteChannel : Id GuildId -> Id ChannelId -> IsMuted -> Model -> Model
setMuteChannel guildId channelId isMuted model =
    updateMutedChannel guildId channelId (\channel -> { channel | mutedChannel = isMuted }) model


setMuteThread : Id GuildId -> Id ChannelId -> Id ChannelMessageId -> IsMuted -> Model -> Model
setMuteThread guildId channelId threadId isMuted model =
    updateMutedChannel
        guildId
        channelId
        (\channel ->
            { channel
                | mutedThreads =
                    case isMuted of
                        IsNotMuted ->
                            SeqDict.remove threadId channel.mutedThreads

                        _ ->
                            SeqDict.insert threadId isMuted channel.mutedThreads
            }
        )
        model


setMuteDiscordChannel : Discord.Id Discord.GuildId -> Discord.Id Discord.ChannelId -> IsMuted -> Model -> Model
setMuteDiscordChannel guildId channelId isMuted model =
    updateMutedDiscordChannel guildId channelId (\channel -> { channel | mutedChannel = isMuted }) model


setMuteDiscordThread :
    Discord.Id Discord.GuildId
    -> Discord.Id Discord.ChannelId
    -> Id ChannelMessageId
    -> IsMuted
    -> Model
    -> Model
setMuteDiscordThread guildId channelId threadId isMuted model =
    updateMutedDiscordChannel
        guildId
        channelId
        (\channel ->
            { channel
                | mutedThreads =
                    case isMuted of
                        IsNotMuted ->
                            SeqDict.remove threadId channel.mutedThreads

                        _ ->
                            SeqDict.insert threadId isMuted channel.mutedThreads
            }
        )
        model


updateMutedChannel : Id GuildId -> Id ChannelId -> (MutedChannel -> MutedChannel) -> Model -> Model
updateMutedChannel guildId channelId updateFunc model =
    { model
        | mutedGuilds =
            SeqDict.update
                guildId
                (\maybeGuild ->
                    let
                        guild : MutedGuild
                        guild =
                            Maybe.withDefault { mutedGuild = IsNotMuted, channels = SeqDict.empty } maybeGuild
                    in
                    { guild
                        | channels =
                            SeqDict.update
                                channelId
                                (\maybeChannel ->
                                    Maybe.withDefault { mutedChannel = IsNotMuted, mutedThreads = SeqDict.empty } maybeChannel
                                        |> updateFunc
                                        |> Just
                                )
                                guild.channels
                    }
                        |> Just
                )
                model.mutedGuilds
    }


updateMutedDiscordChannel :
    Discord.Id Discord.GuildId
    -> Discord.Id Discord.ChannelId
    -> (MutedChannel -> MutedChannel)
    -> Model
    -> Model
updateMutedDiscordChannel guildId channelId updateFunc model =
    { model
        | mutedDiscordGuilds =
            SeqDict.update
                guildId
                (\maybeGuild ->
                    let
                        guild : MutedDiscordGuild
                        guild =
                            Maybe.withDefault { mutedGuild = IsNotMuted, channels = SeqDict.empty } maybeGuild
                    in
                    { guild
                        | channels =
                            SeqDict.update
                                channelId
                                (\maybeChannel ->
                                    Maybe.withDefault { mutedChannel = IsNotMuted, mutedThreads = SeqDict.empty } maybeChannel
                                        |> updateFunc
                                        |> Just
                                )
                                guild.channels
                    }
                        |> Just
                )
                model.mutedDiscordGuilds
    }


isGuildSpecificallyMute : Model -> Id GuildId -> IsMuted
isGuildSpecificallyMute model guildId =
    case SeqDict.get guildId model.mutedGuilds of
        Just guild ->
            guild.mutedGuild

        Nothing ->
            IsNotMuted


isChannelSpecificallyMuted : Model -> Id GuildId -> Id ChannelId -> IsMuted
isChannelSpecificallyMuted model guildId channelId =
    case SeqDict.get guildId model.mutedGuilds of
        Just guild ->
            case SeqDict.get channelId guild.channels of
                Just channel ->
                    channel.mutedChannel

                Nothing ->
                    IsNotMuted

        Nothing ->
            IsNotMuted


isThreadSpecificallyMuted : Model -> Id GuildId -> Id ChannelId -> Id ChannelMessageId -> IsMuted
isThreadSpecificallyMuted model guildId channelId threadId =
    case SeqDict.get guildId model.mutedGuilds of
        Just guild ->
            case SeqDict.get channelId guild.channels of
                Just channel ->
                    SeqDict.get threadId channel.mutedThreads |> Maybe.withDefault IsNotMuted

                Nothing ->
                    IsNotMuted

        Nothing ->
            IsNotMuted


isChannelMuted : Model -> Id GuildId -> Id ChannelId -> ThreadRoute -> IsMuted
isChannelMuted model guildId channelId threadRoute =
    case SeqDict.get guildId model.mutedGuilds of
        Just guild ->
            case SeqDict.get channelId guild.channels of
                Just channel ->
                    strongest guild.mutedGuild (channelOrThreadMuted threadRoute channel)

                Nothing ->
                    guild.mutedGuild

        Nothing ->
            IsNotMuted


channelOrThreadMuted : ThreadRoute -> MutedChannel -> IsMuted
channelOrThreadMuted threadRoute channel =
    case threadRoute of
        NoThread ->
            channel.mutedChannel

        ViewThread threadId ->
            SeqDict.get threadId channel.mutedThreads
                |> Maybe.withDefault IsNotMuted
                |> strongest channel.mutedChannel


strongest : IsMuted -> IsMuted -> IsMuted
strongest a b =
    case ( a, b ) of
        ( IsFullyMuted, _ ) ->
            IsFullyMuted

        ( _, IsFullyMuted ) ->
            IsFullyMuted

        ( IsPartiallyMuted, _ ) ->
            IsPartiallyMuted

        ( _, IsPartiallyMuted ) ->
            IsPartiallyMuted

        ( IsNotMuted, IsNotMuted ) ->
            IsNotMuted


isDmMuted : Model -> Id UserId -> ThreadRoute -> IsMuted
isDmMuted model otherUserId threadRoute =
    case SeqDict.get otherUserId model.mutedDms of
        Just channel ->
            channelOrThreadMuted threadRoute channel

        Nothing ->
            IsNotMuted


isDiscordDmMuted : Model -> Discord.Id Discord.PrivateChannelId -> IsMuted
isDiscordDmMuted model channelId =
    SeqDict.get channelId model.mutedDiscordDms |> Maybe.withDefault IsNotMuted


isDiscordGuildSpecificallyMute : Model -> Discord.Id Discord.GuildId -> IsMuted
isDiscordGuildSpecificallyMute model guildId =
    case SeqDict.get guildId model.mutedDiscordGuilds of
        Just guild ->
            guild.mutedGuild

        Nothing ->
            IsNotMuted


isDiscordChannelSpecificallyMuted : Model -> Discord.Id Discord.GuildId -> Discord.Id Discord.ChannelId -> IsMuted
isDiscordChannelSpecificallyMuted model guildId channelId =
    case SeqDict.get guildId model.mutedDiscordGuilds of
        Just guild ->
            case SeqDict.get channelId guild.channels of
                Just channel ->
                    channel.mutedChannel

                Nothing ->
                    IsNotMuted

        Nothing ->
            IsNotMuted


isDiscordThreadSpecificallyMuted :
    Model
    -> Discord.Id Discord.GuildId
    -> Discord.Id Discord.ChannelId
    -> Id ChannelMessageId
    -> IsMuted
isDiscordThreadSpecificallyMuted model guildId channelId threadId =
    case SeqDict.get guildId model.mutedDiscordGuilds of
        Just guild ->
            case SeqDict.get channelId guild.channels of
                Just channel ->
                    SeqDict.get threadId channel.mutedThreads |> Maybe.withDefault IsNotMuted

                Nothing ->
                    IsNotMuted

        Nothing ->
            IsNotMuted


isDiscordChannelMuted : Model -> Discord.Id Discord.GuildId -> Discord.Id Discord.ChannelId -> ThreadRoute -> IsMuted
isDiscordChannelMuted model guildId channelId threadRoute =
    case SeqDict.get guildId model.mutedDiscordGuilds of
        Just guild ->
            case SeqDict.get channelId guild.channels of
                Just channel ->
                    strongest guild.mutedGuild (channelOrThreadMuted threadRoute channel)

                Nothing ->
                    guild.mutedGuild

        Nothing ->
            IsNotMuted
