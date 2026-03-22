module MembersAndOwner exposing
    ( IsMember(..)
    , MembersAndOwner(..)
    , addMember
    , addOrUpdateMember
    , init
    , isMember
    , members
    , membersAndOwner
    , owner
    , removeMember
    )

import SeqDict exposing (SeqDict)


{-| OpaqueVariants
-}
type MembersAndOwner userId a
    = MembersAndOwner (SeqDict userId a) userId


init : SeqDict userId a -> userId -> MembersAndOwner userId a
init members2 ownerId =
    MembersAndOwner (SeqDict.remove ownerId members2) ownerId


type IsMember
    = IsMember
    | IsOwner
    | IsNotMember


isMember : userId -> MembersAndOwner userId a -> IsMember
isMember userId (MembersAndOwner members2 ownerId) =
    if userId == ownerId then
        IsOwner

    else if SeqDict.member userId members2 then
        IsMember

    else
        IsNotMember


removeMember : userId -> MembersAndOwner userId a -> MembersAndOwner userId a
removeMember userId (MembersAndOwner members2 ownerId) =
    MembersAndOwner (SeqDict.remove userId members2) ownerId


owner : MembersAndOwner userId a -> userId
owner (MembersAndOwner _ ownerId) =
    ownerId


membersAndOwner : MembersAndOwner userId a -> List userId
membersAndOwner (MembersAndOwner members2 ownerId) =
    ownerId :: SeqDict.keys members2


members : MembersAndOwner userId a -> SeqDict userId a
members (MembersAndOwner members2 _) =
    members2


addOrUpdateMember : userId -> a -> MembersAndOwner userId a -> MembersAndOwner userId a
addOrUpdateMember userId user ((MembersAndOwner members2 ownerId) as data) =
    if userId == ownerId then
        data

    else
        MembersAndOwner (SeqDict.insert userId user members2) ownerId


addMember : userId -> a -> MembersAndOwner userId a -> Result () (MembersAndOwner userId a)
addMember userId user (MembersAndOwner members2 ownerId) =
    if userId == ownerId then
        Err ()

    else if SeqDict.member userId members2 then
        Err ()

    else
        MembersAndOwner (SeqDict.insert userId user members2) ownerId |> Ok
