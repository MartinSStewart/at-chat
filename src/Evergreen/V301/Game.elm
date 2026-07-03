module Evergreen.V301.Game exposing (..)

import Array
import Evergreen.V301.Go
import Evergreen.V301.Id
import Evergreen.V301.Message
import Evergreen.V301.SecretId
import Evergreen.V301.UserSession
import Evergreen.V301.WordSpellingGame


type Msg
    = GoGameMsg Evergreen.V301.Go.GameMsg
    | GoSetupMsg Evergreen.V301.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V301.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V301.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V301.Message.Game
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V301.Go.ValidatedSetup (Array.Array Evergreen.V301.Go.ActionWithTime) Evergreen.V301.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V301.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V301.WordSpellingGame.ActionWithTime) Evergreen.V301.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V301.SecretId.SecretId Evergreen.V301.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) (Evergreen.V301.UserSession.ToBeFilledInByBackend (Evergreen.V301.SecretId.SecretId Evergreen.V301.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) Evergreen.V301.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V301.Id.Id Evergreen.V301.Id.ChannelMessageId) Evergreen.V301.WordSpellingGame.LocalChange


type Model
    = GoModel_Setup Evergreen.V301.Go.SetupModel
    | GoModel_Game Evergreen.V301.Go.GameModel
    | WordSpellingGame_Setup Evergreen.V301.WordSpellingGame.SetupModel
    | WordSpellingGame_Game Evergreen.V301.WordSpellingGame.GameData


type BackendGameData
    = GameData_Go Evergreen.V301.Go.ValidatedSetup (Array.Array Evergreen.V301.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V301.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V301.WordSpellingGame.ActionWithTime) Evergreen.V301.WordSpellingGame.Shared
