module Evergreen.V302.Game exposing (..)

import Array
import Evergreen.V302.Go
import Evergreen.V302.Id
import Evergreen.V302.Message
import Evergreen.V302.SecretId
import Evergreen.V302.UserSession
import Evergreen.V302.WordSpellingGame


type Msg
    = GoGameMsg Evergreen.V302.Go.GameMsg
    | GoSetupMsg Evergreen.V302.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V302.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V302.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V302.Message.Game
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V302.Go.ValidatedSetup (Array.Array Evergreen.V302.Go.ActionWithTime) Evergreen.V302.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V302.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V302.WordSpellingGame.ActionWithTime) Evergreen.V302.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V302.SecretId.SecretId Evergreen.V302.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) (Evergreen.V302.UserSession.ToBeFilledInByBackend (Evergreen.V302.SecretId.SecretId Evergreen.V302.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) Evergreen.V302.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V302.Id.Id Evergreen.V302.Id.ChannelMessageId) Evergreen.V302.WordSpellingGame.LocalChange


type Model
    = GoModel_Setup Evergreen.V302.Go.SetupModel
    | GoModel_Game Evergreen.V302.Go.GameModel
    | WordSpellingGame_Setup Evergreen.V302.WordSpellingGame.SetupModel
    | WordSpellingGame_Game Evergreen.V302.WordSpellingGame.GameData


type BackendGameData
    = GameData_Go Evergreen.V302.Go.ValidatedSetup (Array.Array Evergreen.V302.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V302.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V302.WordSpellingGame.ActionWithTime) Evergreen.V302.WordSpellingGame.Shared
