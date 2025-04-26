module LocalState exposing
    ( AdminData
    , AdminStatus(..)
    , LocalState
    , LogWithTime
    , NotAdminData
    , createNewUser
    , currentUser
    , getUser
    , isAdmin
    , updateUser
    )

import Effect.Time as Time
import EmailAddress exposing (EmailAddress)
import Id exposing (Id, UserId)
import Log exposing (Log)
import NonemptyDict exposing (NonemptyDict)
import PersonName exposing (PersonName)
import SeqDict exposing (SeqDict)
import SeqSet
import Unsafe
import User exposing (BackendUser, EmailNotifications(..), FrontendUser)


type alias LocalState =
    { userId : Id UserId
    , adminData : AdminStatus
    }


type AdminStatus
    = IsAdmin AdminData
    | IsNotAdmin NotAdminData


type alias NotAdminData =
    { user : BackendUser
    , otherUsers : SeqDict (Id UserId) FrontendUser
    }


type alias LogWithTime =
    { time : Time.Posix, log : Log }


type alias AdminData =
    { users : NonemptyDict (Id UserId) BackendUser
    , emailNotificationsEnabled : Bool
    , twoFactorAuthentication : SeqDict (Id UserId) Time.Posix
    }


missingUserEmail : EmailAddress
missingUserEmail =
    Unsafe.emailAddress "missing.user@example.com"


currentUser : LocalState -> BackendUser
currentUser localState =
    case localState.adminData of
        IsAdmin data ->
            case NonemptyDict.get localState.userId data.users of
                Just user ->
                    user

                Nothing ->
                    -- This should never happen
                    createNewUser
                        (Time.millisToPosix 0)
                        PersonName.unknown
                        missingUserEmail
                        False

        IsNotAdmin data ->
            data.user


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
getUser userId localState =
    case localState.adminData of
        IsAdmin data ->
            NonemptyDict.get userId data.users |> Maybe.map User.backendToFrontend

        IsNotAdmin data ->
            if localState.userId == userId then
                User.backendToFrontend data.user |> Just

            else
                SeqDict.get userId data.otherUsers


updateUser : Id UserId -> (BackendUser -> BackendUser) -> LocalState -> LocalState
updateUser userId updateFunc localState =
    { localState
        | adminData =
            case localState.adminData of
                IsAdmin data ->
                    IsAdmin { data | users = NonemptyDict.updateIfExists userId updateFunc data.users }

                IsNotAdmin data ->
                    if localState.userId == userId then
                        IsNotAdmin { data | user = updateFunc data.user }

                    else
                        IsNotAdmin data
    }


isAdmin : LocalState -> Bool
isAdmin { adminData } =
    case adminData of
        IsAdmin _ ->
            True

        IsNotAdmin _ ->
            False
