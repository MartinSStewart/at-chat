module LocalState exposing
    ( AdminData
    , AdminStatus(..)
    , BackendChannel
    , BackendGuild
    , ChannelStatus(..)
    , FrontendChannel
    , FrontendGuild
    , JoinGuildError(..)
    , LastTypedAt
    , LocalState
    , LogWithTime
    , Message(..)
    , addInvite
    , addMember
    , addReactionEmoji
    , allUsers
    , channelToFrontend
    , createChannel
    , createChannelFrontend
    , createMessage
    , createNewUser
    , deleteChannel
    , deleteChannelFrontend
    , editChannel
    , editMessage
    , getUser
    , guildToFrontend
    , isAdmin
    , memberIsEditTyping
    , memberIsTyping
    , removeReactionEmoji
    , updateChannel
    )

import Array exposing (Array)
import Array.Extra
import ChannelName exposing (ChannelName)
import Effect.Time as Time
import EmailAddress exposing (EmailAddress)
import Emoji exposing (Emoji)
import GuildName exposing (GuildName)
import Id exposing (ChannelId, GuildId, Id, InviteLinkId, UserId)
import Image exposing (Image)
import List.Nonempty exposing (Nonempty)
import Log exposing (Log)
import NonemptyDict exposing (NonemptyDict)
import NonemptySet exposing (NonemptySet)
import PersonName exposing (PersonName)
import RichText exposing (RichText)
import SecretId exposing (SecretId)
import SeqDict exposing (SeqDict)
import SeqSet exposing (SeqSet)
import String.Nonempty exposing (NonemptyString)
import Unsafe
import User exposing (BackendUser, EmailNotifications(..), FrontendUser)


type alias LocalState =
    { userId : Id UserId
    , adminData : AdminStatus
    , guilds : SeqDict (Id GuildId) FrontendGuild
    , joinGuildError : Maybe JoinGuildError
    , user : BackendUser
    , otherUsers : SeqDict (Id UserId) FrontendUser
    }


type JoinGuildError
    = AlreadyJoined
    | InviteIsInvalid


type alias BackendGuild =
    { createdAt : Time.Posix
    , createdBy : Id UserId
    , name : GuildName
    , icon : Maybe Image
    , channels : SeqDict (Id ChannelId) BackendChannel
    , members : SeqDict (Id UserId) { joinedAt : Time.Posix }
    , owner : Id UserId
    , invites : SeqDict (SecretId InviteLinkId) { createdAt : Time.Posix, createdBy : Id UserId }
    , announcementChannel : Id ChannelId
    }


type alias FrontendGuild =
    { createdAt : Time.Posix
    , createdBy : Id UserId
    , name : GuildName
    , icon : Maybe Image
    , channels : SeqDict (Id ChannelId) FrontendChannel
    , members : SeqDict (Id UserId) { joinedAt : Time.Posix }
    , owner : Id UserId
    , invites : SeqDict (SecretId InviteLinkId) { createdAt : Time.Posix, createdBy : Id UserId }
    , announcementChannel : Id ChannelId
    }


guildToFrontend : Id UserId -> BackendGuild -> Maybe FrontendGuild
guildToFrontend userId guild =
    if userId == guild.owner || SeqDict.member userId guild.members then
        { createdAt = guild.createdAt
        , createdBy = guild.createdBy
        , name = guild.name
        , icon = guild.icon
        , channels = SeqDict.filterMap (\_ channel -> channelToFrontend channel) guild.channels
        , members = guild.members
        , owner = guild.owner
        , invites = guild.invites
        , announcementChannel = guild.announcementChannel
        }
            |> Just

    else
        Nothing


type alias BackendChannel =
    { createdAt : Time.Posix
    , createdBy : Id UserId
    , name : ChannelName
    , messages : Array Message
    , status : ChannelStatus
    , lastTypedAt : SeqDict (Id UserId) LastTypedAt
    }


type alias FrontendChannel =
    { createdAt : Time.Posix
    , createdBy : Id UserId
    , name : ChannelName
    , messages : Array Message
    , isArchived : Maybe Archived
    , lastTypedAt : SeqDict (Id UserId) LastTypedAt
    }


type alias LastTypedAt =
    { time : Time.Posix, messageIndex : Maybe Int }


