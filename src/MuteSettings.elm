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
    , isDiscordGuildSpecificallyMute
    , isDiscordThreadSpecificallyMuted
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
import Id exposing (ChannelId, ChannelMessageId, GuildId, Id, ThreadRoute(..))
import MyUi
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import Ui exposing (Element)


type alias Model =
    { mutedGuilds : SeqDict (Id GuildId) MutedGuild
    , mutedDms : SeqDict (Id GuildId) MutedGuild
    , mutedDiscordGuilds : SeqDict (Discord.Id Discord.GuildId) MutedDiscordGuild
    , mutedDiscordDms : SeqSet (Discord.Id Discord.PrivateChannelId)
    }


type IsMuted
    = IsMuted
    | IsNotMuted


type alias MutedGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict (Id ChannelId) MutedChannel
    }


type alias MutedChannel =
    { mutedChannel : IsMuted, mutedThreads : SeqSet (Id ChannelMessageId) }


type alias MutedDiscordGuild =
    { mutedGuild : IsMuted
    , channels : SeqDict (Discord.Id Discord.ChannelId) MutedChannel
    }


init : Model
init =
    { mutedGuilds = SeqDict.empty
    , mutedDms = SeqDict.empty
    , mutedDiscordGuilds = SeqDict.empty
    , mutedDiscordDms = SeqSet.empty
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

                IsMuted ->
                    Ui.html Icons.bellSlash
            ]
        )
        [ ( IsNotMuted, "Not muted" )
        , ( IsMuted, "Muted (hide red/white dot)" )
        ]


setMuteGuild : Id GuildId -> IsMuted -> Model -> Model
setMuteGuild guildId isMuted model =
    { model | mutedGuilds = SeqDict.updateIfExists guildId (\guild -> { guild | mutedGuild = isMuted }) model.mutedGuilds }


setMuteDiscordGuild : Discord.Id Discord.GuildId -> IsMuted -> Model -> Model
setMuteDiscordGuild guildId isMuted model =
    { model
        | mutedDiscordGuilds =
            SeqDict.updateIfExists guildId (\guild -> { guild | mutedGuild = isMuted }) model.mutedDiscordGuilds
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
                        IsMuted ->
                            SeqSet.insert threadId channel.mutedThreads

                        IsNotMuted ->
                            SeqSet.remove threadId channel.mutedThreads
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
                        IsMuted ->
                            SeqSet.insert threadId channel.mutedThreads

                        IsNotMuted ->
                            SeqSet.remove threadId channel.mutedThreads
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
                                    Maybe.withDefault { mutedChannel = IsNotMuted, mutedThreads = SeqSet.empty } maybeChannel
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
                                    Maybe.withDefault { mutedChannel = IsNotMuted, mutedThreads = SeqSet.empty } maybeChannel
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
                    if SeqSet.member threadId channel.mutedThreads then
                        IsMuted

                    else
                        IsNotMuted

                Nothing ->
                    IsNotMuted

        Nothing ->
            IsNotMuted


isChannelMuted : Model -> Id GuildId -> Id ChannelId -> ThreadRoute -> IsMuted
isChannelMuted model guildId channelId threadRoute =
    case SeqDict.get guildId model.mutedGuilds of
        Just guild ->
            case guild.mutedGuild of
                IsMuted ->
                    IsMuted

                IsNotMuted ->
                    case SeqDict.get channelId guild.channels of
                        Just channel ->
                            case threadRoute of
                                NoThread ->
                                    channel.mutedChannel

                                ViewThread threadId ->
                                    case channel.mutedChannel of
                                        IsMuted ->
                                            IsMuted

                                        IsNotMuted ->
                                            if SeqSet.member threadId channel.mutedThreads then
                                                IsMuted

                                            else
                                                IsNotMuted

                        Nothing ->
                            IsNotMuted

        Nothing ->
            IsNotMuted


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
                    if SeqSet.member threadId channel.mutedThreads then
                        IsMuted

                    else
                        IsNotMuted

                Nothing ->
                    IsNotMuted

        Nothing ->
            IsNotMuted


isDiscordChannelMuted : Model -> Discord.Id Discord.GuildId -> Discord.Id Discord.ChannelId -> ThreadRoute -> IsMuted
isDiscordChannelMuted model guildId channelId threadRoute =
    case SeqDict.get guildId model.mutedDiscordGuilds of
        Just guild ->
            case guild.mutedGuild of
                IsMuted ->
                    IsMuted

                IsNotMuted ->
                    case SeqDict.get channelId guild.channels of
                        Just channel ->
                            case threadRoute of
                                NoThread ->
                                    channel.mutedChannel

                                ViewThread threadId ->
                                    case channel.mutedChannel of
                                        IsMuted ->
                                            IsMuted

                                        IsNotMuted ->
                                            if SeqSet.member threadId channel.mutedThreads then
                                                IsMuted

                                            else
                                                IsNotMuted

                        Nothing ->
                            IsNotMuted

        Nothing ->
            IsNotMuted
