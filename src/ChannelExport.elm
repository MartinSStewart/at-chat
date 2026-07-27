module ChannelExport exposing (discordGuildChannel, fileName, guildChannel)

{-| Turns a guild channel (either a normal channel or a channel belonging to a
Discord guild that we've synced) into a JSON string so that the user can
download a copy of the conversation.

Drawings are deliberately left out. Everything else that makes up a message is
included, along with the publicly available data (name, when they joined, and a
url to their profile image) of every member that has access to the channel.

-}

import Array exposing (Array)
import ChannelDescription
import ChannelName exposing (ChannelName)
import CustomEmoji
import Discord
import DiscordUserData exposing (DiscordUserData)
import Effect.Time as Time
import Embed exposing (Embed(..))
import Emoji exposing (EmojiOrCustomEmoji(..))
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
    (ChannelName.toString channelName
        |> String.map
            (\char ->
                if Char.isAlphaNum char || char == '-' || char == '_' || char == ' ' then
                    char

                else
                    '_'
            )
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
                encodeMessage userIdToString userNames (threadMessages (Id.fromInt index)) index message
            )
        |> Json.Encode.list identity


encodeMessage :
    (userId -> String)
    -> SeqDict userId String
    -> Maybe Json.Encode.Value
    -> Int
    -> Message messageId userId
    -> Json.Encode.Value
encodeMessage userIdToString userNames maybeThread index message =
    (( "index", Json.Encode.int index )
        :: (case message of
                UserTextMessage data ->
                    [ ( "type", Json.Encode.string "userTextMessage" )
                    , ( "createdAt", encodeTime data.createdAt )
                    , ( "createdBy", Json.Encode.string (userIdToString data.createdBy) )
                    , ( "content", encodeContent userNames data.content )
                    , ( "editedAt", encodeMaybe encodeTime data.editedAt )
                    , ( "repliedTo", encodeMaybe (\messageId -> Json.Encode.int (Id.toInt messageId)) data.repliedTo )
                    , ( "reactions", encodeReactions userIdToString data.reactions )
                    , ( "attachedFiles", encodeAttachedFiles data.attachedFiles )
                    , ( "embeds", encodeEmbeds data.embeds )
                    ]

                UserJoinedMessage createdAt userId reactions _ ->
                    [ ( "type", Json.Encode.string "userJoined" )
                    , ( "createdAt", encodeTime createdAt )
                    , ( "createdBy", Json.Encode.string (userIdToString userId) )
                    , ( "reactions", encodeReactions userIdToString reactions )
                    ]

                DeletedMessage deletedAt ->
                    [ ( "type", Json.Encode.string "deleted" )
                    , ( "deletedAt", encodeTime deletedAt )
                    ]

                CallStarted data ->
                    [ ( "type", Json.Encode.string "callStarted" )
                    , ( "createdAt", encodeTime data.startedAt )
                    , ( "createdBy", Json.Encode.string (userIdToString data.startedBy) )
                    , ( "endedAt", encodeMaybe encodeTime data.endedAt )
                    , ( "reactions", encodeReactions userIdToString data.reactions )
                    ]

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
                            )
                      )
                    , ( "reactions", encodeReactions userIdToString data.reactions )
                    ]
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
    RichText.toStringWithGetter identity False userNames content |> Json.Encode.string


encodeReactions : (userId -> String) -> SeqDict EmojiOrCustomEmoji (NonemptySet userId) -> Json.Encode.Value
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
        |> Json.Encode.list identity


emojiToString : EmojiOrCustomEmoji -> String
emojiToString emoji =
    case emoji of
        EmojiOrCustomEmoji_Emoji unicodeEmoji ->
            Emoji.toString unicodeEmoji

        EmojiOrCustomEmoji_CustomEmoji customEmojiId ->
            CustomEmoji.idToString customEmojiId


encodeAttachedFiles : SeqDict (Id FileId) FileData -> Json.Encode.Value
encodeAttachedFiles attachedFiles =
    SeqDict.toList attachedFiles
        |> List.map
            (\( fileId, fileData ) ->
                Json.Encode.object
                    [ ( "id", Json.Encode.string (Id.toString fileId) )
                    , ( "fileName", Json.Encode.string (FileName.toString fileData.fileName) )
                    , ( "fileSize", Json.Encode.int fileData.fileSize )
                    , ( "url", Json.Encode.string (FileStatus.fileUrl fileData.contentType fileData.fileHash) )
                    ]
            )
        |> Json.Encode.list identity


encodeEmbeds : Array Embed -> Json.Encode.Value
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
        |> Json.Encode.list identity


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
