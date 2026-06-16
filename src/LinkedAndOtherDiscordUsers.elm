module LinkedAndOtherDiscordUsers exposing
    ( DiscordFrontendCurrentUser
    , LinkedAndOtherDiscordUsers(..)
    , addLinkedUser
    , addOtherUser
    , allDiscordUsers
    , discordCurrentUserToFrontend
    , getLinkedUser
    , getOtherUser
    , isLinkedUser
    , linkedUsers
    , updateLinkedUser
    )

import Discord
import DiscordUserData exposing (DiscordUserLoadingData)
import Effect.Time as Time
import EmailAddress exposing (EmailAddress)
import FileStatus exposing (FileHash)
import PersonName exposing (PersonName)
import SeqDict exposing (SeqDict)
import UserSession exposing (DiscordFrontendUser)


type LinkedAndOtherDiscordUsers
    = LinkedAndOtherDiscordUsers (SeqDict (Discord.Id Discord.UserId) DiscordFrontendUser) (SeqDict (Discord.Id Discord.UserId) DiscordFrontendCurrentUser)


type alias DiscordFrontendCurrentUser =
    { name : PersonName
    , icon : Maybe FileHash
    , email : Maybe EmailAddress
    , needsAuthAgain : Bool
    , linkedAt : Time.Posix
    , isLoadingData : DiscordUserLoadingData
    }


getLinkedUser : Discord.Id Discord.UserId -> LinkedAndOtherDiscordUsers -> Maybe DiscordFrontendCurrentUser
getLinkedUser userId (LinkedAndOtherDiscordUsers _ a) =
    SeqDict.get userId a


linkedUsers : LinkedAndOtherDiscordUsers -> SeqDict (Discord.Id Discord.UserId) DiscordFrontendCurrentUser
linkedUsers (LinkedAndOtherDiscordUsers _ a) =
    a


addLinkedUser : Discord.Id Discord.UserId -> DiscordFrontendCurrentUser -> LinkedAndOtherDiscordUsers -> LinkedAndOtherDiscordUsers
addLinkedUser userId linkedUser (LinkedAndOtherDiscordUsers otherUsers linkedUsers2) =
    LinkedAndOtherDiscordUsers (SeqDict.remove userId otherUsers) (SeqDict.insert userId linkedUser linkedUsers2)


{-| Only adds other user if they aren't already a linked user
-}
addOtherUser : Discord.Id Discord.UserId -> DiscordFrontendUser -> LinkedAndOtherDiscordUsers -> LinkedAndOtherDiscordUsers
addOtherUser userId otherUser ((LinkedAndOtherDiscordUsers otherUsers linkedUsers2) as linkedAndOther) =
    if SeqDict.member userId linkedUsers2 then
        linkedAndOther

    else
        LinkedAndOtherDiscordUsers (SeqDict.insert userId otherUser otherUsers) linkedUsers2


updateLinkedUser :
    Discord.Id Discord.UserId
    -> (DiscordFrontendCurrentUser -> DiscordFrontendCurrentUser)
    -> LinkedAndOtherDiscordUsers
    -> LinkedAndOtherDiscordUsers
updateLinkedUser userId updateFunc (LinkedAndOtherDiscordUsers otherUsers linkedUsers2) =
    LinkedAndOtherDiscordUsers otherUsers (SeqDict.updateIfExists userId updateFunc linkedUsers2)


isLinkedUser : Discord.Id Discord.UserId -> LinkedAndOtherDiscordUsers -> Bool
isLinkedUser userId (LinkedAndOtherDiscordUsers _ a) =
    SeqDict.member userId a


getOtherUser : Discord.Id Discord.UserId -> LinkedAndOtherDiscordUsers -> Maybe DiscordFrontendUser
getOtherUser userId (LinkedAndOtherDiscordUsers otherUsers _) =
    SeqDict.get userId otherUsers


discordCurrentUserToFrontend : DiscordFrontendCurrentUser -> DiscordFrontendUser
discordCurrentUserToFrontend user =
    { name = user.name
    , icon = user.icon
    }


allDiscordUsers : LinkedAndOtherDiscordUsers -> SeqDict (Discord.Id Discord.UserId) DiscordFrontendUser
allDiscordUsers (LinkedAndOtherDiscordUsers otherUsers a) =
    SeqDict.union (SeqDict.map (\_ user -> discordCurrentUserToFrontend user) a) otherUsers