channelToFrontend : BackendChannel -> Maybe FrontendChannel
channelToFrontend channel =
    case channel.status of
        ChannelActive ->
            { createdAt = channel.createdAt
            , createdBy = channel.createdBy
            , name = channel.name
            , messages = channel.messages
            , isArchived = Nothing
            , lastTypedAt = channel.lastTypedAt
            }
                |> Just

        ChannelArchived archive ->
            { createdAt = channel.createdAt
            , createdBy = channel.createdBy
            , name = channel.name
            , messages = channel.messages
            , isArchived = Just archive
            , lastTypedAt = channel.lastTypedAt
            }
                |> Just

        ChannelDeleted _ ->
            Nothing


type alias Archived =
    { archivedAt : Time.Posix, archivedBy : Id UserId }


type ChannelStatus
    = ChannelActive
    | ChannelArchived Archived
    | ChannelDeleted { deletedAt : Time.Posix, deletedBy : Id UserId }


type Message
    = UserTextMessage
        { createdAt : Time.Posix
        , createdBy : Id UserId
        , content : Nonempty RichText
        , reactions : SeqDict Emoji (NonemptySet (Id UserId))
        , editedAt : Maybe Time.Posix
        }
    | UserJoinedMessage Time.Posix (Id UserId) (SeqDict Emoji (NonemptySet (Id UserId)))
    | DeletedMessage


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin


type alias LogWithTime =
    { time : Time.Posix, log : Log }


type alias AdminData =
    { users : NonemptyDict (Id UserId) BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict (Id UserId) Time.Posix
    }


createNewUser : Time.Posix -> PersonName -> EmailAddress -> Bool -> BackendUser
createNewUser createdAt name email userIsAdmin =
    { name = name
    , isAdmin = userIsAdmin
    , email = email
    , recentLoginEmails = []
    , lastLogPageViewed = 0
    , expandedSections = SeqSet.empty
    , createdAt = createdAt
    , emailNotifications = CheckEvery5Minutes
    , lastEmailNotification = createdAt
    }


getUser : Id UserId -> LocalState -> Maybe FrontendUser
getUser userId local =
    if local.userId == userId then
        User.backendToFrontend local.user |> Just

    else
        SeqDict.get userId local.otherUsers


isAdmin : LocalState -> Bool
isAdmin { adminData } =
    case adminData of
        IsAdmin _ ->
            True

        IsNotAdmin ->
            False


createMessage :
    Message
    -> { d | messages : Array Message, lastTypedAt : SeqDict (Id UserId) LastTypedAt }
    -> { d | messages : Array Message, lastTypedAt : SeqDict (Id UserId) LastTypedAt }
createMessage message channel =
    { channel
        | messages = Array.push message channel.messages
        , lastTypedAt =
            case message of
                UserTextMessage { createdBy } ->
                    SeqDict.remove createdBy channel.lastTypedAt

                UserJoinedMessage _ _ _ ->
                    channel.lastTypedAt

                DeletedMessage ->
                    channel.lastTypedAt
    }


createChannel : Time.Posix -> Id UserId -> ChannelName -> BackendGuild -> BackendGuild
createChannel time userId channelName guild =
    let
        channelId : Id ChannelId
        channelId =
            Id.nextId guild.channels
    in
    { guild
        | channels =
            SeqDict.insert
                channelId
                { createdAt = time
                , createdBy = userId
                , name = channelName
                , messages = Array.empty
                , status = ChannelActive
                , lastTypedAt = SeqDict.empty
                }
                guild.channels
    }


createChannelFrontend : Time.Posix -> Id UserId -> ChannelName -> FrontendGuild -> FrontendGuild
createChannelFrontend time userId channelName guild =
    let
        channelId : Id ChannelId
        channelId =
            Id.nextId guild.channels
    in
    { guild
        | channels =
            SeqDict.insert
                channelId
                { createdAt = time
                , createdBy = userId
                , name = channelName
                , messages = Array.empty
                , isArchived = Nothing
                , lastTypedAt = SeqDict.empty
                }
                guild.channels
    }


editChannel :
    ChannelName
    -> Id ChannelId
    -> { c | channels : SeqDict (Id ChannelId) { d | name : ChannelName } }
    -> { c | channels : SeqDict (Id ChannelId) { d | name : ChannelName } }
editChannel channelName channelId guild =
    updateChannel (\channel -> { channel | name = channelName }) channelId guild


deleteChannel : Time.Posix -> Id UserId -> Id ChannelId -> BackendGuild -> BackendGuild
deleteChannel time userId channelId guild =
    updateChannel
        (\channel -> { channel | status = ChannelDeleted { deletedAt = time, deletedBy = userId } })
        channelId
        guild


