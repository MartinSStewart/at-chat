module ChannelExport exposing
    ( discordDmChannel
    , discordDmName
    , discordGuildChannel
    , dmChannel
    , dmFileName
    , fileName
    , guildChannel
    )

{-| Turns a channel (a guild channel, a channel belonging to a Discord guild
that we've synced, or a DM channel) into a JSON string so that the user can
download a copy of the conversation.

Drawings are deliberately left out. Everything else that makes up a message is
included, along with the publicly available data (name, when they joined, and a
url to their profile image) of every member that has access to the channel. DM
channels have no join times so those are left out there.

-}

import Array exposing (Array)
import ChannelDescription
import ChannelName exposing (ChannelName)
import CustomEmoji
import Discord
import DiscordUserData exposing (DiscordUserData)
import DmChannel exposing (BackendDmChannel, DiscordDmChannel)
import Effect.Time as Time
import Embed exposing (Embed(..))
import Emoji exposing (EmojiOrCustomEmoji(..))
import Encryption as Encrypted
import FileName
import FileStatus exposing (FileData, FileHash, FileId)
import GuildName
import Id exposing (Id, UserId)
import IdArray exposing (IdArray)
import Iso8601
import Json.Encode
import List.Nonempty exposing (Nonempty)
import LocalState exposing (BackendChannel, BackendGuild, DiscordBackendChannel, DiscordBackendGuild)
import MembersAndOwner
import Message exposing (GameType(..), Message(..))
import NonemptyDict exposing (NonemptyDict)
import NonemptySet exposing (NonemptySet)
import PersonName
import RichText exposing (RichText)
import SeqDict exposing (SeqDict)
import User exposing (BackendUser)


{-| A file name that's safe to hand to the browser's download prompt.
-}
fileName : ChannelName -> String
fileName channelName =
    ChannelName.toString channelName |> sanitizeFileName


{-| DM channels aren't named, so they get exported under the name of the people
in them instead.
-}
dmFileName : String -> String
dmFileName dmName =
    sanitizeFileName dmName


sanitizeFileName : String -> String
sanitizeFileName text =
    (String.map
        (\char ->
            if Char.isAlphaNum char || char == '-' || char == '_' || char == ' ' then
                char

            else
                '_'
        )
        text
        |> String.trim
    )
        ++ ".json"


guildChannel : NonemptyDict (Id UserId) BackendUser -> BackendGuild -> BackendChannel -> String
guildChannel users guild channel =
    let
        ownerId : Id UserId
        ownerId =
            MembersAndOwner.owner guild.membersAndOwner

        userNames : SeqDict (Id UserId) String
        userNames =
            NonemptyDict.toSeqDict users |> SeqDict.map (\_ user -> PersonName.toString user.name)

        member : Id UserId -> Maybe Time.Posix -> Json.Encode.Value
        member userId joinedAt =
            encodeMember
                { id = Id.toString userId
                , name = SeqDict.get userId userNames |> Maybe.withDefault unknownUserName
                , joinedAt = joinedAt
                , profileImageUrl =
                    NonemptyDict.get userId users
                        |> Maybe.andThen .icon
                        |> Maybe.map profileImageUrl
                , isOwner = userId == ownerId
                }
    in
    Json.Encode.object
        [ ( "guild"
          , Json.Encode.object
                [ ( "name", Json.Encode.string (GuildName.toString guild.name) )
                , ( "createdAt", encodeTime guild.createdAt )
                ]
          )
        , ( "channel"
          , Json.Encode.object
                [ ( "name", Json.Encode.string (ChannelName.toString channel.name) )
                , ( "description", Json.Encode.string (ChannelDescription.toString channel.description) )
                , ( "createdAt", encodeTime channel.createdAt )
                , ( "createdBy", Json.Encode.string (Id.toString channel.createdBy) )
                ]
          )
        , ( "members"
          , member ownerId (Just guild.createdAt)
                :: (MembersAndOwner.members guild.membersAndOwner
                        |> SeqDict.toList
                        |> List.map (\( userId, data ) -> member userId (Just data.joinedAt))
                   )
                |> Json.Encode.list identity
          )
        , ( "messages"
          , encodeMessages
                Id.toString
                userNames
                (\messageId ->
                    case SeqDict.get messageId channel.threads of
                        Just thread ->
                            encodeMessages Id.toString userNames (\_ -> Nothing) thread.messages |> Just

                        Nothing ->
                            Nothing
                )
                channel.messages
          )
        ]
        |> Json.Encode.encode 2


discordGuildChannel :
    SeqDict (Discord.Id Discord.UserId) DiscordUserData
    -> Discord.Id Discord.GuildId
    -> DiscordBackendGuild
    -> DiscordBackendChannel
    -> String
discordGuildChannel discordUsers guildId guild channel =
    let
        ownerId : Discord.Id Discord.UserId
        ownerId =
            MembersAndOwner.owner guild.membersAndOwner

        userNames : SeqDict (Discord.Id Discord.UserId) String
        userNames =
            SeqDict.map (\_ discordUser -> DiscordUserData.username discordUser) discordUsers

        member : Discord.Id Discord.UserId -> Maybe Time.Posix -> Json.Encode.Value
        member userId joinedAt =
            encodeMember
                { id = Discord.idToString userId
                , name = SeqDict.get userId userNames |> Maybe.withDefault unknownUserName
                , joinedAt = joinedAt
                , profileImageUrl =
                    (case SeqDict.get userId discordUsers |> Maybe.andThen DiscordUserData.icon of
                        Just fileHash ->
                            profileImageUrl fileHash

                        Nothing ->
                            Discord.defaultUserAvatarUrl (Discord.TwoToNthPower 7) userId
                    )
                        |> Just
                , isOwner = userId == ownerId
                }
    in
    Json.Encode.object
        [ ( "guild", Json.Encode.object [ ( "name", Json.Encode.string (GuildName.toString guild.name) ) ] )
        , ( "channel"
          , Json.Encode.object
                [ ( "name", Json.Encode.string (ChannelName.toString channel.name) )
                , ( "description", Json.Encode.string (ChannelDescription.toString channel.description) )
                ]
          )
        , ( "members"
          , member ownerId Nothing
                :: (MembersAndOwner.members guild.membersAndOwner
                        |> SeqDict.toList
                        |> List.filterMap
                            (\( userId, data ) ->
                                if LocalState.canViewDiscordChannel guildId channel guild userId then
                                    member userId data.joinedAt |> Just

                                else
                                    Nothing
                            )
                   )
                |> Json.Encode.list identity
          )
        , ( "messages"
          , encodeMessages
                Discord.idToString
                userNames
                (\messageId ->
                    case SeqDict.get messageId channel.threads of
                        Just thread ->
                            encodeMessages Discord.idToString userNames (\_ -> Nothing) thread.messages |> Just

                        Nothing ->
                            Nothing
                )
                channel.messages
          )
        ]
        |> Json.Encode.encode 2


{-| DM channels have no owner and no join times, so their members are only
listed by name and profile image.
-}
dmChannel : NonemptyDict (Id UserId) BackendUser -> Id UserId -> Id UserId -> BackendDmChannel -> String
dmChannel users currentUserId otherUserId channel =
    let
        userNames : SeqDict (Id UserId) String
        userNames =
            NonemptyDict.toSeqDict users |> SeqDict.map (\_ user -> PersonName.toString user.name)

        member : Id UserId -> Json.Encode.Value
        member userId =
            Json.Encode.object
                [ ( "id", Json.Encode.string (Id.toString userId) )
                , ( "name", Json.Encode.string (SeqDict.get userId userNames |> Maybe.withDefault unknownUserName) )
                , ( "profileImageUrl"
                  , NonemptyDict.get userId users
                        |> Maybe.andThen .icon
                        |> Maybe.map profileImageUrl
                        |> encodeMaybe Json.Encode.string
                  )
                ]
    in
    Json.Encode.object
        [ ( "channel"
          , Json.Encode.object
                [ ( "name"
                  , SeqDict.get otherUserId userNames
                        |> Maybe.withDefault unknownUserName
                        |> Json.Encode.string
                  )
                ]
          )
        , ( "members"
          , (if currentUserId == otherUserId then
                [ member currentUserId ]

             else
                [ member currentUserId, member otherUserId ]
            )
                |> Json.Encode.list identity
          )
        , ( "messages"
          , encodeMessages
                Id.toString
                userNames
                (\messageId ->
                    case SeqDict.get messageId channel.threads of
                        Just thread ->
                            encodeMessages Id.toString userNames (\_ -> Nothing) thread.messages |> Just

                        Nothing ->
                            Nothing
                )
                channel.messages
          )
        ]
        |> Json.Encode.encode 2


{-| Discord DM channels don't have threads, an owner, or join times, so their
members are only listed by name and profile image.
-}
discordDmChannel :
    SeqDict (Discord.Id Discord.UserId) DiscordUserData
    -> Discord.Id Discord.UserId
    -> DiscordDmChannel
    -> String
discordDmChannel discordUsers currentUserId channel =
    let
        userNames : SeqDict (Discord.Id Discord.UserId) String
        userNames =
            SeqDict.map (\_ discordUser -> DiscordUserData.username discordUser) discordUsers

        member : Discord.Id Discord.UserId -> Json.Encode.Value
        member userId =
            Json.Encode.object
                [ ( "id", Json.Encode.string (Discord.idToString userId) )
                , ( "name", Json.Encode.string (SeqDict.get userId userNames |> Maybe.withDefault unknownUserName) )
                , ( "profileImageUrl"
                  , (case SeqDict.get userId discordUsers |> Maybe.andThen DiscordUserData.icon of
                        Just fileHash ->
                            profileImageUrl fileHash

                        Nothing ->
                            Discord.defaultUserAvatarUrl (Discord.TwoToNthPower 7) userId
                    )
                        |> Json.Encode.string
                  )
                ]
    in
    Json.Encode.object
        [ ( "channel"
          , Json.Encode.object
                [ ( "name", Json.Encode.string (discordDmName discordUsers currentUserId channel) ) ]
          )
        , ( "members"
          , NonemptyDict.keys channel.members
                |> List.Nonempty.toList
                |> List.map member
                |> Json.Encode.list identity
          )
        , ( "messages", encodeMessages Discord.idToString userNames (\_ -> Nothing) channel.messages )
        ]
        |> Json.Encode.encode 2


{-| Discord DM channels are named after everyone in them except for the user
that's viewing the channel. When the user is DMing themselves their own name is
used instead.
-}
discordDmName :
    SeqDict (Discord.Id Discord.UserId) DiscordUserData
    -> Discord.Id Discord.UserId
    -> DiscordDmChannel
    -> String
discordDmName discordUsers currentUserId channel =
    (case List.filter (\userId -> userId /= currentUserId) (List.Nonempty.toList (NonemptyDict.keys channel.members)) of
        [] ->
            [ currentUserId ]

        otherUserIds ->
            otherUserIds
    )
        |> List.map
            (\userId ->
                case SeqDict.get userId discordUsers of
                    Just discordUser ->
                        DiscordUserData.username discordUser

                    Nothing ->
                        unknownUserName
            )
        |> String.join ", "


unknownUserName : String
unknownUserName =
    "<unknown user>"


profileImageUrl : FileHash -> String
profileImageUrl fileHash =
    FileStatus.fileUrl FileStatus.pngContent fileHash


encodeMember :
    { id : String
    , name : String
    , joinedAt : Maybe Time.Posix
    , profileImageUrl : Maybe String
    , isOwner : Bool
    }
    -> Json.Encode.Value
encodeMember data =
    Json.Encode.object
        [ ( "id", Json.Encode.string data.id )
        , ( "name", Json.Encode.string data.name )
        , ( "joinedAt", encodeMaybe encodeTime data.joinedAt )
        , ( "profileImageUrl", encodeMaybe Json.Encode.string data.profileImageUrl )
        , ( "isOwner", Json.Encode.bool data.isOwner )
        ]


{-| The third parameter looks up the messages belonging to the thread that was
started from the message with the given id (if there is one).
-}
encodeMessages :
    (userId -> String)
    -> SeqDict userId String
    -> (Id messageId -> Maybe Json.Encode.Value)
    -> IdArray messageId (Message messageId userId)
    -> Json.Encode.Value
encodeMessages userIdToString userNames threadMessages messages =
    IdArray.toList messages
        |> List.indexedMap
            (\index message ->
                encodeMessage userIdToString userNames (threadMessages (Id.fromInt index)) message
            )
        |> Json.Encode.list identity


encodeMessage :
    (userId -> String)
    -> SeqDict userId String
    -> Maybe Json.Encode.Value
    -> Message messageId userId
    -> Json.Encode.Value
encodeMessage userIdToString userNames maybeThread message =
    ((case message of
        UserTextMessage data ->
            [ ( "type", Json.Encode.string "userTextMessage" )
            , ( "createdAt", encodeTime data.createdAt )
            , ( "createdBy", Json.Encode.string (userIdToString data.createdBy) )
            , ( "content", encodeContent userNames data.content.content )
            ]
                ++ optionalField "editedAt" encodeTime data.editedAt
                ++ optionalField
                    "repliedTo"
                    (\messageId -> Json.Encode.int (Id.toInt messageId))
                    data.repliedTo
                ++ encodeReactions userIdToString data.reactions
                ++ encodeAttachedFiles data.content.attachedFiles
                ++ encodeEmbeds data.content.embeds

        EncryptedUserTextMessage data ->
            [ ( "encryptedData", Encrypted.encode data.content )
            , ( "type", Json.Encode.string "userTextMessage" )
            , ( "createdAt", encodeTime data.createdAt )
            , ( "createdBy", Json.Encode.string (userIdToString data.createdBy) )
            ]
                ++ optionalField "editedAt" encodeTime data.editedAt
                ++ optionalField
                    "repliedTo"
                    (\messageId -> Json.Encode.int (Id.toInt messageId))
                    data.repliedTo
                ++ encodeReactions userIdToString data.reactions

        UserJoinedMessage createdAt userId reactions _ ->
            [ ( "type", Json.Encode.string "userJoined" )
            , ( "createdAt", encodeTime createdAt )
            , ( "createdBy", Json.Encode.string (userIdToString userId) )
            ]
                ++ encodeReactions userIdToString reactions

        DeletedMessage deletedAt ->
            [ ( "type", Json.Encode.string "deleted" )
            , ( "deletedAt", encodeTime deletedAt )
            ]

        CallStarted data ->
            [ ( "type", Json.Encode.string "callStarted" )
            , ( "createdAt", encodeTime data.startedAt )
            , ( "createdBy", Json.Encode.string (userIdToString data.startedBy) )
            ]
                ++ optionalField "endedAt" encodeTime data.endedAt
                ++ encodeReactions userIdToString data.reactions

        GameStarted data ->
            [ ( "type", Json.Encode.string "gameStarted" )
            , ( "createdAt", encodeTime data.startedAt )
            , ( "createdBy", Json.Encode.string (userIdToString data.startedBy) )
            , ( "gameType"
              , Json.Encode.string
                    (case data.gameType of
                        GameType_Go ->
                            "go"

                        GameType_WordSpellingGame ->
                            "wordSpellingGame"

                        GameType_SheepGame ->
                            "sheepGame"
                    )
              )
            ]
                ++ encodeReactions userIdToString data.reactions
     )
        ++ (case maybeThread of
                Just thread ->
                    [ ( "threadMessages", thread ) ]

                Nothing ->
                    []
           )
    )
        |> Json.Encode.object


encodeContent : SeqDict userId String -> Nonempty (RichText userId) -> Json.Encode.Value
encodeContent userNames content =
    RichText.toStringWithGetter Time.utc identity False userNames content |> Json.Encode.string


encodeReactions :
    (userId -> String)
    -> SeqDict EmojiOrCustomEmoji (NonemptySet userId)
    -> List ( String, Json.Encode.Value )
encodeReactions userIdToString reactions =
    SeqDict.toList reactions
        |> List.map
            (\( emoji, users ) ->
                Json.Encode.object
                    [ ( "emoji", Json.Encode.string (emojiToString emoji) )
                    , ( "users"
                      , NonemptySet.toList users
                            |> List.map userIdToString
                            |> Json.Encode.list Json.Encode.string
                      )
                    ]
            )
        |> optionalListField "reactions"


emojiToString : EmojiOrCustomEmoji -> String
emojiToString emoji =
    case emoji of
        EmojiOrCustomEmoji_Emoji unicodeEmoji ->
            Emoji.toString unicodeEmoji

        EmojiOrCustomEmoji_CustomEmoji customEmojiId ->
            CustomEmoji.idToString customEmojiId


encodeAttachedFiles : SeqDict (Id FileId) FileData -> List ( String, Json.Encode.Value )
encodeAttachedFiles attachedFiles =
    SeqDict.toList attachedFiles
        |> List.map
            (\( fileId, fileData ) ->
                Json.Encode.object
                    [ ( "id", Json.Encode.string (Id.toString fileId) )
                    , ( "fileName", Json.Encode.string (FileName.toString fileData.fileName) )
                    , ( "fileSize", Json.Encode.int fileData.fileSize )
                    , ( "url", Json.Encode.string (FileStatus.fileDataUrl fileData) )
                    ]
            )
        |> optionalListField "attachedFiles"


encodeEmbeds : Array Embed -> List ( String, Json.Encode.Value )
encodeEmbeds embeds =
    Array.toList embeds
        |> List.filterMap
            (\embed ->
                case embed of
                    EmbedLoaded embedData ->
                        Json.Encode.object
                            [ ( "title", encodeMaybe Json.Encode.string embedData.title )
                            , ( "description", encodeMaybe Json.Encode.string embedData.description )
                            , ( "imageUrl", encodeMaybe (\image -> Json.Encode.string image.url) embedData.image )
                            , ( "createdAt", encodeMaybe encodeTime embedData.createdAt )
                            ]
                            |> Just

                    EmbedLoading ->
                        Nothing
            )
        |> optionalListField "embeds"


encodeTime : Time.Posix -> Json.Encode.Value
encodeTime time =
    Iso8601.fromTime time |> Json.Encode.string


encodeMaybe : (a -> Json.Encode.Value) -> Maybe a -> Json.Encode.Value
encodeMaybe encoder maybe =
    case maybe of
        Just a ->
            encoder a

        Nothing ->
            Json.Encode.null


{-| Most of what a message can carry (a reply, an edit, reactions, files,
embeds) is missing from the average message. Those fields are left out entirely
rather than exported as nulls and empty lists.
-}
optionalField : String -> (a -> Json.Encode.Value) -> Maybe a -> List ( String, Json.Encode.Value )
optionalField key encoder maybe =
    case maybe of
        Just a ->
            [ ( key, encoder a ) ]

        Nothing ->
            []


optionalListField : String -> List Json.Encode.Value -> List ( String, Json.Encode.Value )
optionalListField key values =
    case values of
        [] ->
            []

        _ ->
            [ ( key, Json.Encode.list identity values ) ]
