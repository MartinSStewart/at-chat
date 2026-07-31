module Evergreen.V341.Game exposing (..)

import Array
import Evergreen.V341.Go
import Evergreen.V341.Id
import Evergreen.V341.Message
import Evergreen.V341.SecretId
import Evergreen.V341.UserSession
import Evergreen.V341.WordSpellingGame
import SeqDict


type Msg
    = GoGameMsg Evergreen.V341.Go.GameMsg
    | GoSetupMsg Evergreen.V341.Go.SetupMsg
    | WordSpellingGameMsg Evergreen.V341.WordSpellingGame.GameMsg
    | WordSpellingSetupMsg Evergreen.V341.WordSpellingGame.SetupMsg
    | PressedShareMatch (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId)
    | PressedCopyLink String
    | SelectedMatch (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId)
    | PressedReset
    | PressedSelectGame Evergreen.V341.Message.GameType
    | NoOpMsg


type FrontendGameData
    = FrontendGameData_Go Evergreen.V341.Go.ValidatedSetup (Array.Array Evergreen.V341.Go.ActionWithTime) Evergreen.V341.Go.Shared
    | FrontendGameData_WordSpellingGame Evergreen.V341.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V341.WordSpellingGame.ActionWithTime) Evergreen.V341.WordSpellingGame.Shared


type MatchData
    = MatchData
        { data : FrontendGameData
        , publicLink : Maybe (Evergreen.V341.SecretId.SecretId Evergreen.V341.Id.GamePublicId)
        }


type LocalChange
    = CreatePublicLink (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) (Evergreen.V341.UserSession.ToBeFilledInByBackend (Evergreen.V341.SecretId.SecretId Evergreen.V341.Id.GamePublicId))
    | LocalChange_Go (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) Evergreen.V341.Go.LocalChange
    | LocalChange_WordSpellingGame (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) Evergreen.V341.WordSpellingGame.LocalChange


type Game
    = GoModel_Game Evergreen.V341.Go.GameModel
    | WordSpellingGame_Game Evergreen.V341.WordSpellingGame.GameData


type Setup
    = GameSelect
    | GoModel_Setup Evergreen.V341.Go.SetupModel
    | WordSpellingGame_Setup Evergreen.V341.WordSpellingGame.SetupModel


type alias Model =
    { startedGames : SeqDict.SeqDict (Evergreen.V341.Id.Id Evergreen.V341.Id.ChannelMessageId) Game
    , setup : Setup
    }


type BackendGameData
    = GameData_Go Evergreen.V341.Go.ValidatedSetup (Array.Array Evergreen.V341.Go.ActionWithTime)
    | GameData_WordSpellingGame Evergreen.V341.WordSpellingGame.ValidatedSetup (Array.Array Evergreen.V341.WordSpellingGame.ActionWithTime) Evergreen.V341.WordSpellingGame.Shared