deleteChannelFrontend : Id ChannelId -> FrontendGuild -> FrontendGuild
deleteChannelFrontend channelId guild =
    { guild | channels = SeqDict.remove channelId guild.channels }


memberIsTyping :
    Id UserId
    -> Time.Posix
    -> Id ChannelId
    -> { d | channels : SeqDict (Id ChannelId) { e | lastTypedAt : SeqDict (Id UserId) LastTypedAt } }
    -> { d | channels : SeqDict (Id ChannelId) { e | lastTypedAt : SeqDict (Id UserId) LastTypedAt } }
memberIsTyping userId time channelId guild =
    updateChannel
        (\channel ->
            { channel
                | lastTypedAt =
                    SeqDict.insert userId { time = time, messageIndex = Nothing } channel.lastTypedAt
            }
        )
        channelId
        guild


memberIsEditTyping :
    Id UserId
    -> Time.Posix
    -> Id ChannelId
    -> Int
    -> { d | channels : SeqDict (Id ChannelId) { e | messages : Array Message, lastTypedAt : SeqDict (Id UserId) LastTypedAt } }
    -> Result () { d | channels : SeqDict (Id ChannelId) { e | messages : Array Message, lastTypedAt : SeqDict (Id UserId) LastTypedAt } }
memberIsEditTyping userId time channelId messageIndex guild =
    case SeqDict.get channelId guild.channels of
        Just channel ->
            case Array.get messageIndex channel.messages of
                Just (UserTextMessage data) ->
                    if data.createdBy == userId then
                        { guild
                            | channels =
                                SeqDict.insert
                                    channelId
                                    { channel
                                        | lastTypedAt =
                                            SeqDict.insert
                                                userId
                                                { time = time, messageIndex = Just messageIndex }
                                                channel.lastTypedAt
                                    }
                                    guild.channels
                        }
                            |> Ok

                    else
                        Err ()

                _ ->
                    Err ()

        Nothing ->
            Err ()


addInvite :
    SecretId InviteLinkId
    -> Id UserId
    -> Time.Posix
    -> { d | invites : SeqDict (SecretId InviteLinkId) { createdBy : Id UserId, createdAt : Time.Posix } }
    -> { d | invites : SeqDict (SecretId InviteLinkId) { createdBy : Id UserId, createdAt : Time.Posix } }
addInvite inviteId userId time guild =
    { guild
        | invites =
            SeqDict.insert inviteId { createdBy = userId, createdAt = time } guild.invites
    }


addMember :
    Time.Posix
    -> Id UserId
    ->
        { a
            | owner : Id UserId
            , members : SeqDict (Id UserId) { joinedAt : Time.Posix }
            , announcementChannel : Id ChannelId
            , channels :
                SeqDict
                    (Id ChannelId)
                    { d
                        | messages : Array Message
                        , lastTypedAt : SeqDict (Id UserId) LastTypedAt
                    }
        }
    ->
        Result
            ()
            { a
                | owner : Id UserId
                , members : SeqDict (Id UserId) { joinedAt : Time.Posix }
                , announcementChannel : Id ChannelId
                , channels :
                    SeqDict
                        (Id ChannelId)
                        { d
                            | messages : Array Message
                            , lastTypedAt : SeqDict (Id UserId) LastTypedAt
                        }
            }
addMember time userId guild =
    if guild.owner == userId || SeqDict.member userId guild.members then
        Err ()

    else
        { guild
            | members = SeqDict.insert userId { joinedAt = time } guild.members
            , channels =
                SeqDict.updateIfExists
                    guild.announcementChannel
                    (createMessage (UserJoinedMessage time userId SeqDict.empty))
                    guild.channels
        }
            |> Ok


allUsers : LocalState -> SeqDict (Id UserId) FrontendUser
allUsers local =
    SeqDict.insert local.userId (User.backendToFrontendForUser local.user) local.otherUsers


addReactionEmoji :
    Emoji
    -> Id UserId
    -> Id ChannelId
    -> Int
    -> { a | channels : SeqDict (Id ChannelId) { b | messages : Array Message } }
    -> { a | channels : SeqDict (Id ChannelId) { b | messages : Array Message } }
