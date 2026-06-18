module LinkedAndOtherDiscordUsers exposing
    ( DiscordFrontendCurrentUser
    , LinkedAndOtherDiscordUsers(..)
    , addLinkedUser
    , addOtherUser
    , allDiscordUsers
    , discordCurrentUserToFrontend
    , getLinkedUser
    , getOtherUser
    , init
    , isLinkedUser
    , linkedUsers
    , otherUsers
    , unlinkUser
    , updateLinkedUser
    , updateOtherUser
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


init :
    SeqDict (Discord.Id Discord.UserId) DiscordFrontendUser
    -> SeqDict (Discord.Id Discord.UserId) DiscordFrontendCurrentUser
    -> LinkedAndOtherDiscordUsers
init =
    LinkedAndOtherDiscordUsers


getLinkedUser : Discord.Id Discord.UserId -> LinkedAndOtherDiscordUsers -> Maybe DiscordFrontendCurrentUser
getLinkedUser userId (LinkedAndOtherDiscordUsers _ a) =
    SeqDict.get userId a


linkedUsers : LinkedAndOtherDiscordUsers -> SeqDict (Discord.Id Discord.UserId) DiscordFrontendCurrentUser
linkedUsers (LinkedAndOtherDiscordUsers _ a) =
    a


otherUsers : LinkedAndOtherDiscordUsers -> SeqDict (Discord.Id Discord.UserId) DiscordFrontendUser
otherUsers (LinkedAndOtherDiscordUsers a _) =
    a


addLinkedUser : Discord.Id Discord.UserId -> DiscordFrontendCurrentUser -> LinkedAndOtherDiscordUsers -> LinkedAndOtherDiscordUsers
addLinkedUser userId linkedUser (LinkedAndOtherDiscordUsers otherUsers2 linkedUsers2) =
    LinkedAndOtherDiscordUsers (SeqDict.remove userId otherUsers2) (SeqDict.insert userId linkedUser linkedUsers2)


{-| Only adds other user if they aren't already a linked user
-}
addOtherUser : Discord.Id Discord.UserId -> DiscordFrontendUser -> LinkedAndOtherDiscordUsers -> LinkedAndOtherDiscordUsers
addOtherUser userId otherUser ((LinkedAndOtherDiscordUsers otherUsers2 linkedUsers2) as linkedAndOther) =
    if SeqDict.member userId linkedUsers2 then
        linkedAndOther

    else
        LinkedAndOtherDiscordUsers (SeqDict.insert userId otherUser otherUsers2) linkedUsers2


updateOtherUser :
    Discord.Id Discord.UserId
    -> (Maybe DiscordFrontendUser -> DiscordFrontendUser)
    -> LinkedAndOtherDiscordUsers
    -> LinkedAndOtherDiscordUsers
updateOtherUser userId updateFunc (LinkedAndOtherDiscordUsers otherUsers2 linkedUsers2) =
    LinkedAndOtherDiscordUsers (SeqDict.update userId (\a -> updateFunc a |> Just) otherUsers2) linkedUsers2


updateLinkedUser :
    Discord.Id Discord.UserId
    -> (DiscordFrontendCurrentUser -> DiscordFrontendCurrentUser)
    -> LinkedAndOtherDiscordUsers
    -> LinkedAndOtherDiscordUsers
updateLinkedUser userId updateFunc (LinkedAndOtherDiscordUsers otherUsers2 linkedUsers2) =
    LinkedAndOtherDiscordUsers otherUsers2 (SeqDict.updateIfExists userId updateFunc linkedUsers2)


isLinkedUser : Discord.Id Discord.UserId -> LinkedAndOtherDiscordUsers -> Bool
isLinkedUser userId (LinkedAndOtherDiscordUsers _ a) =
    SeqDict.member userId a


getOtherUser : Discord.Id Discord.UserId -> LinkedAndOtherDiscordUsers -> Maybe DiscordFrontendUser
getOtherUser userId (LinkedAndOtherDiscordUsers otherUsers2 _) =
    SeqDict.get userId otherUsers2


discordCurrentUserToFrontend : DiscordFrontendCurrentUser -> DiscordFrontendUser
discordCurrentUserToFrontend user =
    { name = user.name
    , icon = user.icon
    }


allDiscordUsers : LinkedAndOtherDiscordUsers -> SeqDict (Discord.Id Discord.UserId) DiscordFrontendUser
allDiscordUsers (LinkedAndOtherDiscordUsers otherUsers2 a) =
    SeqDict.union (SeqDict.map (\_ user -> discordCurrentUserToFrontend user) a) otherUsers2


unlinkUser : Discord.Id Discord.UserId -> LinkedAndOtherDiscordUsers -> LinkedAndOtherDiscordUsers
unlinkUser userId ((LinkedAndOtherDiscordUsers otherUsers2 linkedUsers2) as linkedAndOther) =
    case SeqDict.get userId linkedUsers2 of
        Just discordUser ->
            LinkedAndOtherDiscordUsers
                (SeqDict.insert userId (discordCurrentUserToFrontend discordUser) otherUsers2)
                (SeqDict.remove userId linkedUsers2)

        Nothing ->
            linkedAndOther