addReactionEmoji emoji userId channelId messageIndex guild =
    updateChannel
        (\channel ->
            { channel
                | messages =
                    Array.Extra.update messageIndex
                        (\message ->
                            case message of
                                UserTextMessage message2 ->
                                    { message2
                                        | reactions =
                                            SeqDict.update
                                                emoji
                                                (\maybeSet ->
                                                    (case maybeSet of
                                                        Just nonempty ->
                                                            NonemptySet.insert userId nonempty

                                                        Nothing ->
                                                            NonemptySet.singleton userId
                                                    )
                                                        |> Just
                                                )
                                                message2.reactions
                                    }
                                        |> UserTextMessage

                                UserJoinedMessage time userJoined reactions ->
                                    UserJoinedMessage
                                        time
                                        userJoined
                                        (SeqDict.update
                                            emoji
                                            (\maybeSet ->
                                                (case maybeSet of
                                                    Just nonempty ->
                                                        NonemptySet.insert userId nonempty

                                                    Nothing ->
                                                        NonemptySet.singleton userId
                                                )
                                                    |> Just
                                            )
                                            reactions
                                        )

                                DeletedMessage ->
                                    message
                        )
                        channel.messages
            }
        )
        channelId
        guild


updateChannel :
    (v -> v)
    -> Id ChannelId
    -> { a | channels : SeqDict (Id ChannelId) v }
    -> { a | channels : SeqDict (Id ChannelId) v }
updateChannel updateFunc channelId guild =
    { guild | channels = SeqDict.updateIfExists channelId updateFunc guild.channels }


editMessage :
    Id UserId
    -> Time.Posix
    -> Nonempty RichText
    -> Id ChannelId
    -> Int
    ->
        { a
            | channels :
                SeqDict
                    (Id ChannelId)
                    { b
                        | messages : Array Message
                        , lastTypedAt : SeqDict (Id UserId) LastTypedAt
                    }
        }
    ->
        Result
            ()
            { a
                | channels :
                    SeqDict
                        (Id ChannelId)
                        { b
                            | messages : Array Message
                            , lastTypedAt : SeqDict (Id UserId) LastTypedAt
                        }
            }
editMessage editedBy time newContent channelId messageIndex guild =
    case SeqDict.get channelId guild.channels of
        Just channel ->
            case Array.get messageIndex channel.messages of
                Just (UserTextMessage data) ->
                    if data.createdBy == editedBy then
                        { guild
                            | channels =
                                SeqDict.insert
                                    channelId
                                    { channel
                                        | messages =
                                            Array.set
                                                messageIndex
                                                ({ data | editedAt = Just time, content = newContent }
                                                    |> UserTextMessage
                                                )
                                                channel.messages
                                        , lastTypedAt =
                                            SeqDict.update
                                                editedBy
                                                (\maybe ->
                                                    case maybe of
                                                        Just a ->
                                                            if a.messageIndex == Just messageIndex then
                                                                Nothing

                                                            else
                                                                maybe

                                                        Nothing ->
                                                            Nothing
                                                )
                                                channel.lastTypedAt
                                    }
                                    guild.channels
                        }
                            |> Ok

                    else
                        Err ()

                _ ->
                    Err ()

        Nothing ->
            Err ()


removeReactionEmoji :
    Emoji
    -> Id UserId
    -> Id ChannelId
    -> Int
    -> { a | channels : SeqDict (Id ChannelId) { b | messages : Array Message } }
    -> { a | channels : SeqDict (Id ChannelId) { b | messages : Array Message } }
removeReactionEmoji emoji userId channelId messageIndex guild =
    updateChannel
        (\channel ->
            { channel
                | messages =
                    Array.Extra.update messageIndex
                        (\message ->
                            case message of
                                UserTextMessage message2 ->
                                    { message2
                                        | reactions =
                                            SeqDict.update
                                                emoji
                                                (\maybeSet ->
                                                    case maybeSet of
                                                        Just nonempty ->
                                                            NonemptySet.toSeqSet nonempty
                                                                |> SeqSet.remove userId
                                                                |> NonemptySet.fromSeqSet

                                                        Nothing ->
                                                            Nothing
                                                )
                                                message2.reactions
                                    }
                                        |> UserTextMessage

                                UserJoinedMessage time userJoined reactions ->
                                    UserJoinedMessage
                                        time
                                        userJoined
                                        (SeqDict.update
                                            emoji
                                            (\maybeSet ->
                                                case maybeSet of
                                                    Just nonempty ->
                                                        NonemptySet.toSeqSet nonempty
                                                            |> SeqSet.remove userId
                                                            |> NonemptySet.fromSeqSet

                                                    Nothing ->
                                                        Nothing
                                            )
                                            reactions
                                        )

                                DeletedMessage ->
                                    message
                        )
                        channel.messages
            }
        )
        channelId
        guild
